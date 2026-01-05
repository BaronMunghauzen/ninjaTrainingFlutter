import 'package:flutter/material.dart';

class NinjaShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.7),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.04),
      blurRadius: 1,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> pressed = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];
}

