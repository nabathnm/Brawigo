import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                Image.asset("assets/icons/marketplace/receipt.png"),
                SizedBox(width: 8),
                Text(
                  "Ringkasan Pesanan",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(
              height: 1,
              color: const Color(0xff20395A).withValues(alpha: 0.25),
            ),
            SizedBox(height: 6),

            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  "Harga Produk",
                  style: TextStyle(
                    color: BrawigoColors.blue800.withValues(alpha: 0.5),
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Rp200.000",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),

            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  "Jumlah",
                  style: TextStyle(
                    color: BrawigoColors.blue800.withValues(alpha: 0.5),
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "1x",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),

            Divider(
              height: 1,
              color: const Color(0xff20395A).withValues(alpha: 0.25),
            ),
            SizedBox(height: 12),

            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  "Subtotal",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Rp200.000",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
