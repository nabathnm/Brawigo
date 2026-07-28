import 'package:brawigo/features/marketplace/presentation/pages/widgets/custom_search.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/header.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/pages/product_detail_page.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';

class MarketPlaceSellerPage extends StatefulWidget {
  const MarketPlaceSellerPage({super.key});

  @override
  State<MarketPlaceSellerPage> createState() => _MarketPlaceSellerPageState();
}

class _MarketPlaceSellerPageState extends State<MarketPlaceSellerPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Tersedia, 2: Habis, 3: Arsip
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> product) {
    final productId = product['id'].toString();
    final productName = product['product_name'] ?? 'Produk';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Hapus Produk",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Apakah Anda yakin ingin menghapus \"$productName\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MarketplaceBloc>().add(DeleteProduct(id: productId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Produk berhasil dihapus")),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Header(),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSearch(
                controller: _searchController,
                hintText: 'Cari produk saya..',
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                onFilterPressed: () {
                  // Fitur filter tambahan (opsional)
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- Area Filter Chips & Daftar Produk via BLoC ---
            Expanded(
              child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                builder: (context, state) {
                  if (state is MarketplaceLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E6399),
                      ),
                    );
                  } else if (state is MarketplaceError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Error: ${state.message}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else if (state is MarketplaceLoaded) {
                    final allProducts = state.products;

                    // Hitung jumlah masing-masing kategori
                    final availableProducts = allProducts.where((p) {
                      final stock = (p['stock'] as num?)?.toInt() ?? 0;
                      final status = p['status'] as String? ?? 'active';
                      return stock > 0 && status != 'archived';
                    }).toList();

                    final outOfStockProducts = allProducts.where((p) {
                      final stock = (p['stock'] as num?)?.toInt() ?? 0;
                      return stock <= 0;
                    }).toList();

                    final archivedProducts = allProducts.where((p) {
                      final status = p['status'] as String?;
                      return status == 'archived';
                    }).toList();

                    // Daftar label filter chips
                    final filters = [
                      'Semua (${allProducts.length})',
                      'Aktif (${availableProducts.length})',
                      'Habis (${outOfStockProducts.length})',
                      'Arsip (${archivedProducts.length})',
                    ];

                    // Tentukan list aktif berdasarkan _selectedFilter
                    List<Map<String, dynamic>> displayedProducts;
                    if (_selectedFilter == 1) {
                      displayedProducts = availableProducts;
                    } else if (_selectedFilter == 2) {
                      displayedProducts = outOfStockProducts;
                    } else if (_selectedFilter == 3) {
                      displayedProducts = archivedProducts;
                    } else {
                      displayedProducts = allProducts;
                    }

                    // Filter pencarian teks
                    if (_searchQuery.isNotEmpty) {
                      displayedProducts = displayedProducts.where((p) {
                        final name = (p['product_name'] as String? ?? '')
                            .toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                    }

                    return Column(
                      children: [
                        // Horizontal Filter Chips
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final isSelected = _selectedFilter == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFF6097D0),
                                              Color(0xFF244C80),
                                            ],
                                            stops: [0.0, 1.0],
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFD3DFE8),
                                            width: 1,
                                          ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF244C80,
                                              ).withAlpha(60),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    filters[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF4A5D70),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Judul Section "Produk Saya"
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Produk Saya",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4A79),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List Produk (Vertical ListView)
                        Expanded(
                          child: displayedProducts.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  itemCount: displayedProducts.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final item = displayedProducts[index];
                                    return SellerProductCard(
                                      product: item,
                                      onDelete: () =>
                                          _showDeleteDialog(context, item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  }

                  // Initial state
                  return const Center(
                    child: Text(
                      "Memuat data...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 70,
            color: Colors.blueGrey.withAlpha(100),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tidak ada produk pada kategori ini.",
            style: TextStyle(color: Color(0xFF6A7A8A), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final String? imageUrl = product['thumbnail_url'] as String?;
    final String name = product['product_name'] as String? ?? 'Tanpa Nama';
    final dynamic priceVal = product['price'] ?? 0;
    final String formattedPrice = _formatCurrency(priceVal);
    final int stock = (product['stock'] as num?)?.toInt() ?? 0;
    final String status = product['status'] as String? ?? 'active';
    final String categoryName =
        product['category_name'] as String? ?? 'Alat Elektronik';

    // Atur Badge Status sesuai stok/status
    String badgeText = 'Aktif';
    Color badgeBg = const Color(0xFFE5F9EB);
    Color badgeColor = const Color(0xFF23B259);

    if (stock <= 0) {
      badgeText = 'Habis';
      badgeBg = const Color(0xFFFFECEE);
      badgeColor = const Color(0xFFFF4D4F);
    } else if (status == 'archived') {
      badgeText = 'Arsip';
      badgeBg = const Color(0xFFE6F0FF);
      badgeColor = const Color(0xFF1890FF);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Atas: Gambar + Detail Produk
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 95,
                    height: 95,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4A79),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A7A8A),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Rp $formattedPrice",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4A79),
                            ),
                          ),
                          Text(
                            "Stok: $stock",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF556575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah & Tombol Aksi (Edit, Detail, Hapus)
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F7)),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateProductPage(product: product),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF007BFF),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Edit",
                          style: TextStyle(
                            color: Color(0xFF007BFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFEFF3F7)),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF6A7A8A),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Detail",
                          style: TextStyle(
                            color: Color(0xFF6A7A8A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFEFF3F7)),
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                    onTap: () => _showDeleteDialog(context, product),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF4D4F),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Hapus",
                          style: TextStyle(
                            color: Color(0xFFFF4D4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFEBF0F5),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color(0xFF90A4AE),
      ),
    );
  }
}
