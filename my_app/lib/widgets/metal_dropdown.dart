import 'package:flutter/material.dart';
import '../design/ninja_typography.dart';

class MetalDropdown<T> extends StatefulWidget {
  final T value;
  final List<MetalDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final double? width;

  const MetalDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
  });

  @override
  State<MetalDropdown<T>> createState() => _MetalDropdownState<T>();
}

class _MetalDropdownState<T> extends State<MetalDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showMenu(BuildContext context) {
    final RenderBox? renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          final RenderBox? retryRenderBox =
              _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
          if (retryRenderBox != null && retryRenderBox.attached) {
            _showMenu(context);
          }
        }
      });
      return;
    }

    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: widget.width ?? renderBox.size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, renderBox.size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade700,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = item.value == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(item.value);
                          _hideMenu();
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          color: isSelected
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                          child: Text(
                            item.label,
                            style: NinjaText.body.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

    return CompositedTransformTarget(
      key: _dropdownKey,
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry == null) {
            _showMenu(context);
          } else {
            _hideMenu();
          }
        },
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  selectedItem.label,
                  style: NinjaText.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetalDropdownItem<T> {
  final T value;
  final String label;

  MetalDropdownItem({
    required this.value,
    required this.label,
  });
}

