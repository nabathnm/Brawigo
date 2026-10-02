import 'package:flutter/material.dart';

class DeleteProductDialog {
  const DeleteProductDialog._();

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> product,
    required ValueChanged<String> onConfirm,
  }) async {
    final productId = product['id']?.toString();

    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID produk tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productName = product['product_name'] as String? ?? 'Produk';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Apakah Anda yakin ingin menghapus "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm(productId);
    }
  }
}
