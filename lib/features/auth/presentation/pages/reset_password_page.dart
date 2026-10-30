import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';
import 'package:brawigo/core/widgets/custom_password_field.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirim ulang ke email kamu!'),
            backgroundColor: BrawigoColors.greenNormal,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: BrawigoColors.redNormal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ulang kode OTP.'),
            backgroundColor: BrawigoColors.redNormal,
          ),
        );
      }
    }
  }

  Future<void> _submitReset() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan 6 digit kode OTP verifikasi!'),
          backgroundColor: BrawigoColors.redNormal,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final newPassword = _passwordController.text;

    try {
      // 1. Verifikasi kode OTP recovery
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.recovery,
      );

      if (res.session == null && res.user == null) {
        throw const AuthException('Verifikasi kode OTP gagal atau telah kedaluwarsa.');
      }

      // 2. Update password user
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 3. Logout sesi recovery agar user login bersih
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah! Silakan login dengan password baru.'),
            backgroundColor: BrawigoColors.greenNormal,
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: BrawigoColors.redNormal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat mereset password. Coba lagi.'),
            backgroundColor: BrawigoColors.redNormal,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 20,
        color: BrawigoColors.blue950,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: BrawigoColors.blue800.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 154, 154, 154),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.only(right: 2),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: BrawigoColors.blue800,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrawigoColors.blue200, Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrawigoSizes.md,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isKeyboardOpen ? 12 : 32),

                            Center(
                              child: Image.asset(
                                'assets/images/logo_brawigo.png',
                                height: isKeyboardOpen ? 55 : 85,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.card_giftcard,
                                      size: isKeyboardOpen ? 50 : 70,
                                      color: BrawigoColors.blue800,
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: isKeyboardOpen ? 8 : BrawigoSizes.defaultSpace,
                            ),

                            const Text(
                              'Reset Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.sm),

                            Text(
                              'Kode verifikasi telah dikirim ke:\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: BrawigoColors.blue800,
                                fontSize: BrawigoSizes.fontSizeSm,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),

                            SizedBox(height: isKeyboardOpen ? 16 : 28),

                            // Pinput OTP
                            Center(
                              child: Pinput(
                                length: 6,
                                controller: _otpController,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!.copyWith(
                                    border: Border.all(
                                      color: BrawigoColors.blue800,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Resend OTP Countdown
                            Center(
                              child: _canResend
                                  ? TextButton(
                                      onPressed: _isLoading ? null : _resendOtp,
                                      child: const Text(
                                        'Kirim Ulang Kode OTP',
                                        style: TextStyle(
                                          color: BrawigoColors.blue600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: BrawigoSizes.fontSizeSm,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Kirim ulang kode dalam $_countdown detik',
                                      style: TextStyle(
                                        color: BrawigoColors.blue800.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: BrawigoSizes.fontSizeSm,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),

                            SizedBox(height: isKeyboardOpen ? 14 : 24),

                            // Password Baru
                            CustomPasswordField(
                              hintText: 'Password Baru',
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password baru tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: BrawigoSizes.spaceBtwInputFields),

                            // Konfirmasi Password Baru
                            CustomPasswordField(
                              hintText: 'Konfirmasi Password Baru',
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password tidak boleh kosong';
                                }
                                if (value != _passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),

                            const Spacer(),

                            SizedBox(height: isKeyboardOpen ? 16 : 24),

                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    BrawigoSizes.buttonRadius,
                                  ),
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [
                                            BrawigoColors.blue300,
                                            BrawigoColors.blue300,
                                          ]
                                        : [
                                            BrawigoColors.blue400,
                                            BrawigoColors.blue600,
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitReset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: BrawigoSizes.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        BrawigoSizes.buttonRadius,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Simpan Password Baru',
                                          style: TextStyle(
                                            fontSize: BrawigoSizes.fontSizeSm,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            SizedBox(height: isKeyboardOpen ? 16 : 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

