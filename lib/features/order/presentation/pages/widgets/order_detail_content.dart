import 'package:brawigo/features/order/presentation/pages/widgets/order_review_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'order_detail_actions.dart';
import 'order_detail_payment_section.dart';
import 'order_detail_status.dart';

class OrderDetailContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isSeller;
  final ValueChanged<String> onShowProof;
  final void Function(String status, String message) onUpdateStatus;
  final VoidCallback onCancelOrder;

  const OrderDetailContent({
    super.key,
    required this.order,
    required this.isSeller,
    required this.onShowProof,
    required this.onUpdateStatus,
    required this.onCancelOrder,
  });

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return '${DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID').format(DateTime.parse(iso).toLocal())} WIB';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName =
        order['product_name_snapshot']?.toString() ?? 'Produk Brawigo';
    final totalAmount =
        (order['total_amount'] as num?) ??
        (order['product_price_snapshot'] as num?) ??
        0;
    final paymentMethod = order['payment_method']?.toString() ?? 'COD';
    final status = (order['order_status'] ?? order['status'] ?? 'created')
        .toString();
    final proofUrl = order['payment_proof_url']?.toString();
    final location = order['meetup_location']?.toString() ?? '-';
    final meetupTime = order['meetup_time']?.toString() ?? '-';
    final quantity = order['quantity']?.toString() ?? '1';
    final notes = order['notes']?.toString();
    final createdAt = _formatDate(order['created_at']?.toString());
    final thumbnailUrl = order['thumbnail_url_snapshot']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailStatusSection(status: status),
          const SizedBox(height: 14),
          _productSection(
            context: context,
            productName: productName,
            quantity: quantity,
            totalAmount: totalAmount,
            thumbnailUrl: thumbnailUrl,
          ),
          const SizedBox(height: 14),
          _locationSection(
            location: location,
            meetupTime: meetupTime,
            notes: notes,
            createdAt: createdAt,
          ),
          const SizedBox(height: 14),
          OrderDetailPaymentSection(
            paymentMethod: paymentMethod,
            proofUrl: proofUrl,
            onShowProof: onShowProof,
          ),
          const SizedBox(height: 24),
          OrderDetailActions(
            isSeller: isSeller,
            status: status,
            productName: productName,
            onUpdateStatus: onUpdateStatus,
            onCancelOrder: onCancelOrder,
          ),
          const SizedBox(height: 20),

          OrderReviewButton(
            orderId: order['id']?.toString() ?? '',
            orderStatus: order['order_status']?.toString(),
          ),
        ],
      ),
    );
  }

  Widget _productSection({
    required BuildContext context,
    required String productName,
    required String quantity,
    required num totalAmount,
    required String? thumbnailUrl,
  }) {
    return _section(
      title: 'Informasi Produk',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productImage(thumbnailUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF15243C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jumlah: $quantity item',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currency.format(totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B5F9E),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(String? url) {
    Widget placeholder() => Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF94A3B8),
        size: 28,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder(),
            )
          : placeholder(),
    );
  }

  Widget _locationSection({
    required String location,
    required String meetupTime,
    required String? notes,
    required String createdAt,
  }) {
    return _section(
      title: 'Lokasi & Pengiriman',
      child: Column(
        children: [
          OrderDetailInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Lokasi / Alamat',
            value: location,
          ),
          if (meetupTime.isNotEmpty && meetupTime != '-') ...[
            const SizedBox(height: 10),
            OrderDetailInfoRow(
              icon: Icons.access_time_rounded,
              label: 'Waktu Bertemu',
              value: meetupTime,
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            OrderDetailInfoRow(
              icon: Icons.notes_rounded,
              label: 'Catatan Pembeli',
              value: notes,
            ),
          ],
          const SizedBox(height: 10),
          OrderDetailInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Waktu Transaksi',
            value: createdAt,
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return CardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF15243C),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }
}
