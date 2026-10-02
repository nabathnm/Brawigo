import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'add_product_image_picker.dart';
import 'add_product_text_field.dart';

class AddProductForm extends StatelessWidget {
  const AddProductForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.stockController,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedImages,
    required this.isLoadingCategories,
    required this.isPickingImages,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final List<XFile> selectedImages;
  final bool isLoadingCategories;
  final bool isPickingImages;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AddProductTextField.label('Nama Produk'),
            TextFormField(
              controller: nameController,
              maxLength: 100,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              decoration: AddProductTextField.decoration(hintText: 'Magic Com'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama produk tidak boleh kosong'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${nameController.text.length}/100',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AddProductTextField.label('Foto Produk'),
            AddProductImagePicker(
              images: selectedImages,
              isPicking: isPickingImages,
              onPick: onPickImages,
              onRemove: onRemoveImage,
            ),
            const SizedBox(height: 16),
            AddProductTextField.label('Harga'),
            TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: AddProductTextField.decoration(
                hintText: '12.000',
                prefix: const Text(
                  'Rp ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                return price == null || price <= 0
                    ? 'Masukkan harga yang valid'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            AddProductTextField.label('Stok'),
            TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: AddProductTextField.decoration(hintText: '0'),
              validator: (value) {
                final stock = int.tryParse(value?.trim() ?? '');
                return stock == null || stock < 0
                    ? 'Masukkan angka stok yang valid (minimal 0)'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            AddProductTextField.label('Kategori'),
            if (isLoadingCategories)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  decoration: AddProductTextField.decoration(
                    hintText: 'Pilih kategori produk',
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black87,
                  ),
                  initialValue: selectedCategoryId,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'] as String,
                      child: Text(category['name'] as String),
                    );
                  }).toList(),
                  onChanged: onCategoryChanged,
                  validator: (value) =>
                      value == null ? 'Pilih kategori produk' : null,
                ),
              ),
            const SizedBox(height: 16),
            AddProductTextField.label('Deskripsi'),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: AddProductTextField.decoration(
                hintText: 'Jelaskan produk secara detail..',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                if (value.trim().length < 20) {
                  return 'Deskripsi minimal 20 karakter';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Min. 20 karakter',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: onSubmit,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
