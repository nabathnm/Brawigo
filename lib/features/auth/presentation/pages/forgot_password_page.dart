import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP reset password telah dikirim ke email kamu!'),
            backgroundColor: BrawigoColors.greenNormal,
          ),
        );
        context.push('/reset-password', extra: email);
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
            content: Text('Gagal mengirim kode reset password. Coba lagi.'),
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
                            SizedBox(height: isKeyboardOpen ? 16 : 40),

                            Center(
                              child: Image.asset(
                                'assets/images/logo_brawigo.png',
                                height: isKeyboardOpen ? 65 : 95,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.card_giftcard,
                                      size: isKeyboardOpen ? 55 : 80,
                                      color: BrawigoColors.blue800,
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: isKeyboardOpen ? 12 : BrawigoSizes.defaultSpace,
                            ),

                            const Text(
                              'Lupa Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.sm),

                            const Text(
                              'Masukkan email Universitas Brawijaya kamu\nuntuk menerima kode OTP reset password.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BrawigoColors.blue800,
                                fontSize: BrawigoSizes.fontSizeMd,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),

                            SizedBox(height: isKeyboardOpen ? 24 : 40),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _sendOtp(),
                              style: const TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                color: BrawigoColors.blue950,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email UB',
                                hintStyle: const TextStyle(
                                  color: BrawigoColors.blue800,
                                  fontSize: BrawigoSizes.fontSizeSm,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: BrawigoColors.blue800,
                                  size: BrawigoSizes.iconMd,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: BrawigoSizes.md,
                                  vertical: BrawigoSizes.md,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    BrawigoSizes.inputFieldRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: BrawigoColors.blue800,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    BrawigoSizes.inputFieldRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: BrawigoColors.blue800,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    BrawigoSizes.inputFieldRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: BrawigoColors.blue800,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                final trimmed = value.trim();
                                if (!trimmed.endsWith('@ub.ac.id') &&
                                    !trimmed.endsWith('@student.ub.ac.id')) {
                                  return 'Gunakan email resmi UB (@ub.ac.id / @student.ub.ac.id)';
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
                                  onPressed: _isLoading ? null : _sendOtp,
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
                                          'Kirim Kode OTP',
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

