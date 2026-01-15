import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class GifWidget extends StatefulWidget {
  final String? gifUuid;
  final double height;
  final double? width;

  const GifWidget({Key? key, this.gifUuid, this.height = 250, this.width})
    : super(key: key);

  @override
  State<GifWidget> createState() => _GifWidgetState();
}

class _GifWidgetState extends State<GifWidget> {
  Uint8List? _gifData;
  bool _isLoading = true;
  String? _error;
  bool _decodeError = false;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  @override
  void didUpdateWidget(GifWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gifUuid != widget.gifUuid) {
      _decodeError = false;
      _loadGif();
    }
  }

  bool _isValidGifData(Uint8List data) {
    // Проверяем, что данные начинаются с GIF сигнатуры
    if (data.length < 6) return false;
    final signature = String.fromCharCodes(data.take(6));
    return signature == 'GIF89a' || signature == 'GIF87a';
  }

  Future<void> _loadGif() async {
    if (widget.gifUuid == null || widget.gifUuid!.isEmpty) {
      setState(() {
        _gifData = null;
        _isLoading = false;
        _error = null;
        _decodeError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _decodeError = false;
    });

    try {
      final gifData = await ApiService.getFile(widget.gifUuid!);
      if (mounted && gifData != null) {
        // Проверяем валидность данных
        if (!_isValidGifData(gifData)) {
          setState(() {
            _gifData = null;
            _isLoading = false;
            _error = 'Неверный формат GIF файла';
          });
          return;
        }
        setState(() {
          _gifData = gifData;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _gifData = null;
          _isLoading = false;
          _error = 'Не удалось загрузить данные';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gifData = null;
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если gifUuid равен null, не отображаем ничего
    if (widget.gifUuid == null || widget.gifUuid!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      final iconSize = widget.height * 0.4;
      final fontSize = widget.height * 0.15;
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: iconSize, color: Colors.red),
                SizedBox(height: widget.height * 0.1),
                Text(
                  'Ошибка загрузки гифки',
                  style: TextStyle(color: Colors.red[700], fontSize: fontSize),
                  textAlign: TextAlign.center,
                ),
                if (widget.height > 60) ...[
                  SizedBox(height: widget.height * 0.05),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red[600], fontSize: fontSize * 0.75),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_gifData == null) {
      final iconSize = widget.height * 0.6;
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: widget.height < 60
              ? Icon(Icons.image_not_supported, size: iconSize, color: Colors.grey)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: iconSize, color: Colors.grey),
                      SizedBox(height: widget.height * 0.1),
                      Text(
                        'Гифка не загружена',
                        style: TextStyle(color: Colors.grey, fontSize: widget.height * 0.15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    // Если была ошибка декодирования, показываем fallback
    if (_decodeError) {
      final iconSize = widget.height * 0.6;
      return Container(
        height: widget.height,
        width: widget.width,
        color: Colors.grey[300],
        child: Center(
          child: widget.height < 60
              ? Icon(Icons.broken_image, size: iconSize, color: Colors.grey)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: iconSize, color: Colors.grey),
                      SizedBox(height: widget.height * 0.1),
                      Text(
                        'Ошибка отображения гифки',
                        style: TextStyle(color: Colors.grey, fontSize: widget.height * 0.15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipRect(
        child: Image.memory(
          _gifData!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            // Если произошла ошибка декодирования, сохраняем флаг и показываем fallback
            if (mounted && !_decodeError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _decodeError = true;
                  });
                }
              });
            }
            final iconSize = widget.height * 0.6;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: widget.height < 60
                    ? Icon(Icons.broken_image, size: iconSize, color: Colors.grey)
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: iconSize, color: Colors.grey),
                            SizedBox(height: widget.height * 0.1),
                            Text(
                              'Ошибка отображения гифки',
                              style: TextStyle(color: Colors.grey, fontSize: widget.height * 0.15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            // Если кадр не загружен, показываем placeholder
            if (frame == null) {
              return Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return child;
          },
        ),
      ),
    );
  }
}
