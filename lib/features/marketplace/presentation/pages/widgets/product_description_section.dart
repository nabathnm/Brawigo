import 'package:flutter/material.dart';

class ProductDescriptionSection extends StatefulWidget {
  const ProductDescriptionSection({super.key, required this.description});

  final String? description;

  @override
  State<ProductDescriptionSection> createState() =>
      _ProductDescriptionSectionState();
}

class _ProductDescriptionSectionState extends State<ProductDescriptionSection> {
  bool _expanded = false;

  String get _description {
    final value = widget.description;
    return value != null && value.isNotEmpty
        ? value
        : 'Tidak ada deskripsi untuk produk ini.';
  }

  bool get _isLong => _description.length > 120;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF15243C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _description,
          maxLines: _expanded ? null : (_isLong ? 3 : null),
          overflow: _expanded || !_isLong
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF334155),
          ),
        ),
        if (_isLong) ...[
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Tutup Selengkapnya' : 'Lihat Selengkapnya',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF334155),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
