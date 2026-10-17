import 'package:flutter/material.dart';

class OrderPageBackground extends StatelessWidget {
  final Widget child;

  const OrderPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC8DAEF),
            Color(0xFFE6EDF8),
            Color(0xFFFAFAFA),
          ],
          stops: [0.0, 0.2, 1.0],
        ),
      ),
      child: child,
    );
  }
}
