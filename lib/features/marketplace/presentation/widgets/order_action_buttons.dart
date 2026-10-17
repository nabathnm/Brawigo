import 'package:flutter/material.dart';

class OrderActionButtons extends StatelessWidget {
  const OrderActionButtons({
    super.key,
    required this.status,
    required this.isSeller,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
  });

  final String status;
  final bool isSeller;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final children = <Widget>[];

    if (isSeller) {
      if (normalized == 'created' || normalized == 'pending') {
        children.add(_primaryButton(
          icon: Icons.check_circle_outline_rounded,
          label: 'Konfirmasi & Terima Pesanan',
          color: const Color(0xFF2B5F9E),
          onPressed: onConfirm,
        ));
        children.add(const SizedBox(height: 10));
      }
      if (normalized == 'confirmed') {
        children.add(_primaryButton(
          icon: Icons.task_alt_rounded,
          label: 'Selesaikan Pesanan',
          color: const Color(0xFF16A34A),
          onPressed: onComplete,
        ));
        children.add(const SizedBox(height: 10));
      }
      if (normalized != 'completed' && normalized != 'cancelled') {
        children.add(SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: onCancel,
          ),
        ));
      }
    } else if (normalized == 'confirmed') {
      children.add(_primaryButton(
        icon: Icons.check_circle_rounded,
        label: 'Konfirmasi Barang Diterima (Selesai)',
        color: const Color(0xFF16A34A),
        onPressed: onComplete,
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: onPressed,
        ),
      );
}
