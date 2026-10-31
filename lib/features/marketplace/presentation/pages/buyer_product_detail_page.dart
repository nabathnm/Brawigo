import 'seller_profile_page.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'dart:convert';
import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/full_screen_image_viewer.dart';

class BuyerProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const BuyerProductDetailPage({super.key, required this.product});

  @override
  State<BuyerProductDetailPage> createState() => _BuyerProductDetailPageState();
}

class _BuyerProductDetailPageState extends State<BuyerProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  List<String> _images = [];
  bool _isLoadingImages = true;
  late Map<String, dynamic> _productData;

  // Wishlist state
  bool _isWishlisted = false;
  String? _wishlistId;
  bool _isTogglingWishlist = false;

  @override
  void initState() {
    super.initState();
    _productData = Map<String, dynamic>.from(widget.product);
    _fetchImages();
    _refreshProductData();
    _saveToRecentlyViewed();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    final productId = widget.product['id']?.toString();
    if (user == null || productId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('wishlists')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isWishlisted = res != null;
          _wishlistId = res?['id']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    final productId = widget.product['id']?.toString();
    if (user == null) {
      BrawigoToast.showWarning(
        context,
        title: 'Perhatian',
        message: 'Silakan login terlebih dahulu untuk menambah wishlist.',
        bottomMargin: 90,
      );
      return;
    }
    if (productId == null || _isTogglingWishlist) return;
    final sellerId = widget.product['seller_id']?.toString() ?? '';
    if (user.id == sellerId) {
      BrawigoToast.showWarning(
        context,
        title: 'Perhatian',
        message: 'Anda tidak dapat menambahkan produk sendiri ke wishlist.',
        bottomMargin: 90,
      );
      return;
    }

    setState(() => _isTogglingWishlist = true);
    try {
      if (_isWishlisted && _wishlistId != null) {
        await Supabase.instance.client.from('wishlists').delete().eq('id', _wishlistId!);
        if (mounted) setState(() { _isWishlisted = false; _wishlistId = null; });
        if (mounted) {
          BrawigoToast.showInfo(
            context,
            title: 'Dihapus',
            message: 'Barang berhasil dihapus dari wishlist.',
            bottomMargin: 90,
          );
        }
      } else {
        final res = await Supabase.instance.client
            .from('wishlists')
            .insert({'user_id': user.id, 'product_id': productId})
            .select('id')
            .single();
        if (mounted) setState(() { _isWishlisted = true; _wishlistId = res['id']?.toString(); });
        if (mounted) {
          BrawigoToast.showSuccess(
            context,
            title: 'Berhasil!',
            message: 'Barang berhasil ditambahkan ke wishlist.',
            bottomMargin: 90,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(
          context,
          title: 'Gagal',
          message: 'Gagal memperbarui wishlist.',
          bottomMargin: 90,
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingWishlist = false);
    }
  }

  Future<void> _refreshProductData() async {
    final productId = widget.product['id']?.toString();
    if (productId != null && productId.isNotEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('products')
            .select()
            .eq('id', productId)
            .maybeSingle();
        if (res != null && mounted) {
          setState(() {
            _productData = {
              ...widget.product,
              ...Map<String, dynamic>.from(res),
            };
          });
        }
      } catch (_) {}
      await _fetchImages();
    }
  }

  Future<void> _saveToRecentlyViewed() async {
    final productId = widget.product['id'];
    if (productId != null && productId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<String> viewed = prefs.getStringList('recently_viewed') ?? [];
      viewed.remove(productId);
      viewed.add(productId);
      if (viewed.length > 10) {
        viewed.removeAt(0);
      }
      await prefs.setStringList('recently_viewed', viewed);
    }
  }

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openChat() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final product = _productData;
    final sellerId = product['seller_id'] ?? '';
    final productId = product['id'] ?? '';

    if (currentUser == null) {
      BrawigoToast.showWarning(
        context,
        message: 'Silakan login terlebih dahulu untuk memulai chat.',
        title: 'Perhatian',
      );
      return;
    }

    if (sellerId.isEmpty || productId.isEmpty) {
      BrawigoToast.showError(
        context,
        message: 'Informasi produk/penjual tidak lengkap.',
        title: 'Gagal',
      );
      return;
    }

    if (currentUser.id == sellerId) {
      BrawigoToast.showWarning(
        context,
        message: 'Ini adalah produk Anda sendiri.',
        title: 'Perhatian',
      );
      return;
    }

    try {
      final convs = await Supabase.instance.client
          .from('conversations')
          .select('id, product_id, buyer_id, seller_id')
          .or('buyer_id.eq.${currentUser.id},seller_id.eq.${currentUser.id}')
          .order('updated_at', ascending: false);

      Map<String, dynamic>? existingConv;
      for (final c in (convs as List)) {
        final bId = c['buyer_id']?.toString();
        final sId = c['seller_id']?.toString();
        if ((bId == currentUser.id && sId == sellerId) ||
            (bId == sellerId && sId == currentUser.id)) {
          existingConv = Map<String, dynamic>.from(c);
          break;
        }
      }

      String conversationId;
      bool shouldSendMention = false;

      if (existingConv != null) {
        conversationId = existingConv['id'];
        final prevProductId = existingConv['product_id']?.toString() ?? '';
        if (prevProductId != productId) {
          shouldSendMention = true;
        }
        await Supabase.instance.client
            .from('conversations')
            .update({
              'product_id': productId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', conversationId);
      } else {
        try {
          final created = await Supabase.instance.client
              .from('conversations')
              .insert({
                'buyer_id': currentUser.id,
                'seller_id': sellerId,
                'product_id': productId,
              })
              .select('id')
              .single();
          conversationId = created['id'];
          shouldSendMention = true;
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            final convList = await Supabase.instance.client
                .from('conversations')
                .select('id, product_id')
                .or('and(buyer_id.eq.${currentUser.id},seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.${currentUser.id})')
                .order('updated_at', ascending: false)
                .limit(1);
            if ((convList as List).isNotEmpty) {
              conversationId = convList.first['id'];
              shouldSendMention = true;
              await Supabase.instance.client
                  .from('conversations')
                  .update({
                    'product_id': productId,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', conversationId);
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }

      final sellerProfile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', sellerId)
          .maybeSingle();
      final sellerName = sellerProfile?['full_name'] ?? 'Penjual';

      if (!mounted) return;
      final pName = (widget.product['product_name'] ?? widget.product['name'])?.toString() ?? '';
      final pImage = (_images.isNotEmpty
              ? _images.first
              : (widget.product['thumbnail_url'] ?? widget.product['image_url']))
          ?.toString() ?? '';
      final pPrice = widget.product['price']?.toString() ?? '';

      final Map<String, String> mappedProductData = {
        ...widget.product.map((key, value) => MapEntry(key, value?.toString() ?? '')),
        'id': productId,
        'product_id': productId,
        'name': pName,
        'product_name': pName,
        'image_url': pImage,
        'thumbnail_url': pImage,
        'price': pPrice,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: conversationId,
            otherUserName: sellerName,
            otherUserId: sellerId,
            productData: mappedProductData,
            sendProductMention: shouldSendMention,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(
          context,
          message: 'Gagal membuka chat: ${e.toString()}',
          title: 'Gagal',
        );
      }
    }
  }

  Future<void> _fetchImages() async {
    final productId = widget.product['id'];
    if (productId != null && productId.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('image_order', ascending: true);

      final List<String> fetchedImages = (response as List)
          .map((e) => e['image_url'] as String)
          .toList();

      if (mounted) {
        setState(() {
          if (fetchedImages.isNotEmpty) {
            _images = fetchedImages;
          } else {
            final thumb = widget.product['image_url'];
            if (thumb != null && thumb.isNotEmpty) _images = [thumb];
          }
          _isLoadingImages = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          final thumb = widget.product['image_url'];
          if (thumb != null && thumb.isNotEmpty) _images = [thumb];
          _isLoadingImages = false;
        });
      }
    }
  }

  bool get _isLongDescription {
    final desc = widget.product['description'] ?? "";
    return desc.length > 120;
  }

  /// Format harga ke "Rp xxx.xxx"
  /// Aman untuk menerima [num], [int], [double], maupun [String] (angka mentah
  /// atau sudah terformat seperti "Rp 300.000" dari halaman search).
  String _formatPrice(dynamic amount) {
    if (amount == null) return 'Rp 0';

    // Jika sudah berupa String terformat yang mengandung "Rp", kembalikan langsung
    if (amount is String) {
      final trimmed = amount.trim();
      if (trimmed.startsWith('Rp') || trimmed.startsWith('rp')) {
        return trimmed;
      }
      // Coba parse sebagai angka
      final parsed = double.tryParse(trimmed.replaceAll('.', '').replaceAll(',', ''));
      if (parsed == null) return 'Rp 0';
      return _formatNum(parsed.toInt());
    }

    // Jika berupa num
    if (amount is num) {
      return _formatNum(amount.toInt());
    }

    return 'Rp 0';
  }

  String _formatNum(int value) {
    String valStr = value.toString();
    String result = '';
    int count = 0;
    for (int i = valStr.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        result = '.$result';
      }
      result = valStr[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    final product = _productData.isNotEmpty ? _productData : widget.product;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final sellerId = product['seller_id']?.toString() ?? '';
    final bool isOwnProduct = currentUserId != null && currentUserId == sellerId;
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshProductData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                return notification.depth == 0;
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: _isLoadingImages
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : (_images.isNotEmpty)
                        ? PageView.builder(
                            controller: _pageController,
                            physics: const PageScrollPhysics(),
                            itemCount: _images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => FullScreenImageViewer.open(
                                  context,
                                  images: _images,
                                  initialIndex: index,
                                  title: widget.product['product_name']?.toString() ??
                                      widget.product['name']?.toString() ??
                                      'Produk',
                                ),
                                child: Image.network(
                                  _images[index],
                                  width: double.infinity,
                                  height: 380,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 380,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  // Tombol Full Screen
                  if (_images.isNotEmpty)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: InkWell(
                        onTap: () => FullScreenImageViewer.open(
                          context,
                          images: _images,
                          initialIndex: _currentImageIndex,
                          title: widget.product['product_name']?.toString() ??
                              widget.product['name']?.toString() ??
                              'Produk',
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  // Wishlist Heart Button
                  if (!isOwnProduct)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 64,
                      right: 16,
                      child: GestureDetector(
                        onTap: _isTogglingWishlist ? null : _toggleWishlist,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isTogglingWishlist
                              ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2B5F9E))))
                              : Icon(
                                  _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 22,
                                  color: _isWishlisted ? Colors.red : Colors.black87,
                                ),
                        ),
                      ),
                    ),
                  // Panah Kiri Navigasi Gambar
                  if (_images.length > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Panah Kanan Navigasi Gambar
                  if (_images.length > 1 &&
                      _currentImageIndex < _images.length - 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_images.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${_currentImageIndex + 1}/${_images.length}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15243C),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'] ??
                        product['name'] ??
                        'Rice Cooker Mikoya',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5F9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product['price']),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final stock = product['stock'];
                      final stockInt = (stock is int) ? stock : int.tryParse(stock?.toString() ?? '') ?? 0;
                      final stockColor = stockInt == 0
                          ? Colors.red
                          : stockInt <= 3
                              ? const Color(0xFFD97706)
                              : const Color(0xFF22C55E);
                      return Row(
                        children: [
                          Icon(
                            stockInt == 0 ? Icons.remove_shopping_cart_outlined : Icons.inventory_2_outlined,
                            size: 14,
                            color: stockColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stockInt == 0
                                ? 'Stok Habis'
                                : 'Sisa stok: $stockInt item',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: stockColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BrawigoColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FutureBuilder(
                                future: Supabase.instance.client
                                    .from('profiles')
                                    .select(
                                      'full_name, username, profile_photo_url, bio',
                                    )
                                    .eq('id', product['seller_id'] ?? '')
                                    .maybeSingle(),
                                builder: (context, snapshot) {
                                  String sellerName = "Memuat...";
                                  String? photoUrl;
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final p = snapshot.data as Map;
                                      String? storeName;
                                      String? storePhotoUrl;
                                      if (p['bio'] != null) {
                                        try {
                                          final bioJson = jsonDecode(p['bio'].toString());
                                          if (bioJson is Map) {
                                            storeName = bioJson['store_name']?.toString().trim();
                                            storePhotoUrl = bioJson['store_photo_url']?.toString().trim();
                                          }
                                        } catch (_) {}
                                      }

                                      final username = p['username']
                                          ?.toString()
                                          .trim();
                                      final fullName = p['full_name']
                                          ?.toString()
                                          .trim();
                                      photoUrl = (storePhotoUrl != null && storePhotoUrl.isNotEmpty)
                                          ? storePhotoUrl
                                          : p['profile_photo_url']
                                              ?.toString()
                                              .trim();

                                      if (storeName != null && storeName.isNotEmpty) {
                                        sellerName = storeName;
                                      } else if (username != null &&
                                          username.isNotEmpty &&
                                          username != '-') {
                                        sellerName = username;
                                      } else if (fullName != null &&
                                          fullName.isNotEmpty) {
                                        sellerName = fullName;
                                      } else {
                                        sellerName = 'Penjual';
                                      }
                                    } else {
                                      sellerName = 'Penjual Tidak Diketahui';
                                    }
                                  }

                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(
                                          0xFF4A7EBB,
                                        ),
                                        backgroundImage:
                                            (photoUrl != null &&
                                                photoUrl.isNotEmpty)
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child:
                                            (photoUrl == null ||
                                                photoUrl.isEmpty)
                                            ? Text(
                                                sellerName.isNotEmpty
                                                    ? sellerName[0]
                                                          .toUpperCase()
                                                    : 'P',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sellerName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF15243C),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Text(
                                              "Aktif baru saja",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                                final sId = _productData['seller_id']?.toString() ?? '';
                                final isOwnProduct = currentUserId != null && sId.isNotEmpty && currentUserId == sId;

                                return ElevatedButton(
                                  onPressed: isOwnProduct
                                      ? null
                                      : () {
                                          if (sId.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SellerProfilePage(sellerId: sId),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A7EBB),
                                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                                    disabledForegroundColor: const Color(0xFF94A3B8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(
                                    isOwnProduct ? "Toko Anda" : "Kunjungi Toko",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isOwnProduct ? const Color(0xFF94A3B8) : Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                                children: [
                                  TextSpan(
                                    text: "12 ",
                                    style: TextStyle(
                                      color: Color(0xFF2B5F9E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: "Produk"),
                                ],
                              ),
                            ),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                                children: [
                                  TextSpan(
                                    text: "4.9 ",
                                    style: TextStyle(
                                      color: Color(0xFF2B5F9E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: "Penilaian"),
                                ],
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF475569),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Tlogomas, Malang",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2B5F9E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (product['description'] != null &&
                            product['description']!.isNotEmpty)
                        ? product['description']!
                        : "Tidak ada deskripsi untuk produk ini.",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                    maxLines: _isDescriptionExpanded
                        ? null
                        : (_isLongDescription ? 3 : null),
                    overflow: _isDescriptionExpanded
                        ? TextOverflow.visible
                        : (_isLongDescription
                              ? TextOverflow.ellipsis
                              : TextOverflow.visible),
                  ),
                  if (_isLongDescription) const SizedBox(height: 16),
                  if (_isLongDescription)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isDescriptionExpanded
                                  ? "Tutup Selengkapnya"
                                  : "Lihat Selengkapnya",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isDescriptionExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFF334155),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOwnProduct
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF2B5F9E),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: isOwnProduct
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF2B5F9E),
                      size: 22,
                    ),
                    onPressed: isOwnProduct
                        ? () {
                            BrawigoToast.showWarning(
                              context,
                              message: 'Ini adalah produk Anda sendiri, tidak dapat mengirim pesan.',
                              title: 'Perhatian',
                            );
                          }
                        : _openChat,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isOwnProduct
                        ? () {
                            BrawigoToast.showWarning(
                              context,
                              message: 'Ini adalah produk Anda sendiri, tidak dapat melakukan checkout.',
                              title: 'Perhatian',
                            );
                          }
                        : () {
                            final stockVal = product['stock'];
                            final int stockInt = (stockVal is int)
                                ? stockVal
                                : int.tryParse(stockVal?.toString() ?? '') ?? 0;
                            if (stockInt <= 0) {
                              BrawigoToast.showError(
                                context,
                                message: 'Maaf, stok barang ini sudah habis.',
                                title: 'Stok Habis',
                              );
                              return;
                            }
                            final productId = product['id']?.toString() ?? '';
                            if (productId.isNotEmpty) {
                              context.push('/checkout/$productId', extra: product);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwnProduct
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF4A7EBB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      isOwnProduct ? "Produk Anda Sendiri" : "Checkout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isOwnProduct
                            ? const Color(0xFF64748B)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
