import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/pages/login_page.dart';
import 'package:brawigo/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrawigoApp extends StatelessWidget {
  const BrawigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(AuthService()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brawigo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
