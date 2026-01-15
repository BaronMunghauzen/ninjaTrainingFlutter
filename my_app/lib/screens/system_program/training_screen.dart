import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/system_training_list_widget.dart'; // Added import for SystemTrainingListWidget
import '../../screens/admin_training_constructor/admin_training_constructor_screen.dart'; // Added import for AdminTrainingConstructorScreen
import '../my_training/my_training_list_widget.dart'; // Added import for MyTrainingListWidget
import 'dart:async';
import '../system_training/active_system_training_screen.dart'; // Added import for ActiveSystemTrainingScreen
import '../system_training/system_training_detail_screen.dart'; // Added import for SystemTrainingDetailScreen
import '../user_training_constructor/exercise_reference_card_screen.dart';
import '../free_workout/free_workout_screen.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

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

  // Свободная тренировка: активная
  Map<String, dynamic>?
  _activeFreeUserTraining; // { user_training_uuid, training_uuid }

  Future<void> _loadActiveFreeTraining() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;
      if (userUuid == null) return;
      final resp = await ApiService.get(
        '/user_trainings/active/userFree/$userUuid',
      );
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          final training = first['training'] as Map<String, dynamic>?;
          setState(() {
            _activeFreeUserTraining = {
              'user_training_uuid': first['uuid'],
              'training_uuid': training != null ? training['uuid'] : null,
            };
          });
        } else {
          setState(() {
            _activeFreeUserTraining = null;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _loadActiveFreeTraining();
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
            ExerciseReferenceCardScreen(
              exerciseReferenceUuid: exercise.uuid,
            ),
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
      'training_type': training.trainingType,
      'difficulty_level':
          null, // Поля могут отсутствовать в модели Training из search_result_model
      'duration': null,
      'muscle_group': null,
      'image_uuid': training.image is Map
          ? training.image['uuid']
          : (training.image is String ? training.image : null),
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

  Future<void> _startNewFreeTrainingFlow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден userUuid')),
      );
      return;
    }
    // Запрашиваем название через MetalModal
    final name = await MetalModal.show<String>(
      context: context,
      title: 'Новая тренировка',
      children: [const _FreeTrainingNameModalContent()],
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      // Запрос 1: создать training
      final body1 = {
        'training_type': 'userFree',
        'user_uuid': userUuid,
        'caption': name.trim(),
        'description': 'Свободная тренировка',
        'difficulty_level': 1,
        'duration': 1,
        'order': 0,
        'muscle_group': 'Свободная тренировка',
        'stage': 0,
        'actual': true,
      };
      final resp1 = await ApiService.post('/trainings/add/', body: body1);
      if (resp1.statusCode != 200)
        throw Exception('Не удалось создать тренировку');
      final tr = ApiService.decodeJson(resp1.body);
      final trainingUuid = tr['uuid'];

      // Запрос 2: создать user_training
      final today = DateTime.now().toIso8601String().split('T')[0];
      final body2 = {
        'training_uuid': trainingUuid,
        'user_uuid': userUuid,
        'training_date': today,
        'status': 'ACTIVE',
        'is_rest_day': false,
      };
      final resp2 = await ApiService.post('/user_trainings/add/', body: body2);
      if (resp2.statusCode != 200)
        throw Exception('Не удалось создать user_training');
      final ut = ApiService.decodeJson(resp2.body);
      final userTrainingUuid = ut['uuid'];

      // Открываем экран свободной тренировки
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FreeWorkoutScreen(
            userTrainingUuid: userTrainingUuid,
            trainingUuid: trainingUuid,
          ),
        ),
      );

      // Обновляем состояние кнопки
      _loadActiveFreeTraining();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания тренировки: $e')));
    }
  }

  Future<void> _continueFreeTrainingFlow() async {
    final data = _activeFreeUserTraining;
    if (data == null) return;
    final userTrainingUuid = data['user_training_uuid'];
    final trainingUuid = data['training_uuid'];
    if (userTrainingUuid == null || trainingUuid == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FreeWorkoutScreen(
          userTrainingUuid: userTrainingUuid,
          trainingUuid: trainingUuid,
        ),
      ),
    );
    _loadActiveFreeTraining();
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
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: Stack(
          children: [
            // Верхний слой: training_background.png с градиентами
            Positioned.fill(
              child: Container(
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
                      image: AssetImage(
                        'assets/images/training_background.png',
                      ),
                      fit: BoxFit
                          .contain, // Картинка уменьшается, а не обрезается
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
                  ),
                ),
              ),
            ),
            // Контент поверх фонов
            SafeArea(
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
                                    color: Color(0xE6B5BF94).withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xE6B5BF94).withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xE6B5BF94).withOpacity(0.3),
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
                                                  color: Color(
                                                    0xE6B5BF94,
                                                  ).withOpacity(0.3),
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
                          const SizedBox(height: 65),
                        ],
                      ),
                    ),
                  ),
                  // Плавающая кнопка свободной тренировки над контентом
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Builder(
                      builder: (context) {
                        final hasActive = _activeFreeUserTraining != null;
                        return MetalButton(
                          label: hasActive
                              ? 'Продолжить свободную тренировку'
                              : 'Начать свободную тренировку',
                          onPressed: () async {
                            if (hasActive) {
                              await _continueFreeTrainingFlow();
                            } else {
                              await _startNewFreeTrainingFlow();
                            }
                          },
                          height: 56,
                        );
                      },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для содержимого модального окна создания свободной тренировки
class _FreeTrainingNameModalContent extends StatefulWidget {
  const _FreeTrainingNameModalContent();

  @override
  State<_FreeTrainingNameModalContent> createState() =>
      _FreeTrainingNameModalContentState();
}

class _FreeTrainingNameModalContentState
    extends State<_FreeTrainingNameModalContent> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetalTextField(
          controller: _nameController,
          hint: 'Например: Тренировка ног',
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
        ),
        const SizedBox(height: NinjaSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                if (!mounted) return;
                FocusScope.of(context).unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text('Отмена', style: NinjaText.body),
              ),
            ),
            const SizedBox(width: NinjaSpacing.md),
            MetalButton(
              label: 'Создать',
              onPressed: () {
                if (!mounted) return;
                FocusScope.of(context).unfocus();
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  if (mounted) {
                    MetalMessage.show(
                      context: context,
                      message: 'Введите название тренировки',
                      type: MetalMessageType.error,
                    );
                  }
                  return;
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop(name);
                  }
                });
              },
              height: 48,
            ),
          ],
        ),
      ],
    );
  }
}
