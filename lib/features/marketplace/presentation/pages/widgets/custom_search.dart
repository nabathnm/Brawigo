import 'package:flutter/material.dart';

class CustomSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;

  const CustomSearch({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFilterPressed,
    this.hintText = 'Cari ..',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF8C9AA8),
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset(
                    "assets/images/icon/find.png",
                    width: 24,
                    height: 24,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        Container(
          width: 46,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onFilterPressed ?? () {},
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Image.asset(
                "assets/images/icon/filter.png",
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF15243C),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
