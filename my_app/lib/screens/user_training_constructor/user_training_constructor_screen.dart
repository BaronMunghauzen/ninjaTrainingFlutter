import 'package:flutter/material.dart';
import 'user_training_list_screen.dart';
import 'user_exercise_reference_list_screen.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_tab_switcher.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class UserTrainingConstructorScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const UserTrainingConstructorScreen({Key? key, this.onDataChanged})
    : super(key: key);

  @override
  State<UserTrainingConstructorScreen> createState() =>
      _UserTrainingConstructorScreenState();
}

class _UserTrainingConstructorScreenState
    extends State<UserTrainingConstructorScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний раздел с кнопкой назад и названием
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        'Конструктор тренировок',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    // Пустое место для симметрии
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Переключатель вкладок
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MetalTabSwitcher(
                  tabs: const ['Мои тренировки', 'Справочник упражнений'],
                  initialIndex: _selectedTabIndex,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Контент вкладок
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    UserTrainingListScreen(onDataChanged: widget.onDataChanged),
                    const UserExerciseReferenceListScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
