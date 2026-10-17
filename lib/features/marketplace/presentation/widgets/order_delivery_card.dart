import 'package:flutter/material.dart';
import '../../domain/models/order_detail.dart';
import '../../domain/utils/order_detail_formatter.dart';
import 'order_detail_components.dart';

class OrderDeliveryCard extends StatelessWidget {
  const OrderDeliveryCard({super.key, required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) => OrderDetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            orderSectionTitle('Lokasi & Pengiriman'),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            OrderInfoRow(icon: Icons.location_on_outlined, label: 'Lokasi / Alamat', value: order.meetupLocation),
            if (order.meetupTime.isNotEmpty && order.meetupTime != '-') ...[
              const SizedBox(height: 10),
              OrderInfoRow(icon: Icons.access_time_rounded, label: 'Waktu Bertemu', value: order.meetupTime),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              OrderInfoRow(icon: Icons.notes_rounded, label: 'Catatan Pembeli', value: order.notes!),
            ],
            const SizedBox(height: 10),
            OrderInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Waktu Transaksi',
              value: OrderDetailFormatter.date(order.createdAt),
            ),
          ],
        ),
      );
}
