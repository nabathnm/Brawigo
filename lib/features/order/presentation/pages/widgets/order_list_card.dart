import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'order_status_badge.dart';

class OrderListCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const OrderListCard({super.key, required this.order, required this.onTap});

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      return DateFormat(
        'd MMM yyyy, HH:mm',
        'id_ID',
      ).format(DateTime.parse(value).toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = order['thumbnail_url_snapshot']?.toString();
    final productName =
        order['product_name_snapshot']?.toString() ?? 'Produk Brawigo';
    final totalAmount =
        (order['total_amount'] as num?) ??
        (order['product_price_snapshot'] as num?) ??
        0;
    final paymentMethod = order['payment_method']?.toString() ?? 'COD';
    final status = (order['order_status'] ?? order['status'] ?? 'created')
        .toString();
    final orderDate = _formatDate(order['created_at']?.toString());
    final location = order['meetup_location']?.toString() ?? '-';
    final hasProof =
        order['payment_proof_url'] != null &&
        order['payment_proof_url'].toString().isNotEmpty;

    return InkWell(
      onTap: onTap,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    orderDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusBadge(status: status),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
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
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15243C),
                        ),
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _smallTag(
                            paymentMethod,
                            const Color(0xFFF1F5F9),
                            const Color(0xFF475569),
                          ),
                          if (hasProof)
                            _smallTag(
                              'Bukti Uploaded',
                              const Color(0xFFDCFCE7),
                              const Color(0xFF16A34A),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
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
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF94A3B8),
        size: 28,
      ),
    );
  }

  Widget _smallTag(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}
