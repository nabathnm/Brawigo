import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart'; 

class CustomPasswordField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomPasswordField({
    super.key,
    required this.hintText,
    required this.controller,
    this.validator,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      style: const TextStyle(
        fontSize: BrawigoSizes.fontSizeSm,
        color: BrawigoColors.blue950,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
  
        hintStyle: const TextStyle(
          color: BrawigoColors.blue800,
          fontSize: BrawigoSizes.fontSizeSm,
        ),
      
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: BrawigoColors.blue800,
          size: BrawigoSizes.iconMd,
        ),

        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: BrawigoColors.blue800, 
            size: BrawigoSizes.iconMd,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
     
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BrawigoSizes.md,
          vertical: BrawigoSizes.md,
        ),
   
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
          borderSide: const BorderSide(color: BrawigoColors.blue800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
          borderSide: const BorderSide(color: BrawigoColors.blue800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
          borderSide: const BorderSide(
            color: BrawigoColors.blue800,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
