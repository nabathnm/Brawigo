import 'package:flutter/material.dart';

import 'product_form_decoration.dart';
import 'required_field_label.dart';

class ProductCategoryField extends StatelessWidget {
  const ProductCategoryField({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequiredFieldLabel(text: 'Kategori'),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              isExpanded: true,
              decoration: ProductFormDecoration.input(
                hintText: 'Pilih kategori produk',
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'] as String,
                  child: Text(category['name'] as String),
                );
              }).toList(),
              onChanged: onChanged,
              validator: (value) {
                if (value == null) {
                  return 'Pilih kategori produk';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }
}
