import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_radii.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_button.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/metal_text_field.dart';
import '../../../widgets/metal_message.dart';
import '../../../utils/ninja_route.dart' show ninjaRouteReplacement;
import 'food_recognition_result_screen.dart';
import '../../../models/food_recognition_model.dart';
import '../../../services/api_service.dart';

class FoodPhotoSelectionScreen extends StatefulWidget {
  const FoodPhotoSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FoodPhotoSelectionScreen> createState() =>
      _FoodPhotoSelectionScreenState();
}

class _FoodPhotoSelectionScreenState extends State<FoodPhotoSelectionScreen> {
  File? _selectedImage;
  final TextEditingController _commentController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка выбора изображения: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NinjaColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NinjaRadii.lg),
        ),
        title: Text('Выберите источник', style: NinjaText.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: NinjaColors.textPrimary,
              ),
              title: Text('Галерея', style: NinjaText.body),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: NinjaColors.textPrimary,
              ),
              title: Text('Камера', style: NinjaText.body),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _sendForRecognition() async {
    if (_selectedImage == null) {
      MetalMessage.show(
        context: context,
        message: 'Пожалуйста, выберите изображение',
        type: MetalMessageType.warning,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final fields = <String, String>{};
      if (_commentController.text.isNotEmpty) {
        fields['comment'] = _commentController.text;
      }

      final response = await ApiService.multipart(
        '/api/food-recognition/recognize',
        fileField: 'file',
        filePath: _selectedImage!.path,
        fields: fields,
        mimeType: 'image/jpeg',
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.decodeJson(response.body);
        final recognition = FoodRecognition.fromJson(
          data as Map<String, dynamic>,
        );

        Navigator.of(context).pushReplacement(
          ninjaRouteReplacement(
            FoodRecognitionResultScreen(recognition: recognition),
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });

        // Извлекаем сообщение об ошибке из detail.message
        String errorMessage = 'Ошибка распознавания';
        try {
          final errorData = ApiService.decodeJson(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('detail')) {
            final detail = errorData['detail'];
            if (detail is Map<String, dynamic> && detail.containsKey('message')) {
              errorMessage = detail['message'] as String;
            } else if (detail is String) {
              errorMessage = detail;
            }
          }
        } catch (_) {
          // Если не удалось распарсить, используем стандартное сообщение
        }

        MetalMessage.show(
          context: context,
          message: errorMessage,
          type: MetalMessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      MetalMessage.show(
        context: context,
        message: 'Ошибка: $e',
        type: MetalMessageType.error,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Кастомный заголовок с фоном как у экрана
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NinjaSpacing.lg,
                    vertical: NinjaSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const MetalBackButton(),
                      const SizedBox(width: NinjaSpacing.md),
                      Text('Сканирование', style: NinjaText.title),
                    ],
                  ),
                ),
                // Контент
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(NinjaSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Область для изображения
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: MetalCard(
                            padding: EdgeInsets.zero,
                            child: Container(
                              height: 300,
                              width: double.infinity,
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 64,
                                            color: NinjaColors.textSecondary,
                                          ),
                                          const SizedBox(
                                              height: NinjaSpacing.lg),
                                          Text(
                                            'Нажмите, чтобы выбрать фото еды',
                                            style: NinjaText.body.copyWith(
                                              color: NinjaColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.xl),

                        // Поле для комментария
                        MetalTextField(
                          controller: _commentController,
                          hint: 'Комментарий (необязательно)',
                          maxLines: 3,
                        ),
                        const SizedBox(height: NinjaSpacing.xl),

                        // Кнопка отправки
                        MetalButton(
                          label: _isUploading
                              ? 'Отправка...'
                              : 'Отправить на сканирование',
                          icon: _isUploading ? null : Icons.send,
                          onPressed: _sendForRecognition,
                          height: 56,
                          isLoading: _isUploading,
                        ),

                        // Лоадер при загрузке
                        if (_isUploading) ...[
                          const SizedBox(height: NinjaSpacing.xl),
                          Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    NinjaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: NinjaSpacing.lg),
                                Text(
                                  'Пожалуйста, ожидайте завершения сканирования',
                                  style: NinjaText.body.copyWith(
                                    color: NinjaColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
