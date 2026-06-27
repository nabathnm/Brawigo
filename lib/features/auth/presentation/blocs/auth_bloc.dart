import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/datasource/auth_service.dart'; 
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<SendOtpRequested>((event, emit) async {
      emit(AuthLoading()); 
      try {
        await authService.sendOtp(email: event.email);
        emit(AuthOtpSent(event.email));
      } on AuthException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<VerifyOtpRequested>((event, emit) async {
      emit(AuthLoading()); 
      try {
        await authService.verifyOtp(email: event.email, otp: event.otp);
        emit(AuthSuccess());
      } on AuthException catch (e) {
        emit(AuthFailure('OTP Salah atau Kadaluarsa. (${e.message})'));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authService.login(email: event.email, password: event.password);
        String role = 'buyer';
        if (response.user != null) {
          role = await authService.getUserRole(response.user!.id);
        }
        emit(AuthSuccess(role: role));
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('email not confirmed')) {
          emit(AuthEmailNotConfirmed(event.email));
        } else {
          emit(AuthFailure(e.message));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authService.register(
          email: event.email,
          password: event.password,
          fullName: event.fullName,
          username: event.username,
          role: event.role,
        );
        emit(AuthSuccess(role: event.role));
      } on AuthException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

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

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await Supabase.instance.client.auth.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
