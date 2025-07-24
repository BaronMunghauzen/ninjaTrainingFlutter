import 'package:flutter/material.dart';
import 'admin_training_list_screen.dart';
import 'admin_exercise_reference_list_screen.dart';

class AdminTrainingConstructorScreen extends StatefulWidget {
  const AdminTrainingConstructorScreen({Key? key}) : super(key: key);

  @override
  State<AdminTrainingConstructorScreen> createState() =>
      _AdminTrainingConstructorScreenState();
}

class _AdminTrainingConstructorScreenState
    extends State<AdminTrainingConstructorScreen>
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
        title: const Text('Конструктор тренировок'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Тренировки'),
            Tab(text: 'Упражнения'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminTrainingListScreen(),
          AdminExerciseReferenceListScreen(),
        ],
      ),
    );
  }
}
