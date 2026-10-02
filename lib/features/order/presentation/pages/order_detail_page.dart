import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final data = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      if (mounted) {
        setState(() {
          _order = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrawigoColors.blue50,
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: BrawigoColors.blue700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Berhasil'), backgroundColor: BrawigoColors.greenNormal),
            );
            _fetchOrderDetail(); // Refresh
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading || state is OrderLoading) {
            return const Center(child: CircularProgressIndicator(color: BrawigoColors.blue700));
          }

          if (_errorMessage != null || _order == null) {
            return Center(
              child: Text(
                _errorMessage ?? 'Pesanan tidak ditemukan.',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final order = _order!;
          final productName = order['product_name_snapshot'] ?? 'Produk';
          final totalAmount = order['total_amount']?.toString() ?? '0';
          final paymentMethod = order['payment_method']?.toString().toUpperCase() ?? 'COD';
          final orderStatus = order['order_status']?.toString().toUpperCase() ?? 'CREATED';
          final paymentStatus = order['payment_status']?.toString().toUpperCase() ?? 'PENDING';
          final meetupLocation = order['meetup_location'] ?? '-';
          final meetupTime = order['meetup_time'] ?? '-';
          final quantity = order['quantity']?.toString() ?? '1';

          final currentUserId = _supabase.auth.currentUser?.id;
          final isSeller = currentUserId == order['seller_id'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Pesanan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(orderStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrawigoColors.blue950)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BrawigoColors.blue100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(paymentStatus, style: const TextStyle(color: BrawigoColors.blue700, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Product & Payment Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrawigoColors.blue950)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                          Text('x$quantity', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(color: Colors.grey)),
                          Text('Rp $totalAmount', style: const TextStyle(fontWeight: FontWeight.bold, color: BrawigoColors.blue600, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Metode Pembayaran', style: TextStyle(color: Colors.grey)),
                          Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Meetup Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Meetup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrawigoColors.blue950)),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: BrawigoColors.blue600),
                          const SizedBox(width: 8),
                          Expanded(child: Text(meetupLocation, style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: BrawigoColors.blue600),
                          const SizedBox(width: 8),
                          Expanded(child: Text(meetupTime, style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seller Action Buttons
                if (isSeller) ...[
                  const Text('Aksi Penjual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrawigoColors.blue950)),
                  const SizedBox(height: 12),
                  if (orderStatus == 'CREATED' || orderStatus == 'PENDING')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrawigoColors.blue700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Konfirmasi & Terima Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<OrderBloc>().add(UpdateOrderStatus(orderId: widget.orderId, status: 'confirmed'));
                      },
                    ),
                  const SizedBox(height: 8),
                  if (orderStatus != 'COMPLETED' && orderStatus != 'CANCELLED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrawigoColors.greenNormal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Selesaikan Pesanan (Completed)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<OrderBloc>().add(UpdateOrderStatus(orderId: widget.orderId, status: 'completed'));
                      },
                    ),
                  const SizedBox(height: 8),
                  if (orderStatus != 'CANCELLED' && orderStatus != 'COMPLETED')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<OrderBloc>().add(UpdateOrderStatus(orderId: widget.orderId, status: 'cancelled'));
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
