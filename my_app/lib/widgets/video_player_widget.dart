import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                // Превью изображение растягивается во всю ширину
                Positioned.fill(
                  child: Image(
                    image: snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (widget.videoUuid != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showVideo = true;
                          _showVideoControls =
                              true; // Показываем кнопки управления сразу
                        });
                        // Сразу начинаем воспроизведение видео
                        if (_controller != null && _isInitialized) {
                          _controller!.play();
                        }
                        // Автоматически скрываем контролы через 3 секунды
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() {
                              _showVideoControls = false;
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
            // Видео плеер занимает всю площадь
            Positioned.fill(child: VideoPlayer(_controller!)),
            // Контролы видео
            if (widget.showControls) _buildVideoControls(),
            // Кнопка для возврата к превью
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  _controller?.pause();
                  setState(() {
                    _showVideo = false;
                    _showVideoControls = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
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

  Widget _buildVideoControls() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showVideoControls = !_showVideoControls;
          });
          // Автоматически скрываем контролы через 3 секунды только если они показаны
          if (_showVideoControls) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _showVideoControls) {
                setState(() {
                  _showVideoControls = false;
                });
              }
            });
          }
        },
        child: Stack(
          children: [
            // Прозрачная область для тапа по всему видео
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
            // Контролы с анимацией
            AnimatedOpacity(
              opacity: _showVideoControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showVideoControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Ползунок прогресса
                      _buildProgressSlider(),
                      // Кнопки управления
                      _buildControlButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Ползунок
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (context, value, child) {
              final duration = value.duration;
              final position = value.position;

              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.2),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: position.inMilliseconds.toDouble(),
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _controller?.seekTo(Duration(milliseconds: value.toInt()));
                    // Сбрасываем таймер при взаимодействии с ползунком
                    setState(() {
                      _showVideoControls = true;
                    });
                    // Перезапускаем таймер автоскрытия
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted && _showVideoControls) {
                        setState(() {
                          _showVideoControls = false;
                        });
                      }
                    });
                  },
                ),
              );
            },
          ),
          // Время
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (context, value, child) {
              final duration = value.duration;
              final position = value.position;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Кнопка воспроизведения/паузы
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
                // Сбрасываем таймер автоскрытия при взаимодействии с кнопками
                _showVideoControls = true;
              });
              // Перезапускаем таймер автоскрытия
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _showVideoControls) {
                  setState(() {
                    _showVideoControls = false;
                  });
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Кнопка полноэкранного режима
          GestureDetector(
            onTap: () {
              // Сбрасываем таймер при взаимодействии
              setState(() {
                _showVideoControls = true;
              });
              _enterFullscreen();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _enterFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenVideoPlayer(controller: _controller!),
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

// Полноэкранный видео плеер
class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPlayer({required this.controller});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Автоматически скрываем контролы через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showControls = false;
                });
              }
            });
          }
        },
        child: Stack(
          children: [
            // Видео на весь экран
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            // Контролы
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Верхняя панель с кнопкой выхода
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Нижняя панель с контролами
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Ползунок прогресса
                            ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: widget.controller,
                              builder: (context, value, child) {
                                final duration = value.duration;
                                final position = value.position;

                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.3),
                                    thumbColor: AppColors.primary,
                                    overlayColor: AppColors.primary.withOpacity(
                                      0.2,
                                    ),
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                  ),
                                  child: Slider(
                                    value: position.inMilliseconds.toDouble(),
                                    min: 0.0,
                                    max: duration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      widget.controller.seekTo(
                                        Duration(milliseconds: value.toInt()),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Время и кнопки
                            Row(
                              children: [
                                // Кнопка воспроизведения/паузы
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (widget.controller.value.isPlaying) {
                                        widget.controller.pause();
                                      } else {
                                        widget.controller.play();
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Время
                                Expanded(
                                  child:
                                      ValueListenableBuilder<VideoPlayerValue>(
                                        valueListenable: widget.controller,
                                        builder: (context, value, child) {
                                          final duration = value.duration;
                                          final position = value.position;

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(position),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(duration),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                ),
                                const SizedBox(width: 16),
                                // Кнопка выхода из полноэкранного режима
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_exit,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
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
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
