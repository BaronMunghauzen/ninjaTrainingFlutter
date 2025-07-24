import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool showIcon;

  const LogoWidget({Key? key, this.size = 120, this.showIcon = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: showIcon
            ? const Icon(
                Icons.fitness_center,
                size: 60,
                color: AppColors.textPrimary,
              )
            : const Text(
                'NT',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
      ),
    );
  }
}

// Виджет для изображения логотипа (использовать после загрузки изображения)
class LogoImageWidget extends StatelessWidget {
  final double size;
  final String imagePath;

  const LogoImageWidget({Key? key, this.size = 120, required this.imagePath})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: size * 0.8,
          height: size * 0.8,
        ),
      ),
    );
  }
}

// Новый виджет для фонового логотипа ниндзя
class NinjaBackgroundLogo extends StatelessWidget {
  final double opacity;
  final double size;

  const NinjaBackgroundLogo({Key? key, this.opacity = 0.1, this.size = 300})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -120,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
