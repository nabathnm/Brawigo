import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';
import 'dart:async';

import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _pinController = TextEditingController();

  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50, 
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: BrawigoColors.blue950,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BrawigoColors.blue800.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 154, 154, 154),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.only(
                right: 2,
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: BrawigoColors.blue800,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrawigoColors.blue200,
              Colors.white,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: BrawigoColors.redNormal,
                ),
              );
              _pinController.clear();
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verifikasi Berhasil!'),
                  backgroundColor: BrawigoColors.greenNormal,
                ),
              );
              context.go('/complete-profile');
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrawigoSizes.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 160,
                          ), 

                          Center(
                            child: Image.asset(
                              'assets/images/logo_brawigo.png',
                              height: 100, 
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.card_giftcard,
                                    size: 80,
                                    color: BrawigoColors.blue800,
                                  ),
                            ),
                          ),
                          const SizedBox(height: BrawigoSizes.defaultSpace),

                          const Text(
                            'Kode OTP Telah Dikirim',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: BrawigoColors.blue800,
                            ),
                          ),
                          const SizedBox(height: BrawigoSizes.sm),

                          const Text(
                            'Silakan cek kotak masuk email kamu.', 
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: BrawigoColors.blue800,
                              fontSize: BrawigoSizes.fontSizeMd,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),

                          const Spacer(), 

                          Center(
                            child: Pinput(
                              length: 6,
                              controller: _pinController,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: defaultPinTheme
                                  .copyDecorationWith(
                                    border: Border.all(
                                      color: BrawigoColors.blue800,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      BrawigoSizes.inputFieldRadius,
                                    ),
                                  ),
                              onCompleted: (pin) {
                                context.read<AuthBloc>().add(
                                  OtpVerificationRequested(
                                    email: widget.email,
                                    otp: pin,
                                  ),
                                );
                              },
                            ),
                          ),

                          const Spacer(), 

                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  BrawigoSizes.buttonRadius,
                                ),
                                gradient: LinearGradient(
                                  colors: state is AuthLoading
                                      ? [
                                          BrawigoColors.blue300,
                                          BrawigoColors.blue300,
                                        ]
                                      : [
                                          BrawigoColors.blue400,
                                          BrawigoColors.blue600,
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        if (_pinController.text.length == 6) {
                                          context.read<AuthBloc>().add(
                                            OtpVerificationRequested(
                                              email: widget.email,
                                              otp: _pinController.text,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: BrawigoSizes.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      BrawigoSizes.buttonRadius,
                                    ),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Verifikasi Kode',
                                        style: TextStyle(
                                          fontSize: BrawigoSizes.fontSizeSm,
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: BrawigoSizes.defaultSpace),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _canResend
                                    ? () {
                                        // resend kode otp bloc logic belom
                                        _startTimer();
                                      }
                                    : null,
                                child: Text(
                                  "Kirim ulang kode",
                                  style: TextStyle(
                                    color: BrawigoColors.blue800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: BrawigoSizes.fontSizeSm,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              if (!_canResend)
                                Text(
                                  " dalam 00:${_countdown.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: BrawigoColors.blue800,
                                    fontSize: BrawigoSizes.fontSizeSm,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 64), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
