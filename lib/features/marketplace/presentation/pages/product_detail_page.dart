import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _supabase = Supabase.instance.client;
  List<String> _images = [];
  bool _isLoadingImages = true;

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
    final isSeller = product['seller_id'] == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Produk"),
        actions: [
          if (isSeller)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProductPage(product: product),
                  ),
                );
              },
            ),
          if (isSeller)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Gambar
            SizedBox(
              height: 300,
              child: _isLoadingImages
                  ? const Center(child: CircularProgressIndicator())
                  : _images.isNotEmpty
                  ? PageView.builder(
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          _images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 100),
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

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product['product_name'] ?? 'Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product['condition'] == 'new' ? 'Baru' : 'Bekas',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rp ${product['price']}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Deskripsi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text("Stok"),
                    trailing: Text(
                      "${product['stock'] ?? 0}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (product['pickup_location'] != null &&
                      product['pickup_location'].toString().isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text("Lokasi Pengambilan"),
                      subtitle: Text(product['pickup_location']),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isSeller
          ? null // Seller tidak butuh tombol beli
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur Beli / Chat Penjual segera hadir!',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Hubungi Penjual / Beli',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }
}
