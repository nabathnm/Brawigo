import 'package:flutter/material.dart';

import 'order_detail_status.dart';

class OrderDetailPaymentSection extends StatelessWidget {
  final String paymentMethod;
  final String? proofUrl;
  final ValueChanged<String> onShowProof;

  const OrderDetailPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.proofUrl,
    required this.onShowProof,
  });

  @override
  Widget build(BuildContext context) {
    final hasProof = proofUrl != null && proofUrl!.isNotEmpty;

    return CardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF15243C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentMethod,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2B5F9E),
                  ),
                ),
              ),
            ],
          ),
          if (hasProof) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            const Text(
              'Bukti Pembayaran (Screenshot Transfer/QRIS):',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onShowProof(proofUrl!),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      proofUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Text('Gagal memuat gambar bukti'),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Klik untuk perbesar',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              'Pembayaran tunai saat transaksi langsung (COD) atau belum mengunggah bukti.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }
}
