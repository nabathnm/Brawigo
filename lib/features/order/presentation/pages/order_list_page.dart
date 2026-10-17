import 'package:brawigo/features/order/presentation/pages/widgets/order_empty_state.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_filter_tabs.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_list_card.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_page_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final bloc = context.read<OrderBloc>();
    bloc.add(widget.isSeller ? LoadSellerOrders() : LoadBuyerOrders());
  }

  void _openOrderDetail(Map<String, dynamic> order) async {
    final orderBloc = context.read<OrderBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: orderBloc,
          child: OrderDetailPage(orderId: order['id']),
        ),
      ),
    );

    if (mounted) _loadOrders();
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
      body: const OrderPageBackground(child: _OrderListBody()),
    );
  }
}

class _OrderListBody extends StatefulWidget {
  const _OrderListBody();

  @override
  State<_OrderListBody> createState() => _OrderListBodyState();
}

class _OrderListBodyState extends State<_OrderListBody> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final page = context.findAncestorStateOfType<_OrderListPageState>();

    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
          );
        }

        if (state is OrderError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF15243C),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5F9E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: page?._loadOrders,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is OrdersLoaded) {
          final orders = state.orders;
          final counts = OrderFilterTabs.countStatuses(orders);
          final filteredOrders = OrderFilterTabs.filterOrders(
            orders,
            _selectedFilterIndex,
          );

          return Column(
            children: [
              OrderFilterTabs(
                counts: counts,
                selectedIndex: _selectedFilterIndex,
                onSelected: (index) =>
                    setState(() => _selectedFilterIndex = index),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredOrders.isEmpty
                    ? OrderEmptyState(isSeller: page?.widget.isSeller ?? false)
                    : RefreshIndicator(
                        onRefresh: () async => page?._loadOrders(),
                        color: const Color(0xFF2B5F9E),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => OrderListCard(
                            order: filteredOrders[index],
                            onTap: () =>
                                page?._openOrderDetail(filteredOrders[index]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        }

        return const Center(child: Text('Memuat data pesanan...'));
      },
    );
  }
}
