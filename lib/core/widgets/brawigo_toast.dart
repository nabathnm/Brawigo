import 'dart:convert';
import 'package:flutter/material.dart';

enum BrawigoToastType { success, info, warning, error }

class BrawigoToast {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Berhasil!',
    Duration duration = const Duration(seconds: 4),
    double? bottomMargin,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: BrawigoToastType.success,
      duration: duration,
      bottomMargin: bottomMargin,
    );
  }

  static void showError(
    BuildContext context, {
    required dynamic message,
    String title = 'Terjadi Kesalahan!',
    Duration duration = const Duration(seconds: 5),
    double? bottomMargin,
  }) {
    final cleanMessage = _cleanErrorMessage(message);
    show(
      context,
      message: cleanMessage,
      title: title,
      type: BrawigoToastType.error,
      duration: duration,
      bottomMargin: bottomMargin,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String title = 'Peringatan',
    Duration duration = const Duration(seconds: 4),
    double? bottomMargin,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: BrawigoToastType.warning,
      duration: duration,
      bottomMargin: bottomMargin,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'Informasi',
    Duration duration = const Duration(seconds: 4),
    double? bottomMargin,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: BrawigoToastType.info,
      duration: duration,
      bottomMargin: bottomMargin,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    required String title,
    required BrawigoToastType type,
    Duration duration = const Duration(seconds: 4),
    double? bottomMargin,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color bgColor;
    Color borderColor;
    Color iconCircleColor;
    Color iconShadowColor;
    IconData iconData;

    switch (type) {
      case BrawigoToastType.success:
        bgColor = const Color(0xFFF0FDF4); // soft mint green
        borderColor = const Color(0xFFBBF7D0);
        iconCircleColor = const Color(0xFF22C55E); // vivid green
        iconShadowColor = const Color(0xFF22C55E).withValues(alpha: 0.35);
        iconData = Icons.check_rounded;
        break;
      case BrawigoToastType.info:
        bgColor = const Color(0xFFEFF6FF); // soft blue
        borderColor = const Color(0xFFBFDBFE);
        iconCircleColor = const Color(0xFF3B82F6); // vivid blue
        iconShadowColor = const Color(0xFF3B82F6).withValues(alpha: 0.35);
        iconData = Icons.info_outline_rounded;
        break;
      case BrawigoToastType.warning:
        bgColor = const Color(0xFFFFFBEB); // soft amber/yellow
        borderColor = const Color(0xFFFEF08A);
        iconCircleColor = const Color(0xFFF59E0B); // vivid amber
        iconShadowColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        iconData = Icons.priority_high_rounded;
        break;
      case BrawigoToastType.error:
        bgColor = const Color(0xFFFEF2F2); // soft rose red
        borderColor = const Color(0xFFFECACA);
        iconCircleColor = const Color(0xFFEF4444); // vivid red
        iconShadowColor = const Color(0xFFEF4444).withValues(alpha: 0.35);
        iconData = Icons.close_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin ?? 20),
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: iconCircleColor.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular status icon with soft glow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconCircleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconShadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title & message text
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15243C),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Dismiss (X) button
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                messenger.hideCurrentSnackBar();
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  /// Membersihkan pesan error teknis Supabase agar ramah bagi pengguna
  static String _cleanErrorMessage(dynamic raw) {
    if (raw == null) return 'Terjadi kesalahan sistem.';
    String str = raw.toString().trim();

    // Jika pesan berbentuk JSON string, contoh: {"code":"unexpected_failure","message":"Error sending..."}
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          if (decoded['message'] != null) {
            return decoded['message'].toString();
          } else if (decoded['error_description'] != null) {
            return decoded['error_description'].toString();
          } else if (decoded['msg'] != null) {
            return decoded['msg'].toString();
          }
        }
      } catch (_) {}
    }

    // Jika berbentuk PostgrestException atau AuthApiException
    if (str.contains('message:')) {
      final reg = RegExp(r'message:\s*([^,\)]+)');
      final match = reg.firstMatch(str);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    // Terjemahkan error umum
    if (str.contains('Invalid login credentials')) {
      return 'Email atau password yang Anda masukkan salah.';
    }
    if (str.contains('Email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Silakan periksa inbox/spam email Anda.';
    }
    if (str.contains('User already registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (str.contains('Network request failed') || str.contains('SocketException')) {
      return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
    }

    return str;
  }
}

