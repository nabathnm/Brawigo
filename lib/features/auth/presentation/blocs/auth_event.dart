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

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String username;
  final String role;
  RegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
    required this.role,
  });
}

class ResendConfirmationRequested extends AuthEvent {
  final String email;
  ResendConfirmationRequested({required this.email});
}

class LogoutRequested extends AuthEvent {}
