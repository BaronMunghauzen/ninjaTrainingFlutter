import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/gif_widget.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_spacing.dart';
import 'user_exercise_group_create_screen.dart';
import 'user_exercise_group_detail_screen.dart';
import 'user_training_edit_screen.dart';

class UserTrainingDetailScreen extends StatefulWidget {
  final Training training;
  final VoidCallback? onDataChanged;

  const UserTrainingDetailScreen({
    super.key,
    required this.training,
    this.onDataChanged,
  });

  @override
  State<UserTrainingDetailScreen> createState() =>
      _UserTrainingDetailScreenState();
}

class _UserTrainingDetailScreenState extends State<UserTrainingDetailScreen> {
  late Training _training;
  List<ExerciseGroup> exerciseGroups = [];
  Map<String, Map<String, dynamic>> exerciseData =
      {}; // UUID группы -> данные упражнения
  Map<String, Map<String, dynamic>> exerciseReferenceData =
      {}; // UUID группы -> данные exercise_reference
  bool isLoading = true;
  String? _imageUuid; // UUID изображения тренировки
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _training = widget.training;
    _imageUuid = _training.imageUuid; // Инициализируем UUID изображения
    _loadExerciseGroups();
  }

  Future<void> _loadExerciseGroups() async {
    try {
      final groups = await UserTrainingService.getExerciseGroupsForTraining(
        _training.uuid,
      );

      // Загружаем данные для каждого упражнения в группах
      Map<String, Map<String, dynamic>> exerciseDataMap = {};
      Map<String, Map<String, dynamic>> exerciseReferenceDataMap = {};
      for (final group in groups) {
        if (group.exercises.isNotEmpty) {
          try {
            final response = await ApiService.get(
              '/exercises/${group.exercises.first}',
            );
            if (response.statusCode == 200) {
              final data = ApiService.decodeJson(response.body);
              exerciseDataMap[group.uuid] = data;

              // Загружаем данные exercise_reference
              final exerciseReferenceUuid = data['exercise_reference_uuid'];
              if (exerciseReferenceUuid != null) {
                try {
                  final refResponse = await ApiService.get(
                    '/exercise_reference/$exerciseReferenceUuid',
                  );
                  if (refResponse.statusCode == 200) {
                    final refData = ApiService.decodeJson(refResponse.body);
                    exerciseReferenceDataMap[group.uuid] = refData;
                  }
                } catch (e) {
                  print('Error loading exercise reference for group ${group.uuid}: $e');
                }
              }
            }
          } catch (e) {
            print('Error loading exercise data for group ${group.uuid}: $e');
            // Устанавливаем значения по умолчанию
            exerciseDataMap[group.uuid] = {
              'sets_count': 3,
              'reps_count': 12,
              'rest_time': 60,
              'with_weight': true,
            };
          }
        }
      }

      setState(() {
        exerciseGroups = groups;
        exerciseData = exerciseDataMap;
        exerciseReferenceData = exerciseReferenceDataMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading exercise groups: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Обновляет данные тренировки после редактирования
  Future<void> _refreshTrainingData() async {
    try {
      final updatedTraining = await UserTrainingService.getUserTrainingByUuid(
        _training.uuid,
      );

      if (updatedTraining != null) {
        setState(() {
          // Обновляем локальную переменную состояния
          _training = updatedTraining;
          _imageUuid = _training.imageUuid;
        });
      }
    } catch (e) {
      print('Error refreshing training data: $e');
    }
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      setState(() {
        _isUploadingImage = true;
      });

      // Определяем MIME тип
      final fileExtension = image.path.split('.').last.toLowerCase();
      String? mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      final response = await ApiService.multipart(
        '/trainings/${_training.uuid}/upload-image',
        fileField: 'file',
        filePath: image.path,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = ApiService.decodeJson(response.body);
        if (responseData['image_uuid'] != null) {
          setState(() {
            _imageUuid = responseData['image_uuid'];
          });
          MetalMessage.show(
            context: context,
            message: 'Изображение успешно загружено',
            type: MetalMessageType.success,
            title: 'Успешно',
          );
        } else {
          MetalMessage.show(
            context: context,
            message: 'Ошибка: не получен UUID изображения',
            type: MetalMessageType.error,
            title: 'Ошибка',
          );
        }
      } else {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки изображения: ${response.statusCode}',
          type: MetalMessageType.error,
          title: 'Ошибка',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      MetalMessage.show(
        context: context,
        message: 'Ошибка: $e',
        type: MetalMessageType.error,
        title: 'Ошибка',
      );
    }
  }

  Future<void> _deleteImage() async {
    final confirm = await MetalModal.show<bool>(
      context: context,
      title: 'Удалить изображение?',
      children: [
        Text(
          'Вы уверены, что хотите удалить это изображение?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Удалить',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
                topColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete(
        '/trainings/${_training.uuid}/delete-image',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _imageUuid = null;
        });
        MetalMessage.show(
          context: context,
          message: 'Изображение успешно удалено',
          type: MetalMessageType.success,
          title: 'Успешно',
        );
      } else {
        MetalMessage.show(
          context: context,
          message: 'Ошибка удаления: ${response.statusCode}',
          type: MetalMessageType.error,
          title: 'Ошибка',
        );
      }
    } catch (e) {
      MetalMessage.show(
        context: context,
        message: 'Ошибка: $e',
        type: MetalMessageType.error,
        title: 'Ошибка',
      );
    }
  }

  Future<void> _handleImageTap() async {
    if (_imageUuid != null) {
      // Если есть изображение, показываем модалку для удаления
      await _deleteImage();
    } else {
      // Если нет изображения, загружаем
      await _uploadImage();
    }
  }

  Future<void> _archiveTraining() async {
    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Архивирование тренировки',
      children: [
        Text(
          'Вы уверены, что хотите архивировать эту тренировку?',
          style: NinjaText.body,
        ),
        const SizedBox(height: 8),
        Text(
          'После архивирования тренировка не будет отображаться на главной странице.',
          style: NinjaText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Архивировать',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed != true) return;

    final success = await UserTrainingService.archiveTraining(
      _training.uuid,
    );
    if (success) {
      widget.onDataChanged?.call();
      Navigator.of(context).pop();
    } else {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка при архивировании тренировки',
          type: MetalMessageType.error,
          title: 'Ошибка',
        );
      }
    }
  }

  Future<void> _restoreTraining() async {
    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Восстановление тренировки',
      children: [
        Text(
          'Вы уверены, что хотите восстановить эту тренировку из архива?',
          style: NinjaText.body,
        ),
        const SizedBox(height: 8),
        Text(
          'После восстановления тренировка станет видна на главной странице.',
          style: NinjaText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Восстановить',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed != true) return;

    final success = await UserTrainingService.restoreTraining(
      _training.uuid,
    );
    if (success) {
      widget.onDataChanged?.call();
      Navigator.of(context).pop();
    } else {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка при восстановлении тренировки',
          type: MetalMessageType.error,
          title: 'Ошибка',
        );
      }
    }
  }

  Widget _buildExerciseMedia(String? gifUuid, String? imageUuid) {
    // Приоритет: гифка -> картинка
    if (gifUuid != null && gifUuid.isNotEmpty) {
      return SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GifWidget(gifUuid: gifUuid, height: 60, width: 60),
        ),
      );
    }

    if (imageUuid != null && imageUuid.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AuthImageWidget(
          imageUuid: imageUuid,
          height: 60,
          width: 60,
          fit: BoxFit.cover,
        ),
      );
    }

    // Если нет медиа, показываем иконку
    return const SizedBox(
      width: 60,
      height: 60,
      child: Icon(
        Icons.fitness_center,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Верхняя панель с кнопкой назад, названием и кнопками действий
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const MetalBackButton(),
                        const SizedBox(width: NinjaSpacing.md),
                        Expanded(
                          child: Text(
                            _training.caption,
                            style: NinjaText.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: NinjaSpacing.md),
                        // Кнопка редактирования
                        MetalBackButton(
                          icon: Icons.edit,
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserTrainingEditScreen(training: _training),
                              ),
                            );
                            if (result == true) {
                              // Обновляем данные тренировки
                              await _refreshTrainingData();
                              // Обновляем список групп упражнений
                              _loadExerciseGroups();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Кнопка архивирования/восстановления
                        if (_training.actual)
                          MetalBackButton(
                            icon: Icons.archive,
                            onTap: _archiveTraining,
                          )
                        else
                          MetalBackButton(
                            icon: Icons.unarchive,
                            onTap: _restoreTraining,
                          ),
                      ],
                    ),
                  ),
                  // Контент
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Изображение тренировки
                      GestureDetector(
                        onTap: _handleImageTap,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.inputBorder.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: _isUploadingImage
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : _imageUuid != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: AuthImageWidget(
                                            imageUuid: _imageUuid!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Добавить изображение',
                                            style: NinjaText.body.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Описание
                      if (_training.description.isNotEmpty) ...[
                        Text(
                          _training.description,
                          style: NinjaText.body,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Группа мышц
                      if (_training.muscleGroup.isNotEmpty) ...[
                        Text(
                          'Группа мышц: ${_training.muscleGroup}',
                          style: NinjaText.caption,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Список групп упражнений
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                      else if (exerciseGroups.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'В этой тренировке пока нет упражнений',
                              style: NinjaText.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...exerciseGroups.asMap().entries.map((entry) {
                          final index = entry.key;
                          final group = entry.value;
                          final isFirst = index == 0;
                          final isLast = index == exerciseGroups.length - 1;

                          // Получаем медиа из exercise_reference
                          final refData = exerciseReferenceData[group.uuid];
                          String? gifUuid;
                          String? imageUuid;
                          
                          if (refData != null) {
                            final gif = refData['gif_uuid'] ?? refData['gif'];
                            final image = refData['image_uuid'] ?? refData['image'];
                            if (gif != null && gif.toString().isNotEmpty) {
                              gifUuid = gif.toString();
                            }
                            if (image != null && image.toString().isNotEmpty) {
                              imageUuid = image.toString();
                            }
                          }

                          return MetalListItem(
                            leading: _buildExerciseMedia(gifUuid, imageUuid),
                            title: Text(
                              group.caption,
                              style: NinjaText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Подходы: ${exerciseData[group.uuid]?['sets_count']?.toString() ?? '3'}, '
                              'Повторения: ${exerciseData[group.uuid]?['reps_count']?.toString() ?? '12'}, '
                              'Отдых: ${exerciseData[group.uuid]?['rest_time'] ?? 60}с',
                              style: NinjaText.caption,
                            ),
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserExerciseGroupDetailScreen(
                                    exerciseGroup: group,
                                    onDataChanged: () {
                                      // Обновляем данные на этой странице
                                      _loadExerciseGroups();
                                      // Вызываем callback родительской страницы
                                      widget.onDataChanged?.call();
                                    },
                                  ),
                                ),
                              );
                              // Обновляем данные после возврата
                              if (result == true) {
                                _loadExerciseGroups();
                              }
                            },
                            isFirst: isFirst,
                            isLast: isLast,
                            removeSpacing: true,
                          );
                        }),
                          const SizedBox(height: 80), // Отступ для кнопки внизу
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Кнопка добавления в правом нижнем углу
              Positioned(
                right: 24,
                bottom: 24,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: MetalButton(
                    label: '',
                    icon: Icons.add,
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserExerciseGroupCreateScreen(
                            trainingUuid: _training.uuid,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadExerciseGroups();
                      }
                    },
                    height: 56,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
