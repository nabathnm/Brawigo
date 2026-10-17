import 'package:flutter/material.dart';
import 'order_detail_components.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return OrderDetailCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Pesanan', style: TextStyle(color: orderMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                config.label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: config.text),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, color: config.text, size: 22),
          ),
        ],
      ),
    );
  }

  _StatusConfig _config(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return const _StatusConfig('Dikonfirmasi / Diproses', Color(0xFFE6EDF8), Color(0xFF2B5F9E), Icons.check_circle_outline_rounded);
      case 'completed':
        return const _StatusConfig('Pesanan Selesai', Color(0xFFDCFCE7), Color(0xFF16A34A), Icons.task_alt_rounded);
      case 'cancelled':
        return const _StatusConfig('Pesanan Dibatalkan', Color(0xFFFEE2E2), Color(0xFFDC2626), Icons.cancel_outlined);
      default:
        return const _StatusConfig('Menunggu Konfirmasi', Color(0xFFFEF3C7), Color(0xFFD97706), Icons.hourglass_top_rounded);
    }
  }
}

class _StatusConfig {
  const _StatusConfig(this.label, this.background, this.text, this.icon);
  final String label;
  final Color background;
  final Color text;
  final IconData icon;
}
