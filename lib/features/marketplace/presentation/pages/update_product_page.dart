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

class UpdateProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const UpdateProductPage({super.key, required this.product});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  /// Gambar yang sudah ada di DB (dari tabel product_images)
  List<Map<String, dynamic>> _existingImages = [];

  /// Gambar baru yang dipilih user (belum diupload)
  List<XFile> _newImages = [];

  /// ID dari product_images yang akan dihapus
  final List<String> _imageIdsToDelete = [];

  /// image_path dari product_images yang akan dihapus dari Storage
  final List<String> _imagePathsToDelete = [];

  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  bool _isLoadingImages = true;

  static const int _maxImages = 10;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.product['product_name']?.toString() ?? '');
    _descController =
        TextEditingController(text: widget.product['description']?.toString() ?? '');

    final priceVal = widget.product['price'];
    _priceController = TextEditingController(
      text: priceVal != null ? (priceVal as num).toInt().toString() : '0',
    );

    final stockVal = widget.product['stock'];
    _stockController = TextEditingController(
      text: stockVal != null ? stockVal.toString() : '1',
    );

    _selectedCategory = widget.product['category_id']?.toString();
    _nameController.addListener(() => setState(() {}));
    _fetchCategories();
    _fetchExistingImages();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client.from('categories').select();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isLoadingCategories = false;
          if (_selectedCategory != null &&
              !_categories.any((c) => c['id'].toString() == _selectedCategory)) {
            final catName = widget.product['category_name']?.toString().toLowerCase();
            final matched = _categories
                .where((c) => c['name'].toString().toLowerCase() == catName)
                .firstOrNull;
            _selectedCategory = matched != null ? matched['id'].toString() : null;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchExistingImages() async {
    try {
      final productId = widget.product['id']?.toString() ?? '';
      final response = await Supabase.instance.client
          .from('product_images')
          .select('id, image_url, image_path, image_order')
          .eq('product_id', productId)
          .order('image_order', ascending: true);

      if (mounted) {
        setState(() {
          _existingImages = List<Map<String, dynamic>>.from(response);
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  int get _totalImageCount =>
      _existingImages.length + _newImages.length;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImageCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 10 foto.')),
      );
      return;
    }

    final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final toAdd = picked.take(remaining).toList();
    setState(() {
      _newImages.addAll(toAdd);
    });

    if (picked.length > remaining) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Hanya ${toAdd.length} foto yang ditambahkan (batas 10 foto).'),
          ),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    final img = _existingImages[index];
    setState(() {
      _imageIdsToDelete.add(img['id'].toString());
      _imagePathsToDelete.add(img['image_path']?.toString() ?? '');
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price =
          double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final stock = int.tryParse(_stockController.text.trim());

      context.read<MarketplaceBloc>().add(
            UpdateProduct(
              id: widget.product['id'].toString(),
              name: name,
              description: desc,
              price: price,
              stock: stock,
              categoryId: _selectedCategory,
              newImages: _newImages,
              imageIdsToDelete: _imageIdsToDelete,
              imagePathsToDelete: _imagePathsToDelete,
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

  Widget _buildLabel(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 18.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF15243C),
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
    final bool isEmpty = _totalImageCount == 0 && !_isLoadingImages;

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
        child: _isLoadingImages
            ? const Center(child: CircularProgressIndicator())
            : isEmpty
                ? GestureDetector(
                    onTap: _pickImages,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Gambar yang sudah ada di DB
                            ..._existingImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final img = entry.value;
                              return _buildImageThumb(
                                child: Image.network(
                                  img['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                                onDelete: () => _removeExistingImage(index),
                              );
                            }),
                            // Gambar baru yang dipilih (belum diupload)
                            ..._newImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final xfile = entry.value;
                              return _buildImageThumb(
                                child: kIsWeb
                                    ? Image.network(xfile.path,
                                        fit: BoxFit.cover, width: 90, height: 90)
                                    : Image.file(File(xfile.path),
                                        fit: BoxFit.cover, width: 90, height: 90),
                                onDelete: () => _removeNewImage(index),
                                isNew: true,
                              );
                            }),
                            // Tombol Tambah (tampil jika belum max)
                            if (_totalImageCount < _maxImages)
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1FA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFC4D7EC)),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
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
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${_totalImageCount}/$_maxImages foto · JPG, PNG · max 5 MB",
                        style: const TextStyle(
                          color: Color(0xFF8C9AA8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildImageThumb({
    required Widget child,
    required VoidCallback onDelete,
    bool isNew = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 10, top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
        ),
        // Badge "Baru" untuk gambar yang baru ditambah
        if (isNew)
          Positioned(
            left: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3873B2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Baru',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Tombol hapus di pojok kanan atas
        Positioned(
          right: 4,
          top: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
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
              content: Text('Produk berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF0F6),
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
                        'Menyimpan perubahan...',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // --- Header ---
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
                              "Edit Produk",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15243C),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Perbarui informasi produk",
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

                  // --- Form ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Nama Produk
                            _buildLabel("Nama Produk"),
                            _buildTextField(
                              controller: _nameController,
                              hintText: "Contoh: Magic Com Biru",
                              maxLength: 100,
                              bottomHelperText:
                                  "${_nameController.text.length}/100",
                              validator: (value) =>
                                  value == null || value.isEmpty
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
                                if (value == null || value.isEmpty)
                                  return 'Harga tidak boleh kosong';
                                final parsed = double.tryParse(
                                    value.replaceAll(RegExp(r'[^0-9.]'), ''));
                                if (parsed == null || parsed <= 0)
                                  return 'Masukkan angka harga yang valid';
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
                                if (value == null || value.isEmpty)
                                  return 'Stok tidak boleh kosong';
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 0)
                                  return 'Masukkan angka stok yang valid';
                                return null;
                              },
                            ),

                            // 5. Kategori
                            _buildLabel("Kategori"),
                            _isLoadingCategories
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF3873B2)),
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
                                    onChanged: (value) =>
                                        setState(() => _selectedCategory = value),
                                    validator: (value) =>
                                        value == null ? 'Pilih kategori produk' : null,
                                  ),

                            // 6. Deskripsi
                            _buildLabel("Deskripsi"),
                            _buildTextField(
                              controller: _descController,
                              hintText: "Jelaskan produk secara detail..",
                              maxLines: 4,
                              bottomHelperText: "Min. 20 karakter",
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Deskripsi tidak boleh kosong';
                                if (value.trim().length < 20)
                                  return 'Deskripsi minimal 20 karakter';
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            // 7. Tombol Simpan
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
