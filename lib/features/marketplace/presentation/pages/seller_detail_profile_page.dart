import 'seller_reports_list_page.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/brawigo_toast.dart';
import 'seller_reviews_page.dart';
import 'package:brawigo/features/marketplace/data/services/seller_reports_service.dart';

class SellerDetailProfilePage extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic>? initialProfile;
  final int? productCount;

  const SellerDetailProfilePage({
    super.key,
    required this.sellerId,
    this.initialProfile,
    this.productCount,
  });

  @override
  State<SellerDetailProfilePage> createState() => _SellerDetailProfilePageState();
}

class _SellerDetailProfilePageState extends State<SellerDetailProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  int _productCount = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  int _reportCount = 0;
  final Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchSellerDetails();
  }

  Future<void> _fetchSellerDetails() async {
    try {
      // 1. Fetch Profile
      final profileRes = widget.initialProfile ??
          await _supabase
              .from('profiles')
              .select()
              .eq('id', widget.sellerId)
              .maybeSingle();

      // 2. Fetch Products Count & Products
      final productsRes = await _supabase
          .from('products')
          .select('id, product_name, thumbnail_url, price')
          .eq('seller_id', widget.sellerId);

      final pCount = (productsRes as List).length;
      final productMap = <String, Map<String, dynamic>>{};
      for (final p in productsRes) {
        productMap[p['id'].toString()] = Map<String, dynamic>.from(p);
      }

      // 3. Fetch Reviews
      final List<String> productIds = productsRes.map((p) => p['id'].toString()).toList();
      final List<Map<String, dynamic>> loadedReviews = [];
      if (productIds.isNotEmpty) {
        final reviewsRes = await _supabase
            .from('reviews')
            .select()
            .inFilter('product_id', productIds)
            .order('created_at', ascending: false);

        // Fetch Reviewer Profiles
        final reviewerIds = reviewsRes
            .map((r) => r['reviewer_id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        final reviewerProfileMap = <String, Map<String, dynamic>>{};
        if (reviewerIds.isNotEmpty) {
          try {
            final revsRes = await _supabase
                .from('profiles')
                .select('id, full_name, username, faculty, study_program, profile_photo_url')
                .inFilter('id', reviewerIds);
            for (final r in revsRes) {
              reviewerProfileMap[r['id'].toString()] = Map<String, dynamic>.from(r);
            }
          } catch (e) {
            debugPrint('Error fetching reviewer profiles in seller detail: $e');
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

      int rCount = 0;
      try {
        final reports = await SellerReportsService.fetchReports(widget.sellerId);
        rCount = reports.length;
      } catch (e) {
        debugPrint('Error fetching reports in seller_detail_profile_page: $e');
      }

      if (mounted) {
        setState(() {
          _profile = profileRes;
          _productCount = widget.productCount ?? pCount;
          _reviews = loadedReviews;
          _reportCount = rCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatJoinDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Maret 2024';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return 'Maret 2024';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = _profile?['full_name'] ?? 'Penjual';
    final faculty = _profile?['faculty'] ?? 'Filkom';
    final studyProgram = _profile?['study_program'] ?? 'Teknik Informatika';
    final email = _profile?['email'] ?? 'penjual@ub.ac.id';
    final photoUrl = _profile?['profile_photo_url']?.toString();
    final phone = _profile?['phone_number']?.toString() ?? '+6282187954225';
    final joinDate = _formatJoinDate(_profile?['created_at']?.toString());

    // Bio / Description & Tautan Toko
    String storeDescription = 'tidak ada deskripsi';
    String storeLink = 'Tidak tersedia';
    final rawBio = _profile?['bio']?.toString() ?? '';
    try {
      if (rawBio.trim().startsWith('{')) {
        final parsed = jsonDecode(rawBio);
        if (parsed is Map) {
          final desc = parsed['store_description']?.toString().trim();
          if (desc != null && desc.isNotEmpty) {
            storeDescription = desc;
          }
          final link = parsed['store_link']?.toString().trim();
          if (link != null && link.isNotEmpty) {
            storeLink = link;
          }
        }
      } else if (rawBio.trim().isNotEmpty) {
        storeDescription = rawBio.trim();
      }
    } catch (_) {}

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
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Card Banner Biru Penjual (Gambar 2)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B5F9E), Color(0xFF4A84C8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B5F9E).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sellerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$studyProgram · $faculty',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Card Container Rating & Ulasan (Bisa di-tap menuju Gambar 3)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerReviewsPage(
                              sellerId: widget.sellerId,
                              sellerProfile: _profile,
                              initialReviews: _reviews,
                              initialAverageRating: _averageRating,
                              initialTotalReviews: _totalReviews,
                              initialStarCounts: _starCounts,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Rating & Ulasan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15243C),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 22),
                              ],
                            ),
                            const SizedBox(height: 14),
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
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF15243C),
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(5, (index) {
                                        final starVal = index + 1;
                                        return Icon(
                                          starVal <= _averageRating.round()
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 18,
                                          color: starVal <= _averageRating.round()
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFCBD5E1),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_totalReviews ulasan',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),

                                // Kolom Kanan: Horizontal Distribution Bars (5 to 1 star)
                                Expanded(
                                  child: Column(
                                    children: [5, 4, 3, 2, 1].map((star) {
                                      final count = _starCounts[star] ?? 0;
                                      final ratio = _totalReviews > 0 ? (count / _totalReviews) : 0.0;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$star',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: ratio,
                                                  backgroundColor: const Color(0xFFF1F5F9),
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                                  minHeight: 5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              width: 18,
                                              child: Text(
                                                '$count',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Card Info Tambahan Toko (Gambar 2: Performa Chat Dihapus)
                    Container(
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
                        children: [
                          _buildDetailRow(
                            icon: Icons.inventory_2_outlined,
                            label: 'Produk',
                            value: '$_productCount',
                            iconColor: const Color(0xFF2B5F9E),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Bergabung',
                            value: joinDate,
                            iconColor: const Color(0xFF0D9488),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            icon: Icons.description_outlined,
                            label: 'Keterangan',
                            value: storeDescription,
                            iconColor: const Color(0xFF6366F1),
                            isMultiLine: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Card Tautan & Kontak (Gambar 2)
                    Container(
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
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Tautan Toko', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              ),
                              InkWell(
                                onTap: storeLink != 'Tidak tersedia'
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: storeLink));
                                        BrawigoToast.showSuccess(context, title: 'Tersalin', message: 'Tautan toko berhasil disalin ke clipboard');
                                      }
                                    : null,
                                child: Text(
                                  storeLink,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: storeLink != 'Tidak tersedia' ? const Color(0xFF2B5F9E) : const Color(0xFF94A3B8),
                                    fontWeight: storeLink != 'Tidak tersedia' ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2B5F9E)),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Kontak', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              ),
                              Text(
                                phone,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. Card Laporan Pelanggaran (Menampilkan Jumlah Laporan Saja & Bisa Ditekan ke Halaman List Laporan)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerReportsListPage(
                              sellerId: widget.sellerId,
                              sellerName: sellerName,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _reportCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _reportCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _reportCount > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
                                size: 20,
                                color: _reportCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Laporan Pelanggaran',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_reportCount Laporan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _reportCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), fontWeight: FontWeight.w600),
            textAlign: isMultiLine ? TextAlign.start : TextAlign.end,
          ),
        ),
      ],
    );
  }
}

