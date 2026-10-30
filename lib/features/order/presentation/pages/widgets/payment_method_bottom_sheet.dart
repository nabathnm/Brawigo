import 'package:brawigo/features/order/presentation/pages/models/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  const PaymentMethodBottomSheet({super.key});

  @override
  State<PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  PaymentMethod? paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pilih Metode Pengambilan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BrawigoColors.blue700,
            ),
          ),

          const SizedBox(height: 12),

          ...paymentMethods.map(
            (method) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MethodButton(
                method: method,
                isSelected: paymentMethod == method,
                onTap: () {
                  setState(() {
                    paymentMethod = method;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Button pilih metode
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: paymentMethod == null
                  ? null
                  : () {
                      Navigator.pop(context, paymentMethod);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrawigoColors.blue800,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pilih Metode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? BrawigoColors.blue100 : Colors.white,
          border: Border.all(color: Color(0xff20395A).withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BrawigoColors.blue800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: BrawigoColors.blue600,
                    ),
                  ),
                ],
              ),
            ),

            // Check di kanan
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? BrawigoColors.blue700 : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? BrawigoColors.blue700
                      : const Color(0xff20395A).withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
