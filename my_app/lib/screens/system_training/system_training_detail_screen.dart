import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'active_system_training_screen.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_list_item.dart';
import '../../design/ninja_typography.dart';
import 'package:intl/intl.dart';

class SystemTrainingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> training;
  const SystemTrainingDetailScreen({Key? key, required this.training})
    : super(key: key);

  @override
  State<SystemTrainingDetailScreen> createState() =>
      _SystemTrainingDetailScreenState();
}

class _SystemTrainingDetailScreenState
    extends State<SystemTrainingDetailScreen> {
  List<Map<String, dynamic>> _trainingHistory = [];
  bool _isLoadingHistory = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = false;
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrainingHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Загружаем следующую страницу при достижении 80% прокрутки
      if (!_isLoadingMore && _hasNext) {
        _loadTrainingHistory(loadMore: true);
      }
    }
  }

  Future<void> _loadTrainingHistory({bool loadMore = false}) async {
    if (loadMore && !_hasNext) return;

    setState(() {
      if (!loadMore) {
        _isLoadingHistory = true;
        _currentPage = 1;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        throw Exception('Пользователь не авторизован');
      }

      final page = loadMore ? _currentPage + 1 : 1;
      final response = await ApiService.get(
        '/user_trainings/',
        queryParams: {
          'page': page.toString(),
          'page_size': '10',
          'is_rest_day': 'false',
          'training_uuid': widget.training['uuid'],
          'user_uuid': userUuid,
          'status': 'PASSED',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final List<dynamic> items = data['data'] ?? [];
        final pagination = data['pagination'] ?? {};

        if (mounted) {
          setState(() {
            if (loadMore) {
              _trainingHistory.addAll(
                items.map((item) => item as Map<String, dynamic>).toList(),
              );
              _currentPage++;
            } else {
              _trainingHistory = items
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              _currentPage = 1;
            }
            _hasNext = pagination['has_next'] ?? false;
            _totalCount = pagination['total_count'] ?? 0;
            _isLoadingHistory = false;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _isLoadingMore = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки истории: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки истории: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String? _formatDuration(int? minutes) {
    if (minutes == null) return null;

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours ч $mins м';
    } else if (hours > 0) {
      return '$hours ч';
    } else if (mins > 0) {
      return '$mins м';
    } else {
      return null;
    }
  }

  Future<void> _startTraining(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден userUuid')),
      );
      return;
    }
    final now = DateTime.now();
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final body = {
      'training_uuid': widget.training['uuid'],
      'user_uuid': userUuid,
      'training_date': dateStr,
      'status': 'ACTIVE',
      'is_rest_day': false,
    };
    try {
      final response = await ApiService.post(
        '/user_trainings/add/',
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = ApiService.decodeJson(response.body);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ActiveSystemTrainingScreen(userTraining: data),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Верхняя панель с кнопкой назад
                Row(children: [const MetalBackButton()]),
                const SizedBox(height: 16),
                // MetalCard с информацией о тренировке
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: MetalCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.training['caption'] ?? '',
                          style: NinjaText.title,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Поля с описанием и группой мышц в стиле MetalListItem
                        if ((widget.training['description'] != null &&
                                widget.training['description']
                                    .toString()
                                    .isNotEmpty) ||
                            (widget.training['muscle_group'] != null &&
                                widget.training['muscle_group']
                                    .toString()
                                    .isNotEmpty))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Базовый фон
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                // Текстура графита
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Image.asset(
                                      'assets/textures/graphite_noise.png',
                                      fit: BoxFit.cover,
                                      color: Colors.white.withOpacity(0.05),
                                      colorBlendMode: BlendMode.softLight,
                                      filterQuality: FilterQuality.low,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const SizedBox.shrink();
                                          },
                                    ),
                                  ),
                                ),
                                // Вертикальная светотень
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.25),
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.45),
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Горизонтальная светотень
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.black.withOpacity(0.65),
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.70),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Контент
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Описание
                                      if (widget.training['description'] !=
                                              null &&
                                          widget.training['description']
                                              .toString()
                                              .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Text(
                                            widget.training['description'],
                                            style: NinjaText.body,
                                          ),
                                        ),
                                      // Группа мышц
                                      if (widget.training['muscle_group'] !=
                                              null &&
                                          widget.training['muscle_group']
                                              .toString()
                                              .isNotEmpty) ...[
                                        Text(
                                          'Группа мышц',
                                          style: NinjaText.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.training['muscle_group'],
                                          style: NinjaText.caption,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        MetalButton(
                          label: 'Начать',
                          onPressed: () => _startTraining(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Заголовок "История"
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'История${_totalCount > 0 ? ' ($_totalCount)' : ''}',
                      style: NinjaText.title.copyWith(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Список истории тренировок
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _isLoadingHistory && _trainingHistory.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _trainingHistory.isEmpty
                        ? Center(
                            child: Text(
                              'История тренировок пуста',
                              style: NinjaText.body,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _trainingHistory.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _trainingHistory.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final item = _trainingHistory[index];
                              final dateStr = item['training_date'] ?? '';
                              final duration = item['duration'] is int
                                  ? item['duration'] as int?
                                  : (item['duration'] != null
                                        ? int.tryParse(
                                            item['duration'].toString(),
                                          )
                                        : null);
                              final formattedDate = _formatDate(dateStr);
                              final formattedDuration = _formatDuration(
                                duration,
                              );

                              return MetalListItem(
                                leading: const SizedBox.shrink(),
                                title: Text(
                                  formattedDate,
                                  style: NinjaText.body,
                                ),
                                trailing: formattedDuration != null
                                    ? Text(
                                        '~ $formattedDuration',
                                        style: NinjaText.body,
                                      )
                                    : null,
                                onTap: () {
                                  // Можно добавить навигацию к деталям тренировки
                                },
                                isFirst: index == 0,
                                isLast: index == _trainingHistory.length - 1,
                                removeSpacing: true,
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
}
