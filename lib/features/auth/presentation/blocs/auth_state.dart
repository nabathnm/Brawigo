abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}

class AuthSuccess extends AuthState {
  final String role;
  AuthSuccess({this.role = 'buyer'});
}

class AuthEmailNotConfirmed extends AuthState {
  final String email;
  AuthEmailNotConfirmed(this.email);
}

class AuthResendConfirmationSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
