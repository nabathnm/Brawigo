import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';
import 'package:brawigo/features/order/presentation/pages/rating_page.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String? _sellerStoreAddress;
  String? _errorMessage;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Upload state
  XFile? _courierProofImage;
  XFile? _pickupProofImage;
  XFile? _paymentProofImage;
  bool _isActionSubmitting = false;

  Map<String, dynamic>? _existingReview;
  Map<String, dynamic>? _otherUserProfile;

  String? _getRejectionReason(Map<String, dynamic> order) {
    if (order['rejection_reason'] != null && order['rejection_reason'].toString().isNotEmpty) {
      return order['rejection_reason'].toString();
    }
    final n = order['notes']?.toString() ?? '';
    if (n.startsWith('Ditolak Penjual:')) {
      return n.replaceFirst('Ditolak Penjual:', '').trim();
    }
    return null;
  }

  String? _getBuyerNotes(Map<String, dynamic> order) {
    final n = order['notes']?.toString() ?? '';
    if (n.startsWith('Ditolak Penjual:')) {
      return null;
    }
    return n.isNotEmpty ? n : null;
  }

  num _parseAmount(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
      return num.tryParse(clean) ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final data = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      String? sAddress = data['seller_address']?.toString();
      if ((sAddress == null || sAddress.isEmpty) && data['seller_id'] != null) {
        try {
          final sProfile = await _supabase
              .from('profiles')
              .select('bio')
              .eq('id', data['seller_id'])
              .maybeSingle();
          if (sProfile != null && sProfile['bio'] != null) {
            final bioMap = jsonDecode(sProfile['bio'].toString());
            if (bioMap is Map && bioMap['store_address'] != null) {
              sAddress = bioMap['store_address'].toString();
            }
          }
        } catch (_) {}
      }

      // Fetch user profile (lawan bicara)
      final currentUserId = _supabase.auth.currentUser?.id;
      final targetUserId = currentUserId == data['seller_id'] ? data['buyer_id'] : data['seller_id'];
      Map<String, dynamic>? otherProfile;
      if (targetUserId != null) {
        try {
          otherProfile = await _supabase
              .from('profiles')
              .select()
              .eq('id', targetUserId)
              .maybeSingle();
        } catch (_) {}
      }

      // Fetch existing review jika ada
      Map<String, dynamic>? existingReview;
      try {
        existingReview = await _supabase
            .from('reviews')
            .select()
            .eq('order_id', widget.orderId)
            .maybeSingle();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _order = data;
          _sellerStoreAddress = sAddress;
          _otherUserProfile = otherProfile;
          _existingReview = existingReview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getPickupMethod(Map<String, dynamic> order) {
    if (order['pickup_method'] != null && order['pickup_method'].toString().isNotEmpty) {
      return order['pickup_method'].toString().toLowerCase();
    }
    final loc = (order['meetup_location'] ?? '').toString().toLowerCase();
    if (loc.contains('kurir') || loc.contains('ojol') || loc.contains('ojek')) return 'kurir';
    if (loc.contains('ambil') || loc.contains('pickup')) return 'pickup';
    return 'cod';
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() {
        if (type == 'courier') _courierProofImage = picked;
        if (type == 'pickup') _pickupProofImage = picked;
        if (type == 'payment') _paymentProofImage = picked;
      });
    }
  }

  Future<String?> _uploadImageFile(XFile file, String folder) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final uid = _supabase.auth.currentUser?.id ?? 'user';
    final fileName = '$folder/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('product_images').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
    return _supabase.storage.from('product_images').getPublicUrl(fileName);
  }

  Future<void> _sendChatUpdate(String message) async {
    final order = _order;
    if (order == null) return;
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final buyerId = order['buyer_id']?.toString() ?? '';
    final sellerId = order['seller_id']?.toString() ?? '';
    if (buyerId.isEmpty || sellerId.isEmpty) return;

    try {
      final existingConv = await _supabase
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .limit(1);

      String? convId;
      final List convList = existingConv as List;
      if (convList.isNotEmpty) {
        convId = convList.first['id'];
      }

      if (convId != null) {
        await _supabase.from('messages').insert({
          'conversation_id': convId,
          'sender_id': currentUser.id,
          'message': message,
          'is_read': false,
        });

        await _supabase
            .from('conversations')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', convId);
      }
    } catch (_) {}
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              context.read<OrderBloc>().add(UpdateOrderStatus(orderId: widget.orderId, status: 'cancelled'));
              final productName = _order?['product_name_snapshot'] ?? 'produk';
              await _sendChatUpdate("❌ Pesanan '$productName' telah dibatalkan.");
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showProofDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'completed') {
      return {
        'label': 'Pesanan Selesai',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF16A34A),
        'icon': Icons.task_alt_rounded,
      };
    } else if (status == 'cancelled') {
      return {
        'label': 'Pesanan Dibatalkan',
        'bg': const Color(0xFFFEE2E2),
        'text': const Color(0xFFDC2626),
        'icon': Icons.cancel_outlined,
      };
    } else if (status == 'waiting_payment_courier') {
      return {
        'label': 'Menunggu Pembayaran & Pemesanan Kurir',
        'bg': const Color(0xFFE0F2FE),
        'text': const Color(0xFF0284C7),
        'icon': Icons.delivery_dining_rounded,
      };
    } else if (status == 'waiting_pickup') {
      return {
        'label': 'Menunggu Barang Diambil Kurir',
        'bg': const Color(0xFFEDE9FE),
        'text': const Color(0xFF7C3AED),
        'icon': Icons.inventory_2_outlined,
      };
    } else if (status == 'on_delivery') {
      return {
        'label': 'Barang Sedang Diantar Kurir',
        'bg': const Color(0xFFE0E7FF),
        'text': const Color(0xFF4F46E5),
        'icon': Icons.moped_rounded,
      };
    } else if (status == 'waiting_meetup') {
      return {
        'label': 'Dalam Proses Meetup',
        'bg': const Color(0xFFE6EDF8),
        'text': const Color(0xFF2B5F9E),
        'icon': Icons.handshake_outlined,
      };
    } else if (status == 'ready_for_pickup') {
      return {
        'label': 'Siap Diambil di Lokasi Toko',
        'bg': const Color(0xFFE6EDF8),
        'text': const Color(0xFF2B5F9E),
        'icon': Icons.store_mall_directory_outlined,
      };
    } else if (status == 'confirmed') {
      return {
        'label': 'Dikonfirmasi / Diproses',
        'bg': const Color(0xFFE6EDF8),
        'text': const Color(0xFF2B5F9E),
        'icon': Icons.check_circle_outline_rounded,
      };
    } else {
      return {
        'label': 'Menunggu Konfirmasi Penjual',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFFD97706),
        'icon': Icons.hourglass_top_rounded,
      };
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID').format(dt) + ' WIB';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderBloc(),
      child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8DAEF), Color(0xFFE6EDF8), Color(0xFFFAFAFA)],
          stops: [0.0, 0.2, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF15243C),
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          title: const Text(
            'Detail Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C), fontSize: 18),
          ),
        ),
        bottomNavigationBar: _order == null
            ? null
            : _buildBottomBar(
                isSeller: _supabase.auth.currentUser?.id == _order!['seller_id'],
                status: (_order!['order_status'] ?? _order!['status'] ?? 'created').toString().toLowerCase(),
                productId: _order!['product_id']?.toString(),
              ),
        body: BlocConsumer<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderSuccess) {
              BrawigoToast.showSuccess(
                context,
                message: state.message ?? 'Status pesanan berhasil diperbarui.',
                title: 'Berhasil!',
              );
              _fetchOrderDetail();
            } else if (state is OrderError) {
              BrawigoToast.showError(
                context,
                message: state.message,
                title: 'Gagal',
              );
            }
          },
          builder: (context, state) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)));
            }

            if (_order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ?? 'Pesanan tidak ditemukan.',
                        style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5F9E)),
                        onPressed: _fetchOrderDetail,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final order = _order!;
            final productName = order['product_name_snapshot'] ?? 'Produk Brawigo';
            final num totalAmount = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
            final paymentMethod = order['payment_method']?.toString() ?? 'COD';
            final rawStatus = (order['order_status'] ?? order['status'] ?? 'created').toString();
            final statusCfg = _getStatusConfig(rawStatus);
            final String? paymentProofUrl = order['payment_proof_url']?.toString();
            final String? courierProofUrl = order['courier_proof_url']?.toString();
            final String? pickupProofUrl = order['pickup_proof_url']?.toString();
            final meetupLocation = order['meetup_location'] ?? '-';
            final meetupTime = order['meetup_time'] ?? '-';
            final quantity = order['quantity']?.toString() ?? '1';
            // notes read via helper
            final createdAt = _formatDate(order['created_at']?.toString());
            final thumbnailUrl = order['thumbnail_url_snapshot'] as String?;

            final currentUserId = _supabase.auth.currentUser?.id;
            final isSeller = currentUserId == order['seller_id'];
            final pickupMethod = _getPickupMethod(order);
            final s = rawStatus.toLowerCase();

            return RefreshIndicator(
              onRefresh: _fetchOrderDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Status Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status Pesanan', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  statusCfg['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: statusCfg['text'] as Color,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusCfg['bg'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(statusCfg['icon'] as IconData, color: statusCfg['text'] as Color, size: 22),
                            ),
                          ],
                        ),
                        if (pickupMethod == 'kurir' && s != 'completed' && s != 'cancelled') ...[
                          const SizedBox(height: 14),
                          _buildCourierStepper(s),
                        ],
                        if (pickupMethod == 'pickup' && s != 'cancelled') ...[
                          const SizedBox(height: 14),
                          _buildSelfPickupStepper(s),
                        ],
                        if (s == 'cancelled') ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Alasan Pembatalan:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getRejectionReason(order) ?? 'Pesanan telah dibatalkan.',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Product Information Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Produk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      thumbnailUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jumlah: $quantity item',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2B5F9E), fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Lokasi & Pengiriman Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lokasi & Pengiriman',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pickupMethod == 'kurir'
                                    ? 'Kurir Instan'
                                    : 'Self Pick-Up',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          pickupMethod == 'kurir'
                              ? Icons.home_outlined
                              : Icons.storefront_rounded,
                          pickupMethod == 'kurir'
                              ? 'Alamat Tujuan (Pembeli)'
                              : 'Lokasi Pengambilan (Toko Penjual)',
                          (pickupMethod == 'pickup' && (_sellerStoreAddress != null && _sellerStoreAddress!.isNotEmpty))
                              ? _sellerStoreAddress!
                              : meetupLocation,
                        ),
                        if (meetupTime.isNotEmpty && meetupTime != '-') ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.access_time_rounded, 'Waktu Pengambilan / Bertemu', meetupTime),
                        ],
                        if (_getBuyerNotes(order) != null) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.notes_rounded, 'Catatan Pembeli', _getBuyerNotes(order)!),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Waktu Transaksi', createdAt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Card Alamat Toko Penjual (Khusus Kurir Instan & Self Pick-up)
                  if ((pickupMethod == 'kurir' || pickupMethod == 'pickup') &&
                      _sellerStoreAddress != null &&
                      _sellerStoreAddress!.isNotEmpty) ...[
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storefront_rounded, color: Color(0xFF2B5F9E), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Alamat Toko Penjual (Titik Jemput)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _sellerStoreAddress!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Alamat toko penjual disalin ke clipboard!')),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2B5F9E)),
                                      SizedBox(width: 4),
                                      Text('Salin', style: TextStyle(color: Color(0xFF2B5F9E), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sellerStoreAddress!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                          ),
                          if (pickupMethod == 'kurir') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Gunakan alamat penjual di atas sebagai titik penjemputan (Pickup) saat memesan kurir ojek online (GoSend/Grab/Maxim).',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 5. Card Bukti Pembayaran
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                paymentMethod,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2B5F9E)),
                              ),
                            ),
                          ],
                        ),
                        if (paymentProofUrl != null && paymentProofUrl.isNotEmpty) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          const Text('Bukti Pembayaran / Transfer:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const SizedBox(height: 8),
                          _buildImageThumbnail(paymentProofUrl, 'Bukti Pembayaran'),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Pembayaran tunai saat transaksi langsung (COD) atau belum mengunggah bukti pembayaran.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Card Bukti Pemesanan Kurir Ojol (Jika ada)
                  if (courierProofUrl != null && courierProofUrl.isNotEmpty) ...[
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Bukti Pemesanan Kurir Ojek Online (dari Pembeli)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildImageThumbnail(courierProofUrl, 'Screenshot Pemesanan Ojol'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 7. Card Bukti Penyerahan Barang ke Kurir (Jika ada)
                  if (pickupProofUrl != null && pickupProofUrl.isNotEmpty) ...[
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Color(0xFF7C3AED), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Foto Penyerahan Barang ke Kurir (dari Penjual)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _buildImageThumbnail(pickupProofUrl, 'Foto Penyerahan ke Kurir'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 8. Informasi Profil (Penjual / Pembeli)
                  _buildUserCard(isSeller),
                  const SizedBox(height: 14),

                  // 9. Action Area Berdasarkan Status & Role
                  _buildActionArea(
                    isSeller: isSeller,
                    pickupMethod: pickupMethod,
                    status: s,
                    productName: productName,
                    paymentProofUrl: paymentProofUrl,
                    courierProofUrl: courierProofUrl,
                    pickupProofUrl: pickupProofUrl,
                  ),
                ],
              ),
            ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildCourierStepper(String currentStatus) {
    int activeStep = 0;
    if (currentStatus == 'waiting_payment_courier') {
      activeStep = 1;
    } else if (currentStatus == 'waiting_pickup') {
      activeStep = 2;
    } else if (currentStatus == 'on_delivery') {
      activeStep = 3;
    } else if (currentStatus == 'completed') {
      activeStep = 4;
    }

    final steps = ['Konfirmasi\nSeller', 'Pesan\nKurir', 'Pickup\nKurir', 'Barang\nDiantar', 'Selesai'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isPassed = index <= activeStep;
        final isCurrent = index == activeStep;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index > 0
                          ? (index <= activeStep ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0))
                          : Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < steps.length - 1
                          ? (index < activeStep ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0))
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? const Color(0xFF2B5F9E) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSelfPickupStepper(String currentStatus) {
    int activeStep = 0;
    if (currentStatus == 'confirmed') {
      activeStep = 1;
    } else if (currentStatus == 'waiting_meetup') {
      activeStep = 2;
    } else if (currentStatus == 'completed') {
      activeStep = 3;
    }

    final steps = ['Pesanan\nDibuat', 'Pesanan\nDikonfirmasi', 'Proses\nMeetup', 'Selesai'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isPassed = index <= activeStep;
        final isCurrent = index == activeStep;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index > 0
                          ? (index <= activeStep ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0))
                          : Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
                    ),
                    child: Center(
                      child: isPassed && !isCurrent
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < steps.length - 1
                          ? (index < activeStep ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0))
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? const Color(0xFF2B5F9E) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showRejectOrderDialog(String productName) {
    String? selectedReason;
    final reasons = [
      'Barang sudah tidak tersedia',
      'Stok produk tidak sesuai',
      'Tidak dapat memenuhi permintaan COD',
      'Lokasi atau jadwal tidak memungkinkan',
      'Buyer tidak merespons',
      'Tidak menerima pembayaran',
      'Alasan lainnya',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final order = _order!;
            final thumbnailUrl = order['thumbnail_url_snapshot'] as String?;
            final price = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
            final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tolak pesanan?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15243C),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Product info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                              ? Image.network(thumbnailUrl, width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFFE2E8F0)))
                              : Container(width: 56, height: 56, color: const Color(0xFFE2E8F0),
                                  child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(fmt.format(price),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2B5F9E), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),

                    // Reasons
                    const Text(
                      'Alasan penolakan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih satu alasan untuk disampaikan pada pembeli.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    ...reasons.map((reason) => GestureDetector(
                      onTap: () => setSheetState(() => selectedReason = reason),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: reason,
                              groupValue: selectedReason,
                              onChanged: (v) => setSheetState(() => selectedReason = v),
                              activeColor: const Color(0xFF2B5F9E),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Expanded(
                              child: Text(reason,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 14),

                    // Warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tindakan ini tidak dapat dibatalkan. Stok produk akan dikembalikan secara otomatis.',
                              style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kirim button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedReason != null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: selectedReason == null
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  context.read<OrderBloc>().add(UpdateOrderStatus(
                                    orderId: widget.orderId,
                                    status: 'cancelled',
                                    extraData: {
                                      'notes': 'Ditolak Penjual: $selectedReason',
                                    },
                                  ));
                                  await _sendChatUpdate(
                                    "❌ Penjual menolak pesanan '$productName'. Alasan: $selectedReason. Stok produk akan dikembalikan.",
                                  );
                                }
                              },
                        child: Text(
                          'Kirim',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: selectedReason != null ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionArea({
    required bool isSeller,
    required String pickupMethod,
    required String status,
    required String productName,
    required String? paymentProofUrl,
    required String? courierProofUrl,
    required String? pickupProofUrl,
  }) {
    // -------------------------------------------------------------
    // ALUR 1: KURIR INSTAN
    // -------------------------------------------------------------
    if (pickupMethod == 'kurir') {
      // State 1: Menunggu Konfirmasi Penjual
      if (status == 'waiting_confirmation' || status == 'created' || status == 'pending') {
        if (isSeller) {
          return Column(
            children: [
              _buildBigButton(
                label: 'Konfirmasi Pesanan',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF2B5F9E),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'waiting_payment_courier'),
                  );
                  await _sendChatUpdate("✅ Penjual telah mengonfirmasi pesanan '$productName'. Silakan pesan kurir ojek online dan unggah bukti pemesanan.");
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Tolak Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showRejectOrderDialog(productName),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Menunggu Konfirmasi Penjual',
                message: 'Penjual sedang memeriksa ketersediaan barang. Setelah dikonfirmasi oleh penjual, Anda dapat memesan kurir ojol dan mengunggah buktinya.',
              ),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          );
        }
      }

      // State 2: Menunggu Pembayaran & Pemesanan Kurir (oleh Buyer)
      if (status == 'waiting_payment_courier') {
        if (!isSeller) {
          final sAddress = _sellerStoreAddress ?? _order?['seller_address']?.toString() ?? 'Jl. Bunga Coklat, Malang';
          return _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.moped_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text(
                      'Pemesanan Kurir Mandiri & Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                
                // Box Alamat Penjual yang dapat di-copy
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF0284C7)),
                              SizedBox(width: 6),
                              Text(
                                'Titik Jemput Toko Penjual:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: sAddress));
                              BrawigoToast.showSuccess(
                                context,
                                message: 'Alamat toko penjual disalin ke clipboard!',
                                title: 'Tersalin',
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 13, color: Color(0xFF0284C7)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Salin Alamat',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Petunjuk:\n'
                  '1. Buka aplikasi ojol (GoSend / GrabExpress / Maxim).\n'
                  '2. Masukkan alamat penjual di atas sebagai titik penjemputan.\n'
                  '3. Masukkan alamat Anda sebagai tujuan pengantaran.\n'
                  '4. Screenshot bukti pemesanan ojol lalu unggah di bawah ini.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 14),

                // Upload Screenshot Kurir Ojol
                const Text('Screenshot Pemesanan Ojol (*Wajib):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _buildUploadBox(
                  file: _courierProofImage,
                  label: 'Pilih Screenshot Pemesanan Kurir',
                  onPick: () => _pickImage('courier'),
                ),
                const SizedBox(height: 14),

                // Upload Bukti Pembayaran jika belum diunggah saat checkout
                if (paymentProofUrl == null || paymentProofUrl.isEmpty) ...[
                  const Text('Bukti Pembayaran / Transfer (*Wajib):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildUploadBox(
                    file: _paymentProofImage,
                    label: 'Pilih Bukti Pembayaran / Transfer',
                    onPick: () => _pickImage('payment'),
                  ),
                  const SizedBox(height: 14),
                ],

                _buildBigButton(
                  label: 'Kirim Bukti Pemesanan Kurir',
                  icon: Icons.send_rounded,
                  color: const Color(0xFF0284C7),
                  isLoading: _isActionSubmitting,
                  onPressed: () async {
                    if (_courierProofImage == null) {
                      BrawigoToast.showWarning(
                        context,
                        message: 'Harap unggah screenshot pemesanan kurir ojol terlebih dahulu.',
                        title: 'Bukti Kurir Diperlukan',
                      );
                      return;
                    }

                    if ((paymentProofUrl == null || paymentProofUrl.isEmpty) && _paymentProofImage == null) {
                      BrawigoToast.showWarning(
                        context,
                        message: 'Harap unggah bukti pembayaran / transfer terlebih dahulu.',
                        title: 'Bukti Pembayaran Diperlukan',
                      );
                      return;
                    }

                    setState(() => _isActionSubmitting = true);
                    try {
                      final cUrl = await _uploadImageFile(_courierProofImage!, 'courier_proofs');
                      String? pUrl;
                      if (_paymentProofImage != null) {
                        pUrl = await _uploadImageFile(_paymentProofImage!, 'proofs');
                      }

                      if (mounted) {
                        context.read<OrderBloc>().add(
                          UpdateOrderStatus(
                            orderId: widget.orderId,
                            status: 'waiting_pickup',
                            extraData: {
                              'courier_proof_url': cUrl,
                              if (pUrl != null) 'payment_proof_url': pUrl,
                              if (pUrl != null) 'payment_status': 'paid',
                            },
                          ),
                        );
                        await _sendChatUpdate("🛵 Pembeli telah mengunggah bukti pemesanan kurir & pembayaran untuk '$productName'. Mohon bersiap menyerahkan barang ke kurir.");
                      }
                    } catch (e) {
                      if (mounted) {
                        BrawigoToast.showError(
                          context,
                          message: e,
                          title: 'Gagal Mengunggah Bukti',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isActionSubmitting = false);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildCancelButton(),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                title: 'Menunggu Pembeli Membayar & Memesan Kurir',
                message: 'Pesanan telah Anda konfirmasi. Pembeli sedang memesan kurir ojek online ke alamat toko Anda dan mengunggah buktinya.',
              ),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          );
        }
      }

      // State 3: Menunggu Barang Diambil oleh Kurir (oleh Seller)
      if (status == 'waiting_pickup') {
        if (isSeller) {
          return _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text(
                      'Konfirmasi Pengambilan Barang',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                const Text(
                  'Pembeli telah memesan kurir ojol. Saat driver kurir tiba, serahkan barang dan ambil foto penyerahan sebagai bukti serah terima.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 14),

                const Text('Foto Penyerahan ke Kurir (*Wajib):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _buildUploadBox(
                  file: _pickupProofImage,
                  label: 'Ambil / Unggah Foto Penyerahan Barang',
                  onPick: () => _pickImage('pickup'),
                ),
                const SizedBox(height: 14),

                _buildBigButton(
                  label: 'Konfirmasi Barang Diserahkan ke Kurir',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF7C3AED),
                  isLoading: _isActionSubmitting,
                  onPressed: () async {
                    if (_pickupProofImage == null) {
                      BrawigoToast.showWarning(
                        context,
                        message: 'Harap ambil/unggah foto penyerahan barang ke kurir terlebih dahulu.',
                        title: 'Foto Penyerahan Diperlukan',
                      );
                      return;
                    }

                    setState(() => _isActionSubmitting = true);
                    try {
                      final pUrl = await _uploadImageFile(_pickupProofImage!, 'pickup_proofs');
                      if (mounted) {
                        context.read<OrderBloc>().add(
                          UpdateOrderStatus(
                            orderId: widget.orderId,
                            status: 'on_delivery',
                            extraData: {
                              'pickup_proof_url': pUrl,
                            },
                          ),
                        );
                        await _sendChatUpdate("📦 Penjual telah menyerahkan barang '$productName' ke kurir ojek online. Barang sedang dalam perjalanan ke alamat Anda!");
                      }
                    } catch (e) {
                      if (mounted) {
                        BrawigoToast.showError(
                          context,
                          message: e,
                          title: 'Gagal Mengunggah Foto',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isActionSubmitting = false);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildCancelButton(),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.moped_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFEDE9FE),
                title: 'Kurir Menuju Lokasi Penjual',
                message: 'Bukti pemesanan kurir Anda telah diterima penjual. Penjual sedang bersiap menyerahkan barang ke kurir.',
              ),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          );
        }
      }

      // State 4: Menunggu Barang Sampai (oleh Buyer)
      if (status == 'on_delivery') {
        if (!isSeller) {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFE0E7FF),
                title: 'Barang Sedang Dalam Perjalanan',
                message: 'Kurir ojek online sedang mengantarkan barang menuju alamat Anda. Silakan periksa barang saat diterima.',
              ),
              const SizedBox(height: 14),
              _buildBigButton(
                label: 'Konfirmasi Barang Diterima (Selesai)',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'completed'),
                  );
                  await _sendChatUpdate("🎉 Pembeli telah menerima barang '$productName'. Transaksi selesai!");
                },
              ),
            ],
          );
        } else {
          return _buildInfoBanner(
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFE0E7FF),
            title: 'Barang Sedang Diantar Kurir',
            message: 'Barang telah Anda serahkan ke kurir ojek online dan sedang dalam perjalanan menuju pembeli.',
          );
        }
      }
    }

    // -------------------------------------------------------------
    // ALUR 2: CASH ON DELIVERY (COD)
    // -------------------------------------------------------------
    if (pickupMethod == 'cod') {
      if (status == 'waiting_confirmation' || status == 'created' || status == 'pending') {
        if (isSeller) {
          return Column(
            children: [
              _buildBigButton(
                label: 'Konfirmasi Jadwal & Lokasi COD',
                icon: Icons.handshake_outlined,
                color: const Color(0xFF2B5F9E),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'waiting_meetup'),
                  );
                  await _sendChatUpdate("✅ Penjual telah mengonfirmasi jadwal & lokasi COD untuk '$productName'!");
                },
              ),
              const SizedBox(height: 10),
              _buildCancelButton(),
            ],
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Menunggu Konfirmasi Penjual',
                message: 'Penjual sedang memeriksa jadwal dan lokasi pertemuan COD Anda.',
              ),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          );
        }
      }

      if (status == 'waiting_meetup' || status == 'confirmed') {
        return Column(
          children: [
            _buildInfoBanner(
              icon: Icons.handshake_outlined,
              color: const Color(0xFF2B5F9E),
              bgColor: const Color(0xFFE6EDF8),
              title: 'Jadwal COD Telah Dikonfirmasi',
              message: 'Silakan bertemu di lokasi dan waktu yang telah disepakati untuk serah terima barang dan pembayaran.',
            ),
            const SizedBox(height: 14),
            _buildBigButton(
              label: isSeller ? 'Konfirmasi Transaksi COD Selesai' : 'Konfirmasi Barang Diterima (Selesai)',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF16A34A),
              isLoading: _isActionSubmitting,
              onPressed: () async {
                context.read<OrderBloc>().add(
                  UpdateOrderStatus(orderId: widget.orderId, status: 'completed'),
                );
                await _sendChatUpdate("🎉 Transaksi COD '$productName' telah selesai!");
              },
            ),
            const SizedBox(height: 10),
            _buildCancelButton(),
          ],
        );
      }
    }

    // -------------------------------------------------------------
    // ALUR 3: SELF PICK-UP (4 States)
    // waiting_confirmation → confirmed → waiting_meetup → completed
    // -------------------------------------------------------------
    if (pickupMethod == 'pickup') {
      // State 1: Menunggu Konfirmasi Penjual
      if (status == 'waiting_confirmation' || status == 'created' || status == 'pending') {
        if (isSeller) {
          return Column(
            children: [
              // Konfirmasi button
              _buildBigButton(
                label: 'Konfirmasi Pesanan',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF2B5F9E),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'confirmed'),
                  );
                  await _sendChatUpdate("✅ Penjual telah mengonfirmasi pesanan '$productName'. Silakan datang ke toko sesuai jadwal yang telah disepakati.");
                },
              ),
              const SizedBox(height: 10),
              // Tolak button
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Tolak Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showRejectOrderDialog(productName),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Menunggu Konfirmasi Penjual',
                message: 'Penjual sedang memeriksa ketersediaan barang. Setelah dikonfirmasi, Anda dapat menuju ke toko penjual sesuai jadwal.',
              ),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          );
        }
      }

      // State 2: Dikonfirmasi oleh Penjual
      if (status == 'confirmed') {
        if (isSeller) {
          return _buildInfoBanner(
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF2B5F9E),
            bgColor: const Color(0xFFE6EDF8),
            title: 'Pesanan Dikonfirmasi',
            message: 'Pesanan telah Anda konfirmasi. Menunggu pembeli datang ke lokasi toko Anda sesuai jadwal yang disepakati.',
          );
        } else {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF2B5F9E),
                bgColor: const Color(0xFFE6EDF8),
                title: 'Pesanan Dikonfirmasi!',
                message: 'Penjual telah mengonfirmasi pesanan Anda. Datang ke lokasi toko penjual sesuai jadwal untuk mengambil barang.',
              ),
              const SizedBox(height: 14),
              _buildBigButton(
                label: 'Pesanan Diterima (Mulai Meetup)',
                icon: Icons.handshake_outlined,
                color: const Color(0xFF2B5F9E),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'waiting_meetup'),
                  );
                  await _sendChatUpdate("🤝 Pembeli sedang dalam proses meetup untuk mengambil barang '$productName'.");
                },
              ),
            ],
          );
        }
      }

      // State 3: Dalam Proses Meetup
      if (status == 'waiting_meetup') {
        if (!isSeller) {
          return Column(
            children: [
              _buildInfoBanner(
                icon: Icons.handshake_outlined,
                color: const Color(0xFF2B5F9E),
                bgColor: const Color(0xFFE6EDF8),
                title: 'Dalam Proses Meetup',
                message: 'Temui penjual sesuai waktu dan tempat yang telah disepakati, lalu konfirmasi barang diterima.',
              ),
              const SizedBox(height: 14),
              _buildBigButton(
                label: 'Konfirmasi Barang Diterima (Selesai)',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                isLoading: _isActionSubmitting,
                onPressed: () async {
                  context.read<OrderBloc>().add(
                    UpdateOrderStatus(orderId: widget.orderId, status: 'completed'),
                  );
                  await _sendChatUpdate("🎉 Pembeli telah menerima barang '$productName'. Transaksi selesai!");
                },
              ),
            ],
          );
        } else {
          return _buildInfoBanner(
            icon: Icons.handshake_outlined,
            color: const Color(0xFF2B5F9E),
            bgColor: const Color(0xFFE6EDF8),
            title: 'Dalam Proses Meetup',
            message: 'Pembeli sedang dalam perjalanan menuju toko Anda. Serahkan barang saat pembeli tiba dan menunjukkan pesanan.',
          );
        }
      }
    }

    // Default / Selesai / Dibatalkan
    if (status == 'completed') {
      return _buildInfoBanner(
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFDCFCE7),
        title: 'Transaksi Selesai',
        message: 'Pesanan ini telah berhasil diselesaikan dengan baik.',
      );
    }

    if (status == 'cancelled') {
      final rReason = _getRejectionReason(_order ?? {});
      return _buildInfoBanner(
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
        title: 'Pesanan Dibatalkan',
        message: rReason != null && rReason.isNotEmpty
            ? 'Alasan pembatalan: $rReason. Stok produk telah dikembalikan.'
            : 'Pesanan ini telah dibatalkan.',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBigButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _confirmCancelOrder,
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required XFile? file,
    required String label,
    required VoidCallback onPick,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          color: file != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: file != null ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: file != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Foto terpilih: ${file.name}',
                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text('Ubah', style: TextStyle(color: Color(0xFF2B5F9E), fontSize: 12, decoration: TextDecoration.underline)),
                  const SizedBox(width: 12),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B), size: 24),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildImageThumbnail(String url, String dialogTitle) {
    return GestureDetector(
      onTap: () => _showProofDialog(url, dialogTitle),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: const Color(0xFFF1F5F9),
                child: const Center(child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey))),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Klik untuk perbesar', style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToChat() async {
    final order = _order;
    if (order == null) return;
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final buyerId = order['buyer_id']?.toString() ?? '';
    final sellerId = order['seller_id']?.toString() ?? '';
    if (buyerId.isEmpty || sellerId.isEmpty) return;

    final isSeller = currentUserId == sellerId;
    final otherUserId = isSeller ? buyerId : sellerId;
    if (otherUserId == currentUserId) return;

    final otherUserName = _otherUserProfile?['full_name'] ??
        _otherUserProfile?['username'] ??
        (isSeller ? 'Pembeli' : 'Penjual');

    try {
      final existingConvs = await _supabase
          .from('conversations')
          .select('id')
          .or('and(buyer_id.eq.$buyerId,seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.$buyerId)')
          .limit(1);

      String conversationId;
      if ((existingConvs as List).isNotEmpty) {
        conversationId = existingConvs.first['id'];
      } else {
        try {
          final newConv = await _supabase.from('conversations').insert({
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'product_id': order['product_id'],
          }).select('id').single();
          conversationId = newConv['id'];
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            final convList = await _supabase
                .from('conversations')
                .select('id')
                .or('and(buyer_id.eq.$buyerId,seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.$buyerId)')
                .limit(1);
            conversationId = convList.first['id'];
          } else {
            rethrow;
          }
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: conversationId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to chat: $e');
    }
  }

  Widget _buildUserCard(bool isSeller) {
    final name = _otherUserProfile?['full_name'] ?? _otherUserProfile?['username'] ?? (isSeller ? 'Pembeli Brawigo' : 'Penjual Brawigo');
    final phone = _otherUserProfile?['phone_number']?.toString();
    final faculty = _otherUserProfile?['faculty']?.toString() ?? 'Mahasiswa UB';
    final photoUrl = _otherUserProfile?['profile_photo_url']?.toString();
    final isVerified = _otherUserProfile?['verification_status'] == 'verified';

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Color(0xFF2B5F9E), size: 18),
              const SizedBox(width: 8),
              Text(
                isSeller ? 'Informasi Pembeli' : 'Informasi Penjual',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF94A3B8))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '($phone)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          faculty,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVerified ? 'Terverifikasi' : 'Mahasiswa UB',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required bool isSeller,
    required String status,
    required String? productId,
  }) {
    final chatButtonLabel = isSeller ? 'Chat Pembeli' : 'Chat Penjual';

    if (status == 'completed') {
      if (!isSeller) {
        final hasReviewed = _existingReview != null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: hasReviewed
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2B5F9E),
                            side: const BorderSide(color: Color(0xFF2B5F9E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          label: const Text('Lihat Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RatingPage(
                                  order: _order!,
                                  existingReview: _existingReview,
                                ),
                              ),
                            );
                            if (res == true) {
                              _fetchOrderDetail();
                            }
                          },
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B5F9E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RatingPage(order: _order!),
                              ),
                            );
                            if (res == true) {
                              _fetchOrderDetail();
                            }
                          },
                          child: const Text('Beri Penilaian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2B5F9E),
                      side: const BorderSide(color: Color(0xFF2B5F9E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _navigateToChat,
                    child: Text(chatButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2B5F9E),
                  side: const BorderSide(color: Color(0xFF2B5F9E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: Text(chatButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _navigateToChat,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2B5F9E),
              side: const BorderSide(color: Color(0xFF2B5F9E)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: Text(chatButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            onPressed: _navigateToChat,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2B5F9E)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15243C)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }
}
