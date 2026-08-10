import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/gradient_background.dart';
import '../../core/network/token_storage.dart';
import '../../core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _fadeAnimation;

  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: .85,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Future.delayed(
      const Duration(seconds: 3),
      () async {
        if (!mounted) return;

        final isLoggedIn = await TokenStorage.hasToken();

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
        );
      },
    );

  }

  @override
  void dispose() {

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return GradientBackground(

      child: Center(

        child: FadeTransition(

          opacity: _fadeAnimation,

          child: ScaleTransition(

            scale: _scaleAnimation,

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const AppLogo(),

                const SizedBox(
                  height: AppSpacing.xl,
                ),

                Text(
                  "Smart Healthcare",
                  style: AppTextStyles.headline,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                Text(
                  "Clinical Decision Support",
                  style: AppTextStyles.caption,
                ),

                const SizedBox(
                  height: AppSpacing.xxl,
                ),

                SizedBox(
                  width: 140,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      color: AppColors.secondary,
                      backgroundColor: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}