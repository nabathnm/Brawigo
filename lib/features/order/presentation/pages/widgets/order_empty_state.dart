import 'package:flutter/material.dart';

class OrderEmptyState extends StatelessWidget {
  final bool isSeller;

  const OrderEmptyState({super.key, required this.isSeller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSeller
                ? 'Belum ada pesanan masuk.'
                : 'Belum ada riwayat pesanan.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSeller
                ? 'Pesanan dari pembeli akan muncul di sini.'
                : 'Pesanan yang Anda buat akan muncul di sini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
