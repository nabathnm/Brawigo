import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductImagePicker extends StatelessWidget {
  const AddProductImagePicker({
    super.key,
    required this.images,
    required this.isPicking,
    required this.onPick,
    required this.onRemove,
  });

  static const int maxImages = 10;

  final List<XFile> images;
  final bool isPicking;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: images.length < maxImages && !isPicking ? onPick : null,
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
          child: images.isEmpty ? _emptyContent() : _imagesContent(),
        ),
      ),
    );
  }

  Widget _emptyContent() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A), size: 24),
      ),
      const SizedBox(height: 12),
      const Text(
        'Ketuk untuk unggah foto',
        style: TextStyle(color: Color(0xFF6B7490), fontSize: 14),
      ),
      const SizedBox(height: 4),
      _helperText(),
    ],
  );

  Widget _imagesContent() => Column(
    children: [
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length + (images.length < maxImages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == images.length) return _addButton();
            return _imageTile(images[index], index);
          },
        ),
      ),
      if (isPicking) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
      ],
      const SizedBox(height: 8),
      _helperText(),
    ],
  );

  Widget _addButton() => GestureDetector(
    onTap: isPicking ? null : onPick,
    child: Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
          SizedBox(height: 4),
          Text(
            'Tambah',
            style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _imageTile(XFile image, int index) => Stack(
    children: [
      Container(
        margin: const EdgeInsets.only(right: 8),
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(image.path, fit: BoxFit.cover)
              : Image.file(File(image.path), fit: BoxFit.cover),
        ),
      ),
      Positioned(
        top: 4,
        right: 12,
        child: GestureDetector(
          onTap: () => onRemove(index),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
    ],
  );

  Widget _helperText() => Text(
    'Maks. 10 foto · JPG, PNG · max 5 MB',
    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
  );
}
