import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'buyer_product_detail_page.dart';
import 'buyer_search_filter_page.dart';

class LatestProductsPage extends StatefulWidget {
  const LatestProductsPage({super.key});

  @override
  State<LatestProductsPage> createState() => _LatestProductsPageState();
}

class _LatestProductsPageState extends State<LatestProductsPage> {
  final _supabase = Supabase.instance.client;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  Set<String> _wishlistProductIds = {};

  String _selectedSort = 'terbaru'; // terbaru, termurah, termahal, az
  SearchFilterData _currentFilter = const SearchFilterData();

  static const _primary = Color(0xFF2B5F9E);
  static const _textDark = Color(0xFF15243C);
  static const _textGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchLatestProducts(),
      _fetchUserWishlist(),
    ]);
    if (mounted) {
      _applyFiltersAndSort();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserWishlist() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _wishlistProductIds = {};
        return;
      }

      final res = await _supabase
          .from('wishlists')
          .select('product_id')
          .eq('user_id', user.id);

      final ids = (res as List)
          .map((row) => row['product_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      _wishlistProductIds = ids;
    } catch (_) {
      _wishlistProductIds = {};
    }
  }

  Future<void> _fetchLatestProducts() async {
    try {
      List<Map<String, dynamic>> loadedProducts = [];

      try {
        // Coba query dengan join categories
        final res = await _supabase
            .from('products')
            .select('*, categories(id, name, icon)')
            .eq('status', 'active')
            .gt('stock', 0)
            .order('created_at', ascending: false);

        for (final row in (res as List)) {
          final catObj = row['categories'] as Map<String, dynamic>?;
          final catName = catObj?['name']?.toString() ?? 'Lainnya';
          loadedProducts.add({
            ...row,
            'category_name': catName,
          });
        }
      } catch (_) {
        // Fallback: Query langsung table products & categories secara terpisah
        final res = await _supabase
            .from('products')
            .select()
            .eq('status', 'active')
            .gt('stock', 0)
            .order('created_at', ascending: false);

        final catRes = await _supabase.from('categories').select('id, name');
        final catMap = <String, String>{};
        for (final c in (catRes as List)) {
          catMap[c['id'].toString()] = c['name']?.toString() ?? '';
        }

        for (final row in (res as List)) {
          final catId = row['category_id']?.toString() ?? '';
          final catName = catMap[catId] ?? 'Lainnya';
          loadedProducts.add({
            ...row,
            'category_name': catName,
          });
        }
      }

      _allItems = loadedProducts;
    } catch (_) {
      _allItems = [];
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> list = List.from(_allItems);

    // Filter Kategori (jika dipilih)
    if (_currentFilter.category != null &&
        _currentFilter.category!.isNotEmpty &&
        _currentFilter.category != 'Semua') {
      final selectedCat = _currentFilter.category!.toLowerCase().trim();
      list = list.where((p) {
        final cat = (p['category_name'] ?? '').toString().toLowerCase().trim();
        return cat == selectedCat || cat.contains(selectedCat) || selectedCat.contains(cat);
      }).toList();
    }

    // Filter Rentang Harga Min
    if (_currentFilter.minPrice != null) {
      list = list.where((p) {
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
        return price >= _currentFilter.minPrice!;
      }).toList();
    }

    // Filter Rentang Harga Max
    if (_currentFilter.maxPrice != null) {
      list = list.where((p) {
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
        return price <= _currentFilter.maxPrice!;
      }).toList();
    }

    // Pastikan stok > 0 selalu terpenuhi
    list = list.where((p) {
      final stock = (p['stock'] as num?)?.toInt() ?? 0;
      return stock > 0;
    }).toList();

    // Urutkan
    switch (_selectedSort) {
      case 'termurah':
        list.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
        break;
      case 'termahal':
        list.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
        break;
      case 'az':
        list.sort((a, b) => (a['product_name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['product_name'] ?? '').toString().toLowerCase()));
        break;
      case 'terbaru':
      default:
        list.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
    }

    _filteredItems = list;
  }

  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      BrawigoToast.showInfo(
        context,
        title: 'Perhatian',
        message: 'Silakan login terlebih dahulu untuk menambah wishlist.',
      );
      return;
    }

    final productId = item['id']?.toString() ?? '';
    final productName = item['product_name']?.toString() ?? 'Produk';
    if (productId.isEmpty) return;

    final isWishlisted = _wishlistProductIds.contains(productId);

    if (isWishlisted) {
      // Hapus dari wishlist
      setState(() {
        _wishlistProductIds.remove(productId);
      });
      try {
        await _supabase
            .from('wishlists')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);

        if (mounted) {
          BrawigoToast.showInfo(
            context,
            title: 'Dihapus',
            message: '$productName dihapus dari wishlist.',
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _wishlistProductIds.add(productId);
          });
          BrawigoToast.showError(
            context,
            title: 'Gagal',
            message: 'Gagal menghapus dari wishlist.',
          );
        }
      }
    } else {
      // Tambah ke wishlist
      setState(() {
        _wishlistProductIds.add(productId);
      });
      try {
        await _supabase.from('wishlists').insert({
          'user_id': user.id,
          'product_id': productId,
        });

        if (mounted) {
          BrawigoToast.showSuccess(
            context,
            title: 'Ditambahkan',
            message: '$productName ditambahkan ke wishlist.',
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _wishlistProductIds.remove(productId);
          });
          BrawigoToast.showError(
            context,
            title: 'Gagal',
            message: 'Gagal menambahkan ke wishlist.',
          );
        }
      }
    }
  }

  void _openFilterPage() async {
    final result = await Navigator.push<SearchFilterData>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerSearchFilterPage(initialFilter: _currentFilter),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
        _applyFiltersAndSort();
      });
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ),
                const Divider(),
                _sortTile('Terbaru', 'terbaru', ctx),
                _sortTile('Harga Terendah', 'termurah', ctx),
                _sortTile('Harga Tertinggi', 'termahal', ctx),
                _sortTile('Nama (A - Z)', 'az', ctx),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile(String label, String value, BuildContext ctx) {
    final isSelected = _selectedSort == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? _primary : _textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: _primary) : null,
      onTap: () {
        Navigator.pop(ctx);
        setState(() {
          _selectedSort = value;
          _applyFiltersAndSort();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8DAEF), Color(0xFFE6EDF8), Color(0xFFFAFAFA)],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Back Button + Title ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Produk Terbaru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── Filter & Urutkan Buttons ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildPillButton(
                      icon: Icons.tune_rounded,
                      label: _currentFilter.isActive
                          ? (_currentFilter.category != null && _currentFilter.category!.isNotEmpty
                              ? 'Filter (${_currentFilter.category})'
                              : 'Filter (Aktif)')
                          : 'Filter',
                      isActive: _currentFilter.isActive,
                      onTap: _openFilterPage,
                    ),
                    const SizedBox(width: 10),
                    _buildPillButton(
                      icon: Icons.swap_vert_rounded,
                      label: _selectedSort == 'terbaru'
                          ? 'Urutkan'
                          : _selectedSort == 'termurah'
                              ? 'Termurah'
                              : _selectedSort == 'termahal'
                                  ? 'Termahal'
                                  : 'A-Z',
                      isActive: _selectedSort != 'terbaru',
                      onTap: _showSortSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── Content Grid / Empty State ───────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _primary))
                    : _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _primary,
                            onRefresh: _loadData,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(_filteredItems[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _primary : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? _primary : _textDark,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _primary : _textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: _textGrey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentFilter.isActive
                  ? 'Tidak ada produk yang sesuai dengan filter yang Anda pasang.'
                  : 'Belum ada produk terbaru yang tersedia saat ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textGrey,
                height: 1.4,
              ),
            ),
            if (_currentFilter.isActive) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentFilter = const SearchFilterData();
                    _applyFiltersAndSort();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Reset Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final productId = item['id']?.toString() ?? '';
    final name = item['product_name'] ?? '-';
    final category = item['category_name'] ?? 'Lainnya';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final thumbnailUrl = item['thumbnail_url'] as String?;
    final isWishlisted = _wishlistProductIds.contains(productId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerProductDetailPage(product: item),
          ),
        ).then((_) => _fetchUserWishlist());
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Product Name (Bold Blue)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 2),

            // Category (Grey)
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: _textGrey,
              ),
            ),
            const SizedBox(height: 3),

            // Price (Dark Bold)
            Text(
              _currency.format(price),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 8),

            // Actions Row (Heart button + Lihat Barang)
            Row(
              children: [
                // Heart button
                InkWell(
                  onTap: () => _toggleWishlist(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWishlisted ? _primary : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 17,
                      color: isWishlisted ? _primary : _textGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // "Lihat Barang" Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerProductDetailPage(product: item),
                        ),
                      ).then((_) => _fetchUserWishlist());
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3873B2), Color(0xFF244C80)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B5F9E).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Lihat Barang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFF94A3B8),
          size: 28,
        ),
      ),
    );
  }
}

