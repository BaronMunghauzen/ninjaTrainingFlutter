import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ExerciseReferenceSelector extends StatefulWidget {
  final void Function(Map<String, dynamic>?) onSelected;
  final String label;
  final Map<String, dynamic> Function(String search)? buildQueryParams;
  final String? initialCaption;
  final Map<String, dynamic>? initialValue;

  const ExerciseReferenceSelector({
    Key? key,
    required this.onSelected,
    this.label = 'Упражнение из справочника',
    this.buildQueryParams,
    this.initialCaption,
    this.initialValue,
  }) : super(key: key);

  @override
  State<ExerciseReferenceSelector> createState() =>
      _ExerciseReferenceSelectorState();
}

class _ExerciseReferenceSelectorState extends State<ExerciseReferenceSelector> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _options = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialCaption != null) {
      _controller.text = widget.initialCaption!;
    }
    if (widget.initialValue != null) {
      _selected = widget.initialValue;
    }
    _fetchOptions();
  }

  Future<void> _fetchOptions([String search = '']) async {
    setState(() => _isLoading = true);
    Map<String, dynamic> queryParams;
    String endpoint = '/exercise_reference/';
    if (widget.buildQueryParams != null) {
      queryParams = widget.buildQueryParams!(search);
      if (search.isNotEmpty) {
        endpoint = '/exercise_reference/search/by-caption';
      }
    } else {
      if (search.isEmpty) {
        queryParams = {'exercise_type': 'system'};
        endpoint = '/exercise_reference/';
      } else {
        queryParams = {'caption': search, 'exercise_type': 'system'};
        endpoint = '/exercise_reference/search/by-caption';
      }
    }
    // Удаляем caption, если он пустой
    if (queryParams.containsKey('caption') &&
        (queryParams['caption'] == null ||
            queryParams['caption'].toString().isEmpty)) {
      queryParams.remove('caption');
    }
    final resp = await ApiService.get(endpoint, queryParams: queryParams);
    if (resp.statusCode == 200) {
      final data = ApiService.decodeJson(resp.body);
      setState(() {
        _options = List<Map<String, dynamic>>.from(data).take(10).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
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
                : null,
          ),
          onChanged: (v) => _fetchOptions(v),
          onTap: () => _fetchOptions(_controller.text),
        ),
        if (_options.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _options.length,
              itemBuilder: (context, i) {
                final ex = _options[i];
                return ListTile(
                  title: Text(ex['caption'] ?? ''),
                  subtitle: Text(ex['description'] ?? ''),
                  onTap: () {
                    setState(() {
                      _selected = ex;
                      _controller.text = ex['caption'] ?? '';
                      _options = [];
                    });
                    widget.onSelected(ex);
                  },
                  selected: _selected?['uuid'] == ex['uuid'],
                );
              },
            ),
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
