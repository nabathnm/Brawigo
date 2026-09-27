import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient supabaseClient;

  AuthBloc({required this.supabaseClient}) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      try {
        final response = await supabaseClient.auth.signInWithPassword(
          email: event.email,
          password: event.password,
        );
        if (response.session != null) {
          emit(AuthAuthenticated());
        }
      } on AuthException catch (e) {
        emit(AuthError(message: e.message));
      } catch (e) {
        emit(const AuthError(message: 'Terjadi Kesalahan Tidak Terduga.'));
      }
    });

    on<RegisterRequested>((event, emit) async {
      try {
        await supabaseClient.auth.signUp(
          email: event.email,
          password: event.password,
        );

        emit(AuthNeedsVerification(event.email));
      } on AuthException catch (e) {
        emit(AuthError(message: e.message));
      } catch (e) {
        emit(const AuthError(message: 'Terjadi Kesalahan Tidak Terduga'));
      }
    });

    on<OtpVerificationRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await supabaseClient.auth.verifyOTP(
          type: OtpType.signup,
          email: event.email,
          token: event.otp,
        );
        if (response.session != null) {
          emit(AuthAuthenticated());
        }
      } on AuthException catch (e) {
        emit(AuthError(message: e.message));
      } catch (e) {
        emit(const AuthError(message: 'Gagal memverifikasi OTP.'));
      }
    });

    // ini untuk splash screen
    on<AuthCheckRequested>((event, emit) async {
      await Future.delayed(const Duration(seconds: 1));

      final session = supabaseClient.auth.currentSession;
      if (session != null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    // ini buat complete_profile_page
    on<ProfileCompletionRequested>(_onProfileCompletionRequested);
    // INI BUAT SET FOTO PROFIL AWAL 
    on<ProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
  }

  // logika untuk Profile Completion
  Future<void> _onProfileCompletionRequested(
    ProfileCompletionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        emit(
          const AuthError(
            message: 'Sesi tidak ditemukan. Silakan login kembali.',
          ),
        );
        return;
      }

      await supabaseClient
          .from('profiles')
          .update({
            'full_name': event.fullName,
            'faculty': event.faculty,
            'gender': event.gender,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Gagal menyimpan profil: ${e.toString()}'));
    }
  }

  // logic untuk upload foto profil 
Future<void> _onProfilePhotoUploadRequested(
    ProfilePhotoUploadRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        emit(
          AuthError(message: 'Sesi tidak ditemukan. Silakan login kembali.'),
        );
        return;
      }

      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.${event.fileExtension}';

      await supabaseClient.storage
          .from('avatars')
          .uploadBinary(fileName, event.imageBytes);

      final imageUrl = supabaseClient.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await supabaseClient
          .from('profiles')
          .update({
            'profile_photo_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Gagal mengunggah foto: ${e.toString()}'));
    }
  }
}


