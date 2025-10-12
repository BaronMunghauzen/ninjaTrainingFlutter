import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

/// Виджет для отображения статуса сети
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;

  const NetworkStatusBanner({Key? key, required this.child}) : super(key: key);

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  bool _isOnline = true;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Периодически проверяем соединение каждые 5 секунд
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                color: Colors.red,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Нет подключения к интернету',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
