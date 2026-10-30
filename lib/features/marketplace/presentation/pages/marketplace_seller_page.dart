import 'dart:convert';
import 'package:brawigo/core/utils/seller_profile_checker.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/header.dart';
import 'package:brawigo/features/marketplace/presentation/pages/product_detail_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/manage_products_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/seller_earnings_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/seller_reports_list_page.dart';
import 'package:brawigo/features/order/presentation/bloc/order_bloc.dart';
import 'package:brawigo/features/order/presentation/bloc/order_event.dart';
import 'package:brawigo/features/order/presentation/pages/order_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';

class MarketPlaceSellerPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const MarketPlaceSellerPage({super.key, this.onNavigateToProfile});

  @override
  State<MarketPlaceSellerPage> createState() => _MarketPlaceSellerPageState();
}

class _MarketPlaceSellerPageState extends State<MarketPlaceSellerPage> {
  final _supabase = Supabase.instance.client;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  SellerProfileStatus? _profileStatus;
  String _sellerName = 'Toko Saya';

  // Toggle sensor pendapatan
  bool _isBalanceVisible = true;

  // Real data metrics
  bool _isLoadingMetrics = true;
  num _currentMonthRevenue = 0;
  String _growthPercentageText = '+0,0%';
  int _newOrdersCount = 0;
  int _paymentVerificationCount = 0;
  int _violationReportsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _fetchSellerMetrics();
  }

  Future<void> _checkProfileStatus() async {
    final user = _supabase.auth.currentUser;
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

  num _parseAmount(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
      return num.tryParse(clean) ?? 0;
    }
    return 0;
  }

  Future<void> _fetchSellerMetrics() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingMetrics = false);
      return;
    }

    try {
      // 1. Ambil Nama Seller
      final profileRes = await _supabase
          .from('profiles')
          .select('full_name, username, bio')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes != null && mounted) {
        final u = profileRes['username']?.toString().trim();
        final f = profileRes['full_name']?.toString().trim();
        _sellerName = (u != null && u.isNotEmpty && u != '-') ? u : (f ?? 'Toko Saya');
      }

      // 2. Ambil Orders Seller
      final ordersRes = await _supabase
          .from('orders')
          .select()
          .eq('seller_id', user.id);

      final allOrders = List<Map<String, dynamic>>.from(ordersRes);

      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      final prevMonthDt = DateTime(now.year, now.month - 1);
      final prevYear = prevMonthDt.year;
      final prevMonth = prevMonthDt.month;

      num curRev = 0;
      num prevRev = 0;
      int newOrders = 0;
      int paymentVerify = 0;

      for (final order in allOrders) {
        final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase();
        final paymentStatus = (order['payment_status'] ?? '').toString().toLowerCase();
        final createdAtStr = order['created_at']?.toString();
        final dt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        final amount = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);

        // Pendapatan selesai
        if (status == 'completed' && dt != null) {
          if (dt.year == currentYear && dt.month == currentMonth) {
            curRev += amount;
          } else if (dt.year == prevYear && dt.month == prevMonth) {
            prevRev += amount;
          }
        }

        // Pesanan baru yang butuh konfirmasi
        if (status == 'created' || status == 'waiting_confirmation' || status == 'pending') {
          newOrders++;
        }

        // Verifikasi pembayaran
        if (paymentStatus == 'uploaded' || paymentStatus == 'waiting_verification') {
          paymentVerify++;
        }
      }

      // Hitung pertumbuhan % dari bulan lalu
      String growthText = '+0,0%';
      if (prevRev > 0) {
        final diff = ((curRev - prevRev) / prevRev) * 100;
        final sign = diff >= 0 ? '+' : '';
        growthText = '$sign${diff.toStringAsFixed(1).replaceAll('.', ',')}%';
      } else if (curRev > 0) {
        growthText = '+100%';
      }

      // 3. Ambil Jumlah Laporan Pelanggaran Masuk
      // Menggunakan 3 sumber dengan deduplikasi:
      // - Sumber 1: profiles.bio store_reports
      // - Sumber 2: product_reports table
      // - Sumber 3: Pesan laporan di conversations seller (selalu lolos RLS Supabase)
      int reportCount = 0;

      // Sumber 1: profiles.bio -> store_reports
      int bioReportCount = 0;
      if (profileRes != null && profileRes['bio'] != null) {
        final rawBio = profileRes['bio'].toString();
        if (rawBio.trim().startsWith('{')) {
          try {
            final parsed = jsonDecode(rawBio);
            if (parsed is Map && parsed['store_reports'] is List) {
              bioReportCount = (parsed['store_reports'] as List).length;
            }
            if (bioReportCount == 0 && parsed is Map && parsed['store_reports_count'] is int) {
              bioReportCount = parsed['store_reports_count'] as int;
            }
          } catch (_) {}
        }
      }

      // Sumber 2: product_reports table
      int dbReportCount = 0;
      try {
        final pRes = await _supabase.from('products').select('id').eq('seller_id', user.id);
        final pList = (pRes as List);
        if (pList.isNotEmpty) {
          final pIds = pList.map((p) => p['id'].toString()).toList();
          final prRes = await _supabase
              .from('product_reports')
              .select('id')
              .inFilter('product_id', pIds);
          dbReportCount = (prRes as List).length;
        }
      } catch (e) {
        debugPrint('Error fetching product_reports: $e');
      }

      // Sumber 3: Pesan laporan di conversations seller (karena RLS conversations mengizinkan seller membaca)
      int chatReportCount = 0;
      try {
        final convsRes = await _supabase
            .from('conversations')
            .select('id')
            .eq('seller_id', user.id);
        final convIds = (convsRes as List).map((c) => c['id'].toString()).toList();
        if (convIds.isNotEmpty) {
          final msgRes = await _supabase
              .from('messages')
              .select('id, message')
              .inFilter('conversation_id', convIds)
              ;
          final reportMsgs = (msgRes as List).where((m) => (m['message'] ?? '').toString().contains('[LAPORAN]')).toList();
          chatReportCount = reportMsgs.length;
        }
      } catch (e) {
        debugPrint('Error fetching chat reports: $e');
      }

      // Ambil nilai terbesar yang ditemukan dari sumber-sumber valid
      int maxFound = dbReportCount;
      if (bioReportCount > maxFound) maxFound = bioReportCount;
      if (chatReportCount > maxFound) maxFound = chatReportCount;
      reportCount = maxFound;

      debugPrint('[SellerHome] bioReportCount=$bioReportCount, dbReportCount=$dbReportCount, chatReportCount=$chatReportCount, final=$reportCount');

      if (mounted) {
        setState(() {
          _currentMonthRevenue = curRev;
          _growthPercentageText = growthText;
          _newOrdersCount = newOrders;
          _paymentVerificationCount = paymentVerify;
          _violationReportsCount = reportCount;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller metrics: $e');
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
  }

  void _navigateToOrderList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OrderBloc()..add(LoadSellerOrders()),
          child: const OrderListPage(isSeller: true),
        ),
      ),
    ).then((_) {
      _fetchSellerMetrics();
      if (mounted) {
        context.read<MarketplaceBloc>().add(LoadSellerProducts());
      }
    });
  }

  void _navigateToEarningsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerEarningsPage(),
      ),
    ).then((_) => _fetchSellerMetrics());
  }

  void _navigateToManageProductsPage() {
    final bloc = context.read<MarketplaceBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ManageProductsPage(
            onNavigateToProfile: widget.onNavigateToProfile,
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        bloc.add(LoadSellerProducts());
        _fetchSellerMetrics();
      }
    });
  }

  void _navigateToViolationReports() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerReportsListPage(
          sellerId: user.id,
          sellerName: _sellerName,
        ),
      ),
    ).then((_) => _fetchSellerMetrics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2B5F9E),
          onRefresh: () async {
            final bloc = context.read<MarketplaceBloc>();
            await Future.wait([
              _checkProfileStatus(),
              _fetchSellerMetrics(),
            ]);
            if (!mounted) return;
            bloc.add(LoadSellerProducts());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // 1. Header (Avatar, Nama, Switch Role 'Seller ⌄')
              Header(
                onRoleSwitch: () => context.go('/buyer'),
              ),

              // Banner kelengkapan profil jika belum selesai
              if (_profileStatus != null && !_profileStatus!.isComplete) ...[
                const SizedBox(height: 12),
                InkWell(
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
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pengaturan Toko Belum Lengkap",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                              ),
                              Text(
                                "Belum ada: ${_profileStatus!.missingFields.join(', ')}. Klik di sini untuk melengkapi profil.",
                                style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 14),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 2. Card: Pendapatan Bulan Ini (Sesuai Gambar 1)
              _buildEarningsCard(),
              const SizedBox(height: 14),

              // 3. Card: Ringkasan Toko (Sesuai Gambar 1)
              BlocBuilder<MarketplaceBloc, MarketplaceState>(
                builder: (context, state) {
                  int activeCount = 0;
                  int lowStockCount = 0;

                  if (state is MarketplaceLoaded) {
                    final products = state.products;
                    activeCount = products.where((p) {
                      final stock = (p['stock'] as num?)?.toInt() ?? 0;
                      final status = p['status'] as String? ?? 'active';
                      return stock > 0 && status != 'archived';
                    }).length;

                    // Ketentuan user: stok menipis apabila stoknya itu kurang dari sama dengan 3
                    lowStockCount = products.where((p) {
                      final stock = (p['stock'] as num?)?.toInt() ?? 0;
                      return stock <= 3;
                    }).length;
                  }

                  return _buildStoreSummaryCard(
                    newOrders: _newOrdersCount,
                    activeProducts: activeCount,
                    lowStock: lowStockCount,
                  );
                },
              ),
              const SizedBox(height: 18),

              // 4. Section: Perlu Perhatian (Sesuai Gambar 1 + Laporan Pelanggaran)
              _buildAttentionSection(),
              const SizedBox(height: 20),

              // 5. Section: Produk Kamu (Sesuai Gambar 1 + Link panah ke Kelola Produk Gambar 2)
              _buildProductsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // CARD 1: PENDAPATAN BULAN INI (Gambar 1)
  // =========================================================================
  Widget _buildEarningsCard() {
    final displayAmount = _isLoadingMetrics
        ? 'Memuat...'
        : _isBalanceVisible
            ? _currencyFormat.format(_currentMonthRevenue)
            : 'Rp •••••••••';

    return InkWell(
      onTap: _navigateToEarningsPage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A7EBB), Color(0xFF244C80)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF244C80).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Label + Pertumbuhan + Tombol Chevron Lingkaran Putih
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pendapatan Bulan ini",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$_growthPercentageText dari bulan lalu",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // Tombol Panah Lingkaran Putih
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF244C80),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Container: Nominal Pendapatan + Toggle Sensor Mata
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayAmount,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD 2: RINGKASAN TOKO (Gambar 1)
  // =========================================================================
  Widget _buildStoreSummaryCard({
    required int newOrders,
    required int activeProducts,
    required int lowStock,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3DFE8)),
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
            "Ringkasan Toko",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 1. Pesanan Baru (Kuning/Orange)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$newOrders",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15243C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pesanan baru",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 12),

              // 2. Produk Aktif (Biru)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B5F9E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$activeProducts",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15243C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Produk aktif",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 12),

              // 3. Stok Menipis (Merah - Ketentuan: stok <= 3)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$lowStock",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15243C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Stok menipis",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 3: PERLU PERHATIAN (Gambar 1 + Laporan Pelanggaran)
  // =========================================================================
  Widget _buildAttentionSection() {
    final int totalTasks = _newOrdersCount + _paymentVerificationCount + _violationReportsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Perlu perhatian",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15243C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Tugas yang membutuhkan respons kamu",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                "$totalTasks",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B5F9E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kontainer Utama Item Perlu Perhatian
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD3DFE8)),
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
              // 1. Konfirmasi Pesanan Baru
              _buildAttentionItem(
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                title: "Konfirmasi pesanan baru",
                subtitle: "$_newOrdersCount pembeli sedang menunggu respons",
                actionText: "Tinjau pesanan",
                onTap: _navigateToOrderList,
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 2. Verifikasi Pembayaran
              _buildAttentionItem(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                title: "Verifikasi pembayaran",
                subtitle: "$_paymentVerificationCount bukti pembayaran telah diunggah",
                actionText: "Periksa bukti",
                onTap: _navigateToOrderList,
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 3. Laporan Pelanggaran (Permintaan Khusus User)
              _buildAttentionItem(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: "Laporan pelanggaran",
                subtitle: "$_violationReportsCount laporan masuk",
                actionText: "Lihat laporan",
                onTap: _navigateToViolationReports,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5F9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION 4: PRODUK KAMU (Gambar 1)
  // =========================================================================
  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section dengan tombol panah (chevron >) ke Kelola Produk
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Produk kamu",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15243C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Produk terbaru dan stok menipis",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            // Tombol panah di samping Produk Kamu sesuai permintaan
            InkWell(
              onTap: _navigateToManageProductsPage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD3DFE8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2B5F9E),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Preview Produk
        BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            if (state is MarketplaceLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                ),
              );
            } else if (state is MarketplaceLoaded) {
              final products = state.products;
              if (products.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD3DFE8)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      const Text(
                        "Belum ada produk",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tambahkan produk untuk mulai berjualan.",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              }

              // Ambil maksimal 4 produk untuk preview
              final previewList = products.take(4).toList();

              return Column(
                children: previewList.map((product) {
                  return _buildProductPreviewCard(product);
                }).toList(),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildProductPreviewCard(Map<String, dynamic> product) {
    final String name = product['product_name'] as String? ?? 'Tanpa Nama';
    final String? imageUrl = product['thumbnail_url'] as String?;
    final int stock = (product['stock'] as num?)?.toInt() ?? 0;
    final String status = product['status'] as String? ?? 'active';
    final String categoryName = product['category_name'] as String? ?? 'Alat Elektronik';
    final dynamic priceVal = product['price'] ?? 0;
    final num priceNum = (priceVal is num) ? priceVal : (_parseAmount(priceVal));

    // Badge status (Aktif, Arsip, Habis) sesuai Gambar 1
    String badgeText = 'Aktif';
    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeColor = const Color(0xFF16A34A);

    if (stock <= 0) {
      badgeText = 'Habis';
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
    } else if (status == 'archived') {
      badgeText = 'Arsip';
      badgeBg = const Color(0xFFDBEAFE);
      badgeColor = const Color(0xFF2563EB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3DFE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final bloc = context.read<MarketplaceBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: ProductDetailPage(product: product),
                ),
              ),
            ).then((_) {
              if (mounted) {
                bloc.add(LoadSellerProducts());
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15243C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currencyFormat.format(priceNum),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B5F9E),
                            ),
                          ),
                          Text(
                            "Stok: $stock",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF94A3B8),
        size: 28,
      ),
    );
  }
}
