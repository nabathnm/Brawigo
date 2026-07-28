import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart' ;
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatelessWidget{
 const SplashPage({super.key});
  
  @override 
  Widget build(BuildContext context){
    context.read<AuthBloc>().add(AuthCheckRequested());
    return Scaffold(
      body: BlocListener<AuthBloc,AuthState>(listener: (context, state){
        if(state is AuthAuthenticated){
          debugPrint('User sudah login, diarahkan ke Home');
          context.go('/home');
        }
        else if (state is AuthUnauthenticated){
          debugPrint('User belum login, diarahkan ke halaman login');
          context.go('/login');
        }
      } ,
      child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrawigoColors.blue700,
                BrawigoColors.blue100,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_brawigo_text.png',
                  width: 150,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}