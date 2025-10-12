import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/program_service.dart';
import '../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'active_training_screen.dart';
import '../../services/api_service.dart';
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
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _loadData();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('user_token');
    });
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Программа'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programData == null
          ? const Center(child: Text('Не удалось загрузить программу'))
          : Stack(
              fit: StackFit.expand,
              children: [
                // Фоновое изображение с сильным затемнением
                if (programData!['image_uuid'] != null)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        '${ApiService.baseUrl}/files/file/${programData!['image_uuid']}',
                        fit: BoxFit.cover,
                        headers: _authToken != null
                            ? {'Cookie': 'users_access_token=$_authToken'}
                            : {},
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.background,
                            child: const Center(
                              child: Icon(
                                Icons.fitness_center,
                                size: 100,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                        key: ValueKey(programData!['image_uuid']),
                      ),
                      // Темная накладка для очень сильного затемнения
                      Container(color: Colors.black.withOpacity(0.7)),
                    ],
                  )
                else
                  Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 100,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                // Темный оверлей для читаемости
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Контент
                SafeArea(
                  child: Column(
                    children: [
                      // Навигация по неделям и дням сверху
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: WeeksDaysNavigation(weeksCount: 4, daysCount: 7),
                      ),
                      // Основной контент
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Информация и кнопка по центру
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                programData!['caption'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                      color: Colors.black54,
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                programData!['description'] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 1),
                                                      blurRadius: 2,
                                                      color: Colors.black54,
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 32),
                                              SizedBox(
                                                width: 220,
                                                height: 56,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 8,
                                                    shadowColor: Colors.black
                                                        .withOpacity(0.3),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    // Сохраняем контекст для использования после async операций
                                                    final navigator =
                                                        Navigator.of(context);
                                                    final scaffoldMessenger =
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        );

                                                    final authProvider =
                                                        Provider.of<
                                                          AuthProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        );
                                                    final userUuid =
                                                        authProvider.userUuid;
                                                    if (userUuid == null) {
                                                      if (!mounted) return;
                                                      scaffoldMessenger
                                                          .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Ошибка: не найден userUuid',
                                                              ),
                                                            ),
                                                          );
                                                      return;
                                                    }
                                                    if (!mounted) return;
                                                    setState(() {
                                                      isLoading = true;
                                                    });

                                                    String? error;
                                                    Map<String, dynamic>?
                                                    userData;

                                                    try {
                                                      final userProgramUuid =
                                                          await ProgramService.addUserProgram(
                                                            widget.programUuid,
                                                            userUuid,
                                                            null, // caption будет получен автоматически из программы
                                                          );

                                                      if (userProgramUuid !=
                                                          null) {
                                                        // После успешного добавления — проверяем активность
                                                        final queryParams = {
                                                          'user_uuid': userUuid,
                                                          'program_uuid': widget
                                                              .programUuid,
                                                          'status': 'active',
                                                        };
                                                        final checkResponse =
                                                            await ApiService.get(
                                                              '/user_programs/',
                                                              queryParams:
                                                                  queryParams,
                                                            );
                                                        if (checkResponse
                                                                .statusCode ==
                                                            200) {
                                                          final data =
                                                              ApiService.decodeJson(
                                                                checkResponse
                                                                    .body,
                                                              );
                                                          if (data is List &&
                                                              data.isNotEmpty) {
                                                            userData =
                                                                data.first;
                                                          }
                                                        }
                                                      } else {
                                                        error =
                                                            'Ошибка запуска программы';
                                                      }
                                                    } catch (e) {
                                                      error = 'Ошибка: $e';
                                                    }

                                                    // Проверяем mounted перед использованием контекста
                                                    if (!mounted) return;

                                                    setState(() {
                                                      isLoading = false;
                                                    });

                                                    if (userData != null) {
                                                      // Навигация в самом конце
                                                      navigator.pushReplacement(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ActiveTrainingScreen(
                                                                userProgramData:
                                                                    userData!,
                                                              ),
                                                        ),
                                                      );
                                                    } else if (error != null) {
                                                      scaffoldMessenger
                                                          .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                error,
                                                              ),
                                                            ),
                                                          );
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Начать программу',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
