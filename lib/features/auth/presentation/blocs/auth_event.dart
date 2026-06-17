

abstract class AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String email;
  SendOtpRequested(this.email);
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;
  VerifyOtpRequested(this.email, this.otp);
}

class LogoutRequested extends AuthEvent {}
