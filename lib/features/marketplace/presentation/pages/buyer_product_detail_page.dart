import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';
import 'package:brawigo/features/marketplace/core/utils/product_price_formatter.dart';
import 'package:brawigo/features/marketplace/data/repositories/buyer_product_detail_repository.dart';
import 'package:brawigo/features/marketplace/presentation/pages/seller_reviews_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/product_description_section.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/product_detail_bottom_bar.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/product_image_gallery.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_info_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyerProductDetailPage extends StatefulWidget {
  const BuyerProductDetailPage({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  State<BuyerProductDetailPage> createState() => _BuyerProductDetailPageState();
}

class _BuyerProductDetailPageState extends State<BuyerProductDetailPage> {
  final BuyerProductDetailRepository _repository =
      BuyerProductDetailRepository();

  List<String> _images = <String>[];
  bool _isLoadingImages = true;
  late Future<Map<String, dynamic>?> _sellerProfileFuture;

  Map<String, dynamic> get _product => widget.product;
  String get _productId => _product['id']?.toString() ?? '';
  String get _sellerId => _product['seller_id']?.toString() ?? '';
  String get _productName =>
      (_product['product_name'] ?? _product['name'])?.toString() ?? 'Produk';

  @override
  void initState() {
    super.initState();
    _loadImages();
    _sellerProfileFuture = _repository.fetchSellerProfile(_sellerId);
    _repository.saveToRecentlyViewed(_productId).catchError((_) {
      // Gagal menyimpan riwayat tidak boleh mengganggu detail produk.
    });
  }

  Future<void> _loadImages() async {
    try {
      final images = await _repository.fetchProductImages(_product);
      if (!mounted) return;
      setState(() {
        _images = images;
        _isLoadingImages = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final fallback = _product['image_url']?.toString();
        _images = fallback == null || fallback.isEmpty
            ? <String>[]
            : <String>[fallback];
        _isLoadingImages = false;
      });
    }
  }

  Future<void> _openChat() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _showMessage('Silakan login terlebih dahulu untuk memulai chat.');
      return;
    }
    if (_sellerId.isEmpty || _productId.isEmpty) {
      _showMessage('Informasi produk/penjual tidak lengkap.');
      return;
    }
    if (currentUser.id == _sellerId) {
      _showMessage('Ini adalah produk Anda sendiri.');
      return;
    }

    try {
      final result = await _repository.openOrCreateConversation(
        buyerId: currentUser.id,
        sellerId: _sellerId,
        productId: _productId,
      );
      if (!mounted) return;

      final image = _images.isNotEmpty
          ? _images.first
          : (_product['thumbnail_url'] ?? _product['image_url'])?.toString() ??
                '';
      final Map<String, String> productData = {
        ..._product.map((key, value) => MapEntry(key, value?.toString() ?? '')),
        'id': _productId,
        'product_id': _productId,
        'name': _productName,
        'product_name': _productName,
        'image_url': image,
        'thumbnail_url': image,
        'price': _product['price']?.toString() ?? '',
      };

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: result.conversationId,
            otherUserName: result.sellerName,
            otherUserId: _sellerId,
            productData: productData,
            sendProductMention: result.shouldSendMention,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Gagal membuka chat: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleChatTap() {
    if (Supabase.instance.client.auth.currentUser?.id == _sellerId &&
        _sellerId.isNotEmpty) {
      _showMessage(
        'Ini adalah produk Anda sendiri, tidak dapat mengirim pesan.',
      );
      return;
    }
    _openChat();
  }

  void _handleCheckout() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null && currentUserId == _sellerId) {
      _showMessage(
        'Ini adalah produk Anda sendiri, tidak dapat melakukan checkout.',
      );
      return;
    }
    if (_productId.isNotEmpty) {
      context.push('/checkout/$_productId', extra: _product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProduct = currentUserId != null && currentUserId == _sellerId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) => notification.depth == 0,
              child: ProductImageGallery(
                images: _images,
                isLoading: _isLoadingImages,
                title: _productName,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5F9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ProductPriceFormatter.format(_product['price']),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SellerInfoCard(
                    profileFuture: _sellerProfileFuture,
                    onTap: () {
                      if (_sellerId.isEmpty) {
                        _showMessage('Informasi penjual tidak tersedia.');
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SellerReviewsPage(sellerId: _sellerId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ProductDescriptionSection(
                    description: _product['description']?.toString(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProductDetailBottomBar(
        isOwnProduct: isOwnProduct,
        onChat: _handleChatTap,
        onCheckout: _handleCheckout,
      ),
    );
  }
}
