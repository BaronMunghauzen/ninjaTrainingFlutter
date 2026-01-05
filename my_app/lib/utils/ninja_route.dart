import 'package:flutter/material.dart';

Route ninjaRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offset = Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: offset,
          child: child,
        ),
      );
    },
  );
}

Route ninjaRouteReplacement(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offset = Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: offset,
          child: child,
        ),
      );
    },
  );
}

