import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:async'; // Added for Timer

class ExerciseReferenceSelector extends StatefulWidget {
  final void Function(Map<String, dynamic>?) onSelected;
  final String label;
  final Map<String, dynamic> Function(String search)? buildQueryParams;
  final String? initialCaption;
  final Map<String, dynamic>? initialValue;
  final String? endpoint;

  const ExerciseReferenceSelector({
    super.key,
    required this.onSelected,
    this.label = 'Упражнение из справочника',
    this.buildQueryParams,
    this.initialCaption,
    this.initialValue,
    this.endpoint,
  });

  @override
  State<ExerciseReferenceSelector> createState() =>
      _ExerciseReferenceSelectorState();
}

class _ExerciseReferenceSelectorState extends State<ExerciseReferenceSelector> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _options = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selected;
  bool _showDropdown = false;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.initialCaption != null) {
      _controller.text = widget.initialCaption!;
    }
    if (widget.initialValue != null) {
      _selected = widget.initialValue;
    }
    // Не загружаем упражнения при открытии страницы
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    if (_options.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Учитываем padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 10), // Поднимаем список выше
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey[900], // Темный фон
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _options.length,
                itemBuilder: (context, i) {
                  final ex = _options[i];
                  print(
                    '🔍 ExerciseReferenceSelector: Отрисовка элемента $i: ${ex['caption']}',
                  );
                  return ListTile(
                    title: Text(
                      ex['caption'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                      ), // Белый текст
                    ),
                    subtitle: Text(
                      ex['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[300],
                      ), // Светло-серый подзаголовок
                    ),
                    onTap: () {
                      setState(() {
                        _selected = ex;
                        _controller.text = ex['caption'] ?? '';
                        _options = [];
                        _showDropdown = false;
                      });
                      _removeOverlay();
                      widget.onSelected(ex);
                    },
                    selected: _selected?['uuid'] == ex['uuid'],
                    selectedTileColor:
                        Colors.grey[800], // Цвет выбранного элемента
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _fetchOptions(String search) async {
    if (search.trim().isEmpty) {
      setState(() {
        _options = [];
        _showDropdown = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> queryParams;
      String endpoint =
          widget.endpoint ?? '/exercise_reference/search/by-caption';

      if (widget.buildQueryParams != null) {
        queryParams = widget.buildQueryParams!(search);
      } else {
        queryParams = {'caption': search, 'exercise_type': 'system'};
      }

      print(
        '🔍 ExerciseReferenceSelector: Поиск "$search" с параметрами $queryParams',
      );

      final resp = await ApiService.get(endpoint, queryParams: queryParams);

      print(
        '🔍 ExerciseReferenceSelector: Ответ получен, статус: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        print(
          '🔍 ExerciseReferenceSelector: Данные получены, тип: ${data.runtimeType}',
        );
        print('🔍 ExerciseReferenceSelector: Содержимое: $data');

        if (data is List) {
          final options = List<Map<String, dynamic>>.from(
            data,
          ).take(5).toList();
          print(
            '🔍 ExerciseReferenceSelector: Создано ${options.length} опций',
          );

          setState(() {
            _options = options;
            _showDropdown = options.isNotEmpty;
            _isLoading = false;
          });

          print(
            '🔍 ExerciseReferenceSelector: Состояние обновлено, _options.length = ${_options.length}, _showDropdown = $_showDropdown',
          );

          // Показываем overlay если есть опции
          if (options.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        } else {
          print('🔍 ExerciseReferenceSelector: Данные не являются списком');
          setState(() {
            _options = [];
            _showDropdown = false;
            _isLoading = false;
          });
          _removeOverlay();
        }
      } else {
        print(
          '🔍 ExerciseReferenceSelector: Неуспешный статус: ${resp.statusCode}',
        );
        setState(() {
          _options = [];
          _showDropdown = false;
          _isLoading = false;
        });
        _removeOverlay();
      }
    } catch (e) {
      print('❌ ExerciseReferenceSelector: Ошибка поиска: $e');
      setState(() {
        _options = [];
        _showDropdown = false;
        _isLoading = false;
      });
      _removeOverlay();
    }
  }

  void _onSearchChanged(String value) {
    print(
      '🔍 ExerciseReferenceSelector: _onSearchChanged вызван с значением "$value"',
    );

    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();

    // Устанавливаем новый таймер для debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      print('🔍 ExerciseReferenceSelector: Выполняю поиск для "$value"');
      _fetchOptions(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🔍 ExerciseReferenceSelector build: _options.length = ${_options.length}, _showDropdown = $_showDropdown, _isLoading = $_isLoading',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Stack(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Поиск упражнения',
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _options = [];
                            _showDropdown = false;
                          });
                          _removeOverlay();
                          widget.onSelected(null);
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              onTap: () {
                if (_controller.text.isNotEmpty) {
                  _fetchOptions(_controller.text);
                }
              },
            ),
          ],
        ),
        // Невидимый элемент для позиционирования overlay
        CompositedTransformTarget(
          link: _layerLink,
          child: const SizedBox.shrink(),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Выбрано: ${_selected?['caption'] ?? ''}',
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }
}
