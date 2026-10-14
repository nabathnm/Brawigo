import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brawigo/features/marketplace/presentation/pages/buyer_product_detail_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final Map<String, String>? productData;
  final bool sendProductMention;

  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    this.productData,
    this.sendProductMention = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingImage = false;
  Map<String, String>? _productData;

  @override
  void initState() {
    super.initState();
    _productData = widget.productData;
    _loadMessages();
    _subscribeToMessages();
    _markMessagesAsRead();
    if (_productData == null) {
      _loadProductFromDb();
    }
    if (widget.sendProductMention && widget.productData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendProductMention();
      });
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, message, sender_id, created_at, is_read')
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('room_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final newMsg = payload.newRecord;
            if (mounted) {
              setState(() {
                _messages.add(newMsg);
              });
              _scrollToBottom();
              _markMessagesAsRead();
            }
          },
        )
        .subscribe();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', widget.conversationId)
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': currentUser.id,
        'message': text.trim(),
        'is_read': false,
      });
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.conversationId);
    } catch (_) {}
    
    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  Future<void> _loadProductFromDb() async {
    try {
      final conv = await _supabase
          .from('conversations')
          .select('product_id')
          .eq('id', widget.conversationId)
          .maybeSingle();
      final productId = conv?['product_id'];
      if (productId != null && productId.toString().isNotEmpty) {
        final prod = await _supabase
            .from('products')
            .select('id, product_name, price, thumbnail_url, seller_id')
            .eq('id', productId)
            .maybeSingle();
        if (prod != null && mounted) {
          String imageUrl = prod['thumbnail_url']?.toString() ?? '';
          if (imageUrl.isEmpty) {
            final imgRes = await _supabase
                .from('product_images')
                .select('image_url')
                .eq('product_id', productId)
                .order('image_order', ascending: true)
                .limit(1)
                .maybeSingle();
            imageUrl = imgRes?['image_url']?.toString() ?? '';
          }
          setState(() {
            _productData = {
              'id': prod['id']?.toString() ?? '',
              'name': prod['product_name']?.toString() ?? '',
              'product_name': prod['product_name']?.toString() ?? '',
              'price': prod['price']?.toString() ?? '',
              'image_url': imageUrl,
              'thumbnail_url': imageUrl,
            };
          });
        }
      }
    } catch (_) {}
  }

  String _formatPrice(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('Rp')) return raw;
    final numVal = num.tryParse(raw);
    if (numVal != null) {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(numVal);
    }
    return 'Rp $raw';
  }

  Future<void> _sendProductMention() async {
    final p = _productData ?? widget.productData;
    if (p == null) return;
    final name = (p['product_name'] != null && p['product_name']!.isNotEmpty)
        ? p['product_name']!
        : ((p['name'] != null && p['name']!.isNotEmpty) ? p['name']! : 'Produk');
    final price = _formatPrice(p['price']);
    final mention = '🛍️ Menanyakan produk: $name\nHarga: $price';
    await _sendMessage(mention);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(isoTime).toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15243C), size: 20),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4A7EBB),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFF2B5F9E)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF2B5F9E)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if ((_productData ?? widget.productData) != null) _buildProductCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Mulai percakapan...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == currentUserId;
                          return _MessageBubble(
                            message: msg['message'] ?? '',
                            isMe: isMe,
                            time: _formatTime(msg['created_at']),
                          );
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Future<void> _openProductDetail(String productId) async {
    if (productId.isEmpty) return;
    try {
      final res = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();
      if (res != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerProductDetailPage(
              product: Map<String, dynamic>.from(res),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka produk: $e')),
        );
      }
    }
  }

  Widget _buildProductCard() {
    final p = _productData ?? widget.productData;
    if (p == null) return const SizedBox.shrink();

    final productId = p['id'] ?? p['product_id'] ?? '';
    final name = (p['product_name'] != null && p['product_name']!.isNotEmpty)
        ? p['product_name']!
        : ((p['name'] != null && p['name']!.isNotEmpty) ? p['name']! : 'Produk');
    final imageUrl = (p['thumbnail_url'] != null && p['thumbnail_url']!.isNotEmpty)
        ? p['thumbnail_url']!
        : (p['image_url'] ?? '');
    final price = _formatPrice(p['price']);

    return InkWell(
      onTap: () => _openProductDetail(productId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15243C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B5F9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
    );
  }

  Future<void> _showAttachmentBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim Gambar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: const Color(0xFF2B5F9E),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15243C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last.toLowerCase();
      final cleanExt = (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp') ? ext : 'jpg';
      final fileName = 'chat/${widget.conversationId}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      await _supabase.storage.from('product_images').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$cleanExt'),
          );

      final imageUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);

      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': currentUser.id,
        'message': '[IMAGE]: $imageUrl',
        'is_read': false,
      });

      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _isUploadingImage ? null : _showAttachmentBottomSheet,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2B5F9E)),
                    )
                  : const Icon(Icons.attach_file_rounded, color: Color(0xFF94A3B8)),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Kak masih ada?',
                    hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B5F9E),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
  });

  bool get _isImage => message.trim().startsWith('[IMAGE]:');

  String get _imageUrl {
    if (!_isImage) return '';
    return message.trim().replaceFirst('[IMAGE]:', '').trim();
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: _isImage
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2B5F9E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isImage
                  ? GestureDetector(
                      onTap: () => _showFullScreenImage(context, _imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: Image.network(
                            _imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : const Color(0xFF15243C),
                        height: 1.4,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
