import 'package:flutter/material.dart';

class AddProductTextField {
  const AddProductTextField._();

  static Widget label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w600,
          fontSize: 16,
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

  static InputDecoration decoration({
    String? hintText,
    Widget? prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefix: prefix,
      suffix: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(const Color(0xFF1E3A8A), width: 1.5),
      errorBorder: border(Colors.red, width: 1.5),
      focusedErrorBorder: border(Colors.red, width: 1.5),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
