import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerReportsService {
  static final _supabase = Supabase.instance.client;

  /// Mem-parsing description yang mungkin berupa plain text, JSON payload,
  /// atau string bertanda '| PAYLOAD:...'
  static Map<String, dynamic> parseReportDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return {'description': '-', 'images': <String>[]};
    }
    String text = raw.trim();
    List<String> images = [];

    // 1. Format Payload Lama: "text | PAYLOAD: {json}"
    if (text.contains('| PAYLOAD:')) {
      final parts = text.split('| PAYLOAD:');
      final head = parts.first.trim();
      final jsonStr = parts.last.trim();
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          final d = decoded['description']?.toString() ?? decoded['text']?.toString();
          if (d != null && d.trim().isNotEmpty) {
            text = d.trim();
          } else {
            text = head;
          }
          final imgList = decoded['images'] ?? decoded['photos'];
          if (imgList is List) {
            images = imgList.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {
        text = head;
      }
    } else if (text.startsWith('{') && text.endsWith('}')) {
      // 2. Format JSON murni: {"description": "...", "images": [...]}
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final d = decoded['description']?.toString() ?? decoded['text']?.toString();
          if (d != null && d.trim().isNotEmpty) {
            text = d.trim();
          }
          final imgList = decoded['images'] ?? decoded['photos'];
          if (imgList is List) {
            images = imgList.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {}
    }

    // Bersihkan prefix tag [LAPORAN] dan [Kategori: ...] jika tersisa
    text = text.replaceAll(RegExp(r'\[LAPORAN\]:?'), '').trim();
    text = text.replaceAll(RegExp(r'\[Kategori:\s*[^\]]+\]'), '').trim();
    if (text.isEmpty) text = '-';

    return {
      'description': text,
      'images': images,
    };
  }

  /// Mengambil seluruh laporan untuk seller tertentu dari semua sumber valid:
  /// tabel product_reports, messages/conversations, dan profiles.bio.
  /// Data digabungkan dan dideduplikasi secara sinkron.
  static Future<List<Map<String, dynamic>>> fetchReports(String sellerId) async {
    final List<Map<String, dynamic>> collectedReports = [];
    final Set<String> existingKeys = {};

    try {
      // 1. Ambil seluruh produk milik seller
      final productsRes = await _supabase
          .from('products')
          .select('id, product_name')
          .eq('seller_id', sellerId);

      final List pList = (productsRes as List);
      final Map<String, String> productNames = {};
      for (final p in pList) {
        productNames[p['id'].toString()] = p['product_name']?.toString() ?? 'Produk Toko';
      }

      final productIds = pList.map((p) => p['id'].toString()).toList();

      // 2. Sumber Utama: Tabel product_reports
      if (productIds.isNotEmpty) {
        try {
          final pReports = await _supabase
              .from('product_reports')
              .select()
              .inFilter('product_id', productIds)
              .order('created_at', ascending: false);

          for (final pr in (pReports as List)) {
            final pid = pr['product_id']?.toString() ?? '';
            final parsed = parseReportDescription(pr['description']?.toString());
            final id = pr['id']?.toString() ?? '';
            final reason = pr['reason']?.toString() ?? 'Laporan Pelanggaran';
            final desc = parsed['description'] as String;
            final images = parsed['images'] as List<String>;
            final createdAt = pr['created_at']?.toString();

            collectedReports.add({
              'id': id,
              'reason': reason,
              'description': desc,
              'created_at': createdAt,
              'status': pr['status']?.toString() ?? 'pending',
              'product_name': productNames[pid] ?? 'Produk Toko',
              'images': images,
            });

            if (id.isNotEmpty) existingKeys.add(id);
            if (desc != '-' && desc.isNotEmpty) {
              existingKeys.add('${reason}_$desc');
            }
          }
        } catch (e) {
          debugPrint('SellerReportsService: Error fetching product_reports: $e');
        }
      }

      // 3. Sumber Percakapan (messages & conversations)
      try {
        final convsRes = await _supabase
            .from('conversations')
            .select('id, buyer_id, product_id')
            .eq('seller_id', sellerId);

        final List convList = (convsRes as List);
        if (convList.isNotEmpty) {
          final convIds = convList.map((c) => c['id'].toString()).toList();
          final reportMsgs = await _supabase
              .from('messages')
              .select('id, conversation_id, sender_id, message, created_at')
              .inFilter('conversation_id', convIds)
              .order('created_at', ascending: false);

          final filteredMsgs = (reportMsgs as List)
              .where((m) => (m['message'] ?? '').toString().contains('[LAPORAN]'))
              .toList();

          for (final msg in filteredMsgs) {
            final mid = msg['id']?.toString() ?? '';
            final rawText = (msg['message'] ?? '').toString();
            final parsed = parseReportDescription(rawText);
            final desc = parsed['description'] as String;
            final images = parsed['images'] as List<String>;

            String reason = 'Laporan Pelanggaran';
            final catRegex = RegExp(r'\[Kategori:\s*([^\]]+)\]');
            final match = catRegex.firstMatch(rawText);
            if (match != null) {
              reason = match.group(1)?.trim() ?? reason;
            }

            final dedupeKey = '${reason}_$desc';
            if (existingKeys.contains(mid) || (desc != '-' && existingKeys.contains(dedupeKey))) {
              continue;
            }

            String prodName = 'Toko Penjual';
            final cId = msg['conversation_id']?.toString();
            for (final c in convList) {
              if (c['id'].toString() == cId && c['product_id'] != null) {
                final pid = c['product_id'].toString();
                prodName = productNames[pid] ?? 'Toko Penjual';
                break;
              }
            }

            collectedReports.add({
              'id': mid,
              'reason': reason,
              'description': desc,
              'created_at': msg['created_at']?.toString(),
              'status': 'pending',
              'product_name': prodName,
              'images': images,
            });

            if (mid.isNotEmpty) existingKeys.add(mid);
            if (desc != '-' && desc.isNotEmpty) existingKeys.add(dedupeKey);
          }
        }
      } catch (e) {
        debugPrint('SellerReportsService: Error fetching chat reports: $e');
      }

      // 4. Sumber profiles.bio (store_reports) jika ada
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('bio')
            .eq('id', sellerId)
            .maybeSingle();

        if (profileRes != null && profileRes['bio'] != null) {
          final rawBio = profileRes['bio'].toString();
          if (rawBio.trim().startsWith('{')) {
            final parsed = jsonDecode(rawBio);
            if (parsed is Map && parsed['store_reports'] is List) {
              for (final r in parsed['store_reports']) {
                if (r is Map) {
                  final rid = r['id']?.toString() ?? '';
                  final desc = r['description']?.toString() ?? '-';
                  final reason = r['reason']?.toString() ?? 'Pelanggaran';
                  final dedupeKey = '${reason}_$desc';
                  if (!existingKeys.contains(rid) && (desc == '-' || !existingKeys.contains(dedupeKey))) {
                    collectedReports.add(Map<String, dynamic>.from(r));
                    if (rid.isNotEmpty) existingKeys.add(rid);
                    if (desc != '-') existingKeys.add(dedupeKey);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      // Urutkan berdasarkan created_at descending
      collectedReports.sort((a, b) {
        final tA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final tB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return tB.compareTo(tA);
      });

    } catch (e) {
      debugPrint('SellerReportsService error: $e');
    }

    return collectedReports;
  }
}

