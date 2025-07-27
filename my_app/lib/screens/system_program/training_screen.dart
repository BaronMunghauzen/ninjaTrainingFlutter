import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/program_model.dart';
import '../../services/program_service.dart';
import 'active_training_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin_program_constructor/program_constructor_screen.dart';
import 'inactive_training_screen.dart';
import '../../services/api_service.dart';
import 'system_training_list_widget.dart'; // Added import for SystemTrainingListWidget
import '../../screens/admin_training_constructor/admin_training_constructor_screen.dart'; // Added import for AdminTrainingConstructorScreen
import '../my_training/my_training_list_widget.dart'; // Added import for MyTrainingListWidget

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  List<Program> programs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programsList = await ProgramService.getActualPrograms();
      setState(() {
        programs = programsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading programs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<ImageProvider?> _loadProgramImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      final response = await ApiService.get('/files/file/$imageUuid');
      if (response.statusCode == 200) {
        return MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ninja',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Training',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Spacer убираем, чтобы контент был выше
                      SizedBox(height: 200), // Аккуратный отступ сверху
                      // Текстовое поле поиска
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
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
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Кнопка "Разминка"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Замокать действие разминки
                            print('Разминка нажата');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Разминка',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
                                  authProvider.userProfile?.isAdmin ?? false;
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
                                        final found = userPrograms.firstWhere(
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
                                        program.imageUuid,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                      BorderRadius.circular(12),
                                                  child: ColorFiltered(
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                          Colors.black
                                                              .withOpacity(0.5),
                                                          BlendMode.darken,
                                                        ),
                                                    child: Image(
                                                      image: image,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Text(
                                                    program.caption,
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
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
                                  authProvider.userProfile?.isAdmin ?? false;
                              if (!isAdmin) return const SizedBox.shrink();
                              return IconButton(
                                icon: const Icon(Icons.build),
                                tooltip: 'Конструктор тренировок',
                                color: AppColors.textPrimary,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminTrainingConstructorScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 140,
                        child:
                            SystemTrainingListWidget(), // TODO: реализовать виджет
                      ),
                      // Новый блок "Мои тренировки"
                      const SizedBox(height: 32),
                      MyTrainingListWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
