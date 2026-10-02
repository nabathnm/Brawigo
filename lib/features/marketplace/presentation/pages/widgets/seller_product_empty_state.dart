import 'package:flutter/material.dart';

class SellerProductEmptyState extends StatelessWidget {
  const SellerProductEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 70,
            color: Colors.blueGrey.withAlpha(100),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada produk pada kategori ini.',
            style: TextStyle(color: Color(0xFF6A7A8A), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
