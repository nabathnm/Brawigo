import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/category_repository.dart';
import '../widgets/product_category_field.dart';
import '../widgets/product_form_decoration.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/product_submit_button.dart';
import '../widgets/required_field_label.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  final _picker = ImagePicker();
  final _categoryRepository = CategoryRepository();

  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _categories = [];

  String? _selectedCategory;

  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_refreshForm);
    _fetchCategories();
  }

  void _refreshForm() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryRepository.fetchCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat kategori: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      debugPrint('[IMAGE PICKER] Membuka pemilih gambar');

      final image = await _picker.pickImage(source: ImageSource.gallery);

      debugPrint('[IMAGE PICKER] Hasil: ${image?.name ?? "NULL"}');

      if (!mounted || image == null) return;

      setState(() {
        _selectedImages.add(image);
      });
    } catch (error, stackTrace) {
      debugPrint('[IMAGE PICKER] Error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _removeImage(int index) {
    if (_isSubmitting) return;

    if (index < 0 || index >= _selectedImages.length) {
      return;
    }

    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitForm() {
    if (_isSubmitting || _hasPopped) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (_selectedImages.isEmpty) {
      _showError('Harap unggah minimal 1 foto produk!');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Harap pilih kategori produk!');
      return;
    }

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (price == null || price <= 0) {
      _showError('Harga harus lebih besar dari 0.');
      return;
    }

    if (stock == null || stock < 0) {
      _showError('Stok tidak boleh negatif.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<MarketplaceBloc>().add(
      AddProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: _selectedCategory!,
        images: List<XFile>.of(_selectedImages),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleMarketplaceState(BuildContext context, MarketplaceState state) {
    if (state is MarketplaceError) {
      if (_isSubmitting) {
        setState(() {
          _isSubmitting = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
      return;
    }

    if (state is MarketplaceLoaded && _isSubmitting && !_hasPopped) {
      _hasPopped = true;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }

  void _handleBackPressed() {
    if (_hasPopped || _isSubmitting) return;

    _hasPopped = true;
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshForm);

    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarketplaceBloc, MarketplaceState>(
      listener: _handleMarketplaceState,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: InkWell(
              onTap: _handleBackPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1E3A8A),
                  size: 18,
                ),
              ),
            ),
          ),
          leadingWidth: 64,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Produk',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Isi data produk baru',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            final isLoading = state is MarketplaceLoading || _isSubmitting;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AbsorbPointer(
                    absorbing: isLoading,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 16),

                          ProductImagePicker(
                            images: _selectedImages,
                            onPick: _pickImages,
                            onRemove: _removeImage,
                          ),
                          const SizedBox(height: 16),

                          _buildPriceField(),
                          const SizedBox(height: 16),

                          _buildStockField(),
                          const SizedBox(height: 16),

                          ProductCategoryField(
                            categories: _categories,
                            isLoading: _isLoadingCategories,
                            selectedCategory: _selectedCategory,
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildDescriptionField(),
                          const SizedBox(height: 32),

                          ProductSubmitButton(
                            isSubmitting: _isSubmitting,
                            onPressed: _submitForm,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                if (isLoading) _buildLoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequiredFieldLabel(text: 'Nama Produk'),
        TextFormField(
          controller: _nameController,
          maxLength: 100,
          decoration: ProductFormDecoration.input(
            hintText: 'Contoh: Nama Produk',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama produk tidak boleh kosong';
            }

            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_nameController.text.length}/100',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequiredFieldLabel(text: 'Harga'),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: ProductFormDecoration.input(
            hintText: '0',
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

            if (price == null || price <= 0) {
              return 'Masukkan harga yang valid';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequiredFieldLabel(text: 'Stok'),
        TextFormField(
          controller: _stockController,
          keyboardType: TextInputType.number,
          decoration: ProductFormDecoration.input(hintText: '0'),
          validator: (value) {
            final stock = int.tryParse(value?.trim() ?? '');

            if (stock == null || stock < 0) {
              return 'Masukkan stok minimal 0';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RequiredFieldLabel(text: 'Deskripsi'),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          decoration: ProductFormDecoration.input(
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
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            SizedBox(height: 16),
            Text(
              'Menyimpan produk dan mengunggah gambar...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
