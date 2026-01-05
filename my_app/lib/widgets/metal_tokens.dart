import 'package:flutter/material.dart';

class MetalTokens {
  static const double radius = 16.0;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  static const List<Color> gradientColors = [
    Color(0xFF2A2A2A), // highlight edge
    Color(0xFF1E1E1E), // base
    Color(0xFF161616), // shadow edge
  ];

  static const BorderRadius borderRadius =
      BorderRadius.all(Radius.circular(radius));
}

