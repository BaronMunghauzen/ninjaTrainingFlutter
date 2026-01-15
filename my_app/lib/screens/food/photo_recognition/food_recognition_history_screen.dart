import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_radii.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../models/food_recognition_model.dart';
import '../../../services/api_service.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_list_item.dart';
import '../../../widgets/metal_search_bar.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/macro_info_chip.dart';
import '../../../widgets/auth_image_widget.dart';
import '../../../utils/ninja_route.dart';
import 'food_recognition_result_screen.dart';

class FoodRecognitionHistoryScreen extends StatefulWidget {
  const FoodRecognitionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<FoodRecognitionHistoryScreen> createState() =>
      _FoodRecognitionHistoryScreenState();
}

class _FoodRecognitionHistoryScreenState
    extends State<FoodRecognitionHistoryScreen> {
  List<FoodRecognition> _recognitions = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasNext = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecognitions();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
    _loadRecognitions();
  }

  Future<void> _loadRecognitions({bool loadMore = false}) async {
    if (loadMore && !_hasNext) return;

    setState(() {
      if (!loadMore) {
        _isLoading = true;
        _currentPage = 1;
      }
    });

    try {
      final queryParams = <String, String>{
        'page': loadMore ? (_currentPage + 1).toString() : '1',
        'size': '10',
        'actual': 'true',
      };

      if (_searchQuery.isNotEmpty) {
        queryParams['name'] = _searchQuery;
      }

      final response = await ApiService.get(
        '/api/food-recognition/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final listResponse = FoodRecognitionListResponse.fromJson(
          data as Map<String, dynamic>,
        );

        if (mounted) {
          setState(() {
            if (loadMore) {
              _recognitions.addAll(listResponse.items);
              _currentPage++;
            } else {
              _recognitions = listResponse.items;
              _currentPage = 1;
            }
            _hasNext = listResponse.pagination.hasNext;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: NinjaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecognition(String uuid) async {
    try {
      final response = await ApiService.put(
        '/api/food-recognition/$uuid/deactivate',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Сканирование удалено'),
              backgroundColor: NinjaColors.success,
            ),
          );
          _loadRecognitions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка удаления'),
              backgroundColor: NinjaColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: NinjaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NinjaColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NinjaRadii.lg),
        ),
        title: Text('Подтверждение удаления', style: NinjaText.title),
        content: Text(
          'Вы уверены, что хотите удалить это сканирование?',
          style: NinjaText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Отмена',
              style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Удалить',
              style: NinjaText.body.copyWith(color: NinjaColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteRecognition(uuid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Снимаем фокус при нажатии в любом месте экрана
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: TexturedBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Заголовок и кнопка назад
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NinjaSpacing.lg,
                    vertical: NinjaSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const MetalBackButton(),
                      const SizedBox(width: NinjaSpacing.md),
                      Text('История сканирований', style: NinjaText.title),
                    ],
                  ),
                ),
                // Поиск
                Padding(
                  padding: const EdgeInsets.all(NinjaSpacing.lg),
                  child: MetalSearchBar(
                    controller: _searchController,
                    hint: 'Поиск по названию',
                    onChanged: _onSearchChanged,
                  ),
                ),

                // Список
                Expanded(
                  child: _isLoading && _recognitions.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              NinjaColors.textPrimary,
                            ),
                          ),
                        )
                      : _recognitions.isEmpty
                      ? Center(
                          child: Text(
                            'Нет сканирований',
                            style: NinjaText.body,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadRecognitions(),
                          color: NinjaColors.textPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: NinjaSpacing.lg,
                            ),
                            itemCount:
                                _recognitions.length + (_hasNext ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _recognitions.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(
                                    NinjaSpacing.lg,
                                  ),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () =>
                                          _loadRecognitions(loadMore: true),
                                      child: Text(
                                        'Загрузить еще',
                                        style: NinjaText.body.copyWith(
                                          color: NinjaColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final recognition = _recognitions[index];
                              final isFirst = index == 0;
                              final isLast = index == _recognitions.length - 1;
                              return _buildRecognitionCard(
                                recognition,
                                isFirst: isFirst,
                                isLast: isLast,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecognitionCard(
    FoodRecognition recognition, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateStr = dateFormat.format(DateTime.parse(recognition.createdAt));

    return MetalListItem(
      leading: ClipOval(
        child: AuthImageWidget(
          imageUuid: recognition.imageUuid,
          width: 60,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              recognition.name,
              style: NinjaText.title.copyWith(fontSize: 16),
            ),
          ),
          Transform.translate(
            offset: const Offset(
              50,
              0,
            ), // Смещаем правее, но не за пределы элемента
            child: Text(
              dateStr,
              style: NinjaText.caption.copyWith(
                color: NinjaColors.textSecondary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            'Вес: ${recognition.weightG.toStringAsFixed(0)} г',
            style: NinjaText.caption,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              MacroInfoChip(
                label: 'К',
                value: recognition.caloriesTotal.toStringAsFixed(0),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Б',
                value: recognition.proteinsTotal.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Ж',
                value: recognition.fatsTotal.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'У',
                value: recognition.carbsTotal.toStringAsFixed(1),
                size: 32,
              ),
            ],
          ),
        ],
      ),
      trailing: GestureDetector(
        onTap: () => _showDeleteConfirmation(recognition.uuid),
        child: IconButton(
          icon: const Icon(
            Icons.close,
            color: NinjaColors.textSecondary,
            size: 20,
          ),
          onPressed: () => _showDeleteConfirmation(recognition.uuid),
        ),
      ),
      onTap: () {
        Navigator.of(context)
            .push(
              ninjaRoute(FoodRecognitionResultScreen(recognition: recognition)),
            )
            .then((_) {
              _loadRecognitions();
            });
      },
      isFirst: isFirst,
      isLast: isLast,
      removeSpacing: true,
    );
  }
}
