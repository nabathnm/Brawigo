import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/avatar.png'),
              ),
            ),
            const SizedBox(width: 7),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Selamat Datang,",
                  style: TextStyle(
                    fontSize: 16,
                    color: BrawigoColors.primary950,
                  ),
                ),
                Text(
                  "John Doe",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrawigoColors.primary950,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: BrawigoColors.primary200),
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Text(
                "Seller",
                style: TextStyle(color: BrawigoColors.primary950, fontSize: 14),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF334A60),
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
