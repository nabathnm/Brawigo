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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Login berhasil")));

              // pindah halaman
              // Navigator.push(...)
            }

            // LOGIN GAGAL
            if (state is AuthFailure) {
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
              ],
            );
          },
        ),
      ),
    );
  }
}
