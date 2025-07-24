import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета темной темы
  static const Color primary = Color(0xFF0B0B0C); // Основной фон
  static const Color secondary = Color(0xFF1F2121); // Цвет кнопок
  static const Color accent = Color(0xFFD2D1D1); // Акцент теперь белый/серый

  // Фон и поверхности
  static const Color background = Color(0xFF0B0B0C); // Основной фон (светлее)
  static const Color surface = Color(
    0xFF0D0D0E,
  ); // Поверхность карточек (светлее)
  static const Color surfaceLight = Color(0xFF080809); // Светлая поверхность

  // Текст
  static const Color textPrimary = Color(0xFFD2D1D1); // Основной цвет текста
  static const Color textSecondary = Color(0xFFB3B3B3); // Серый текст
  static const Color textHint = Color(0xFF666666); // Текст подсказок

  // Кнопки
  static const Color buttonPrimary = Color(0xFF1F2121); // Основной цвет кнопок
  static const Color buttonSecondary = Color(
    0xFF1F2121,
  ); // Вторичный цвет кнопок
  static const Color buttonDisabled = Color(0xFF404040);

  // Поля ввода
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF404040);
  static const Color inputFocused = Color(
    0xFFD2D1D1,
  ); // Фокус теперь белый/серый

  // Ошибки и успех
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF0E0E0F), // Светлее в правом верхнем углу
      Color(0xFF0B0B0C), // Основной темный цвет (светлее)
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2121), Color(0xFF1F2121)],
  );
}
