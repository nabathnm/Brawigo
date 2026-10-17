import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brawigo/features/order/presentation/bloc/order_bloc.dart';
import 'package:brawigo/features/order/presentation/bloc/order_event.dart';
import 'package:brawigo/features/order/presentation/bloc/order_state.dart';
import '../../data/repositories/order_detail_repository.dart';
import '../../domain/models/order_detail.dart';
import '../widgets/order_action_buttons.dart';
import '../widgets/order_delivery_card.dart';
import '../widgets/order_payment_card.dart';
import '../widgets/order_product_card.dart';
import '../widgets/order_status_card.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    this.orderId = 'ID20346-218',
    this.paymentMethod,
    this.productTitle,
    this.price,
    this.buyerName,
  });

  final String orderId;
  final String? paymentMethod;
  final String? productTitle;
  final String? price;
  final String? buyerName;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderDetailRepository _repository;
  OrderDetail? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = OrderDetailRepository(client: Supabase.instance.client);
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.fetchOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = OrderDetail(data);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendChatUpdate(String message) async {
    final order = _order;
    if (order == null) return;
    try {
      await _repository.sendChatUpdate(order: order.data, message: message);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diperbarui, tetapi pesan chat gagal dikirim: $error')),
      );
    }
  }

  Future<void> _updateStatus(String status, String message) async {
    context.read<OrderBloc>().add(
          UpdateOrderStatus(orderId: widget.orderId, status: status),
        );
    await _sendChatUpdate(message);
  }

  void _confirmCancelOrder() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              final productName = _order?.productName ?? 'produk';
              _updateStatus('cancelled', "❌ Pesanan '$productName' telah dibatalkan.");
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showProofDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF15243C),
          title: const Text(
            'Detail Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C), fontSize: 18),
          ),
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
          child: BlocConsumer<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message ?? 'Berhasil diperbarui'),
                    backgroundColor: Colors.green,
                  ),
                );
                _fetchOrderDetail();
              } else if (state is OrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (_isLoading || (state is OrderLoading && _order == null)) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                );
              }

              if (_errorMessage != null || _order == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Pesanan tidak ditemukan.',
                          style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5F9E)),
                          onPressed: _fetchOrderDetail,
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final order = _order!;
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
              final isSeller = currentUserId == order.sellerId;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OrderStatusCard(status: order.status),
                    const SizedBox(height: 14),
                    OrderProductCard(order: order),
                    const SizedBox(height: 14),
                    OrderDeliveryCard(order: order),
                    const SizedBox(height: 14),
                    OrderPaymentCard(order: order, onProofTap: _showProofDialog),
                    const SizedBox(height: 24),
                    OrderActionButtons(
                      status: order.status,
                      isSeller: isSeller,
                      onConfirm: () => _updateStatus(
                        'confirmed',
                        "✅ Penjual telah mengonfirmasi pesanan '${order.productName}'!",
                      ),
                      onComplete: () {
                        final message = isSeller
                            ? "🎉 Pesanan '${order.productName}' telah selesai!"
                            : "📦 Pembeli telah mengonfirmasi bahwa barang '${order.productName}' sudah diterima.";
                        _updateStatus('completed', message);
                      },
                      onCancel: _confirmCancelOrder,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}
