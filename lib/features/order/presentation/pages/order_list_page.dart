import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrawigoColors.blue50,
      appBar: AppBar(
        title: Text(widget.isSeller ? 'Pesanan Masuk (Seller)' : 'Daftar Pesanan Saya', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: BrawigoColors.blue700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator(color: BrawigoColors.blue700));
          } else if (state is OrderError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state is OrdersLoaded) {
            final orders = state.orders;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 70, color: Colors.blueGrey.withAlpha(100)),
                    const SizedBox(height: 12),
                    const Text(
                      "Belum ada pesanan.",
                      style: TextStyle(color: Color(0xFF6A7A8A), fontSize: 15),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final String? thumbnailUrl = order['thumbnail_url_snapshot'] as String?;
                final String productName = order['product_name_snapshot'] ?? 'Produk';
                final String totalAmount = order['total_amount']?.toString() ?? '0';
                final String paymentMethod = order['payment_method']?.toString().toUpperCase() ?? 'COD';
                final String meetupLocation = order['meetup_location'] ?? '-';
                final String orderStatus = order['order_status']?.toString().toUpperCase() ?? 'CREATED';

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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    thumbnailUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: BrawigoColors.blue100,
                                    child: const Icon(Icons.shopping_bag_outlined, color: BrawigoColors.blue700),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: BrawigoColors.blue950,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: BrawigoColors.blue100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        orderStatus,
                                        style: const TextStyle(
                                          color: BrawigoColors.blue700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rp $totalAmount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BrawigoColors.blue600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.payment, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      paymentMethod,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        meetupLocation,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                );
              },
            );
          }
          return const Center(child: Text('Memuat data pesanan...'));
        },
      ),
    );
  }
}
