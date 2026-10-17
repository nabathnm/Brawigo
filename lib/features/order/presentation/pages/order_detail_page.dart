import 'package:brawigo/features/marketplace/data/repositories/order_detail_repository.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_detail_content.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_detail_feedback.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_detail_page_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late final OrderDetailRepository _repository;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = OrderDetailRepository();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final order = await _repository.fetchOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
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
    await _repository.sendChatUpdate(order: order, message: message);
  }

  Future<void> _updateStatus(String status, String message) async {
    context.read<OrderBloc>().add(
      UpdateOrderStatus(orderId: widget.orderId, status: status),
    );
    await _sendChatUpdate(message);
  }

  Future<void> _confirmCancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batalkan Pesanan?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final productName = _order?['product_name_snapshot'] ?? 'produk';
    await _updateStatus(
      'cancelled',
      "❌ Pesanan '$productName' telah dibatalkan.",
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF15243C),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF15243C),
            fontSize: 18,
          ),
        ),
      ),
      body: OrderDetailPageBackground(
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
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
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
              return OrderDetailErrorView(
                message: _errorMessage ?? 'Pesanan tidak ditemukan.',
                onRetry: _fetchOrderDetail,
              );
            }

            final order = _order!;
            final currentUserId = _repository.currentUserId;
            final isSeller = currentUserId == order['seller_id'];

            return OrderDetailContent(
              order: order,
              isSeller: isSeller,
              onShowProof: _showProofDialog,
              onUpdateStatus: (status, message) =>
                  _updateStatus(status, message),
              onCancelOrder: _confirmCancelOrder,
            );
          },
        ),
      ),
    );
  }
}
