import 'package:flutter/material.dart';

class OrderDetailActions extends StatelessWidget {
  final bool isSeller;
  final String status;
  final String productName;
  final void Function(String status, String message) onUpdateStatus;
  final VoidCallback onCancelOrder;

  const OrderDetailActions({
    super.key,
    required this.isSeller,
    required this.status,
    required this.productName,
    required this.onUpdateStatus,
    required this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (isSeller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (normalized == 'created' || normalized == 'pending') ...[
            _primaryButton(
              label: 'Konfirmasi & Terima Pesanan',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF2B5F9E),
              onPressed: () => onUpdateStatus(
                'confirmed',
                "✅ Penjual telah mengonfirmasi pesanan '$productName'!",
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (normalized == 'confirmed') ...[
            _primaryButton(
              label: 'Selesaikan Pesanan',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF16A34A),
              onPressed: () => onUpdateStatus(
                'completed',
                "🎉 Pesanan '$productName' telah selesai!",
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (normalized != 'completed' && normalized != 'cancelled')
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text(
                  'Batalkan Pesanan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: onCancelOrder,
              ),
            ),
        ],
      );
    }

    if (normalized == 'confirmed') {
      return _primaryButton(
        label: 'Konfirmasi Barang Diterima (Selesai)',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        onPressed: () => onUpdateStatus(
          'completed',
          "📦 Pembeli telah mengonfirmasi bahwa barang '$productName' sudah diterima.",
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: Icon(icon),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
