import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'user_training_list_screen.dart';
import 'user_exercise_reference_list_screen.dart';

class UserTrainingConstructorScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const UserTrainingConstructorScreen({Key? key, this.onDataChanged})
    : super(key: key);

  @override
  State<UserTrainingConstructorScreen> createState() =>
      _UserTrainingConstructorScreenState();
}

class _UserTrainingConstructorScreenState
    extends State<UserTrainingConstructorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Конструктор тренировок',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.buttonPrimary,
          tabs: const [
            Tab(text: 'Мои тренировки'),
            Tab(text: 'Справочник упражнений'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          UserTrainingListScreen(onDataChanged: widget.onDataChanged),
          const UserExerciseReferenceListScreen(),
        ],
      ),
    );
  }
}
