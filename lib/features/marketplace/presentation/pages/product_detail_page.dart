import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/full_screen_image_viewer.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isPreview;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isPreview = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _currentProduct;
  List<String> _images = [];
  bool _isLoadingImages = true;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = Map<String, dynamic>.from(widget.product);
    _fetchImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchImages() async {
    try {
      final productId = _currentProduct['id']?.toString() ?? '';
      if (productId.isEmpty) {
        setState(() {
          _images = [];
          final thumb = _currentProduct['thumbnail_url'] ?? _currentProduct['image_url'];
          if (thumb != null && thumb.toString().isNotEmpty) {
            _images.add(thumb.toString());
          }
          _isLoadingImages = false;
        });
        return;
      }

      final response = await _supabase
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('image_order', ascending: true);

      if (mounted) {
        setState(() {
          _images = (response as List)
              .map((e) => e['image_url'] as String)
              .where((url) => url.isNotEmpty)
              .toList();

          if (_images.isEmpty) {
            final thumb = _currentProduct['thumbnail_url'] ?? _currentProduct['image_url'];
            if (thumb != null && thumb.toString().isNotEmpty) {
              _images.add(thumb.toString());
            }
          }
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final thumb = _currentProduct['thumbnail_url'] ?? _currentProduct['image_url'];
          if (thumb != null && thumb.toString().isNotEmpty) {
            _images = [thumb.toString()];
          }
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _refreshProduct() async {
    try {
      final productId = _currentProduct['id']?.toString() ?? '';
      if (productId.isEmpty) return;

      final response = await _supabase
          .from('products')
          .select('*, categories(id, name, icon)')
          .eq('id', productId)
          .maybeSingle();

      if (response != null && mounted) {
        final Map<String, dynamic> updatedMap = Map<String, dynamic>.from(response);
        final cat = response['categories'] as Map<String, dynamic>?;
        if (cat != null && cat['name'] != null) {
          updatedMap['category_name'] = cat['name'];
        }

        setState(() {
          _currentProduct = updatedMap;
          _isLoadingImages = true;
        });
        await _fetchImages();
      }
    } catch (_) {}
  }

  String _formatCurrency(dynamic amount) {
    final int value = (amount as num?)?.toInt() ?? 0;
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
    return result;
  }

  Future<void> _openEditProduct() async {
    final bloc = context.read<MarketplaceBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: UpdateProductPage(product: _currentProduct),
        ),
      ),
    );

    if (result == true && mounted) {
      _hasUpdated = true;
      await _refreshProduct();
      bloc.add(LoadSellerProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentProduct['product_name']?.toString() ?? 'Tanpa Nama';
    final categoryName = _currentProduct['category_name']?.toString() ??
        (_currentProduct['categories'] is Map ? _currentProduct['categories']['name']?.toString() : null) ??
        'Lainnya';
    final priceVal = _currentProduct['price'] ?? 0;
    final formattedPrice = _formatCurrency(priceVal);
    final stock = (_currentProduct['stock'] as num?)?.toInt() ?? 0;
    final status = _currentProduct['status']?.toString() ?? 'active';
    final description = _currentProduct['description']?.toString() ?? 'Tidak ada deskripsi produk.';

    // Status Badge styling
    String badgeText = 'Aktif Dijual';
    Color badgeBg = const Color(0xFFE5F9EB);
    Color badgeColor = const Color(0xFF16A34A);

    if (stock <= 0) {
      badgeText = 'Stok Habis';
      badgeBg = const Color(0xFFFFECEE);
      badgeColor = const Color(0xFFDC2626);
    } else if (status == 'archived') {
      badgeText = 'Diarsipkan';
      badgeBg = const Color(0xFFE0F2FE);
      badgeColor = const Color(0xFF0284C7);
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _hasUpdated) {
          // Handled via pop return if needed
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Area Gambar dengan Tombol Back & Navigasi
                    Stack(
                      children: [
                        SizedBox(
                          height: 360,
                          width: double.infinity,
                          child: _isLoadingImages
                              ? Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                                  ),
                                )
                              : _images.isNotEmpty
                                  ? PageView.builder(
                                      controller: _pageController,
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
                                            title: name,
                                          ),
                                          child: Image.network(
                                            _images[index],
                                            width: double.infinity,
                                            height: 360,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                                          ),
                                        );
                                      },
                                    )
                                  : _buildPlaceholderImage(),
                        ),

                        // Tombol Back Melayang ke Halaman Seller
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          left: 16,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 3,
                            shadowColor: Colors.black.withAlpha(50),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context, _hasUpdated),
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: Color(0xFF15243C),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Tombol Full Screen Melayang
                        if (_images.isNotEmpty)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            right: 16,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 3,
                              shadowColor: Colors.black.withAlpha(50),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => FullScreenImageViewer.open(
                                  context,
                                  images: _images,
                                  initialIndex: _currentImageIndex,
                                  title: name,
                                ),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.fullscreen_rounded,
                                    size: 24,
                                    color: Color(0xFF15243C),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Panah Kiri Navigasi Gambar jika ada lebih dari 1 gambar
                        if (_images.length > 1 && _currentImageIndex > 0)
                          Positioned(
                            left: 12,
                            top: 160,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(90),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),

                        // Panah Kanan Navigasi Gambar jika ada lebih dari 1 gambar
                        if (_images.length > 1 && _currentImageIndex < _images.length - 1)
                          Positioned(
                            right: 12,
                            top: 160,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(90),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),

                        // Indikator Halaman Gambar (Contoh: 1/3)
                        if (_images.length > 1)
                          Positioned(
                            bottom: 14,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${_currentImageIndex + 1}/${_images.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Konten Detail Produk
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Status & Kategori
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Nama Produk
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15243C),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Harga Produk
                          Text(
                            "Rp $formattedPrice",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2B5F9E),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Card Informasi Stok
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF4FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF2B5F9E),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Stok Produk",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$stock unit tersedia",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF15243C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: stock > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stock > 0 ? "Siap Kirim" : "Perlu Restock",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: stock > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Judul Deskripsi
                          const Text(
                            "Deskripsi Produk",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Isi Deskripsi
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF475569),
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

            // Bottom Bar: Tombol Edit Produk
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5F9E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text(
                      'Edit Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _openEditProduct,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 360,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
