import 'package:flutter/material.dart';
import '../../domain/models/order_detail.dart';
import '../../domain/utils/order_detail_formatter.dart';
import 'order_detail_components.dart';

class OrderProductCard extends StatelessWidget {
  const OrderProductCard({super.key, required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) => OrderDetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            orderSectionTitle('Informasi Produk'),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: order.thumbnailUrl != null && order.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          order.thumbnailUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => orderPlaceholder(),
                        )
                      : orderPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: orderNavy),
                      ),
                      const SizedBox(height: 4),
                      Text('Jumlah: ${order.quantity} item', style: const TextStyle(color: orderMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        OrderDetailFormatter.currency.format(order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: orderBlue, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
