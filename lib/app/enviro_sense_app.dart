import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/devices/presentation/device_scan_screen.dart';
import 'app_motion.dart';
import 'app_theme.dart';

Page<void> _premiumPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.routeDuration,
    reverseTransitionDuration: AppMotion.reverseRouteDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Respect the user's system setting to reduce motion.
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }

      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: AppMotion.routeCurve,
        reverseCurve: AppMotion.reverseRouteCurve,
      );

      final slideAnimation = Tween<Offset>(
        begin: AppMotion.routeSlide,
        end: Offset.zero,
      ).animate(curvedAnimation);

      final scaleAnimation = Tween<double>(
        begin: AppMotion.routeScaleStart,
        end: 1,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _premiumPage(state, const DashboardScreen()),
    ),
    GoRoute(
      path: '/scan',
      pageBuilder: (context, state) =>
          _premiumPage(state, const DeviceScanScreen()),
    ),
  ],
);

class EnviroSenseApp extends StatelessWidget {
  const EnviroSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EnviroSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
