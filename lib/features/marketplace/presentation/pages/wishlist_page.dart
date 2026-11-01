import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'buyer_product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _supabase = Supabase.instance.client;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];

  String _selectedSort = 'terbaru'; // terbaru, termurah, termahal, az
  String? _selectedCategory;

  static const _primary = Color(0xFF2B5F9E);
  static const _textDark = Color(0xFF15243C);
  static const _textGrey = Color(0xFF64748B);

  // Kategori resmi sesuai desain Gambar 3
  static const List<String> kCategories = [
    'Semua',
    'Alat Elektronik',
    'Perlengkapan Kuliah',
    'Buku & Alat Tulis',
    'Makanan & Minuman',
    'Perawatan Diri',
    'Fashion',
    'Hobi & Kreatif',
    'Perabotan Kos/Rumah',
    'Jasa',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchWishlists();
  }

  String _mapToCanonicalCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Lainnya';
    final lower = raw.toLowerCase().trim();
    if (lower.contains('elektronik') || lower.contains('electronic')) return 'Alat Elektronik';
    if (lower.contains('kuliah') || lower.contains('kampus') || lower.contains('perlengkapan')) return 'Perlengkapan Kuliah';
    if (lower.contains('buku') || lower.contains('tulis') || lower.contains('alat tulis')) return 'Buku & Alat Tulis';
    if (lower.contains('makan') || lower.contains('minum') || lower.contains('food') || lower.contains('snack')) return 'Makanan & Minuman';
    if (lower.contains('rawat') || lower.contains('sehat') || lower.contains('kesehatan') || lower.contains('care')) return 'Perawatan Diri';
    if (lower.contains('fashion') || lower.contains('baju') || lower.contains('pakaian') || lower.contains('sepatu') || lower.contains('tas')) return 'Fashion';
    if (lower.contains('hobi') || lower.contains('kreatif') || lower.contains('olahraga') || lower.contains('sport')) return 'Hobi & Kreatif';
    if (lower.contains('perabot') || lower.contains('kos') || lower.contains('kost') || lower.contains('rumah')) return 'Perabotan Kos/Rumah';
    if (lower.contains('jasa') || lower.contains('service')) return 'Jasa';
    return raw;
  }

  Future<void> _fetchWishlists() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _items = [];
          _filteredItems = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> loadedItems = [];

      // 1. Try join query with products and categories
      try {
        final res = await _supabase
            .from('wishlists')
            .select('id, product_id, created_at, products(id, product_name, price, stock, thumbnail_url, category_id, seller_id, description, status, categories(name))')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        for (final row in (res as List)) {
          final prod = row['products'] as Map<String, dynamic>?;
          if (prod != null) {
            final catObj = prod['categories'] as Map<String, dynamic>?;
            final rawCatName = catObj?['name']?.toString();
            final catName = _mapToCanonicalCategory(rawCatName);
            loadedItems.add({
              'wishlist_id': row['id'],
              'created_at': row['created_at'],
              'category_name': catName,
              ...prod,
            });
          }
        }
      } catch (joinError) {
        // 2. Fallback: manual 2-step query if join had issues
        try {
          final wishRes = await _supabase
              .from('wishlists')
              .select('id, product_id, created_at')
              .eq('user_id', user.id)
              .order('created_at', ascending: false);

          final wishList = wishRes as List;
          if (wishList.isNotEmpty) {
            final productIds = wishList.map((w) => w['product_id'].toString()).toList();
            final prodRes = await _supabase
                .from('products')
                .select('id, product_name, price, stock, thumbnail_url, category_id, seller_id, description, status, categories(name)')
                .inFilter('id', productIds);

            final Map<String, Map<String, dynamic>> prodMap = {};
            for (final p in (prodRes as List)) {
              final catObj = p['categories'] as Map<String, dynamic>?;
              final rawCatName = catObj?['name']?.toString();
              prodMap[p['id'].toString()] = {
                ...p,
                'category_name': _mapToCanonicalCategory(rawCatName),
              };
            }

            for (final w in wishList) {
              final pId = w['product_id'].toString();
              if (prodMap.containsKey(pId)) {
                loadedItems.add({
                  'wishlist_id': w['id'],
                  'created_at': w['created_at'],
                  ...prodMap[pId]!,
                });
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _items = loadedItems;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _filteredItems = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> list = List.from(_items);

    // Filter category
    if (_selectedCategory != null && _selectedCategory != 'Semua') {
      list = list.where((p) {
        final cat = (p['category_name'] ?? '').toString();
        return cat.toLowerCase() == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'termurah':
        list.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
        break;
      case 'termahal':
        list.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
        break;
      case 'az':
        list.sort((a, b) => (a['product_name'] ?? '').toString().compareTo((b['product_name'] ?? '').toString()));
        break;
      case 'terbaru':
      default:
        // default order by created_at descending
        break;
    }

    _filteredItems = list;
  }

  Future<void> _removeWishlist(String wishlistId, String productName) async {
    try {
      await _supabase.from('wishlists').delete().eq('id', wishlistId);
      setState(() {
        _items.removeWhere((e) => e['wishlist_id'] == wishlistId);
        _applyFilters();
      });
      if (mounted) {
        BrawigoToast.showInfo(
          context,
          title: 'Dihapus',
          message: '$productName dihapus dari wishlist.',
        );
      }
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(
          context,
          title: 'Gagal',
          message: 'Gagal menghapus dari wishlist.',
        );
      }
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
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
          _applyFilters();
        });
      },
    );
  }

  // Bottom sheet filter kategori sesuai desain Gambar 3
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        if (_selectedCategory != null && _selectedCategory != 'Semua')
                          GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedCategory = 'Semua');
                              setState(() {
                                _selectedCategory = null;
                                _applyFilters();
                              });
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Chips (Wrap) matching Gambar 3
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: kCategories.map((cat) {
                        final isSelected = (_selectedCategory == null && cat == 'Semua') ||
                            (_selectedCategory?.toLowerCase() == cat.toLowerCase());

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedCategory = cat == 'Semua' ? null : cat;
                              _applyFilters();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE6EDF8) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? _primary : const Color(0xFFCBD5E1),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? _primary : _textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
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
                      'Wishlist Kamu',
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
                      label: _selectedCategory != null ? 'Filter ($_selectedCategory)' : 'Filter',
                      isActive: _selectedCategory != null,
                      onTap: _showFilterSheet,
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
                            onRefresh: _fetchWishlists,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.68, // Card proporsional & compact, aman dari overflow
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
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: _primary, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? _primary : _textDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? _primary : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card produk compact & proporsional persis Gambar 2 (Zero-overflow responsive)
  Widget _buildProductCard(Map<String, dynamic> item) {
    final name = item['product_name']?.toString() ?? 'Produk';
    final category = item['category_name']?.toString() ??
        (item['categories'] is Map ? item['categories']['name']?.toString() : null) ??
        'Lainnya';
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final thumbnailUrl = item['thumbnail_url']?.toString();
    final wishlistId = item['wishlist_id']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (Expanded agar secara responsif menyesuaikan tinggi tanpa overflow)
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
                // Heart button (blue border + blue filled heart)
                InkWell(
                  onTap: () => _removeWishlist(wishlistId, name),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primary, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color: _primary,
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
                      ).then((_) => _fetchWishlists());
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
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Lihat Barang',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
      color: const Color(0xFFE6EDF8),
      child: const Center(
        child: Icon(Icons.image_outlined, color: _primary, size: 36),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Spacer(flex: 2),

        // Geometric Shapes Icon (matching Gambar 4: △ ♡ / ○ ▢)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.change_history, size: 28, color: Color(0xFF1F4A7A)),
                  SizedBox(width: 6),
                  Icon(Icons.favorite_border_rounded, size: 28, color: Color(0xFF1F4A7A)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.circle_outlined, size: 26, color: Color(0xFF1F4A7A)),
                  SizedBox(width: 6),
                  Icon(Icons.crop_square_rounded, size: 26, color: Color(0xFF1F4A7A)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title
        const Text(
          'Wishlist Kamu Masih Kosong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'Yuk, mulai cari barang yang kamu suka!',
          style: TextStyle(
            fontSize: 13,
            color: _textGrey,
          ),
        ),

        const Spacer(flex: 3),

        // Bottom "Cari Barang" Button (spanning width)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3873B2), Color(0xFF204E85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B5F9E).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/buyer');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Cari Barang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
