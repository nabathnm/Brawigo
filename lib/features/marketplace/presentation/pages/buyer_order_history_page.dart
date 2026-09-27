import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BuyerOrderHistoryPage extends StatefulWidget {
  const BuyerOrderHistoryPage({super.key});

  @override
  State<BuyerOrderHistoryPage> createState() => _BuyerOrderHistoryPageState();
}

class _BuyerOrderHistoryPageState extends State<BuyerOrderHistoryPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? isoTime) {
    if (isoTime == null) return '';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(isoTime).toLocal());
    } catch (_) {
      return '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'selesai':
        return const Color(0xFF16A34A);
      case 'pending':
      case 'created':
        return const Color(0xFFD97706);
      case 'cancelled':
      case 'batal':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2B5F9E);
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15243C),
                  ),
                ),
              ),

              // Filter & Urutkan Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _buildChip(Icons.filter_list_rounded, 'Filter'),
                    const SizedBox(width: 10),
                    _buildChip(Icons.import_export_rounded, 'Urutkan'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Order List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 72, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  "Belum ada riwayat transaksi",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                final productName = order['product_name_snapshot'] ?? 'Produk';
                                final price = order['total_amount'] != null
                                    ? _currencyFormat.format(order['total_amount'])
                                    : (order['product_price_snapshot'] != null
                                        ? _currencyFormat.format(order['product_price_snapshot'])
                                        : 'Rp 0');
                                final thumbnailUrl = order['thumbnail_url_snapshot'] ?? '';
                                final qty = order['quantity'] ?? 1;
                                final status = order['order_status'] ?? order['status'] ?? 'pending';
                                final timeStr = _formatDate(order['created_at']);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Status & Date Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            timeStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 18),
                                      // Product Row
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: thumbnailUrl.isNotEmpty
                                                ? Image.network(
                                                    thumbnailUrl,
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                                                  )
                                                : _placeholderImage(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15243C),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$qty barang',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Total Belanja',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                price,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF2B5F9E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
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

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF15243C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 24),
    );
  }
}
