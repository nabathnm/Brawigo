import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'buyer_product_detail_page.dart';

enum SortOption { none, priceLow, priceHigh }

class BuyerSearchResultPage extends StatefulWidget {
  final String searchQuery;

  const BuyerSearchResultPage({super.key, required this.searchQuery});

  @override
  State<BuyerSearchResultPage> createState() => _BuyerSearchResultPageState();
}

class _BuyerSearchResultPageState extends State<BuyerSearchResultPage> {
  late TextEditingController _searchController;
  List<Map<String, String>> _searchResults = [];
  List<Map<String, String>> _sortedResults = [];
  bool _isLoading = true;
  SortOption _currentSort = SortOption.none;
  final _formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _performSearch(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _sortedResults = [];
      _currentSort = SortOption.none;
    });

    if (query.trim().isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .ilike('product_name', '%$query%')
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        final results = products.map((p) {
          return {
            'id': p['id']?.toString() ?? '',
            'name': p['product_name']?.toString() ?? '',
            'category': 'Kategori',
            'price': p['price'] != null ? _formatCurrency.format(p['price']) : '',
            'raw_price': p['price']?.toString() ?? '0',
            'image_url': p['thumbnail_url']?.toString() ?? '',
            'description': p['description']?.toString() ?? '',
            'seller_id': p['seller_id']?.toString() ?? '',
          };
        }).toList();

        setState(() {
          _searchResults = results;
          _sortedResults = List.from(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySort(SortOption option) {
    setState(() {
      _currentSort = option;
      _sortedResults = List.from(_searchResults);
      if (option == SortOption.priceLow) {
        _sortedResults.sort((a, b) {
          final aPrice = double.tryParse(a['raw_price'] ?? '0') ?? 0;
          final bPrice = double.tryParse(b['raw_price'] ?? '0') ?? 0;
          return aPrice.compareTo(bPrice);
        });
      } else if (option == SortOption.priceHigh) {
        _sortedResults.sort((a, b) {
          final aPrice = double.tryParse(a['raw_price'] ?? '0') ?? 0;
          final bPrice = double.tryParse(b['raw_price'] ?? '0') ?? 0;
          return bPrice.compareTo(aPrice);
        });
      }
    });
    Navigator.pop(context);
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Urutkan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15243C),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption(
                label: 'Harga Termurah',
                icon: Icons.arrow_downward_rounded,
                isSelected: _currentSort == SortOption.priceLow,
                onTap: () => _applySort(SortOption.priceLow),
              ),
              const Divider(height: 1),
              _buildSortOption(
                label: 'Harga Termahal',
                icon: Icons.arrow_upward_rounded,
                isSelected: _currentSort == SortOption.priceHigh,
                onTap: () => _applySort(SortOption.priceHigh),
              ),
              if (_currentSort != SortOption.none) ...[
                const Divider(height: 1),
                _buildSortOption(
                  label: 'Hapus Pengurutan',
                  icon: Icons.close_rounded,
                  isSelected: false,
                  onTap: () => _applySort(SortOption.none),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFF15243C),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_rounded, color: Color(0xFF2B5F9E), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFF9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 1.0],
            colors: [
              Color(0xFFB8CEE8),
              Color(0xFFD6E4F0),
              Color(0xFFF0F5FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilterRow(),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF15243C),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2B5F9E), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Cari produk',
                  hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF2B5F9E),
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFFA0AEC0)),
                    onPressed: () => _searchController.clear(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _buildChip(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            isActive: false,
            onTap: () {}, // Filter belum aktif
          ),
          const SizedBox(width: 10),
          _buildChip(
            icon: Icons.import_export_rounded,
            label: _currentSort == SortOption.priceLow
                ? 'Harga Termurah'
                : _currentSort == SortOption.priceHigh
                    ? 'Harga Termahal'
                    : 'Urutkan',
            isActive: _currentSort != SortOption.none,
            onTap: _showSortBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2B5F9E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2B5F9E) : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF15243C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sortedResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "Maaf, barang yang Anda cari\nsedang tidak ada atau tidak ditemukan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _sortedResults.length,
      itemBuilder: (context, index) {
        final product = _sortedResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuyerProductDetailPage(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: (product['image_url'] != null && product['image_url']!.isNotEmpty)
                      ? Image.network(
                          product['image_url']!,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 145,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 145,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B5F9E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product['category'] ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          product['price'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15243C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

