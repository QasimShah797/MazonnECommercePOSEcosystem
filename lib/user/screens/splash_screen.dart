import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/mazonn_colors.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../user/controllers/catalog_controller.dart';
import '../../../user/controllers/order_controller.dart';
import '../../../vendor/controllers/vendor_studio_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    final auth = context.read<AuthController>();
    await Future.wait([
      Future<void>.delayed(AppConstants.splashDuration),
      auth.restoreSession(),
    ]);
    if (!mounted) return;
    if (auth.isUser) {
      await Future.wait([
        context.read<OrderController>().load(),
        context.read<CatalogController>().load(),
      ]);
    } else if (auth.isVendor) {
      await context.read<VendorStudioController>().load();
    }
    if (!mounted) return;
    if (!auth.onboardingComplete) {
      context.go(RouteNames.onboarding);
    } else if (auth.isVendor) {
      context.go(RouteNames.vendorDashboard);
    } else if (auth.isUser) {
      context.go(RouteNames.userHome);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: MazonnColors.splash),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      border: Border.all(color: MazonnColors.gold, width: 1.2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 40,
                          color: MazonnColors.goldSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: MazonnColors.ivory,
                          letterSpacing: 8,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppConstants.tagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MazonnColors.goldSoft,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
