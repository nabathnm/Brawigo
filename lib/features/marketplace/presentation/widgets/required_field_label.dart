import 'package:flutter/material.dart';

class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({super.key, required this.text});

  final String text;

  static const _primaryColor = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
