import 'package:flutter/material.dart';

import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

class MarketplaceSectionTitle extends StatelessWidget {
  final String title;

  const MarketplaceSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BrawigoColors.blue950,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: BrawigoColors.blue950,
            size: 22,
          ),
        ],
      ),
    );
  }
}
