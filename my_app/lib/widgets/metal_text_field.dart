import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetalTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isPassword;

  const MetalTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.isPassword = false,
  });

  @override
  State<MetalTextField> createState() => _MetalTextFieldState();
}

class _MetalTextFieldState extends State<MetalTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _focused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    // Убираем фокус перед dispose, чтобы избежать ошибок с HighlightModeManager
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.maxLines == 1 ? 52.0 : null;
    final minHeight = widget.maxLines > 1 ? 96.0 : null;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: double.infinity,
        height: height,
        constraints: minHeight != null
            ? BoxConstraints(minHeight: minHeight)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF161616), Color(0xFF0F0F0F)],
          ),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.8),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
            if (_focused)
              const BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.06),
                offset: Offset(0, -1),
                blurRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              obscureText: widget.isPassword && _obscureText,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: widget.enabled
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
              onTapOutside: (event) {
                // Скрываем клавиатуру при нажатии вне поля
                _focusNode.unfocus();
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 16,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
