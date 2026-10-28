import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerEarningsPage extends StatefulWidget {
  const SellerEarningsPage({super.key});

  @override
  State<SellerEarningsPage> createState() => _SellerEarningsPageState();
}

class _SellerEarningsPageState extends State<SellerEarningsPage> {
  final _supabase = Supabase.instance.client;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  List<Map<String, dynamic>> _completedOrders = [];
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('orders')
          .select()
          .eq('seller_id', user.id)
          .eq('order_status', 'completed')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _completedOrders = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller earnings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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

  List<Map<String, dynamic>> get _ordersForSelectedMonth {
    return _completedOrders.where((order) {
      final createdAtStr = order['created_at']?.toString();
      if (createdAtStr == null) return false;
      final dt = DateTime.tryParse(createdAtStr);
      if (dt == null) return false;
      return dt.year == _selectedMonth.year && dt.month == _selectedMonth.month;
    }).toList();
  }

  num get _totalRevenue {
    num total = 0;
    for (final order in _ordersForSelectedMonth) {
      total += _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
    }
    return total;
  }

  int get _totalItemsSold {
    int total = 0;
    for (final order in _ordersForSelectedMonth) {
      final qty = (order['quantity'] as num?)?.toInt() ?? 1;
      total += qty;
    }
    return total;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthOrders = _ordersForSelectedMonth;

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
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Center(
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF15243C),
                  ),
                ),
              ),
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Rekap Pendapatan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
              Text(
                "Laporan Penjualan Toko",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2B5F9E)),
              onPressed: _fetchEarningsData,
              tooltip: 'Perbarui Data',
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2B5F9E),
                  onRefresh: _fetchEarningsData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      // Month Selector Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD3DFE8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF2B5F9E)),
                              onPressed: _previousMonth,
                              tooltip: 'Bulan Sebelumnya',
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2B5F9E)),
                                const SizedBox(width: 8),
                                Text(
                                  _formatMonthYear(_selectedMonth),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15243C),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2B5F9E)),
                              onPressed: _nextMonth,
                              tooltip: 'Bulan Berikutnya',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Main Revenue Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Pendapatan ${_formatMonthYear(_selectedMonth)}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Selesai",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currencyFormat.format(_totalRevenue),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pesanan Selesai",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${currentMonthOrders.length} transaksi",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 32, color: Colors.white24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Barang Terjual",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$_totalItemsSold unit",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Title: Barang Terjual Bulan Ini
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Barang Terjual",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15243C),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Rincian barang yang terjual di bulan ini",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${currentMonthOrders.length} item",
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

                      // List of sold items
                      if (currentMonthOrders.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 28,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Belum Ada Barang Terjual",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15243C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tidak ada transaksi yang selesai pada ${_formatMonthYear(_selectedMonth)}.",
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...currentMonthOrders.map((order) {
                          final name = order['product_name_snapshot'] ?? 'Produk Brawigo';
                          final num totalAmount = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
                          final int qty = (order['quantity'] as num?)?.toInt() ?? 1;
                          final String? thumb = order['thumbnail_url_snapshot'] as String?;
                          final String dateStr = _formatDate(order['created_at']?.toString());
                          final String paymentMethod = order['payment_method']?.toString() ?? 'Transfer Bank';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: (thumb != null && thumb.isNotEmpty)
                                        ? Image.network(
                                            thumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: const Color(0xFFF1F5F9),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Terjual",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            "$qty unit terjual",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text("•", style: TextStyle(color: Color(0xFF94A3B8))),
                                          const SizedBox(width: 8),
                                          Text(
                                            paymentMethod,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _currencyFormat.format(totalAmount),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2B5F9E),
                                            ),
                                          ),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
