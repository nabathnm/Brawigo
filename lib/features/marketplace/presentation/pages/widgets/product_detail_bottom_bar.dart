import 'package:flutter/material.dart';

class ProductDetailBottomBar extends StatelessWidget {
  const ProductDetailBottomBar({
    super.key,
    required this.isOwnProduct,
    required this.onChat,
    required this.onCheckout,
  });

  final bool isOwnProduct;
  final VoidCallback onChat;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOwnProduct
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF2B5F9E),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isOwnProduct
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF2B5F9E),
                    size: 22,
                  ),
                  onPressed: onChat,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwnProduct
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF4A7EBB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    isOwnProduct ? 'Produk Anda Sendiri' : 'Checkout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isOwnProduct
                          ? const Color(0xFF64748B)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
