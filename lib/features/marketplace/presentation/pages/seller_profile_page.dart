import 'report_user_page.dart';
import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'buyer_product_detail_page.dart';
import 'seller_detail_profile_page.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;

  const SellerProfilePage({super.key, required this.sellerId});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _supabase = Supabase.instance.client;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  Map<String, dynamic>? _sellerProfile;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Map<String, String> _categoryMap = {};

  String _searchQuery = '';
  String _selectedSort = 'terbaru'; // terbaru, termurah, termahal
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopData() async {
    try {
      // 1. Fetch Profile Penjual
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.sellerId)
          .maybeSingle();

      // 2. Fetch Kategori untuk pemetaan ID -> Nama
      try {
        final catRes = await _supabase.from('categories').select('id, name');
        for (final c in (catRes as List)) {
          _categoryMap[c['id'].toString()] = c['name'].toString();
        }
      } catch (_) {}

      // 3. Fetch Produk Toko Penjual
      final productsRes = await _supabase
          .from('products')
          .select('id, product_name, description, price, stock, category_id, thumbnail_url, created_at, seller_id')
          .eq('seller_id', widget.sellerId)
          .order('created_at', ascending: false);

      final loaded = List<Map<String, dynamic>>.from(productsRes);

      if (mounted) {
        setState(() {
          _sellerProfile = profileRes;
          _allProducts = loaded;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching shop data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> list = List.from(_allProducts);

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final name = (p['product_name'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final catName = _getCategoryName(p['category_id']?.toString()).toLowerCase();
        return name.contains(q) || desc.contains(q) || catName.contains(q);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((p) {
        final catName = _getCategoryName(p['category_id']?.toString());
        return catName.toLowerCase() == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Sort
    if (_selectedSort == 'termurah') {
      list.sort((a, b) => _parsePrice(a['price']).compareTo(_parsePrice(b['price'])));
    } else if (_selectedSort == 'termahal') {
      list.sort((a, b) => _parsePrice(b['price']).compareTo(_parsePrice(a['price'])));
    } else {
      // terbaru (default)
      list.sort((a, b) {
        final dtA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final dtB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return dtB.compareTo(dtA);
      });
    }

    setState(() {
      _filteredProducts = list;
    });
  }

  num _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    final clean = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return num.tryParse(clean) ?? 0;
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Lainnya';
    return _categoryMap[categoryId] ?? 'Produk';
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('Urutkan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15243C))),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                activeColor: const Color(0xFF2B5F9E),
                title: const Text('Terbaru (Default)'),
                value: 'terbaru',
                groupValue: _selectedSort,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  if (val != null) {
                    setState(() => _selectedSort = val);
                    _applyFiltersAndSort();
                  }
                },
              ),
              RadioListTile<String>(
                activeColor: const Color(0xFF2B5F9E),
                title: const Text('Harga Terendah (Termurah)'),
                value: 'termurah',
                groupValue: _selectedSort,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  if (val != null) {
                    setState(() => _selectedSort = val);
                    _applyFiltersAndSort();
                  }
                },
              ),
              RadioListTile<String>(
                activeColor: const Color(0xFF2B5F9E),
                title: const Text('Harga Tertinggi (Termahal)'),
                value: 'termahal',
                groupValue: _selectedSort,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  if (val != null) {
                    setState(() => _selectedSort = val);
                    _applyFiltersAndSort();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryFilterDialog() {
    final categories = _allProducts
        .map((p) => _getCategoryName(p['category_id']?.toString()))
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('Filter Kategori Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15243C))),
              ),
              const Divider(height: 1),
              RadioListTile<String?>(
                activeColor: const Color(0xFF2B5F9E),
                title: const Text('Semua Kategori'),
                value: null,
                groupValue: _selectedCategory,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  setState(() => _selectedCategory = val);
                  _applyFiltersAndSort();
                },
              ),
              ...categories.map((cat) {
                return RadioListTile<String?>(
                activeColor: const Color(0xFF2B5F9E),
                  title: Text(cat),
                  value: cat,
                  groupValue: _selectedCategory,
                  onChanged: (val) {
                    Navigator.pop(ctx);
                    setState(() => _selectedCategory = val);
                    _applyFiltersAndSort();
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openChatWithSeller(String storeName) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      BrawigoToast.showWarning(context, title: 'Perlu Login', message: 'Silakan login terlebih dahulu untuk memulai percakapan.');
      return;
    }

    if (currentUser.id == widget.sellerId) {
      BrawigoToast.showWarning(context, title: 'Perhatian', message: 'Ini adalah toko dan produk milik Anda sendiri.');
      return;
    }

    try {
      final convs = await _supabase
          .from('conversations')
          .select('id, product_id, buyer_id, seller_id')
          .or('buyer_id.eq.${currentUser.id},seller_id.eq.${currentUser.id}')
          .order('updated_at', ascending: false);

      Map<String, dynamic>? existingConv;
      for (final c in (convs as List)) {
        final bId = c['buyer_id']?.toString();
        final sId = c['seller_id']?.toString();
        if ((bId == currentUser.id && sId == widget.sellerId) ||
            (bId == widget.sellerId && sId == currentUser.id)) {
          existingConv = Map<String, dynamic>.from(c);
          break;
        }
      }

      String conversationId;
      final defaultProdId = _allProducts.isNotEmpty ? _allProducts.first['id']?.toString() : null;

      if (existingConv != null) {
        conversationId = existingConv['id'];
      } else {
        try {
          final created = await _supabase
              .from('conversations')
              .insert({
                'buyer_id': currentUser.id,
                'seller_id': widget.sellerId,
                'product_id': defaultProdId ?? '',
              })
              .select('id')
              .single();
          conversationId = created['id'];
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            final convList = await _supabase
                .from('conversations')
                .select('id')
                .or('and(buyer_id.eq.${currentUser.id},seller_id.eq.${widget.sellerId}),and(buyer_id.eq.${widget.sellerId},seller_id.eq.${currentUser.id})')
                .order('updated_at', ascending: false)
                .limit(1);
            if ((convList as List).isNotEmpty) {
              conversationId = convList.first['id'];
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              conversationId: conversationId,
              otherUserName: storeName,
              otherUserId: widget.sellerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(context, title: 'Gagal', message: 'Gagal membuka obrolan: $e');
      }
    }
  }

  void _openReportUser(String storeName, String? photoUrl) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null && currentUserId == widget.sellerId) {
      BrawigoToast.showWarning(context, title: 'Akun Anda', message: 'Anda tidak dapat melaporkan toko Anda sendiri.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportUserPage(
          sellerId: widget.sellerId,
          sellerName: storeName,
          sellerPhoto: photoUrl,
          productId: _allProducts.isNotEmpty ? _allProducts.first['id']?.toString() : null,
        ),
      ),
    );
  }

  void _navigateToSellerDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerDetailProfilePage(
          sellerId: widget.sellerId,
          initialProfile: _sellerProfile,
          productCount: _allProducts.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil nama toko dan info penjual
    final fullName = _sellerProfile?['full_name'] ?? 'Penjual Brawigo';
    final faculty = _sellerProfile?['faculty'] ?? 'Filkom';
    final studyProgram = _sellerProfile?['study_program'] ?? 'Teknik Informatika';
    final email = _sellerProfile?['email'] ?? 'penjual@ub.ac.id';
    String storeName = fullName;
    String? photoUrl = _sellerProfile?['profile_photo_url']?.toString();
    try {
      final bio = _sellerProfile?['bio']?.toString() ?? '';
      if (bio.startsWith('{') && bio.contains('"')) {
        final parsed = jsonDecode(bio);
        if (parsed is Map) {
          if (parsed['store_name'] != null && parsed['store_name'].toString().isNotEmpty) {
            storeName = parsed['store_name'].toString();
          }
          // Prioritaskan store_photo_url dari bio; fallback ke profile_photo_url
          final storePhoto = parsed['store_photo_url']?.toString().trim();
          if (storePhoto != null && storePhoto.isNotEmpty) {
            photoUrl = storePhoto;
          }
        }
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)))
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Header Biru Toko (Gambar 1)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B90C9), Color(0xFF4376AF), Color(0xFF264E82)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Tombol Back Bulat Putih + Search Bar (Gambar 1)
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF15243C)),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
                                        decoration: const InputDecoration(
                                          hintText: 'Cari..',
                                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (val) {
                                          _searchQuery = val;
                                          _applyFiltersAndSort();
                                        },
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _applyFiltersAndSort();
                                        },
                                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Row 2: Profil Toko & Penjual (Gambar 1)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar bulat
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person, color: Color(0xFF2B5F9E), size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 14),

                            // Info Identitas Penjual & Toko (Sesuai Prompt User)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Nama Toko yang bisa ditekan menuju Gambar 2
                                  InkWell(
                                    onTap: _navigateToSellerDetail,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              storeName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // 2. Nama Pengguna Aslinya
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),

                                  // 3. Fakultas dan Jurusan
                                  Text(
                                    '$studyProgram · $faculty',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),

                                  // 4. Email
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Titik Tiga ⋮ (Gambar 1)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              offset: const Offset(0, 40),
                              onSelected: (val) {
                                if (val == 'chat') {
                                  _openChatWithSeller(storeName);
                                } else if (val == 'report') {
                                  _openReportUser(storeName, photoUrl);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'chat',
                                  height: 48,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F1FC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF2B5F9E)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Chat Penjual',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                                                                PopupMenuItem(
                                  value: 'report',
                                  height: 48,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F1FC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2B5F9E)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Laporkan Pengguna ini',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Bar Filter & Urutkan (Gambar 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        // Tombol Filter
                        InkWell(
                          onTap: _showCategoryFilterDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _selectedCategory != null ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedCategory != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list_rounded, size: 16, color: _selectedCategory != null ? const Color(0xFF2B5F9E) : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedCategory != null ? 'Kategori: $_selectedCategory' : 'Filter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCategory != null ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Tombol Urutkan
                        InkWell(
                          onTap: _showSortDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _selectedSort != 'terbaru' ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedSort != 'terbaru' ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.swap_vert_rounded, size: 16, color: _selectedSort != 'terbaru' ? const Color(0xFF2B5F9E) : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedSort == 'termurah'
                                      ? 'Termurah'
                                      : _selectedSort == 'termahal'
                                          ? 'Termahal'
                                          : 'Urutkan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedSort != 'terbaru' ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedCategory != null || _selectedSort != 'terbaru' || _searchQuery.isNotEmpty) ...[
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedCategory = null;
                                _selectedSort = 'terbaru';
                              });
                              _applyFiltersAndSort();
                            },
                            child: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Grid Produk Toko (Gambar 1)
                if (_filteredProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada produk yang ditemukan',
                            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coba ubah kata kunci pencarian atau filter.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['product_name']?.toString() ?? 'Produk';
    final price = _parsePrice(product['price']);
    final thumb = product['thumbnail_url']?.toString();
    final catName = _getCategoryName(product['category_id']?.toString());

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerProductDetailPage(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Produk (Gambar 1)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: (thumb != null && thumb.isNotEmpty)
                    ? Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 36),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 36),
                      ),
              ),
            ),

            // Informasi Produk (Nama, Kategori, Harga)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15243C),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          catName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(
                      _currencyFormat.format(price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B5F9E),
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
  }
}
