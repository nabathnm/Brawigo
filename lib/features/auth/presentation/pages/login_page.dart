import 'package:brawigo/features/auth/presentation/pages/resgisterpage_page.dart';
import 'package:brawigo/features/seller/marketplace/pages/marketplace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // LOGIN BERHASIL
            if (state is AuthSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Login berhasil")));

              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const MarketPlacePage())
              );
            }

            // EMAIL BELUM DIKONFIRMASI
            if (state is AuthEmailNotConfirmed) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Email belum dikonfirmasi. Silakan cek inbox atau kirim ulang."),
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: "Kirim Ulang",
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        ResendConfirmationRequested(email: state.email),
                      );
                    },
                  ),
                ),
              );
            }

            // BERHASIL KIRIM ULANG EMAIL
            if (state is AuthResendConfirmationSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email konfirmasi baru telah dikirim! Silakan cek inbox Anda."),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // LOGIN GAGAL
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },

          builder: (context, state) {
            return Column(
              children: [
                // EMAIL
                TextField(
                  controller: emailController,

                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,

                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                // LOADING
                if (state is AuthLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          LoginRequested(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          ),
                        );
                      },

                      child: const Text("Login"),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },

                  child: const Text("Belum punya akun? Register"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
