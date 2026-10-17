import 'package:flutter/material.dart';

class OrderStatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const OrderStatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  factory OrderStatusConfig.fromStatus(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'confirmed':
        return const OrderStatusConfig(
          label: 'Dikonfirmasi',
          backgroundColor: Color(0xFFE6EDF8),
          textColor: Color(0xFF2B5F9E),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'completed':
        return const OrderStatusConfig(
          label: 'Selesai',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
          icon: Icons.task_alt_rounded,
        );
      case 'cancelled':
        return const OrderStatusConfig(
          label: 'Dibatalkan',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFDC2626),
          icon: Icons.cancel_outlined,
        );
      default:
        return const OrderStatusConfig(
          label: 'Perlu Diproses',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFD97706),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = OrderStatusConfig.fromStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
