import 'package:equatable/equatable.dart';
import 'dart:io';
import 'dart:typed_data';
abstract class  AuthEvent extends Equatable{
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent{
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent{
  final String email;
  final String password;
  const RegisterRequested({required this.email, required this.password});
}

class OtpVerificationRequested extends AuthEvent{
  final String email;
  final String otp;
  const OtpVerificationRequested({required this.email, required this.otp});
}
//ini buat splash screen
class AuthCheckRequested extends AuthEvent{}

//ini buat complete_profile_page
class ProfileCompletionRequested extends AuthEvent {
  final String fullName;
  final String faculty;
  final String gender;

  ProfileCompletionRequested({
    required this.fullName,
    required this.faculty,
    required this.gender,
  });
}

//ini buat set foto profil
class ProfilePhotoUploadRequested extends AuthEvent {
  final Uint8List imageBytes;
  final String fileExtension;

  ProfilePhotoUploadRequested({
    required this.imageBytes,
    required this.fileExtension,
  });
}
