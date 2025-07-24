import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_exercise_reference_create_screen.dart';
import 'admin_exercise_reference_detail_screen.dart';

class AdminExerciseReferenceListScreen extends StatefulWidget {
  const AdminExerciseReferenceListScreen({Key? key}) : super(key: key);

  @override
  State<AdminExerciseReferenceListScreen> createState() =>
      _AdminExerciseReferenceListScreenState();
}

class _AdminExerciseReferenceListScreenState
    extends State<AdminExerciseReferenceListScreen> {
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() => isLoading = true);
    final response = await ApiService.get(
      '/exercise_reference/',
      queryParams: {'exercise_type': 'system'},
    );
    if (response.statusCode == 200) {
      final data = ApiService.decodeJson(response.body);
      setState(() {
        exercises = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteExercise(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: const Text('Вы уверены, что хотите удалить упражнение?'),
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
      await ApiService.delete('/exercise_reference/delete/$uuid');
      _fetchExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : exercises.isEmpty
            ? const Center(child: Text('Нет упражнений'))
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final e = exercises[i];
                  return ListTile(
                    title: Text(e['caption'] ?? ''),
                    subtitle: Text(e['description'] ?? ''),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminExerciseReferenceDetailScreen(
                          exerciseReferenceUuid: e['uuid'],
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _deleteExercise(e['uuid']),
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
                  builder: (_) => const AdminExerciseReferenceCreateScreen(),
                ),
              );
              _fetchExercises();
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
