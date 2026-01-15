import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_button.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_spacing.dart';
import 'user_exercise_reference_edit_screen.dart';
import '../../models/search_result_model.dart' as search_models;

class ExerciseReferenceCardScreen extends StatefulWidget {
  final String exerciseReferenceUuid;

  const ExerciseReferenceCardScreen({
    Key? key,
    required this.exerciseReferenceUuid,
  }) : super(key: key);

  @override
  State<ExerciseReferenceCardScreen> createState() =>
      _ExerciseReferenceCardScreenState();
}

class _ExerciseReferenceCardScreenState
    extends State<ExerciseReferenceCardScreen> {
  Map<String, dynamic>? _exerciseData;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(
        '/exercise_reference/${widget.exerciseReferenceUuid}',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          _exerciseData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки данных: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
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
        '/exercise_reference/${widget.exerciseReferenceUuid}/upload-image',
        fileField: 'file',
        filePath: image.path,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Перезагружаем данные упражнения
        await _loadExerciseData();
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Изображение успешно загружено',
            type: MetalMessageType.success,
            title: 'Успешно',
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка загрузки изображения: ${response.statusCode}',
            type: MetalMessageType.error,
            title: 'Ошибка',
          );
        }
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

    if (!mounted) return;
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final response = await ApiService.delete(
        '/exercise_reference/${widget.exerciseReferenceUuid}/delete-image',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Перезагружаем данные упражнения
        await _loadExerciseData();
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Изображение успешно удалено',
            type: MetalMessageType.success,
            title: 'Успешно',
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка удаления изображения: ${response.statusCode}',
            type: MetalMessageType.error,
            title: 'Ошибка',
          );
        }
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

  void _openEditScreen() {
    if (_exerciseData == null) return;

    // Преобразуем данные в ExerciseReference
    final exercise = search_models.ExerciseReference.fromJson(_exerciseData!);

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                UserExerciseReferenceEditScreen(exercise: exercise),
          ),
        )
        .then((result) {
          // Если вернулись с результатом (успешное редактирование), перезагружаем данные
          if (result == true) {
            _loadExerciseData();
          }
        });
  }

  String? _getVideoUuid() {
    if (_exerciseData == null) return null;
    final videoUuid = _exerciseData!['video_uuid'];
    if (videoUuid == null || videoUuid.toString().isEmpty) return null;
    return videoUuid.toString();
  }

  String? _getGifUuid() {
    if (_exerciseData == null) return null;
    final gifUuid = _exerciseData!['gif_uuid'];
    if (gifUuid == null || gifUuid.toString().isEmpty) return null;
    return gifUuid.toString();
  }

  String? _getImageUuid() {
    if (_exerciseData == null) return null;
    final imageUuid = _exerciseData!['image_uuid'];
    if (imageUuid == null || imageUuid.toString().isEmpty) return null;
    return imageUuid.toString();
  }

  bool _isUserExercise() {
    if (_exerciseData == null) return false;
    return _exerciseData!['exercise_type'] == 'user';
  }

  Widget _buildMediaContent() {
    // Приоритет: видео > гифка > картинка
    final videoUuid = _getVideoUuid();
    final gifUuid = _getGifUuid();
    final imageUuid = _getImageUuid();

    if (videoUuid != null) {
      // Показываем видео
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(
          videoUuid: videoUuid,
          imageUuid: imageUuid,
          width: double.infinity,
          height: 200,
          exerciseReferenceUuid: widget.exerciseReferenceUuid,
          autoInitialize: true,
        ),
      );
    } else if (gifUuid != null) {
      // Показываем гифку
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GifWidget(gifUuid: gifUuid, width: double.infinity, height: 200),
      );
    } else if (imageUuid != null) {
      // Показываем картинку с возможностью удаления для user упражнений
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AuthImageWidget(
              imageUuid: imageUuid,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          if (_isUserExercise())
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _deleteImage,
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
            ),
        ],
      );
    } else {
      // Нет медиа - показываем плейсхолдер
      if (_isUserExercise()) {
        return GestureDetector(
          onTap: _uploadImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
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
        );
      } else {
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text('Нет изображения', style: NinjaText.body),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхняя панель с кнопкой назад и редактировать
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const Spacer(),
                    if (_isUserExercise())
                      MetalBackButton(icon: Icons.edit, onTap: _openEditScreen),
                  ],
                ),
              ),
              // Контент
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: NinjaText.body.copyWith(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadExerciseData,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _exerciseData == null
                    ? const Center(child: Text('Данные не найдены'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название упражнения
                            Center(
                              child: Text(
                                _exerciseData!['caption'] ?? 'Без названия',
                                style: NinjaText.title,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Описание
                            MetalCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Описание', style: NinjaText.section),
                                  const SizedBox(height: 8),
                                  Text(
                                    _exerciseData!['description'] ??
                                        'Нет описания',
                                    style: NinjaText.body,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Изображение
                            MetalCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Изображение', style: NinjaText.section),
                                  const SizedBox(height: 12),
                                  _isUploadingImage
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : _buildMediaContent(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Группа мышц
                            MetalCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Группа мышц', style: NinjaText.section),
                                  const SizedBox(height: 8),
                                  Text(
                                    _exerciseData!['muscle_group'] ??
                                        'Не указано',
                                    style: NinjaText.body,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Оборудование
                            MetalCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Оборудование',
                                    style: NinjaText.section,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _exerciseData!['equipment_name'] ??
                                        'Не указано',
                                    style: NinjaText.body,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
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
