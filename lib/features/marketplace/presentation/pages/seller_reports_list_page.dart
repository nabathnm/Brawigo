import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/full_screen_image_viewer.dart';
import 'package:brawigo/features/marketplace/data/services/seller_reports_service.dart';

class SellerReportsListPage extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerReportsListPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerReportsListPage> createState() => _SellerReportsListPageState();
}

class _SellerReportsListPageState extends State<SellerReportsListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await SellerReportsService.fetchReports(widget.sellerId);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Baru saja';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dt)} WIB";
    } catch (_) {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF3FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF15243C),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Pelanggaran',
          style: TextStyle(
            color: Color(0xFF15243C),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)))
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFF2B5F9E),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _reports.isEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _reports.isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _reports.isEmpty ? Icons.verified_user_rounded : Icons.report_problem_rounded,
                            color: _reports.isEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _reports.isEmpty ? 'Toko Beroperasi Baik' : '${_reports.length} Laporan Masuk',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF15243C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _reports.isEmpty
                                    ? 'Tidak ada riwayat pelanggaran untuk ${widget.sellerName}.'
                                    : 'Laporan ini ditinjau secara berkala oleh tim moderator Brawigo.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_reports.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F1FC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 36,
                              color: Color(0xFF2B5F9E),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum Ada Laporan Pelanggaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Toko ini tidak memiliki catatan laporan dari pembeli. Seluruh transaksi berlangsung aman.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Daftar Riwayat Laporan (${_reports.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A60),
                        ),
                      ),
                    ),
                    ..._reports.map((rep) {
                      final reason = rep['reason'] ?? 'Pelanggaran';
                      final desc = rep['description'] ?? '-';
                      final date = _formatDate(rep['created_at']);
                      final status = rep['status'] ?? 'Menunggu Tindakan';
                      final List images = (rep['images'] as List?) ?? [];
                      final productName = rep['product_name'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 6),
                                    Text(
                                      reason,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15243C),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (productName != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    productName.toString(),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                            ),
                            if (images.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 60,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                                  itemBuilder: (ctx, i) {
                                    final imgUrl = images[i].toString();
                                    return GestureDetector(
                                      onTap: () {
                                        FullScreenImageViewer.open(
                                          context,
                                          images: images.map((e) => e.toString()).toList(),
                                          initialIndex: i,
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imgUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(Icons.broken_image, size: 18, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              date,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}

