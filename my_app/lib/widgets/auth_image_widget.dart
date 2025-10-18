import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class AuthImageWidget extends StatefulWidget {
  final String? imageUuid;
  final double height;
  final double width;
  final BoxFit fit;

  const AuthImageWidget({
    Key? key,
    this.imageUuid,
    this.height = 60,
    this.width = 60,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<AuthImageWidget> createState() => _AuthImageWidgetState();
}

class _AuthImageWidgetState extends State<AuthImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUuid != widget.imageUuid) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUuid == null || widget.imageUuid!.isEmpty) {
      setState(() {
        _imageData = null;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final imageData = await ApiService.getFile(widget.imageUuid!);
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageData = null;
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если imageUuid равен null, не отображаем ничего
    if (widget.imageUuid == null || widget.imageUuid!.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Icon(Icons.image, color: Colors.grey, size: 24),
        ),
      );
    }

    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      );
    }

    if (_imageData == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Icon(
            Icons.image_not_supported,
            size: 24,
            color: Colors.grey,
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _imageData!,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: const Icon(
                Icons.broken_image,
                size: 24,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }
}
