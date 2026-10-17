import 'package:flutter/material.dart';

class OrderStatusConfig {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const OrderStatusConfig({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  factory OrderStatusConfig.from(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'confirmed':
        return const OrderStatusConfig(
          label: 'Dikonfirmasi / Diproses',
          background: Color(0xFFE6EDF8),
          foreground: Color(0xFF2B5F9E),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'completed':
        return const OrderStatusConfig(
          label: 'Pesanan Selesai',
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF16A34A),
          icon: Icons.task_alt_rounded,
        );
      case 'cancelled':
        return const OrderStatusConfig(
          label: 'Pesanan Dibatalkan',
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFDC2626),
          icon: Icons.cancel_outlined,
        );
      default:
        return const OrderStatusConfig(
          label: 'Menunggu Konfirmasi',
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFD97706),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}

class OrderDetailStatusSection extends StatelessWidget {
  final String status;

  const OrderDetailStatusSection({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = OrderStatusConfig.from(status);
    return CardSection(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pesanan',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  config.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: config.foreground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, color: config.foreground, size: 22),
          ),
        ],
      ),
    );
  }
}

class CardSection extends StatelessWidget {
  final Widget child;

  const CardSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class OrderDetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const OrderDetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2B5F9E)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15243C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
