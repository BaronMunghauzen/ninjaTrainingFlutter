import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'api_service.dart';

/// Примеры использования системы кэширования файлов
class FileCacheExamples {
  /// Пример 1: Загрузка изображения с автоматическим кэшированием
  static Future<ImageProvider?> loadImageExample(String imageUuid) async {
    // Файл автоматически загрузится с сервера и сохранится в кэш
    // При повторном запросе будет загружен из кэша
    return await ApiService.getImageProvider(imageUuid);
  }

  /// Пример 2: Загрузка файла как байты с кэшированием
  static Future<Uint8List?> loadFileBytesExample(String fileUuid) async {
    // Получаем файл как байты (полезно для PDF, документов и т.д.)
    return await ApiService.getFile(fileUuid);
  }

  /// Пример 3: Принудительное обновление файла из кэша
  static Future<ImageProvider?> forceRefreshImageExample(
    String imageUuid,
  ) async {
    // Принудительно загружаем файл с сервера, игнорируя кэш
    return await ApiService.getImageProvider(imageUuid, forceRefresh: true);
  }

  /// Пример 4: Очистка кэша файлов
  static Future<void> clearCacheExample() async {
    // Очищает все кэшированные файлы (память + диск)
    await ApiService.clearFileCache();
  }

  /// Пример 5: Получение размера кэша
  static Future<String> getCacheSizeExample() async {
    final sizeInBytes = await ApiService.getCacheSize();
    final sizeInMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
    return '${sizeInMB} МБ';
  }

  /// Пример 6: Виджет для отображения изображения с кэшированием
  static Widget buildCachedImage(
    String imageUuid, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<ImageProvider?>(
      future: ApiService.getImageProvider(imageUuid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return errorWidget ?? const Center(child: Icon(Icons.error));
        }

        return Image(
          image: snapshot.data!,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

/// Виджет для отображения кэшированного изображения
class CachedImage extends StatelessWidget {
  final String imageUuid;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    Key? key,
    required this.imageUuid,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FileCacheExamples.buildCachedImage(
      imageUuid,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
