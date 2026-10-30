import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/full_screen_image_viewer.dart';

class SellerReviewsPage extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic>? sellerProfile;
  final List<Map<String, dynamic>>? initialReviews;
  final double? initialAverageRating;
  final int? initialTotalReviews;
  final Map<int, int>? initialStarCounts;

  const SellerReviewsPage({
    super.key,
    required this.sellerId,
    this.sellerProfile,
    this.initialReviews,
    this.initialAverageRating,
    this.initialTotalReviews,
    this.initialStarCounts,
  });

  @override
  State<SellerReviewsPage> createState() => _SellerReviewsPageState();
}

class _SellerReviewsPageState extends State<SellerReviewsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  final Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  // Filter rating bintang: 0 = Semua, 5 = Bintang 5, 4 = Bintang 4, dst.
  int _selectedStarFilter = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialReviews != null &&
        widget.initialReviews!.isNotEmpty &&
        widget.initialReviews!.first['reviewer_profile'] != null) {
      _reviews = List.from(widget.initialReviews!);
      _averageRating = widget.initialAverageRating ?? 0.0;
      _totalReviews = widget.initialTotalReviews ?? _reviews.length;
      if (widget.initialStarCounts != null) {
        _starCounts.addAll(widget.initialStarCounts!);
      }
      _isLoading = false;
    } else {
      _fetchReviews();
    }
  }

  Future<void> _fetchReviews() async {
    try {
      // 1. Ambil produk milik penjual untuk mendapatkan ID produknya
      final productsRes = await _supabase
          .from('products')
          .select('id, product_name, thumbnail_url, price')
          .eq('seller_id', widget.sellerId);

      final productMap = <String, Map<String, dynamic>>{};
      final List<String> productIds = [];
      for (final p in productsRes) {
        final pid = p['id'].toString();
        productIds.add(pid);
        productMap[pid] = Map<String, dynamic>.from(p);
      }

      final List<Map<String, dynamic>> loadedReviews = [];
      if (productIds.isNotEmpty) {
        final reviewsRes = await _supabase
            .from('reviews')
            .select()
            .inFilter('product_id', productIds)
            .order('created_at', ascending: false);

        // Cari tahu apakah ada produk tambahan dari ulasan yang belum ada di map
        final missingProductIds = reviewsRes
            .map((r) => r['product_id']?.toString())
            .where((id) => id != null && id.isNotEmpty && !productMap.containsKey(id))
            .cast<String>()
            .toSet()
            .toList();

        if (missingProductIds.isNotEmpty) {
          try {
            final extraProductsRes = await _supabase
                .from('products')
                .select('id, product_name, thumbnail_url, price')
                .inFilter('id', missingProductIds);
            for (final p in extraProductsRes) {
              productMap[p['id'].toString()] = Map<String, dynamic>.from(p);
            }
          } catch (e) {
            debugPrint('Error fetching missing products: $e');
          }
        }

        final reviewerIds = reviewsRes
            .map((r) => r['reviewer_id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        final reviewerProfileMap = <String, Map<String, dynamic>>{};
        if (reviewerIds.isNotEmpty) {
          final reviewersRes = await _supabase
              .from('profiles')
              .select('id, full_name, username, faculty, study_program, profile_photo_url')
              .inFilter('id', reviewerIds);

          for (final r in reviewersRes) {
            reviewerProfileMap[r['id'].toString()] = Map<String, dynamic>.from(r);
          }
        }

        int sumRating = 0;
        _starCounts.updateAll((key, value) => 0);

        for (final r in reviewsRes) {
          final revMap = Map<String, dynamic>.from(r);
          final pId = revMap['product_id']?.toString() ?? '';
          final revId = revMap['reviewer_id']?.toString() ?? '';

          revMap['product_data'] = productMap[pId];
          revMap['reviewer_profile'] = reviewerProfileMap[revId];

          final ratingVal = (revMap['rating'] as num?)?.toInt() ?? 5;
          sumRating += ratingVal;
          _starCounts[ratingVal] = (_starCounts[ratingVal] ?? 0) + 1;

          loadedReviews.add(revMap);
        }

        _totalReviews = loadedReviews.length;
        _averageRating = _totalReviews > 0 ? (sumRating / _totalReviews) : 0.0;
      }

      if (mounted) {
        setState(() {
          _reviews = loadedReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredReviews {
    if (_selectedStarFilter == 0) return _reviews;
    return _reviews.where((r) {
      final rating = (r['rating'] as num?)?.toInt() ?? 5;
      return rating == _selectedStarFilter;
    }).toList();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Baru saja';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return 'Baru saja';
    }
  }

  Map<String, dynamic> _parseCommentData(String? raw) {
    String text = '';
    List<String> photos = [];
    if (raw == null || raw.isEmpty) {
      text = 'Pembeli tidak meninggalkan ulasan tertulis.';
      return {'text': text, 'photos': photos};
    }
    try {
      if (raw.startsWith('{') && raw.contains('"text"')) {
        final parsed = jsonDecode(raw);
        text = parsed['text']?.toString() ?? '';
        if (parsed['photos'] is List) {
          photos = List<String>.from(parsed['photos']);
        }
      } else {
        text = raw;
      }
    } catch (_) {
      text = raw;
    }
    if (text.isEmpty) text = 'Pembeli tidak meninggalkan ulasan tertulis.';
    return {'text': text, 'photos': photos};
  }

  void _showReviewDetailModal(Map<String, dynamic> review) {
    final reviewerProfile = review['reviewer_profile'] as Map<String, dynamic>?;
    final rawName = reviewerProfile?['full_name']?.toString().trim();
    final reviewerName = (rawName != null && rawName.isNotEmpty) ? rawName : 'Pengguna Brawigo';
    final rawUsername = reviewerProfile?['username']?.toString().trim();
    final usernameText = (rawUsername != null && rawUsername.isNotEmpty)
        ? (rawUsername.startsWith('@') ? rawUsername : '@$rawUsername')
        : '';
    final faculty = reviewerProfile?['faculty']?.toString().trim() ?? '';
    final studyProgram = reviewerProfile?['study_program']?.toString().trim() ?? '';
    final studentInfo = [studyProgram, faculty].where((s) => s.isNotEmpty).join(' • ');
    final subtitleText = studentInfo.isNotEmpty ? studentInfo : 'Mahasiswa UB';
    final reviewerPhoto = reviewerProfile?['profile_photo_url']?.toString();
    final dateStr = _formatDate(review['created_at']?.toString());
    final ratingVal = (review['rating'] as num?)?.toInt() ?? 5;

    final commentData = _parseCommentData(review['comment']?.toString());
    final commentText = commentData['text'] as String;
    final photos = commentData['photos'] as List<String>;

    final productData = review['product_data'] as Map<String, dynamic>?;
    final productName = productData?['product_name'] ?? 'Produk Brawigo';
    final productThumb = productData?['thumbnail_url']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Penilaian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),

              // Reviewer Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: (reviewerPhoto != null && reviewerPhoto.isNotEmpty)
                        ? NetworkImage(reviewerPhoto)
                        : null,
                    child: (reviewerPhoto == null || reviewerPhoto.isEmpty)
                        ? Text(
                            reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2B5F9E)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reviewerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (usernameText.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                usernameText,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF2B5F9E), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Bintang
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < ratingVal ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 24,
                  );
                }),
              ),

              const SizedBox(height: 12),

              // Ulasan teks
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  commentText,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                ),
              ),

              // Foto-foto bukti yang dilampirkan (jika ada)
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF2B5F9E)),
                    const SizedBox(width: 6),
                    Text(
                      'Foto Bukti Transaksi (${photos.length}):',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () {
                          FullScreenImageViewer.open(context, images: photos, initialIndex: i);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                photos[i],
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 84,
                                  height: 84,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info Produk yang dinilai (Rill Thumbnail + Nama)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (productThumb != null && productThumb.isNotEmpty)
                          ? Image.network(
                              productThumb,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFCBD5E1),
                                child: const Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF64748B)),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFFCBD5E1),
                              child: const Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF64748B)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Produk yang dibeli:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            productName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          foregroundColor: const Color(0xFF15243C),
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profil Penjual',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF15243C)),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)))
            : RefreshIndicator(
                onRefresh: _fetchReviews,
                color: const Color(0xFF2B5F9E),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Card Rating & Ulasan (Persis Gambar 3)
                      _buildRatingSummaryCard(),
                      const SizedBox(height: 14),

                      // 2. Filter Bintang (Chips horizontal)
                      _buildStarFilterChips(),
                      const SizedBox(height: 14),

                      // 3. Daftar Ulasan Pembeli
                      if (_filteredReviews.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                _selectedStarFilter > 0
                                    ? 'Tidak Ada Ulasan Bintang $_selectedStarFilter'
                                    : 'Belum Ada Ulasan',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedStarFilter > 0
                                    ? 'Coba pilih filter bintang lainnya untuk melihat ulasan.'
                                    : 'Penjual ini belum memiliki ulasan dari pembeli.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredReviews.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildReviewCard(_filteredReviews[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating & Ulasan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15243C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Kiri: Angka Rating Besar + Bintang + Jumlah Ulasan
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _totalReviews > 0 ? _averageRating.toStringAsFixed(1) : '0.0',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15243C),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return Icon(
                        starVal <= _averageRating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 20,
                        color: starVal <= _averageRating.round()
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFCBD5E1),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalReviews ulasan',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Kolom Kanan: Horizontal Distribution Bars (5 to 1 star)
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = _starCounts[star] ?? 0;
                    final ratio = _totalReviews > 0 ? (count / _totalReviews) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarFilterChips() {
    final filters = [
      {'label': 'Semua ($_totalReviews)', 'value': 0},
      {'label': '5 ⭐ (${_starCounts[5] ?? 0})', 'value': 5},
      {'label': '4 ⭐ (${_starCounts[4] ?? 0})', 'value': 4},
      {'label': '3 ⭐ (${_starCounts[3] ?? 0})', 'value': 3},
      {'label': '2 ⭐ (${_starCounts[2] ?? 0})', 'value': 2},
      {'label': '1 ⭐ (${_starCounts[1] ?? 0})', 'value': 1},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final val = item['value'] as int;
          final isSelected = _selectedStarFilter == val;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedStarFilter = val;
              });
            },
            borderRadius: BorderRadius.circular(19),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2B5F9E) : Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final reviewerProfile = review['reviewer_profile'] as Map<String, dynamic>?;
    final rawName = reviewerProfile?['full_name']?.toString().trim();
    final reviewerName = (rawName != null && rawName.isNotEmpty) ? rawName : 'Pengguna Brawigo';
    final rawUsername = reviewerProfile?['username']?.toString().trim();
    final usernameText = (rawUsername != null && rawUsername.isNotEmpty)
        ? (rawUsername.startsWith('@') ? rawUsername : '@$rawUsername')
        : '';
    final faculty = reviewerProfile?['faculty']?.toString().trim() ?? '';
    final studyProgram = reviewerProfile?['study_program']?.toString().trim() ?? '';
    final studentInfo = [studyProgram, faculty].where((s) => s.isNotEmpty).join(' • ');
    final subtitleText = studentInfo.isNotEmpty ? studentInfo : 'Mahasiswa UB';
    final reviewerPhoto = reviewerProfile?['profile_photo_url']?.toString();
    final dateStr = _formatDate(review['created_at']?.toString());
    final ratingVal = (review['rating'] as num?)?.toDouble() ?? 5.0;

    final commentData = _parseCommentData(review['comment']?.toString());
    final commentText = commentData['text'] as String;
    final photos = commentData['photos'] as List<String>;

    final productData = review['product_data'] as Map<String, dynamic>?;
    final productName = productData?['product_name'] ?? 'Produk Brawigo';
    final productThumb = productData?['thumbnail_url']?.toString();

    return InkWell(
      onTap: () => _showReviewDetailModal(review),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Reviewer Avatar + Real Full Name + Username + Faculty + Date
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: (reviewerPhoto != null && reviewerPhoto.isNotEmpty)
                      ? NetworkImage(reviewerPhoto)
                      : null,
                  child: (reviewerPhoto == null || reviewerPhoto.isEmpty)
                      ? Text(
                          reviewerName.isNotEmpty ? reviewerName.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B5F9E)),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF15243C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (usernameText.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                usernameText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2B5F9E),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitleText,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tanda kutip besar (") persis Gambar 3
            const Text(
              '”',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF15243C),
                height: 0.8,
              ),
            ),
            const SizedBox(height: 4),

            // Gelembung Komentar Abu-abu + Thumbnail Foto Bukti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commentText,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                  ),
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () {
                              FullScreenImageViewer.open(context, images: photos, initialIndex: i);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    photos[i],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.fullscreen, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer: Real Product Thumbnail & Name + Rating Star
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: (productThumb != null && productThumb.isNotEmpty)
                              ? Image.network(
                                  productThumb,
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 26,
                                    height: 26,
                                    color: const Color(0xFFCBD5E1),
                                    child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                                  ),
                                )
                              : Container(
                                  width: 26,
                                  height: 26,
                                  color: const Color(0xFFCBD5E1),
                                  child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        ratingVal.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

