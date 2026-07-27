import 'dart:io';
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
  final _pickupLocationController = TextEditingController();

  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String _selectedCondition = 'new';
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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
      if (images.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maksimal 10 foto yang diperbolehkan! Foto lainnya akan diabaikan.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _selectedImages = images.take(10).toList();
        });
      } else {
        setState(() {
          _selectedImages = images;
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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
      final pickupLoc = _pickupLocationController.text.trim();

      // Memicu event AddProduct ke MarketplaceBloc
      context.read<MarketplaceBloc>().add(
        AddProduct(
          name: name,
          description: desc,
          price: price,
          stock: stock,
          categoryId: _selectedCategory!,
          condition: _selectedCondition,
          pickupLocation: pickupLoc.isEmpty ? null : pickupLoc,
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
    _pickupLocationController.dispose();
    super.dispose();
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
        appBar: AppBar(title: const Text("Tambah Produk")),
        body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            // Tampilkan loading indicator ketika proses upload & insert berlangsung
            if (state is MarketplaceLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Menyimpan produk dan mengunggah gambar...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Area Image Picker ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _selectedImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Ketuk untuk memilih hingga 10 foto",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  final image = _selectedImages[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: kIsWeb
                                          ? Image.network(
                                              image.path,
                                              width: 180,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(image.path),
                                              width: 180,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Form Input ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama produk tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Produk',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Deskripsi tidak boleh kosong';
                        if (value.trim().length < 20)
                          return 'Deskripsi minimal 20 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Harga tidak boleh kosong';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Masukkan angka harga yang valid dan lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Dropdown Kategori ---
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Kategori Produk',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategory,
                            hint: const Text('Pilih Kategori'),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['id'] as String,
                                child: Text(cat['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Pilih kategori produk' : null,
                          ),
                    const SizedBox(height: 16),

                    // --- Dropdown Kondisi ---
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Kondisi Produk',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCondition,
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('Baru')),
                        DropdownMenuItem(value: 'used', child: Text('Bekas')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Stok ---
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(),
                      ),
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

                    // --- Lokasi Pengambilan ---
                    TextFormField(
                      controller: _pickupLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Pengambilan (Opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Contoh: Gedung Filkom, UB',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Tombol Submit ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'Simpan Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
