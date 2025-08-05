import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? imageUuid; // UUID для превью изображения
  final String? videoUuid; // UUID для видео
  final double? width;
  final double? height;
  final bool showControls;
  final String? exerciseReferenceUuid; // UUID упражнения для загрузки файлов

  const VideoPlayerWidget({
    Key? key,
    this.imageUuid,
    this.videoUuid,
    this.width,
    this.height,
    this.showControls = true,
    this.exerciseReferenceUuid,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showVideo =
      false; // Новое состояние для переключения между видео и превью
  bool _showVideoControls = false; // Показывать ли кнопки управления видео

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.videoUuid == null) {
      setState(() {
        _isLoading = false;
        _hasError = false; // Не показываем ошибку, если видео просто нет
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Создаем URL для стриминга видео
      final videoUrl = '${ApiService.baseUrl}/files/file/${widget.videoUuid}';
      print('Streaming video from: $videoUrl');

      // Создаем контроллер для стриминга с кастомными заголовками и оптимизацией буфера
      _controller = VideoPlayerController.network(
        videoUrl,
        httpHeaders: {'Cookie': 'users_access_token=${await _getAuthToken()}'},
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false, // Отключаем смешивание для стабильности
          allowBackgroundPlayback: false,
        ),
      );

      // Инициализируем контроллер с увеличенным таймаутом
      await _controller!.initialize().timeout(
        const Duration(seconds: 60), // Увеличиваем таймаут
        onTimeout: () {
          throw Exception('Timeout initializing video controller');
        },
      );

      // Устанавливаем зацикливание
      _controller!.setLooping(true);

      // Устанавливаем громкость на 0.3 для лучшей производительности
      _controller!.setVolume(0.3);

      // Оптимизация буферизации для больших файлов
      _controller!.setPlaybackSpeed(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Video loading error: $e');
      // Пытаемся переинициализировать с другими настройками
      await _retryWithDifferentSettings();
    }
  }

  Future<void> _retryWithDifferentSettings() async {
    try {
      print('Retrying video initialization with different settings');

      // Освобождаем предыдущий контроллер
      await _controller?.dispose();
      _controller = null;

      final videoUrl = '${ApiService.baseUrl}/files/file/${widget.videoUuid}';

      // Пробуем с минимальными настройками
      _controller = VideoPlayerController.network(
        videoUrl,
        httpHeaders: {'Cookie': 'users_access_token=${await _getAuthToken()}'},
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Retry timeout');
        },
      );

      _controller!.setLooping(false); // Отключаем зацикливание
      _controller!.setVolume(0.2); // Уменьшаем громкость еще больше
      _controller!.setPlaybackSpeed(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Retry failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false; // Показываем превью вместо ошибки
        });
      }
    }
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token') ?? '';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildPreviewImage() {
    print('Building preview image, imageUuid: ${widget.imageUuid}');
    if (widget.imageUuid == null) {
      print('No image UUID provided');
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: const Center(
          child: Icon(Icons.image, color: AppColors.textSecondary, size: 48),
        ),
      );
    }

    print('Creating FutureBuilder for image: ${widget.imageUuid}');
    return FutureBuilder<ImageProvider?>(
      future: _loadImage(widget.imageUuid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
          );
        }

        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image(image: snapshot.data!, fit: BoxFit.cover),
                if (widget.videoUuid != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showVideo = true;
                          _showVideoControls =
                              false; // Скрываем кнопки управления
                        });
                        // Сразу начинаем воспроизведение видео
                        if (_controller != null && _isInitialized) {
                          _controller!.play();
                        }
                        // Показываем кнопки управления через 2 секунды
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _showVideoControls = true;
                            });
                          }
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ImageProvider?> _loadImage(String imageUuid) async {
    try {
      print('Loading image: $imageUuid');
      // Загружаем изображение через ApiService с авторизацией
      final response = await ApiService.get('/files/file/$imageUuid');

      if (response.statusCode == 200) {
        print('Image loaded successfully: ${response.bodyBytes.length} bytes');
        return MemoryImage(response.bodyBytes);
      } else {
        print('Image loading failed: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _controller == null) {
      return _buildLoadingState();
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (widget.showControls && _showVideoControls)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    try {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                      // Скрываем кнопки управления при воспроизведении
                      if (_controller!.value.isPlaying) {
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted && _controller!.value.isPlaying) {
                            setState(() {
                              _showVideoControls = false;
                            });
                          }
                        });
                      }
                    } catch (e) {
                      print('Error toggling video playback: $e');
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _controller!.value.isPlaying ? 0.0 : 0.8,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Кнопка для возврата к превью
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showVideo = false;
                    _showVideoControls =
                        false; // Сбрасываем состояние кнопок управления
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      'VideoPlayer build - isLoading: $_isLoading, isInitialized: $_isInitialized, controller: ${_controller != null}, showVideo: $_showVideo',
    );

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    // Если видео инициализировано и пользователь хочет смотреть видео, показываем плеер
    if (_isInitialized && _controller != null && _showVideo) {
      print('Showing video player');
      return _buildVideoPlayer();
    }

    // Иначе показываем превью изображение
    print('Showing preview image');
    return _buildPreviewImage();
  }
}
