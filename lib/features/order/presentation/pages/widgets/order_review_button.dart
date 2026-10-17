import 'package:flutter/material.dart';

import '../review_page.dart';

class OrderReviewButton extends StatelessWidget {
  const OrderReviewButton({
    super.key,
    required this.orderId,
    required this.orderStatus,
  });

  final String orderId;
  final String? orderStatus;

  @override
  Widget build(BuildContext context) {
    if (orderStatus?.trim().toLowerCase() != 'completed') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => ReviewPage(orderId: orderId)),
          );
        },
        icon: const Icon(Icons.star_outline),
        label: const Text('Beri Review'),
      ),
    );
  }
}
