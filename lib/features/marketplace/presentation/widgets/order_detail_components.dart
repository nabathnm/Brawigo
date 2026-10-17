import 'package:flutter/material.dart';

const orderNavy = Color(0xFF15243C);
const orderBlue = Color(0xFF2B5F9E);
const orderMuted = Color(0xFF64748B);
const orderBorder = Color(0xFFE2E8F0);

class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: orderBorder),
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

class OrderInfoRow extends StatelessWidget {
  const OrderInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: orderBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: orderMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: orderNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

Widget orderSectionTitle(String title) => Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: orderNavy,
      ),
    );

Widget orderPlaceholder() => Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF94A3B8),
        size: 28,
      ),
    );
