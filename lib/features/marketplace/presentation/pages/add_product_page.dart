import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_event.dart';
import '../bloc/marketplace_state.dart';

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

  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _nameController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      if (_selectedImages.length + images.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maksimal 10 foto yang diperbolehkan! Foto lainnya akan diabaikan.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          final spaceLeft = 10 - _selectedImages.length;
          _selectedImages.addAll(images.take(spaceLeft));
        });
      } else {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap unggah minimal 1 foto produk!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih kategori produk!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 1;
      // Memicu event AddProduct ke MarketplaceBloc
      context.read<MarketplaceBloc>().add(
        AddProduct(
          name: name,
          description: desc,
          price: price,
          stock: stock,
          categoryId: _selectedCategory!,
          images: _selectedImages,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Helper widget for Label + *
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
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

  InputDecoration _buildInputDecoration({
    String? hintText,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),

      prefix: prefix,

      suffix: suffix,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarketplaceBloc, MarketplaceState>(
      listener: (context, state) {
        if (state is MarketplaceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is MarketplaceLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
          leadingWidth: 64, // Padding + Icon Width
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tambah Produk",
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "Isi data produk baru",
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            if (state is MarketplaceLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                    SizedBox(height: 16),
                    Text('Menyimpan produk dan mengunggah gambar...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Nama Produk ---
                    _buildLabel("Nama Produk"),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 100,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null, // Hide default counter
                      decoration: _buildInputDecoration(
                        hintText: 'Contoh: John Doe',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama produk tidak boleh kosong'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${_nameController.text.length}/100',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Foto Produk ---
                    _buildLabel("Foto Produk"),
                    GestureDetector(
                      onTap: _selectedImages.length < 10 ? _pickImage : null,
                      child: DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          color: Colors.grey.shade400,
                          strokeWidth: 1.5,
                          dashPattern: const [6, 4],
                          radius: const Radius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 140),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImages.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Color(0xFF1E3A8A),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Ketuk untuk unggah foto",
                                      style: TextStyle(
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Maks. 10 foto · JPG, PNG · max 5 MB",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            _selectedImages.length +
                                            (_selectedImages.length < 10
                                                ? 1
                                                : 0),
                                        itemBuilder: (context, index) {
                                          if (index == _selectedImages.length) {
                                            // Tombol Tambah
                                            return GestureDetector(
                                              onTap: _pickImage,
                                              child: Container(
                                                width: 80,
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.camera_alt,
                                                      color: Color(0xFF1E3A8A),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "Tambah",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF1E3A8A,
                                                        ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          final image = _selectedImages[index];
                                          return Stack(
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: kIsWeb
                                                      ? Image.network(
                                                          image.path,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Image.file(
                                                          File(image.path),
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 12,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedImages.removeAt(
                                                        index,
                                                      );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Maks. 10 foto · JPG, PNG · max 5 MB",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Harga ---
                    _buildLabel("Harga"),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
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
                    ),

                    const SizedBox(height: 16),

                    // --- Stok ---
                    _buildLabel("Stok"),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(hintText: '0'),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Stok tidak boleh kosong';
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Masukkan angka stok yang valid (minimal 0)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Kategori ---
                    _buildLabel("Kategori"),
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(
                                hintText: 'Pilih kategori produk',
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black87,
                              ),
                              initialValue: _selectedCategory,
                              items: _categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat['id'] as String,
                                  child: Text(cat['name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value),
                              validator: (value) => value == null
                                  ? 'Pilih kategori produk'
                                  : null,
                            ),
                          ),
                    const SizedBox(height: 16),

                    // --- Deskripsi ---
                    _buildLabel("Deskripsi"),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: _buildInputDecoration(
                        hintText: 'Jelaskan produk secara detail..',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Deskripsi tidak boleh kosong';
                        if (value.trim().length < 20)
                          return 'Deskripsi minimal 20 karakter';
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Min. 20 karakter',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 32),

                    // --- Tombol Submit ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              Colors.transparent, // Required for gradient
                          shadowColor:
                              Colors.transparent, // Disable default shadow
                        ),
                        onPressed: _submitForm,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF1E3A8A),
                              ], // light to dark blue
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
          },
        ),
      ),
    );
  }
}
