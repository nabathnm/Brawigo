import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';

class OnboardingSuccessPage extends StatelessWidget {
  const OnboardingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 154, 154, 154),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.only(right: 2),
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
            colors: [BrawigoColors.blue200, Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
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
                      const SizedBox(height: 120),

                      const Text(
                        'Sudah Siap!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: BrawigoColors.blue800,
                        ),
                      ),
                      const SizedBox(height: BrawigoSizes.sm),

                      const Text(
                        'Temukan kebutuhanmu dan mulai tawarkan\nproduk dan jasamu.',
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
                        child: Image.asset(
                          'assets/images/logo_brawigo.png',
                          width: 140, 
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.card_giftcard,
                              size: 140,
                              color: BrawigoColors.blue800,
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
                            gradient: const LinearGradient(
                              colors: [
                                BrawigoColors.blue400,
                                BrawigoColors.blue600,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/home');
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
                            child: const Text(
                              'Masuk ke Beranda',
                              style: TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
