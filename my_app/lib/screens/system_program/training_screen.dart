import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/program_model.dart';
import '../../models/search_result_model.dart';
import '../../services/program_service.dart';
import '../../services/search_service.dart';
import 'active_training_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin_program_constructor/program_constructor_screen.dart';
import 'inactive_training_screen.dart';
import '../../services/api_service.dart';
import 'system_training_list_widget.dart'; // Added import for SystemTrainingListWidget
import '../../screens/admin_training_constructor/admin_training_constructor_screen.dart'; // Added import for AdminTrainingConstructorScreen
import '../my_training/my_training_list_widget.dart'; // Added import for MyTrainingListWidget
import 'dart:async';
import '../system_training/active_system_training_screen.dart'; // Added import for ActiveSystemTrainingScreen
import '../system_training/system_training_detail_screen.dart'; // Added import for SystemTrainingDetailScreen
import '../user_training_constructor/user_exercise_reference_detail_screen.dart';
import '../free_workout/free_workout_screen.dart';
import '../free_workout/free_training_name_modal.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  List<Program> programs = [];
  bool isLoading = true;

  // Состояние для поиска
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchFieldKey = GlobalKey();
  Timer? _searchTimer;
  SearchResult? _searchResult;
  bool _isSearching = false;
  bool _showSearchResults = false;
  double _searchFieldBottomPosition = 0;

  // Счетчик для принудительного обновления SystemTrainingListWidget
  int _systemTrainingRefreshCounter = 0;

  // Состояние для свободной тренировки
  bool _isCheckingFreeTraining = true;
  Map<String, dynamic>? _activeFreeTraining;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _checkActiveFreeTraining();
  }

  Future<void> _checkActiveFreeTraining() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() => _isCheckingFreeTraining = false);
        return;
      }

      final response = await ApiService.get(
        '/user_trainings/active/userFree/$userUuid',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final List trainings = data ?? [];

        setState(() {
          _activeFreeTraining = trainings.isNotEmpty ? trainings[0] : null;
          _isCheckingFreeTraining = false;
        });
      } else {
        setState(() => _isCheckingFreeTraining = false);
      }
    } catch (e) {
      print('Error checking active free training: $e');
      setState(() => _isCheckingFreeTraining = false);
    }
  }

  Future<void> _startNewFreeTraining() async {
    // Показываем модалку для ввода названия
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const FreeTrainingNameModal(),
    );

    if (name == null || name.isEmpty) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: не найден userUuid')),
        );
        return;
      }

      // Запрос 1: POST /trainings/add/
      final trainingResponse = await ApiService.post(
        '/trainings/add/',
        body: {
          'training_type': 'userFree',
          'user_uuid': userUuid,
          'caption': name,
          'description': 'Свободная тренировка',
          'difficulty_level': 1,
          'duration': 1,
          'order': 0,
          'muscle_group': 'Свободная тренировка',
          'stage': 0,
          'actual': true,
        },
      );

      if (trainingResponse.statusCode != 200) {
        throw Exception('Failed to create training');
      }

      final trainingData = ApiService.decodeJson(trainingResponse.body);
      final trainingUuid = trainingData['uuid'];

      // Запрос 2: POST /user_trainings/add/
      final userTrainingResponse = await ApiService.post(
        '/user_trainings/add/',
        body: {
          'training_uuid': trainingUuid,
          'user_uuid': userUuid,
          'training_date': DateTime.now().toIso8601String().split('T')[0],
          'status': 'ACTIVE',
          'is_rest_day': false,
        },
      );

      if (userTrainingResponse.statusCode != 200) {
        throw Exception('Failed to create user training');
      }

      final userTrainingData = ApiService.decodeJson(userTrainingResponse.body);
      final userTrainingUuid = userTrainingData['uuid'];

      // Переходим на экран свободной тренировки
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FreeWorkoutScreen(
              userTrainingUuid: userTrainingUuid,
              trainingUuid: trainingUuid,
            ),
          ),
        );

        if (result == true) {
          // Обновляем после завершения тренировки
          _checkActiveFreeTraining();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания тренировки: $e')),
        );
      }
    }
  }

  Future<void> _continueFreeTraining() async {
    if (_activeFreeTraining == null) return;

    final userTrainingUuid = _activeFreeTraining!['uuid'];
    final trainingUuid = _activeFreeTraining!['training']?['uuid'];

    if (userTrainingUuid == null || trainingUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найдены данные тренировки')),
      );
      return;
    }

    // Переходим на экран свободной тренировки
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FreeWorkoutScreen(
          userTrainingUuid: userTrainingUuid,
          trainingUuid: trainingUuid,
        ),
      ),
    );

    if (result == true) {
      // Обновляем после завершения тренировки
      _checkActiveFreeTraining();
    }
  }

  Future<void> _loadPrograms() async {
    print('TrainingScreen: Загружаем программы...');
    try {
      final programsList = await ProgramService.getActualPrograms();
      // Отладочная информация
      for (final program in programsList) {
        print(
          'Program ${program.caption}: imageUuid=${program.imageUuid} (type: ${program.imageUuid.runtimeType})',
        );
      }
      if (mounted) {
        setState(() {
          programs = programsList;
          isLoading = false;
        });
      }
    } on NetworkException catch (e) {
      print('Network error loading programs: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error loading programs: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSystemTrainings() async {
    print('TrainingScreen: Обновляем системные тренировки...');
    // Принудительно обновляем SystemTrainingListWidget через setState
    setState(() {
      _systemTrainingRefreshCounter++;
    });
  }

  Future<ImageProvider?> _loadProgramImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      // Используем новый метод кэширования
      return await ApiService.getImageProvider(imageUuid);
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
  }

  String? _getImageUuid(String? imageUuid) {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    return imageUuid;
  }

  void _calculateSearchFieldPosition() {
    final RenderBox? renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      print('🔍 Search field position: ${position.dy}');
      print('🔍 Search field height: ${size.height}');
      print('🔍 Bottom position: ${position.dy + size.height}');
      setState(() {
        _searchFieldBottomPosition = position.dy + size.height;
      });
    }
  }

  void _performSearch(String query) async {
    print('_performSearch called with query: "$query"');
    if (query.trim().isEmpty) {
      print('Query is empty, clearing results');
      setState(() {
        _searchResult = null;
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;

    if (userUuid == null) {
      print('User UUID not found');
      return;
    }

    print('Starting search for userUuid: $userUuid');
    setState(() {
      _isSearching = true;
    });

    try {
      final result = await SearchService.search(userUuid, query.trim());
      print('Search result received: $result');
      print(
        'Search result exerciseReferences: ${result?.exerciseReferences.length}',
      );
      print('Search result programs: ${result?.programs.length}');
      print('Search result trainings: ${result?.trainings.length}');

      if (mounted) {
        // Рассчитываем позицию поисковой строки перед показом результатов
        _calculateSearchFieldPosition();
        setState(() {
          _searchResult = result;
          _showSearchResults = true;
          _isSearching = false;
        });
        print(
          'State updated: _showSearchResults = $_showSearchResults, _searchResult = $_searchResult',
        );
      }
    } on NetworkException catch (e) {
      print('Network error during search: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    // Отменяем предыдущий таймер
    _searchTimer?.cancel();

    // Создаем новый таймер на 1 секунду
    _searchTimer = Timer(const Duration(seconds: 1), () {
      _performSearch(value);
    });
  }

  void _onSearchItemTap(dynamic item, String type) {
    switch (type) {
      case 'exercise_reference':
        if (item is ExerciseReference) {
          _navigateToExerciseReference(item);
        }
        break;
      case 'program':
        if (item is Program && item.programType == 'system') {
          _navigateToProgram(item);
        }
        break;
      case 'training':
        if (item is Training) {
          if (item.trainingType == 'system_training') {
            _navigateToSystemTraining(item);
          } else if (item.trainingType == 'user') {
            _navigateToUserTraining(item);
          }
        }
        break;
    }
  }

  void _navigateToExerciseReference(ExerciseReference exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            UserExerciseReferenceDetailScreen(exercise: exercise),
      ),
    );
  }

  void _navigateToProgram(Program program) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден userUuid')),
      );
      return;
    }

    final userProgramsResponse = await ProgramService.getUserPrograms(
      userUuid,
      programUuid: program.uuid,
    );
    bool isStarted = false;
    Map<String, dynamic>? userProgramData;
    if (userProgramsResponse != null && userProgramsResponse['status'] == 200) {
      final userPrograms = userProgramsResponse['data'] as List;
      final found = userPrograms.firstWhere(
        (up) => up['program']['uuid'] == program.uuid,
        orElse: () => null,
      );
      if (found != null) {
        isStarted = true;
        userProgramData = found as Map<String, dynamic>;
      }
    }

    if (isStarted && userProgramData != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ActiveTrainingScreen(userProgramData: userProgramData!),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              InactiveTrainingScreen(programUuid: program.uuid),
        ),
      );
    }
  }

  void _navigateToSystemTraining(Training training) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        'training_uuid': training.uuid,
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
            builder: (context) =>
                ActiveSystemTrainingScreen(userTraining: trainingsList[0]),
          ),
        );
        return;
      }
    }

    // Если нет активной тренировки — открываем карточку тренировки
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SystemTrainingDetailScreen(training: _trainingToMap(training)),
      ),
    );
  }

  Map<String, dynamic> _trainingToMap(Training training) {
    return {
      'uuid': training.uuid,
      'caption': training.caption,
      'description': training.description,
      'difficulty_level': null, // Добавьте если есть в Training
      'duration': null, // Добавьте если есть в Training
      'muscle_group': null, // Добавьте если есть в Training
      // Добавьте другие нужные поля из Training
    };
  }

  void _navigateToUserTraining(Training training) {
    // TODO: Реализовать навигацию к пользовательской тренировке
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Навигация к пользовательской тренировке в разработке'),
        backgroundColor: Color(0xFF1F2121),
      ),
    );
  }

  Widget _buildSearchSection(String title, List<dynamic> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => _buildSearchItem(item, type)).toList(),
      ],
    );
  }

  Widget _buildSearchItem(dynamic item, String type) {
    String caption = '';
    if (item is ExerciseReference) {
      caption = item.caption;
    } else if (item is Program) {
      caption = item.caption;
    } else if (item is Training) {
      caption = item.caption;
    }

    return GestureDetector(
      onTap: () => _onSearchItemTap(item, type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.inputBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                caption,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Очистка ресурсов при удалении виджета
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.background],
            stops: [0.0, 0.9], // Еще более плавный градиент
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/training_background.png'),
              fit: BoxFit.contain, // Картинка уменьшается, а не обрезается
              alignment: Alignment.topCenter,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
                stops: [
                  0.2,
                  1.0,
                ], // Градиент начинается с 20% для более плавного перехода
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Основной контент страницы
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Логотип "Ninja Training"
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 200),
                          // Поле поиска (без Stack)
                          Container(
                            key: _searchFieldKey,
                            width: double.infinity,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onTap: () {
                                // Пересчитываем позицию при нажатии на поле
                                _calculateSearchFieldPosition();
                              },
                              decoration: InputDecoration(
                                hintText: 'Поиск',
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.inputFocused,
                                    width: 2,
                                  ),
                                ),
                                hintStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textSecondary,
                                        ),
                                      )
                                    : _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResult = null;
                                            _showSearchResults = false;
                                            _isSearching = false;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Заголовок "Программы" с кнопкой "Конструктор" для администратора
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Программы',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  final isAdmin =
                                      authProvider.userProfile?.isAdmin ??
                                      false;
                                  if (!isAdmin) return const SizedBox.shrink();
                                  return IconButton(
                                    icon: const Icon(Icons.build),
                                    tooltip: 'Конструктор программ',
                                    color: AppColors.textPrimary,
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProgramConstructorScreen(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Карусель программ
                          SizedBox(
                            height: 140, // Фиксированная высота блока программ
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : programs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Программы не найдены',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: programs.length,
                                    itemBuilder: (context, index) {
                                      final program = programs[index];
                                      return GestureDetector(
                                        onTap: () async {
                                          final authProvider =
                                              Provider.of<AuthProvider>(
                                                context,
                                                listen: false,
                                              );
                                          final userUuid =
                                              authProvider.userUuid;
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
                                          final userProgramsResponse =
                                              await ProgramService.getUserPrograms(
                                                userUuid,
                                                programUuid: program.uuid,
                                              );
                                          bool isStarted = false;
                                          Map<String, dynamic>? userProgramData;
                                          if (userProgramsResponse != null &&
                                              userProgramsResponse['status'] ==
                                                  200) {
                                            final userPrograms =
                                                userProgramsResponse['data']
                                                    as List;
                                            final found = userPrograms
                                                .firstWhere(
                                                  (up) =>
                                                      up['program']['uuid'] ==
                                                      program.uuid,
                                                  orElse: () => null,
                                                );
                                            if (found != null) {
                                              isStarted = true;
                                              userProgramData =
                                                  found as Map<String, dynamic>;
                                            }
                                          }
                                          if (isStarted &&
                                              userProgramData != null) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ActiveTrainingScreen(
                                                      userProgramData:
                                                          userProgramData!,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    InactiveTrainingScreen(
                                                      programUuid: program.uuid,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        child: FutureBuilder<ImageProvider?>(
                                          future: _loadProgramImage(
                                            _getImageUuid(program.imageUuid),
                                          ),
                                          builder: (context, snapshot) {
                                            final image = snapshot.data;
                                            return Container(
                                              width: 140,
                                              height: 140,
                                              margin: const EdgeInsets.only(
                                                right: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.inputBorder,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (image != null)
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: ColorFiltered(
                                                        colorFilter:
                                                            ColorFilter.mode(
                                                              Colors.black
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                              BlendMode.darken,
                                                            ),
                                                        child: Image(
                                                          image: image,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    bottom: 15,
                                                    left: 8,
                                                    right: 8,
                                                    child: Text(
                                                      program.caption,
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ), // Конец блока программ
                          // Новый блок "Тренировки" (system_training)
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Тренировки',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  final isAdmin =
                                      authProvider.userProfile?.isAdmin ??
                                      false;
                                  if (!isAdmin) return const SizedBox.shrink();
                                  return IconButton(
                                    icon: const Icon(Icons.build),
                                    tooltip: 'Конструктор тренировок',
                                    color: AppColors.textPrimary,
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminTrainingConstructorScreen(
                                                onDataChanged: () {
                                                  // Обновляем данные на странице тренировок
                                                  print(
                                                    'TrainingScreen: Получен callback от AdminTrainingConstructorScreen',
                                                  );
                                                  _refreshSystemTrainings();
                                                },
                                              ),
                                        ),
                                      );
                                      // Обновляем данные после возврата
                                      _loadPrograms();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 140,
                            child: SystemTrainingListWidget(
                              key: ValueKey(_systemTrainingRefreshCounter),
                            ),
                          ),
                          // Новый блок "Мои тренировки"
                          const SizedBox(height: 32),
                          MyTrainingListWidget(
                            onDataChanged: () {
                              // Обновляем данные на странице тренировок
                              setState(() {
                                // Можно добавить дополнительную логику обновления
                              });
                            },
                          ),
                          // Добавляем отступ снизу для кнопок свободной тренировки
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  // Overlay с результатами поиска - теперь поверх всего
                  if (_showSearchResults && _searchResult != null) ...[
                    // Полупрозрачный фон для закрытия по клику
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSearchResults = false;
                          });
                        },
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                    ),
                    // Результаты поиска
                    Positioned(
                      top:
                          _searchFieldBottomPosition -
                          15, // Отрицательный отступ для наложения
                      left: 24,
                      right: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.inputBorder,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_searchResult!
                                    .exerciseReferences
                                    .isNotEmpty) ...[
                                  _buildSearchSection(
                                    'Упражнения',
                                    _searchResult!.exerciseReferences,
                                    'exercise_reference',
                                  ),
                                ],
                                if (_searchResult!.programs.isNotEmpty) ...[
                                  _buildSearchSection(
                                    'Программы',
                                    _searchResult!.programs,
                                    'program',
                                  ),
                                ],
                                if (_searchResult!.trainings.isNotEmpty) ...[
                                  _buildSearchSection(
                                    'Тренировки',
                                    _searchResult!.trainings,
                                    'training',
                                  ),
                                ],
                                if (_searchResult!.exerciseReferences.isEmpty &&
                                    _searchResult!.programs.isEmpty &&
                                    _searchResult!.trainings.isEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'По вашему запросу ничего не найдено',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Кнопки свободной тренировки - всегда внизу экрана
                  if (!_isCheckingFreeTraining)
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom:
                          10, // Близко к нижнему краю (безопасно - SafeArea активен)
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _activeFreeTraining == null
                              ? _startNewFreeTraining
                              : _continueFreeTraining,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _activeFreeTraining == null
                                ? 'Начать новую тренировку'
                                : 'Продолжить свободную тренировку',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
