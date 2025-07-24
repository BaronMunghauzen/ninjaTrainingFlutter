import 'package:flutter/material.dart';
import '../../services/program_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'active_training_screen.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'weeks_days_navigation.dart';

class InactiveTrainingScreen extends StatefulWidget {
  final String programUuid;
  const InactiveTrainingScreen({Key? key, required this.programUuid})
    : super(key: key);

  @override
  State<InactiveTrainingScreen> createState() => _InactiveTrainingScreenState();
}

class _InactiveTrainingScreenState extends State<InactiveTrainingScreen> {
  Map<String, dynamic>? programData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final program = await ProgramService.getProgramById(widget.programUuid);
      setState(() {
        programData = program?.toJson();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = List.generate(4, (i) => '${i + 1} неделя');
    final days = List.generate(7, (i) => 'День ${i + 1}');
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Программа')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programData == null
          ? const Center(child: Text('Не удалось загрузить программу'))
          : Column(
              children: [
                // Навигация по неделям и дням сверху
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: WeeksDaysNavigation(weeksCount: 4, daysCount: 7),
                ),
                // Основной контент
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Информация и кнопка по центру
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                programData!['caption'] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                programData!['description'] ?? '',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: 220,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.08),
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    final userUuid = authProvider.userUuid;
                                    if (userUuid == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ошибка: не найден userUuid',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      isLoading = true;
                                    });
                                    try {
                                      final userProgramUuid =
                                          await ProgramService.addUserProgram(
                                            widget.programUuid,
                                            userUuid,
                                            null, // caption будет получен автоматически из программы
                                          );

                                      if (userProgramUuid != null) {
                                        // После успешного добавления — проверяем активность
                                        final queryParams = {
                                          'user_uuid': userUuid,
                                          'program_uuid': widget.programUuid,
                                          'status': 'active',
                                        };
                                        final checkResponse =
                                            await ApiService.get(
                                              '/user_programs/',
                                              queryParams: queryParams,
                                            );
                                        if (checkResponse.statusCode == 200) {
                                          final data = ApiService.decodeJson(
                                            checkResponse.body,
                                          );
                                          if (data is List && data.isNotEmpty) {
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ActiveTrainingScreen(
                                                      userProgramData:
                                                          data.first,
                                                    ),
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ошибка запуска программы',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Ошибка: $e')),
                                      );
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                                  child: const Text('Начать программу'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
