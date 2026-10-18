import 'package:flutter/material.dart';

class ProductFormDecoration {
  ProductFormDecoration._();

  static const primaryColor = Color(0xFF1E3A8A);

  static InputDecoration input({
    String? hintText,
    Widget? prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefix: prefix,
      suffix: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(primaryColor, width: 1.5),
      errorBorder: border(Colors.red, width: 1.5),
      focusedErrorBorder: border(Colors.red, width: 1.5),
    );
  }
}
