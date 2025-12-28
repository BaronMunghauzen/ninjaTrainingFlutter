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
  final bool autoInitialize; // Инициализировать видео автоматически
  final bool cacheController; // Кэшировать VideoPlayerController
  final bool limitActiveLoads; // Ограничивать параллельные инициализации

  const VideoPlayerWidget({
    Key? key,
    this.imageUuid,
    this.videoUuid,
    this.width,
    this.height,
    this.showControls = true,
    this.exerciseReferenceUuid,
    this.autoInitialize = false,
    this.cacheController = true,
    this.limitActiveLoads = true,
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
  bool _isFromCache = false; // Контроллер взят из кэша
  bool _cachedByThisInstance =
      false; // Контроллер добавлен в кэш этой инстанцией

  // Кэш для изображений - предотвращает повторную загрузку
  static final Map<String, ImageProvider> _imageCache = {};
  static const int _maxImageCacheSize =
      10; // Максимальное количество изображений в кэше

  // Кэш для видео - предотвращает повторную загрузку
  static final Map<String, VideoPlayerController> _videoCache = {};
  static const int _maxVideoCacheSize =
      5; // Максимальное количество видео в кэше

  // Ограничение на количество одновременно загружаемых изображений
  static int _activeImageLoads = 0;
  static const int _maxActiveImageLoads = 3;

  // Ограничение на количество одновременно загружаемых видео
  static int _activeVideoLoads = 0;
  static const int _maxActiveVideoLoads = 1;

  /// Очищает кэш изображений для освобождения памяти
  static void clearImageCache() {
    _imageCache.clear();
    _activeImageLoads = 0;
    print('Image cache cleared and active loads reset');
  }

  /// Очищает кэш видео для освобождения памяти
  static void clearVideoCache() {
    for (final controller in _videoCache.values) {
      controller.dispose();
    }
    _videoCache.clear();
    _activeVideoLoads = 0;
    print('Video cache cleared and active loads reset');
  }

  /// Принудительно очищает память и сбрасывает все состояния
  static void forceMemoryCleanup() {
    _imageCache.clear();
    _activeImageLoads = 0;
    clearVideoCache();
    print('Force memory cleanup completed');
  }

  /// Очищает кэш для конкретного упражнения (при смене упражнения)
  static void clearExerciseCache(String? exerciseReferenceUuid) {
    if (exerciseReferenceUuid != null) {
      // Удаляем видео, связанные с этим упражнением
      final keysToRemove = <String>[];
      for (final entry in _videoCache.entries) {
        // Здесь можно добавить логику для определения связи между видео и упражнением
        // Пока просто очищаем весь кэш видео
        keysToRemove.add(entry.key);
      }

      for (final key in keysToRemove) {
        final controller = _videoCache.remove(key);
        controller?.dispose();
      }

      print('Exercise cache cleared for: $exerciseReferenceUuid');
    }
  }

  @override
  void initState() {
    super.initState();

    // Очищаем кэш предыдущего упражнения при инициализации нового
    if (widget.exerciseReferenceUuid != null) {
      // Можно добавить логику для определения, нужно ли очищать кэш
      // Например, если это новое упражнение
    }

    if (widget.autoInitialize) {
      setState(() {
        _showVideo = true;
        _isLoading = true;
      });
      _initializeVideo();
    } else {
      // Отложенная инициализация до пользовательского действия
      _isLoading = false;
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.videoUuid == null) {
      setState(() {
        _isLoading = false;
        _hasError = false; // Не показываем ошибку, если видео просто нет
      });
      return;
    }

    // Проверяем кэш видео
    if (widget.cacheController && _videoCache.containsKey(widget.videoUuid)) {
      print('Video found in cache: ${widget.videoUuid}');
      final cachedController = _videoCache[widget.videoUuid];

      // Проверяем, что контроллер инициализирован и не disposed
      try {
        if (cachedController != null && cachedController.value.isInitialized) {
          _controller = cachedController;
          _isFromCache = true;

          if (mounted) {
            setState(() {
              _isInitialized = true;
              _isLoading = false;
            });
          }
          return;
        } else {
          // Контроллер в кэше не инициализирован - удаляем из кэша и создаем новый
          print('Cached controller not initialized, removing from cache');
          _videoCache.remove(widget.videoUuid);
          cachedController?.dispose();
        }
      } catch (e) {
        // Контроллер в кэше disposed или недоступен - удаляем из кэша
        print('Cached controller error: $e, removing from cache');
        _videoCache.remove(widget.videoUuid);
        try {
          cachedController?.dispose();
        } catch (_) {}
      }
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Проверяем ограничение на количество активных загрузок видео (опционально)
      if (widget.limitActiveLoads) {
        if (_activeVideoLoads >= _maxActiveVideoLoads) {
          print('Too many active video loads, waiting...');
          await Future.delayed(const Duration(milliseconds: 1000));
          if (_activeVideoLoads >= _maxActiveVideoLoads) {
            print('Still too many active video loads, skipping this video');
            setState(() {
              _isLoading = false;
              _hasError = false; // Показываем превью вместо ошибки
            });
            return;
          }
        }
        _activeVideoLoads++;
      }

      try {
        // Очищаем кэш видео если он слишком большой
        if (_videoCache.length >= _maxVideoCacheSize) {
          print('Clearing video cache due to size limit');
          clearVideoCache();
        }

        // Создаем URL для стриминга видео
        final videoUrl = '${ApiService.baseUrl}/files/file/${widget.videoUuid}';
        print('Streaming video from: $videoUrl');

        // Создаем контроллер для стриминга с кастомными заголовками и оптимизацией буфера
        _controller = VideoPlayerController.network(
          videoUrl,
          httpHeaders: {
            'Cookie': 'users_access_token=${await _getAuthToken()}',
          },
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

        // Добавляем в кэш при необходимости
        if (widget.cacheController) {
          _videoCache[widget.videoUuid!] = _controller!;
          _cachedByThisInstance = true;
        }
        print('Video added to cache: ${widget.videoUuid}');

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
        }
      } finally {
        // Уменьшаем счетчик активных загрузок видео
        if (widget.limitActiveLoads) {
          _activeVideoLoads--;
        }
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

      // Добавляем в кэш даже при повторной попытке
      _videoCache[widget.videoUuid!] = _controller!;
      _cachedByThisInstance = true;
      print('Video added to cache after retry: ${widget.videoUuid}');

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
    try {
      // Всегда останавливаем и корректно освобождаем контроллер
      if (_controller != null) {
        _controller!.pause();
      }
      // Если контроллер кэшируется, НЕ удаляем из кэша и не диспоузим, чтобы другие виджеты не сломались
      final isCachedController =
          widget.cacheController && (_isFromCache || _cachedByThisInstance);

      if (!isCachedController) {
        // Контроллер не используется совместно — освобождаем полностью
        _controller?.dispose();
        _controller = null;
      }
    } catch (_) {}

    // Очищаем кэш изображений если он слишком большой
    if (_imageCache.length > _maxImageCacheSize) {
      _imageCache.clear();
    }

    super.dispose();
  }

  Widget _buildPreviewImage() {
    print('Building preview image, imageUuid: ${widget.imageUuid}');
    if (widget.imageUuid == null) {
      print('No image UUID provided');
      // Если нет превью, но есть видео
      if (widget.videoUuid != null) {
        if (widget.autoInitialize) {
          // Автоинициализация: показываем первый кадр (пауза) или лоадер пока готовится
          if (!_isInitialized || _controller == null) {
            _initializeVideo();
          }
          _showVideo = true;
          return _isInitialized && _controller != null
              ? _buildVideoPlayer()
              : _buildLoadingState();
        } else {
          // Без автоинициализации: показываем нейтральный плейсхолдер, запуск по клику на ListTile
          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
          );
        }
      }
      // Иначе — обычная заглушка для изображения
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
          // Если произошла ошибка загрузки изображения, показываем fallback
          print('Image loading failed, showing fallback');
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
                      onTap: () async {
                        setState(() {
                          _showVideo = true;
                          _showVideoControls = true;
                          _isLoading = true;
                        });
                        if (!_isInitialized || _controller == null) {
                          await _initializeVideo();
                        }
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

      // Проверяем кэш
      if (_imageCache.containsKey(imageUuid)) {
        print('Image found in cache: $imageUuid');
        return _imageCache[imageUuid];
      }

      // Проверяем ограничение на количество активных загрузок
      if (_activeImageLoads >= _maxActiveImageLoads) {
        print('Too many active image loads, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (_activeImageLoads >= _maxActiveImageLoads) {
          print('Still too many active loads, skipping this image');
          return null;
        }
      }

      // Увеличиваем счетчик активных загрузок
      _activeImageLoads++;

      try {
        // Очищаем кэш если он слишком большой
        if (_imageCache.length >= _maxImageCacheSize) {
          print('Clearing image cache due to size limit');
          _imageCache.clear();
        }

        // Используем новый метод кэширования ApiService
        final imageProvider = await ApiService.getImageProvider(imageUuid);

        if (imageProvider != null) {
          // Добавляем в локальный кэш для совместимости
          _imageCache[imageUuid] = imageProvider;
          print('Image loaded successfully from cache or server');
          return imageProvider;
        } else {
          print('Image loading failed');
        }
        return null;
      } finally {
        // Уменьшаем счетчик активных загрузок
        _activeImageLoads--;
      }
    } catch (e) {
      print('Error loading image: $e');

      // Если произошла ошибка памяти, очищаем кэш
      if (e.toString().contains('OutOfMemory') ||
          e.toString().contains('memory')) {
        print('Memory error detected, clearing cache');
        _imageCache.clear();
        _activeImageLoads = 0;
      }

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
