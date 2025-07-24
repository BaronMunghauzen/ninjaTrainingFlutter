import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../system_training/system_training_detail_screen.dart';
import '../system_training/active_system_training_screen.dart';

class SystemTrainingListWidget extends StatefulWidget {
  const SystemTrainingListWidget({Key? key}) : super(key: key);

  @override
  State<SystemTrainingListWidget> createState() =>
      _SystemTrainingListWidgetState();
}

class _SystemTrainingListWidgetState extends State<SystemTrainingListWidget> {
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    try {
      final response = await ApiService.get(
        '/trainings/',
        queryParams: {'training_type': 'system_training', 'actual': 'true'},
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          setState(() {
            trainings = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
          return;
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trainings.isEmpty) {
      return const Center(child: Text('Тренировки не найдены'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: trainings.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final training = trainings[index];
        return GestureDetector(
          onTap: () async {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final userUuid = authProvider.userUuid;
            if (userUuid == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка: не найден userUuid')),
              );
              return;
            }
            final response = await ApiService.get(
              '/user_trainings/',
              queryParams: {
                'user_uuid': userUuid,
                'status': 'active',
                'training_uuid': training['uuid'],
              },
            );
            if (response.statusCode == 200) {
              final data = ApiService.decodeJson(response.body);
              final trainingsList = (data is Map && data['data'] is List)
                  ? data['data']
                  : null;
              if (trainingsList != null && trainingsList.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveSystemTrainingScreen(
                      userTraining: trainingsList[0],
                    ),
                  ),
                );
                return;
              }
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    SystemTrainingDetailScreen(training: training),
              ),
            );
          },
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  training['caption'] ?? '',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
