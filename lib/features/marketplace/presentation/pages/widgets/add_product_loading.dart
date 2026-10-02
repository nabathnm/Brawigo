import 'package:flutter/material.dart';

class AddProductLoading extends StatelessWidget {
  const AddProductLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            SizedBox(height: 16),
            Text('Menyimpan produk dan mengunggah gambar...'),
          ],
        ),
      );
}
