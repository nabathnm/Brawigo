import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';

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
  List<String> _images = [];
  bool _isLoadingImages = true;
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

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

  Widget _buildSellerStat(String val, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E659A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF515151)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final response = await _supabase
          .from('product_images')
          .select('image_url')
          .eq('product_id', widget.product['id'])
          .order('image_order', ascending: true);

      if (mounted) {
        setState(() {
          _images = (response as List)
              .map((e) => e['image_url'] as String)
              .toList();
          if (_images.isEmpty && widget.product['thumbnail_url'] != null) {
            _images.add(widget.product['thumbnail_url']);
          }
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (widget.product['thumbnail_url'] != null) {
            _images.add(widget.product['thumbnail_url']);
          }
          _isLoadingImages = false;
        });
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              context.read<MarketplaceBloc>().add(
                DeleteProduct(
                  id: widget.product['id'],
                  imageUrl: widget.product['thumbnail_url'],
                ),
              );
              Navigator.pop(context); // Kembali ke halaman sebelumnya
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk sedang dihapus...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentUserId = _supabase.auth.currentUser?.id;
    final bool isSeller =
        (product['seller_id'] == currentUserId) && !widget.isPreview;
    final dynamic priceVal = product['price'] ?? 0;
    final String formattedPrice = _formatCurrency(priceVal);
    final String categoryName =
        product['category_name']?.toString() ?? 'Alat Elektronik';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Area Gambar + Overlay Tombol & Badge
                    SizedBox(
                      height: 360,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _isLoadingImages
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _images.isNotEmpty
                                ? PageView.builder(
                                    itemCount: _images.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      return Image.network(
                                        _images[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 80,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),

                          // Top Buttons Overlay (Back, Edit, Delete)
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tombol Kembali
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 18,
                                      color: Color(0xFF15243C),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                // Tombol Edit & Delete untuk Seller
                                if (isSeller)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                            color: Color(0xFF1890FF),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UpdateProductPage(
                                                      product: product,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Color(0xFFFF4D4F),
                                          ),
                                          onPressed: _confirmDelete,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Badge Indikator Halaman Gambar
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "${_currentImageIndex + 1}/${_images.isEmpty ? 1 : _images.length}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Area Judul, Kategori & Harga
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name'] ?? 'Tanpa Nama',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4A79),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF6A7A8A),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                "Rp $formattedPrice",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E659A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider Abu-abu
                    Container(height: 8, color: const Color(0xFFF4F6F8)),

                    // Area Profil Penjual / Toko
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: const CircleAvatar(
                                  radius: 23,
                                  backgroundImage: AssetImage(
                                    'assets/images/avatar.png',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['seller_name']?.toString() ??
                                          'John Doe',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15243C),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Aktif 3 jam lalu",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6A7A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fitur Kunjungi Toko segera hadir!',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E659A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Kunjungi Toko",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSellerStat("12", "Produk"),
                              _buildSellerStat("4.9", "Penilaian"),
                              _buildSellerStat("12", "Produk"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider Abu-abu
                    Container(height: 8, color: const Color(0xFFF4F6F8)),

                    // Area Deskripsi Produk & Spesifikasi
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Deskripsi",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product['description']?.toString().isNotEmpty ==
                                    true
                                ? product['description']
                                : 'Hadirkan kemudahan memasak dalam satu sentuhan dengan Magic Com. Dilengkapi fitur serbaguna 3-in-1, penanak nasi ini tidak hanya memasak dengan sempurna, tetapi juga dapat mengukus dan menghangatkan makanan. Pilihan cerdas untuk menyajikan hidangan lezat dan pulen setiap hari.',
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFF333333),
                            ),
                            maxLines: _isDescriptionExpanded ? null : 4,
                            overflow: _isDescriptionExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded =
                                      !_isDescriptionExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isDescriptionExpanded
                                          ? "Sembunyikan"
                                          : "Lihat Selengkapnya",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF515151),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isDescriptionExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: const Color(0xFF333333),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 20,
                                    color: Color(0xFF6A7A8A),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Stok Tersedia",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF515151),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${product['stock'] ?? 0}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1D4A79),
                                ),
                              ),
                            ],
                          ),
                          if (product['pickup_location'] != null &&
                              product['pickup_location']
                                  .toString()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: Color(0xFF6A7A8A),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Lokasi Pengambilan",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF515151),
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Text(
                                    product['pickup_location'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1D4A79),
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button ("Lihat Tampilan Asli" / "Hubungi Penjual")
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3873b2), Color(0xFF244c80)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF244c80).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (isSeller) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              isPreview: true,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur Beli / Chat Penjual segera hadir!',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isSeller
                          ? 'Lihat Tampilan Asli'
                          : 'Hubungi Penjual / Beli',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
