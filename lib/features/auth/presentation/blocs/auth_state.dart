abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

/// State khusus ketika email belum dikonfirmasi.
/// UI bisa tampilkan tombol "Kirim ulang email konfirmasi".
class AuthEmailNotConfirmed extends AuthState {
  final String email;
  AuthEmailNotConfirmed(this.email);
}

/// State setelah berhasil kirim ulang email konfirmasi.
class AuthResendConfirmationSuccess extends AuthState {}
