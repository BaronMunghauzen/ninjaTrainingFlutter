import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_gradients.dart';
import '../../../design/ninja_radii.dart';
import '../../../design/ninja_shadows.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_button.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: $e'),
            backgroundColor: NinjaColors.error,
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Пожалуйста, выберите изображение'),
          backgroundColor: NinjaColors.error,
        ),
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

        final errorData = ApiService.decodeJson(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['detail'] ?? 'Ошибка распознавания')
            : 'Ошибка распознавания';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: NinjaColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: NinjaColors.error,
        ),
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
      appBar: AppBar(
        title: Text('Сканирование еды', style: NinjaText.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: NinjaColors.textPrimary),
      ),
      body: TexturedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Область для изображения
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: NinjaGradients.metalSoft,
                      borderRadius: BorderRadius.circular(NinjaRadii.sm),
                      boxShadow: NinjaShadows.card,
                      border: Border.all(
                        color: NinjaColors.metalEdgeSoft,
                        width: 0.6,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(NinjaRadii.sm),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: NinjaColors.textSecondary,
                              ),
                              const SizedBox(height: NinjaSpacing.lg),
                              Text(
                                'Нажмите, чтобы выбрать фото',
                                style: NinjaText.body.copyWith(
                                  color: NinjaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: NinjaSpacing.xl),

                // Поле для комментария
                Container(
                  decoration: BoxDecoration(
                    gradient: NinjaGradients.metalSoft,
                    borderRadius: BorderRadius.circular(NinjaRadii.sm),
                    border: Border.all(
                      color: NinjaColors.metalEdgeSoft,
                      width: 0.6,
                    ),
                    boxShadow: NinjaShadows.card,
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: NinjaText.body,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Комментарий (необязательно)',
                      hintStyle: NinjaText.body.copyWith(
                        color: NinjaColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(NinjaSpacing.md),
                    ),
                  ),
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
      ),
    );
  }
}
