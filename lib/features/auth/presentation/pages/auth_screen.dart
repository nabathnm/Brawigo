import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/auth/data/datasource/auth_service.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;

  // Instansiasi file service yang baru kita buat di atas
  final AuthService _authService = AuthService();

  // Memanggil fungsi kirim OTP dari service
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    // Validasi domain UB tetap ada di UI agar mencegah request ke database jika email salah
    if (!email.endsWith('@student.ub.ac.id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak. Gunakan email @student.ub.ac.id!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PANGGIL DARI AUTH SERVICE
      await _authService.sendOtp(email: email);

      setState(() {
        _isOtpSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP berhasil dikirim ke email Anda.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $error')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Memanggil fungsi verifikasi OTP dari service
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan kode OTP!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PANGGIL DARI AUTH SERVICE
      final res = await _authService.verifyOtp(email: email, otp: otp);

      if (res.session != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login Berhasil!')));
          // TODO: Arahkan ke halaman utama setelah login sukses
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP salah atau kadaluarsa.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // KODE UI DI BAWAH INI SAMA PERSIS SEPERTI SEBELUMNYA
    return Scaffold(
      appBar: AppBar(title: const Text('Login Mahasiswa UB')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isOtpSent) ...[
                const Text(
                  'Masukkan Email UB Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'contoh@student.ub.ac.id',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kirim OTP'),
                ),
              ] else ...[
                Text(
                  'Masukkan OTP yang dikirim ke\n${_emailController.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Verifikasi & Login'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: const Text('Ganti Email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
