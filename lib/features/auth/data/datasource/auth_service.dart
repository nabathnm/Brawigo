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
}
