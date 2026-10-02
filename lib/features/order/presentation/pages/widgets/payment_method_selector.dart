import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import '../models/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final VoidCallback onTap;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0Xffffffff),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset("assets/icons/marketplace/balance.png"),
                SizedBox(width: 8),
                Text(
                  "Pembayaran",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selectedMethod != null
                    ? BrawigoColors.blue100
                    : Colors.white,
                border: Border.all(
                  color: selectedMethod != null
                      ? const Color(0xff20395A).withValues(alpha: 0.3)
                      : Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: selectedMethod == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Metode',
                          style: TextStyle(
                            fontWeight: .w600,
                            fontSize: 14,
                            color: const Color(
                              0xff20395A,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedMethod!.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BrawigoColors.blue800,
                          ),
                        ),
                        Text(
                          selectedMethod!.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: BrawigoColors.blue600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
