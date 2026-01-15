import 'dart:async';
import 'package:flutter/material.dart';

class MetalSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const MetalSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Поиск',
    this.onChanged,
  });

  @override
  State<MetalSearchBar> createState() => _MetalSearchBarState();
}

class _MetalSearchBarState extends State<MetalSearchBar> {
  bool _focused = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
    // Слушаем изменения текста для обновления кнопки очистки
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();

    // Создаем новый таймер на 1 секунду
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      // Вызываем callback только через 1 секунду после окончания ввода
      widget.onChanged?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _focused
              ? const [Color(0xFF1C1C1C), Color(0xFF282828)]
              : const [Color(0xFF1A1A1A), Color(0xFF262626)],
        ),
        boxShadow: [
          // inner feel (top shadow)
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
          // bottom highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Текстура (очень слабая, покрывает весь элемент)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.015),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // Контент (выровнен по центру)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      onTapOutside: (event) {
                        // Скрываем клавиатуру при нажатии вне поля
                        _focusNode.unfocus();
                      },
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      cursorColor: Colors.white.withOpacity(0.6),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Кнопка очистки
                  if (widget.controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        _onTextChanged('');
                        _focusNode.unfocus();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
