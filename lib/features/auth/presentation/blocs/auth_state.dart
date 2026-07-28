import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState{}

class AuthLoading extends AuthState{}

class AuthAuthenticated extends AuthState{
  final User? user;

  const AuthAuthenticated({this.user}); 

  @override
  List<Object> get props => user != null ? [user!] : [];
}

class AuthNeedsVerification extends AuthState{
  final String email;
  const AuthNeedsVerification(this.email);
  @override
  List<Object> get props => [email];
}

class AuthError extends AuthState{
  final String message;
  const AuthError({required this.message});
  @override
  List<Object> get props => [message];
}

//ini untuk splash screen

class AuthUnauthenticated extends AuthState {}
