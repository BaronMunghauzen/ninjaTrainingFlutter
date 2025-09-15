import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_training_create_screen.dart';
import 'admin_training_detail_screen.dart';

class AdminTrainingListScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminTrainingListScreen({Key? key, this.onDataChanged})
    : super(key: key);

  @override
  State<AdminTrainingListScreen> createState() =>
      _AdminTrainingListScreenState();
}

class _AdminTrainingListScreenState extends State<AdminTrainingListScreen> {
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrainings();
  }

  Future<void> _fetchTrainings() async {
    setState(() => isLoading = true);
    final response = await ApiService.get(
      '/trainings/',
      queryParams: {'training_type': 'system_training'},
    );
    if (response.statusCode == 200) {
      final data = ApiService.decodeJson(response.body);
      setState(() {
        trainings = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });

      // Вызываем callback для обновления данных на родительской странице
      print('AdminTrainingListScreen: Вызываем callback onDataChanged');
      widget.onDataChanged?.call();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTraining(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Вы уверены, что хотите удалить тренировку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.delete('/trainings/delete/$uuid');
      _fetchTrainings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : trainings.isEmpty
            ? const Center(child: Text('Нет тренировок'))
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: trainings.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final t = trainings[i];
                  return ListTile(
                    title: Text(t['caption'] ?? ''),
                    subtitle: Text(
                      (t['description'] ?? '') +
                          (t['actual'] == true
                              ? '  |  Актуальная'
                              : '  |  Неактуальная'),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminTrainingDetailScreen(
                            trainingUuid: t['uuid'],
                            onDataChanged: widget.onDataChanged,
                          ),
                        ),
                      );
                      // Обновляем данные после возврата
                      _fetchTrainings();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _deleteTraining(t['uuid']),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 24,
          right: 24,
          child: RawMaterialButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminTrainingCreateScreen(
                    onDataChanged: widget.onDataChanged,
                  ),
                ),
              );
              _fetchTrainings();
            },
            elevation: 2.0,
            fillColor: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
