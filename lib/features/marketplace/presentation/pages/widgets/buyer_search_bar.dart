import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerSearchBar extends StatelessWidget {
  const BuyerSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          readOnly: true,
          onTap: () {
            context.push('/buyer-search');
          },
          decoration: const InputDecoration(
            hintText: 'Cari produk',
            hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Color(0xFFA0AEC0),
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
