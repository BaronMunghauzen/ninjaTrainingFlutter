import 'package:flutter/material.dart';

class SystemTrainingListScreen extends StatelessWidget {
  const SystemTrainingListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Системные тренировки')),
      body: Center(
        child: Text('Здесь будет список тренировок'),
      ), // TODO: реализовать
    );
  }
}
