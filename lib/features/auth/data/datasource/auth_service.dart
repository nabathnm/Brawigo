import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> sendOtp({required String email}) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true, 
    );
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: otp,
    );

    return response;
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'username': username,
        'role': role,
      },
    );

    if (response.user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'username': username,
          'role': role,
        });
      } catch (e) {
        print("Upsert Profile Error: $e");
      }
    }
    return response;
  }

  Future<String> getUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return data['role'] as String? ?? 'buyer';
    } catch (e) {
      return 'buyer';
    }
  }

  Future<void> resendConfirmation({required String email}) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }
}
