import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    // LOGIN
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.login(email: event.email, password: event.password);
        emit(AuthSuccess());
      } on AuthException catch (e) {
        // Supabase mengembalikan "Email not confirmed" dengan status 400
        if (e.message.toLowerCase().contains('email not confirmed')) {
          emit(AuthEmailNotConfirmed(event.email));
        } else {
          emit(AuthFailure(e.message));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // REGISTER
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.register(
          email: event.email,
          password: event.password,
        );
        emit(AuthSuccess());
      } on AuthException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // LOGOUT
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.logout();
        emit(AuthInitial());
      } on AuthException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // RESEND CONFIRMATION EMAIL
    on<ResendConfirmationRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.resendConfirmation(email: event.email);
        emit(AuthResendConfirmationSuccess());
      } on AuthException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}

