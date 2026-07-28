import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../../../../core/widgets/custom_password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: BrawigoColors.redNormal,
                ),
              );
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login Berhasil!'),
                  backgroundColor: BrawigoColors.greenNormal,
                ),
              );
              context.go('/home');
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrawigoSizes.md, 
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 160),

                            Center(
                              child: Image.asset(
                                'assets/images/logo_brawigo.png',
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.card_giftcard,
                                      size: 80,
                                      color: BrawigoColors.blue800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.defaultSpace),

                            const Text(
                              'Masuk ke Akun',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.sm),

                            const Text(
                              'Gunakan akun Universitas Brawijaya kamu\nuntuk masuk.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BrawigoColors.blue800,
                                fontSize: BrawigoSizes.fontSizeMd,
                                fontWeight:FontWeight.w600,
                                
                                height: 1.2,
                              ),
                            ),

                            const Spacer(),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
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
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.endsWith('@ub.ac.id') &&
                                    !value.endsWith('@student.ub.ac.id')) {
                                  return 'Gunakan email resmi UB (@ub.ac.id / @student.ub.ac.id)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: BrawigoSizes.spaceBtwInputFields,
                            ),

                            CustomPasswordField(
                              hintText: 'Password',
                              controller: _passwordController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Password tidak boleh kosong'
                                  : null,
                            ),
                            const SizedBox(height: BrawigoSizes.fontSizeSm,),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  context.push('/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                    top: BrawigoSizes.xs,
                                    bottom: BrawigoSizes.sm,
                                  ),
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              
                                child: const Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    color: BrawigoColors.blue600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: BrawigoSizes.fontSizeSm,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    BrawigoSizes.buttonRadius,
                                  ),
                                  gradient: LinearGradient(
                                    colors: state is AuthLoading
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
                                  onPressed: state is AuthLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            context.read<AuthBloc>().add(
                                              LoginRequested(
                                                email: _emailController.text
                                                    .trim(),
                                                password:
                                                    _passwordController.text,
                                              ),
                                            );
                                          }
                                        },
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
                                  child: state is AuthLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: BrawigoSizes.fontSizeSm,
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.defaultSpace),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Belum punya akun? ",
                                  style: TextStyle(
                                    color: BrawigoColors.blue800,
                                    fontSize: BrawigoSizes.fontSizeSm,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.push('/register');
                                  },
                                  child: const Text(
                                    "Daftar",
                                    style: TextStyle(
                                      color: BrawigoColors.blue800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: BrawigoSizes.fontSizeSm,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 64),
                          ],
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
    );
  }
}
