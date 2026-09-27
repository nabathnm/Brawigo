import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'buyer_product_detail_page.dart';
import 'buyer_search_result_page.dart';

class BuyerSearchPage extends StatefulWidget {
  const BuyerSearchPage({super.key});

  @override
  State<BuyerSearchPage> createState() => _BuyerSearchPageState();
}

class _BuyerSearchPageState extends State<BuyerSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<Map<String, String>> _recentlyViewedProducts = [];
  bool _isLoadingViewed = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });

    final viewedIds = prefs.getStringList('recently_viewed') ?? [];
    if (viewedIds.isEmpty) {
      if (mounted) setState(() => _isLoadingViewed = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .inFilter('id', viewedIds)
          .limit(10);
      
      final products = List<Map<String, dynamic>>.from(response);
      final List<Map<String, String>> viewed = [];
      final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      // Sort according to viewedIds order
      for (final id in viewedIds.reversed) {
        final p = products.firstWhere((element) => element['id'].toString() == id, orElse: () => {});
        if (p.isNotEmpty) {
          viewed.add({
            'id': p['id']?.toString() ?? '',
            'name': p['product_name']?.toString() ?? '',
            'category': 'Kategori',
            'price': p['price'] != null ? formatCurrency.format(p['price']) : '',
            'image_url': p['thumbnail_url']?.toString() ?? '',
            'description': p['description']?.toString() ?? '',
            'seller_id': p['seller_id']?.toString() ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _recentlyViewedProducts = viewed;
          _isLoadingViewed = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingViewed = false);
    }
  }

  Future<void> _addRecentSearch(String query) async {
    final trimQuery = query.trim();
    if (trimQuery.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(trimQuery);
    _recentSearches.insert(0, trimQuery);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    
    if (mounted) {
      // Use standard push to search result page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuyerSearchResultPage(searchQuery: trimQuery),
        ),
      ).then((_) {
        // Reload history when coming back
        _loadHistory();
      });
    }
  }

  Future<void> _removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(query);
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              if (_recentSearches.isNotEmpty) _buildRecentSearches(),
              if (_recentSearches.isNotEmpty) const SizedBox(height: 24),
              _buildRecentlyViewed(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF15243C), 
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true, 
                textInputAction: TextInputAction.search,
                onSubmitted: _addRecentSearch,
                decoration: const InputDecoration(
                  hintText: 'Cari produk',
                  hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFFA0AEC0),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Pencarian Terakhir",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSearches.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(
                Icons.history_rounded,
                color: Color(0xFF2B5F9E),
                size: 22,
              ),
              title: Text(
                _recentSearches[index],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B5F9E),
                ),
              ),
              onTap: () {
                _addRecentSearch(_recentSearches[index]);
              },
              trailing: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF2B5F9E),
                  size: 20,
                ),
                onPressed: () => _removeSearch(_recentSearches[index]),
              ),
              dense: true,
            );
          },
        )
      ],
    );
  }

  Widget _buildRecentlyViewed() {
    if (_isLoadingViewed) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_recentlyViewedProducts.isEmpty) {
      return const SizedBox.shrink(); // Hide if empty
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Terakhir Dilihat",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF15243C),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _recentlyViewedProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = _recentlyViewedProducts[index];
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuyerProductDetailPage(product: product),
                      ),
                    ).then((_) {
                       _loadHistory();
                    });
                  },
                  child: Container(
                    width: 155,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
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
                              )
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
            ),
          ),
        ),
      ],
    );
  }
}
