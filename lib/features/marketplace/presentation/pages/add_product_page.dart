import 'dart:io';
import 'dart:ui' as ui;
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
    _nameController.addListener(() => setState(() {}));
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
      if (images.length + _selectedImages.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maksimal 10 foto yang diperbolehkan! Foto lainnya akan diabaikan.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        final int remaining = 10 - _selectedImages.length;
        if (remaining > 0) {
          setState(() {
            _selectedImages.addAll(images.take(remaining));
          });
        }
      } else {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap unggah minimal 1 foto produk!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 1;
      final pickupLoc = _pickupLocationController.text.trim();

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

  Widget _buildLabel(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 18.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF15243C), // Deep Navy
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFFF4444), fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    String? bottomHelperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE6F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF15243C),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF8C9AA8),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixText: prefixText,
              prefixStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15243C),
              ),
              counterText: "",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ),
        if (bottomHelperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 6.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                bottomHelperText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8C9AA8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPickerSection() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFFA0B4C8),
        strokeWidth: 1.5,
        gap: 6.0,
        dashWidth: 6.0,
        radius: 16.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: _selectedImages.isEmpty
            ? GestureDetector(
                onTap: _pickImage,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF3873B2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Ketuk untuk unggah foto",
                      style: TextStyle(
                        color: Color(0xFF516A86),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Maks. 10 foto · JPG, PNG · max 5 MB",
                      style: TextStyle(
                        color: Color(0xFF8C9AA8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          if (_selectedImages.length >= 10) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(left: 4, right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC4D7EC)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: Color(0xFF3873B2),
                                    size: 26,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Tambah",
                                    style: TextStyle(
                                      color: Color(0xFF516A86),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final image = _selectedImages[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: kIsWeb
                                      ? Image.network(image.path, fit: BoxFit.cover)
                                      : Image.file(File(image.path), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Maks. 10 foto · JPG, PNG · max 5 MB",
                    style: TextStyle(
                      color: Color(0xFF8C9AA8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF15243C), size: 26),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(hintText, style: const TextStyle(color: Color(0xFF8C9AA8), fontSize: 15)),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF15243C),
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        backgroundColor: const Color(0xFFEAF0F6), // Ice Blue reference background
        body: SafeArea(
          child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              if (state is MarketplaceLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF3873B2)),
                      const SizedBox(height: 16),
                      Text(
                        'Menyimpan produk dan mengunggah gambar...',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // --- Header Atas Sesuai Referensi ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFF15243C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tambah Produk",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15243C),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Isi data produk baru",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF516A86),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Form Content ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Nama Produk
                            _buildLabel("Nama Produk"),
                            _buildTextField(
                              controller: _nameController,
                              hintText: "Contoh: John Doe",
                              maxLength: 100,
                              bottomHelperText: "${_nameController.text.length}/100",
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Nama produk tidak boleh kosong'
                                  : null,
                            ),

                            // 2. Foto Produk
                            _buildLabel("Foto Produk"),
                            _buildPhotoPickerSection(),

                            // 3. Harga
                            _buildLabel("Harga"),
                            _buildTextField(
                              controller: _priceController,
                              hintText: "0",
                              prefixText: "Rp ",
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Harga tidak boleh kosong';
                                final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
                                if (parsed == null || parsed <= 0) return 'Masukkan angka harga yang valid';
                                return null;
                              },
                            ),

                            // 4. Stok
                            _buildLabel("Stok"),
                            _buildTextField(
                              controller: _stockController,
                              hintText: "1",
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Stok tidak boleh kosong';
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 0) return 'Masukkan angka stok yang valid';
                                return null;
                              },
                            ),

                            // 5. Kategori
                            _buildLabel("Kategori"),
                            _isLoadingCategories
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(color: Color(0xFF3873B2)),
                                    ),
                                  )
                                : _buildDropdown<String>(
                                    value: _selectedCategory,
                                    hintText: "Pilih kategori produk",
                                    items: _categories.map((cat) {
                                      return DropdownMenuItem<String>(
                                        value: cat['id'] as String,
                                        child: Text(cat['name'] as String),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _selectedCategory = value),
                                    validator: (value) => value == null ? 'Pilih kategori produk' : null,
                                  ),

                            // 6. Deskripsi
                            _buildLabel("Deskripsi"),
                            _buildTextField(
                              controller: _descController,
                              hintText: "Jelaskan produk secara detail..",
                              maxLines: 4,
                              bottomHelperText: "Min. 20 karakter",
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Deskripsi tidak boleh kosong';
                                if (value.trim().length < 20) return 'Deskripsi minimal 20 karakter';
                                return null;
                              },
                            ),

                            // 7. Kondisi & Lokasi (Fitur Tambahan)
                            _buildLabel("Kondisi"),
                            _buildDropdown<String>(
                              value: _selectedCondition,
                              hintText: "Pilih Kondisi",
                              items: const [
                                DropdownMenuItem(value: 'new', child: Text('Baru')),
                                DropdownMenuItem(value: 'used', child: Text('Bekas')),
                              ],
                              onChanged: (value) => setState(() => _selectedCondition = value!),
                            ),

                            _buildLabel("Lokasi Pengambilan", required: false),
                            _buildTextField(
                              controller: _pickupLocationController,
                              hintText: "Contoh: Gedung Filkom, UB",
                            ),

                            const SizedBox(height: 32),

                            // 8. Tombol Simpan Gradient
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4580C2), Color(0xFF163C66)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2B5F9E).withAlpha(60),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _submitForm,
                                child: const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.dashWidth = 6.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
