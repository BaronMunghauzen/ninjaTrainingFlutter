import 'package:flutter/material.dart';
import '../../services/program_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'active_training_screen.dart';
import '../../services/api_service.dart';
import 'weeks_days_navigation.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_back_button.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

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
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programData == null
          ? const Center(child: Text('Не удалось загрузить программу'))
          : TexturedBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    // Заголовок и кнопка назад
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NinjaSpacing.lg,
                        vertical: NinjaSpacing.md,
                      ),
                      child: Row(
                        children: [
                          const MetalBackButton(),
                          const SizedBox(width: NinjaSpacing.md),
                          Expanded(
                            child: Text('Программа', style: NinjaText.title),
                          ),
                        ],
                      ),
                    ),
                    // Контент
                    Expanded(
                      child: Column(
                        children: [
                          // Навигация по неделям и дням сверху
                          Container(
                            margin: const EdgeInsets.all(16),
                            child: MetalCard(
                              child: WeeksDaysNavigation(
                                weeksCount: 4,
                                daysCount: 7,
                              ),
                            ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Информация и кнопка по центру
                                          Center(
                                            child: MetalCard(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    programData!['caption'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Описание в контейнере со стилем MetalCardList
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF202020,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      programData!['description'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 32),
                                                  SizedBox(
                                                    width: 220,
                                                    child: MetalButton(
                                                      label: 'Начать программу',
                                                      onPressed: () async {
                                                        // Сохраняем контекст для использования после async операций
                                                        final navigator =
                                                            Navigator.of(
                                                              context,
                                                            );
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
                                                            authProvider
                                                                .userUuid;
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
                                                                widget
                                                                    .programUuid,
                                                                userUuid,
                                                                null, // caption будет получен автоматически из программы
                                                              );

                                                          if (userProgramUuid !=
                                                              null) {
                                                            // После успешного добавления — проверяем активность
                                                            final queryParams = {
                                                              'user_uuid':
                                                                  userUuid,
                                                              'program_uuid':
                                                                  widget
                                                                      .programUuid,
                                                              'status':
                                                                  'active',
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
                                                              if (data
                                                                      is List &&
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
                                                        } else if (error !=
                                                            null) {
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
              ),
            ),
    );
  }
}
