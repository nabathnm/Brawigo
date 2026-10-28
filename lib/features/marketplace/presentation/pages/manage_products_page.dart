import 'package:brawigo/core/utils/seller_profile_checker.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageProductsPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const ManageProductsPage({super.key, this.onNavigateToProfile});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Aktif, 2: Habis, 3: Arsip
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SellerProfileStatus? _profileStatus;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final status = await SellerProfileStatus.check(user.id);
      if (mounted) {
        setState(() {
          _profileStatus = status;
        });
      }
    }
  }

  bool _requireProfileComplete() {
    if (_profileStatus != null && !_profileStatus!.isComplete) {
      SellerProfileStatus.showIncompleteDialog(
        context,
        onGoToProfile: () => widget.onNavigateToProfile?.call(),
        onEscapeToBuyer: () => Navigator.pop(context),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> product) {
    if (!_requireProfileComplete()) return;
    final productId = product['id'].toString();
    final productName = product['product_name'] ?? 'Produk';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Hapus Produk",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
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
              elevation: 0,
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
    return Container(
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
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Center(
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF15243C),
                  ),
                ),
              ),
            ),
          ),
          title: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              final count = (state is MarketplaceLoaded) ? state.products.length : 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Kelola Produk",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  Text(
                    "$count produk",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              if (state is MarketplaceLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                );
              } else if (state is MarketplaceError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Error: ${state.message}",
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else if (state is MarketplaceLoaded) {
                final allProducts = state.products;

                // Hitung jumlah masing-masing kategori
                final activeProducts = allProducts.where((p) {
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

                // Daftar label filter chips sesuai Gambar 2
                final filters = [
                  'Semua (${allProducts.length})',
                  'Aktif (${activeProducts.length})',
                  'Habis (${outOfStockProducts.length})',
                  'Arsip (${archivedProducts.length})',
                ];

                List<Map<String, dynamic>> displayedProducts;
                if (_selectedFilter == 1) {
                  displayedProducts = activeProducts;
                } else if (_selectedFilter == 2) {
                  displayedProducts = outOfStockProducts;
                } else if (_selectedFilter == 3) {
                  displayedProducts = archivedProducts;
                } else {
                  displayedProducts = allProducts;
                }

                if (_searchQuery.isNotEmpty) {
                  displayedProducts = displayedProducts.where((p) {
                    final name = (p['product_name'] as String? ?? '').toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();
                }

                return RefreshIndicator(
                  color: const Color(0xFF2B5F9E),
                  onRefresh: () async {
                    await _checkProfileStatus();
                    if (context.mounted) {
                      context.read<MarketplaceBloc>().add(LoadSellerProducts());
                    }
                  },
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Search bar & Filter Button Row (Gambar 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFD3DFE8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.toLowerCase().trim();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Cari..',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD3DFE8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFF15243C),
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Optional quick filter sheet
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Filter Chips (Gambar 2)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                                  horizontal: 16,
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
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: const Color(0xFFD3DFE8),
                                          width: 1,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF244C80).withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  filters[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF4A5D70),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul Section "Produk Saya"
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Produk Saya",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // List Produk
                      Expanded(
                        child: displayedProducts.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: displayedProducts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final item = displayedProducts[index];
                                  return SellerProductCard(
                                    product: item,
                                    onDelete: () => _showDeleteDialog(context, item),
                                    onBeforeAction: _requireProfileComplete,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text("Memuat produk..."));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                "Tidak ada produk pada kategori ini.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

