import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
