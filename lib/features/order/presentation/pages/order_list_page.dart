import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  final bool isSeller;
  const OrderListPage({super.key, this.isSeller = false});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Perlu Diproses, 2: Dikonfirmasi, 3: Selesai, 4: Dibatalkan
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    if (widget.isSeller) {
      context.read<OrderBloc>().add(LoadSellerOrders());
    } else {
      context.read<OrderBloc>().add(LoadBuyerOrders());
    }
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> allOrders) {
    if (_selectedFilterIndex == 0) return allOrders;
    return allOrders.where((order) {
      final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase();
      if (_selectedFilterIndex == 1) {
        return status == 'created' || status == 'pending';
      } else if (_selectedFilterIndex == 2) {
        return status == 'confirmed';
      } else if (_selectedFilterIndex == 3) {
        return status == 'completed';
      } else if (_selectedFilterIndex == 4) {
        return status == 'cancelled';
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> _getStatusConfig(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'confirmed') {
      return {
        'label': 'Dikonfirmasi',
        'bg': const Color(0xFFE6EDF8),
        'text': const Color(0xFF2B5F9E),
        'icon': Icons.check_circle_outline_rounded,
      };
    } else if (status == 'completed') {
      return {
        'label': 'Selesai',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF16A34A),
        'icon': Icons.task_alt_rounded,
      };
    } else if (status == 'cancelled') {
      return {
        'label': 'Dibatalkan',
        'bg': const Color(0xFFFEE2E2),
        'text': const Color(0xFFDC2626),
        'icon': Icons.cancel_outlined,
      };
    } else {
      return {
        'label': 'Perlu Diproses',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFFD97706),
        'icon': Icons.hourglass_top_rounded,
      };
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF15243C),
        title: Text(
          widget.isSeller ? 'Pesanan Masuk (Seller)' : 'Daftar Pesanan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF15243C),
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2B5F9E)),
            onPressed: _loadOrders,
            tooltip: 'Refresh Pesanan',
          ),
        ],
      ),
      body: Container(
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
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
              );
            } else if (state is OrderError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5F9E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _loadOrders,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is OrdersLoaded) {
              final allOrders = state.orders;
              final filteredOrders = _filterOrders(allOrders);

              final int countAll = allOrders.length;
              final int countPending = allOrders.where((o) {
                final s = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
                return s == 'created' || s == 'pending';
              }).length;
              final int countConfirmed = allOrders.where((o) => (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase() == 'confirmed').length;
              final int countCompleted = allOrders.where((o) => (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase() == 'completed').length;
              final int countCancelled = allOrders.where((o) => (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase() == 'cancelled').length;

              final filterTabs = [
                'Semua ($countAll)',
                'Perlu Diproses ($countPending)',
                'Dikonfirmasi ($countConfirmed)',
                'Selesai ($countCompleted)',
                'Dibatalkan ($countCancelled)',
              ];

              return Column(
                children: [
                  // Filter Pills (Horizontal)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: filterTabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2B5F9E) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2B5F9E).withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                filterTabs[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Orders List
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  widget.isSeller ? 'Belum ada pesanan masuk.' : 'Belum ada riwayat pesanan.',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.isSeller
                                      ? 'Pesanan dari pembeli akan muncul di sini.'
                                      : 'Pesanan yang Anda buat akan muncul di sini.',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadOrders(),
                            color: const Color(0xFF2B5F9E),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filteredOrders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final String? thumbnailUrl = order['thumbnail_url_snapshot'] as String?;
                                final String productName = order['product_name_snapshot'] ?? 'Produk Brawigo';
                                final num totalAmount = (order['total_amount'] as num?) ?? (order['product_price_snapshot'] as num?) ?? 0;
                                final String paymentMethod = order['payment_method']?.toString() ?? 'COD';
                                final String rawStatus = (order['order_status'] ?? order['status'] ?? 'created').toString();
                                final statusCfg = _getStatusConfig(rawStatus);
                                final String orderDate = _formatDate(order['created_at']?.toString());
                                final String location = order['meetup_location'] ?? '-';
                                final bool hasProof = order['payment_proof_url'] != null && order['payment_proof_url'].toString().isNotEmpty;

                                return InkWell(
                                  onTap: () async {
                                    final orderBloc = context.read<OrderBloc>();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider.value(
                                          value: orderBloc,
                                          child: OrderDetailPage(orderId: order['id']),
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      _loadOrders();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
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
                                        // Header row: Date and Status Badge
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              orderDate,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusCfg['bg'] as Color,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(statusCfg['icon'] as IconData, size: 12, color: statusCfg['text'] as Color),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    statusCfg['label'] as String,
                                                    style: TextStyle(
                                                      color: statusCfg['text'] as Color,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16, color: Color(0xFFF1F5F9)),

                                        // Body row: Image + Info
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                                  ? Image.network(
                                                      thumbnailUrl,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                                    )
                                                  : _buildPlaceholder(),
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
                                                    _currencyFormat.format(totalAmount),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF2B5F9E),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          paymentMethod,
                                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                        ),
                                                      ),
                                                      if (hasProof) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFDCFCE7),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Text(
                                                            'Bukti Uploaded',
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Footer note / location
                                        if (location.isNotEmpty && location != '-') ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    location,
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
            return const Center(child: Text('Memuat data pesanan...'));
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }
}
