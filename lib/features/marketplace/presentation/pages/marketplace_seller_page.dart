import 'package:brawigo/core/utils/seller_profile_checker.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/custom_search.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/header.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketPlaceSellerPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const MarketPlaceSellerPage({super.key, this.onNavigateToProfile});

  @override
  State<MarketPlaceSellerPage> createState() => _MarketPlaceSellerPageState();
}

class _MarketPlaceSellerPageState extends State<MarketPlaceSellerPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Tersedia, 2: Habis, 3: Arsip
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
        if (!status.isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SellerProfileStatus.showIncompleteDialog(
              context,
              onGoToProfile: () => widget.onNavigateToProfile?.call(),
              onEscapeToBuyer: () => context.go('/buyer'),
            );
          });
        }
      }
    }
  }

  bool _requireProfileComplete() {
    if (_profileStatus != null && !_profileStatus!.isComplete) {
      SellerProfileStatus.showIncompleteDialog(
        context,
        onGoToProfile: () => widget.onNavigateToProfile?.call(),
        onEscapeToBuyer: () => context.go('/buyer'),
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
              child: Header(onRoleSwitch: () => context.go('/buyer')),
            ),
            if (_profileStatus != null && !_profileStatus!.isComplete) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    SellerProfileStatus.showIncompleteDialog(
                      context,
                      onGoToProfile: () => widget.onNavigateToProfile?.call(),
                      onEscapeToBuyer: () => context.go('/buyer'),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pengaturan Toko Belum Lengkap",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                "Belum ada: ${_profileStatus!.missingFields.join(', ')}. Klik di sini untuk melengkapi profil.",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFD97706),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                                      onBeforeAction: _requireProfileComplete,
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
}
