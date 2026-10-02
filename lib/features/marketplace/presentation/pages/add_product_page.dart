import 'package:brawigo/brawigo.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_event.dart';
import '../bloc/marketplace_state.dart';
import '../data/category_repository.dart';
import 'widgets/add_product_form.dart';
import 'widgets/add_product_loading.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _imagePicker = ImagePicker();

  final _categoryRepository = CategoryRepository();
  List<Map<String, dynamic>> _categories = [];
  List<XFile> _selectedImages = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _nameController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      _showMessage('Gagal memuat kategori: $error', isError: true);
    }
  }

  Future<void> _pickImages() async {
    if (_isPickingImages || _selectedImages.length >= 10) return;
    setState(() => _isPickingImages = true);

    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (!mounted || picked.isEmpty) return;

      final remaining = 10 - _selectedImages.length;
      setState(() {
        _selectedImages = [..._selectedImages, ...picked.take(remaining)];
      });

      if (picked.length > remaining) {
        _showMessage('Maksimal 10 foto. Foto yang melebihi batas diabaikan.');
      }
    } catch (error) {
      if (mounted) _showMessage('Gagal memilih foto: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _showMessage('Harap unggah minimal 1 foto produk!', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      _showMessage('Harap pilih kategori produk!', isError: true);
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    if (price == null || price <= 0) {
      _showMessage('Masukkan harga yang valid.', isError: true);
      return;
    }
    if (stock == null || stock < 0) {
      _showMessage('Masukkan stok yang valid.', isError: true);
      return;
    }

    context.read<MarketplaceBloc>().add(
      AddProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        categoryId: _selectedCategoryId!,
        images: List<XFile>.unmodifiable(_selectedImages),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.orange,
        ),
      );
  }

  void _onMarketplaceState(BuildContext context, MarketplaceState state) {
    if (state is MarketplaceError) {
      _showMessage(state.message, isError: true);
    } else if (state is MarketplaceLoaded) {
      // Pertahankan perilaku kode awal. Sebaiknya ganti dengan state sukses
      // khusus AddProduct agar state Loaded dari proses lain tidak dianggap sukses.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refresh)
      ..dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8DAEF), Color(0xFFE6EDF8), Color(0xFFFAFAFA)],
          stops: [0.0, 0.2, 1.0],
        ),
      ),
      child: BlocListener<MarketplaceBloc, MarketplaceState>(
        listener: _onMarketplaceState,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  overlayColor: Colors.transparent,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.05),
                  minimumSize: const Size(42, 42),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Produk',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Isi data produk baru',
                  style: TextStyle(color: BrawigoColors.blue800, fontSize: 16),
                ),
              ],
            ),
          ),
          body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              if (state is MarketplaceLoading) {
                return const AddProductLoading();
              }
              return AddProductForm(
                formKey: _formKey,
                nameController: _nameController,
                descriptionController: _descriptionController,
                priceController: _priceController,
                stockController: _stockController,
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategoryChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                selectedImages: _selectedImages,
                isLoadingCategories: _isLoadingCategories,
                isPickingImages: _isPickingImages,
                onPickImages: _pickImages,
                onRemoveImage: _removeImage,
                onSubmit: _submit,
              );
            },
          ),
        ),
      ),
    );
  }
}
