import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../application/auth_controller.dart';
import 'sign_in_form.dart';
import 'sign_up_form.dart';

class AuthShellPage extends ConsumerWidget {
  const AuthShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error.isNotEmpty) {
        final flushbar = Flushbar(
          title: 'Error',
          message: error,
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.errorRed,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          leftBarIndicatorColor: AppColors.errorRed.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          shouldIconPulse: true,
        );
        flushbar.show(context);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.jetBlack,
              AppColors.midnightGray,
              AppColors.richBlack,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LogoHeader()
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 100.ms)
                            .slideY(begin: -0.2, end: 0),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.charcoal.withValues(alpha: 0.4),
                          ),
                          child: const TabBar(
                            indicator: BoxDecoration(
                              color: AppColors.sunsetGold,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppColors.richBlack,
                            unselectedLabelColor: AppColors.snowWhite,
                            tabs: [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Create Account'),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                        const SizedBox(height: 24),
                        const Expanded(
                          child: TabBarView(
                            children: [SignInForm(), SignUpForm()],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.theaters, size: 56, color: AppColors.sunsetGold),
        SizedBox(height: 12),
        Text(
          'Actor Studio Global',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Where global talent meets casting opportunities',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.snowWhite,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
