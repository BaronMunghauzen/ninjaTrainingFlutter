import 'package:flutter/material.dart';
import '../../services/program_service.dart';
import 'program_edit_screen.dart';
import 'admin_training_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/avatar_modal.dart';
import 'package:http_parser/http_parser.dart';
import 'admin_training_create_screen.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;

class ProgramAdminDetailScreen extends StatefulWidget {
  final String programUuid;
  const ProgramAdminDetailScreen({Key? key, required this.programUuid})
    : super(key: key);

  @override
  State<ProgramAdminDetailScreen> createState() =>
      _ProgramAdminDetailScreenState();
}

class _ProgramAdminDetailScreenState extends State<ProgramAdminDetailScreen> {
  Map<String, dynamic>? programData;
  List<dynamic> trainings = [];
  bool isLoading = true;
  bool isDeleting = false;

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
      final trainingsList = await _fetchTrainings(widget.programUuid);
      setState(() {
        programData = program?.toJson();
        trainings = trainingsList;
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

  Future<List<dynamic>> _fetchTrainings(String programUuid) async {
    try {
      final queryParams = {'program_uuid': programUuid};
      final response = await ApiService.get(
        '/trainings/',
        queryParams: queryParams,
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching trainings: $e');
      return [];
    }
  }

  // Показать сообщение о невозможности удаления
  void _showCannotDeleteMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Удаление невозможно - в программе есть тренировки'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Редактировать программу
  void _editProgram() {
    if (programData == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ProgramEditScreen(
              programUuid: widget.programUuid,
              initialData: programData!,
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            // Обновляем данные после редактирования
            _loadData();
          }
        });
  }

  // Открыть детали тренировки
  void _openTrainingDetail(Map<String, dynamic> training) {
    print(
      '[program_admin_detail] _openTrainingDetail: trainingUuid=${training['uuid']}',
    );
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AdminTrainingDetailScreen(
              trainingUuid: training['uuid'],
              trainingData: training,
            ),
          ),
        )
        .then((result) {
          print('[program_admin_detail] _openTrainingDetail: result=$result');
          if (result == true) {
            // Обновляем данные после удаления тренировки
            _loadData();
          }
        });
  }

  // Добавить тренировку
  void _addTraining(int dayOfWeek) {
    print(
      '[program_admin_detail] _addTraining: dayOfWeek=$dayOfWeek, programUuid=${widget.programUuid}',
    );
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                TrainingCreateScreen(programUuid: widget.programUuid),
          ),
        )
        .then((result) {
          print('[program_admin_detail] _addTraining: result=$result');
          if (result == true) {
            // Обновляем данные после создания тренировки
            _loadData();
          }
        });
  }

  Future<void> _deleteProgram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить программу?'),
        content: const Text('Вы уверены, что хотите удалить эту программу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      isDeleting = true;
    });
    try {
      final response = await ApiService.delete(
        '/programs/delete/${widget.programUuid}',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    } finally {
      setState(() {
        isDeleting = false;
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

  Future<void> _uploadProgramImage(String programUuid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    try {
      // Определяем mime-type
      final ext = picked.path.split('.').last.toLowerCase();
      String? mimeType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = null;
      }
      if (mimeType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поддерживаются только JPG, PNG, GIF, WEBP'),
          ),
        );
        return;
      }

      final response = await ApiService.multipart(
        '/programs/$programUuid/upload-image',
        fileField: 'file',
        filePath: picked.path,
        mimeType: mimeType,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки фото: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
    }
  }

  Future<void> _deleteProgramImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return;
    try {
      final response = await ApiService.delete('/files/file/$imageUuid');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления фото: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления фото: $e')));
    }
  }

  void _showImageModal(String? imageUuid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarModal(
        hasAvatar: imageUuid != null && imageUuid.isNotEmpty,
        onUploadPhoto: () => _uploadProgramImage(widget.programUuid),
        onDeletePhoto: imageUuid != null && imageUuid.isNotEmpty
            ? () => _deleteProgramImage(imageUuid)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];

    // Парсим training_days один раз
    List<int> trainingDaysList = [];
    if (programData != null && programData!['training_days'] != null) {
      try {
        final daysString = programData!['training_days']
            .replaceAll('[', '')
            .replaceAll(']', '');
        trainingDaysList = daysString
            .split(',')
            .map((e) => int.parse(e.trim()))
            .toList()
            .cast<int>();
      } catch (e) {
        print('Ошибка парсинга training_days: $e');
        trainingDaysList = [];
      }
    }

    // Группируем тренировки по stage один раз
    final groupedTrainings = <int, List<dynamic>>{};
    for (final training in trainings) {
      final stage = training['stage'] as int? ?? 0;
      if (!groupedTrainings.containsKey(stage)) {
        groupedTrainings[stage] = [];
      }
      groupedTrainings[stage]!.add(training);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Программа'),
        actions: [
          // Кнопка редактирования
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () => _editProgram(),
          ),
          // Кнопка удаления (заблокирована если есть тренировки)
          IconButton(
            icon: isDeleting
                ? const CircularProgressIndicator()
                : Icon(
                    Icons.delete,
                    color: trainings.isNotEmpty ? Colors.grey : null,
                  ),
            tooltip: trainings.isNotEmpty
                ? 'Удаление невозможно - в программе есть тренировки'
                : 'Удалить',
            onPressed: isDeleting
                ? null
                : trainings.isNotEmpty
                ? _showCannotDeleteMessage
                : _deleteProgram,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : programData == null
          ? const Center(child: Text('Не удалось загрузить программу'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: FutureBuilder<ImageProvider?>(
                        future: _loadProgramImage(programData?['image_uuid']),
                        builder: (context, snapshot) {
                          final image = snapshot.data;
                          return GestureDetector(
                            onTap: () =>
                                _showImageModal(programData?['image_uuid']),
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 2,
                                ),
                                image: image != null
                                    ? DecorationImage(
                                        image: image,
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.5),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                              ),
                              child: image == null
                                  ? const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 48,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    Text(
                      programData!['caption'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      programData!['description'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сложность: ${programData!['difficulty_level'] ?? '-'}',
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // 7 блоков по дням недели
                    ...List.generate(7, (i) {
                      final dayName = days[i];
                      List<dynamic> dayTrainings = [];

                      // Проверяем, есть ли тренировки в этот день
                      final dayOfWeek = i + 1;
                      if (trainingDaysList.contains(dayOfWeek)) {
                        // Получаем позицию дня в списке тренировочных дней
                        final dayIndex = trainingDaysList.indexOf(dayOfWeek);

                        // Собираем тренировки для этого дня из всех stage
                        final sortedStages = groupedTrainings.keys.toList()
                          ..sort();
                        for (final stage in sortedStages) {
                          final stageTrainings = groupedTrainings[stage]!;
                          if (dayIndex < stageTrainings.length) {
                            dayTrainings.add(stageTrainings[dayIndex]);
                          }
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () => _addTraining(dayOfWeek),
                                    tooltip: 'Добавить тренировку',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (dayTrainings.isEmpty)
                                const Text('Нет тренировок'),
                              ...dayTrainings.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: InkWell(
                                    onTap: () => _openTrainingDetail(t),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Этап ${t['stage'] ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              t['caption'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${t['duration'] ?? 0} мин',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
