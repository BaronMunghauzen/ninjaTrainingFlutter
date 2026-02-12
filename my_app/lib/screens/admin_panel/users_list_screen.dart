import 'package:flutter/material.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_dropdown.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
import '../../services/api_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = false;
  
  // Пагинация
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  int _totalPages = 0;
  final List<int> _availablePageSizes = [10, 20, 50, 75];
  
  // Сортировка
  String _sortBy = 'id';
  String _sortOrder = 'desc';
  Map<String, int> _sortState = {}; // 0 = desc, 1 = asc, 2 = reset to id
  
  // Фильтры
  String? _actualFilter; // null, 'true', 'false'
  String? _emailVerifiedFilter; // null, 'true', 'false'
  String? _emailNotificationsEnabledFilter; // null, 'true', 'false'

  // Контроллеры для синхронизации горизонтальной прокрутки
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Синхронизация прокрутки заголовков и таблицы
    _headerScrollController.addListener(_syncHeaderScroll);
    _tableScrollController.addListener(_syncTableScroll);
  }

  void _syncHeaderScroll() {
    if (_isSyncingScroll) return;
    if (_headerScrollController.hasClients && _tableScrollController.hasClients) {
      final offset = _headerScrollController.offset;
      if ((_tableScrollController.offset - offset).abs() > 1.0) {
        _isSyncingScroll = true;
        _tableScrollController.jumpTo(offset);
        _isSyncingScroll = false;
      }
    }
  }

  void _syncTableScroll() {
    if (_isSyncingScroll) return;
    if (_headerScrollController.hasClients && _tableScrollController.hasClients) {
      final offset = _tableScrollController.offset;
      if ((_headerScrollController.offset - offset).abs() > 1.0) {
        _isSyncingScroll = true;
        _headerScrollController.jumpTo(offset);
        _isSyncingScroll = false;
      }
    }
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderScroll);
    _tableScrollController.removeListener(_syncTableScroll);
    _headerScrollController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'size': _pageSize,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };

      if (_actualFilter != null) {
        queryParams['actual'] = _actualFilter == 'true';
      }
      if (_emailVerifiedFilter != null) {
        queryParams['email_verified'] = _emailVerifiedFilter == 'true';
      }
      if (_emailNotificationsEnabledFilter != null) {
        queryParams['email_notifications_enabled'] =
            _emailNotificationsEnabledFilter == 'true';
      }

      final response = await ApiService.get(
        '/auth/all_users/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          // API возвращает либо массив напрямую, либо объект с items и pagination
          if (data is List) {
            // Если ответ - это массив напрямую
            _users = data;
            _totalCount = data.length;
            _totalPages = (_totalCount / _pageSize).ceil();
            if (_totalPages == 0) _totalPages = 1;
          } else if (data is Map<String, dynamic>) {
            // Если ответ - это объект с items и pagination
            _users = data['items'] ?? [];
            
            // Безопасное преобразование total_count
            final totalCountValue = data['pagination']?['total_count'];
            if (totalCountValue is int) {
              _totalCount = totalCountValue;
            } else if (totalCountValue != null) {
              _totalCount = int.tryParse(totalCountValue.toString()) ?? _users.length;
            } else {
              _totalCount = _users.length;
            }
            
            // Безопасное преобразование total_pages
            final totalPagesValue = data['pagination']?['total_pages'];
            if (totalPagesValue is int) {
              _totalPages = totalPagesValue;
            } else if (totalPagesValue != null) {
              _totalPages = int.tryParse(totalPagesValue.toString()) ?? 
                  ((_totalCount / _pageSize).ceil());
            } else {
              _totalPages = (_totalCount / _pageSize).ceil();
              if (_totalPages == 0) _totalPages = 1;
            }
            
            // Безопасное преобразование page
            final pageValue = data['pagination']?['page'];
            if (pageValue is int) {
              _currentPage = pageValue;
            } else if (pageValue != null) {
              _currentPage = int.tryParse(pageValue.toString()) ?? _currentPage;
            }
          } else {
            _users = [];
            _totalCount = 0;
            _totalPages = 1;
          }
        });
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при загрузке пользователей',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSort(String field) {
    // Если поле uuid, считаем его как id
    final sortField = field == 'uuid' ? 'id' : field;
    
    // Проверяем текущее состояние сортировки для этого поля
    final currentSortField = _sortBy;
    final currentSortOrder = _sortOrder;
    
    setState(() {
      if (currentSortField == sortField) {
        // Если уже сортируем по этому полю, меняем порядок
        if (currentSortOrder == 'desc') {
          // Второе нажатие - asc
          _sortOrder = 'asc';
          _sortState[sortField] = 1;
        } else {
          // Третье нажатие - сброс к id
          _sortState.clear();
          _sortBy = 'id';
          _sortOrder = 'desc';
        }
      } else {
        // Первое нажатие на новое поле - desc
        _sortState.clear();
        _sortState[sortField] = 0;
        _sortBy = sortField;
        _sortOrder = 'desc';
      }
      _currentPage = 1;
    });

    _loadUsers();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadUsers();
  }

  void _onPageSizeChanged(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    _loadUsers();
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$minute';
    } catch (e) {
      return dateTimeString;
    }
  }

  Future<void> _toggleEmailNotifications(String userUuid, bool currentValue) async {
    try {
      final response = await ApiService.post(
        '/auth/toggle-email-notifications/$userUuid',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Обновляем список
        _loadUsers();
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Настройки уведомлений обновлены',
            type: MetalMessageType.success,
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при обновлении настроек',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Widget _buildUsersTable() {
    // Заголовки для MetalTable (строки, так как MetalTable требует строки)
    final headers = [
      'UUID',
      'Логин',
      'Email',
      'Телефон',
      'Имя',
      'Фамилия',
      'Пол',
      'Описание',
      'Актуальный',
      'Статус подписки',
      'Подписка до',
      'Email подтвержден',
      'Уведомления email',
      'Очки',
      'Последний вход',
    ];

    // Данные строк
    final rows = _users.map((user) {
      return [
        Text(
          user['uuid'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['login'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['email'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['phone_number'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['first_name'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['last_name'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['gender'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['description'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Center(
          child: _RoundCheckbox(
            value: user['actual'] ?? false,
            onChanged: null,
          ),
        ),
        Text(
          user['subscription_status'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['subscription_until'] != null
              ? DateTime.parse(user['subscription_until']).toString().substring(0, 10)
              : '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Center(
          child: _RoundCheckbox(
            value: user['email_verified'] ?? false,
            onChanged: null,
          ),
        ),
        Center(
          child: _RoundCheckbox(
            value: user['email_notifications_enabled'] ?? false,
            onChanged: (val) => _toggleEmailNotifications(
              user['uuid'],
              user['email_notifications_enabled'] ?? false,
            ),
          ),
        ),
        Text(
          '${user['score'] ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
        Text(
          user['last_login_at'] != null
              ? _formatDateTime(user['last_login_at'])
              : '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
      ];
    }).toList();

    // Используем MetalTable с кастомными заголовками для сортировки
    final headerFields = [
      'uuid',
      'login',
      'email',
      'phone_number',
      'first_name',
      'last_name',
      'gender',
      'description',
      'actual',
      'subscription_status',
      'subscription_until',
      'email_verified',
      'email_notifications_enabled',
      'score',
      'last_login_at',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Кастомные заголовки в стиле MetalTable с сортировкой
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerScrollController,
            child: Row(
              children: List.generate(
                headers.length,
                (index) => SizedBox(
                  width: 150,
                  child: _buildSortableMetalTableHeader(
                    headers[index],
                    headerFields[index],
                    index,
                    headers.length,
                  ),
                ),
              ),
            ),
          ),
          // Данные через кастомную таблицу в стиле MetalTable (без заголовков)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _tableScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    final isLastRow = rowIndex == rows.length - 1;
                    return Row(
                      children: List.generate(
                        row.length,
                        (index) => SizedBox(
                          width: 150,
                          child: _buildDataCell(row[index], index, isLastRow, headers.length),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableMetalTableHeader(
    String label,
    String field,
    int index,
    int totalColumns,
  ) {
    final isSorting = _sortBy == field || (field == 'uuid' && _sortBy == 'id');
    final currentOrder = isSorting ? _sortOrder : null;

    return GestureDetector(
      onTap: () => _onSort(field),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
            topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5E5E5E),
              Color(0xFF3E3E3E),
              Color(0xFF272727),
              Color(0xFF161616),
            ],
            stops: [0.0, 0.4, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Текстура
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                  topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                ),
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.05),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            // Свечение сверху
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                    topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.7,
                        colors: [
                          const Color(0xFFC5D09D).withOpacity(0.32),
                          const Color(0xFFC5D09D).withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Градиентная обводка сверху
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                    topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          const Color(0xFFC5D09D),
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Затемнение снизу
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                    topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Inner highlight
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                    topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                        topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          offset: const Offset(0, -1),
                          blurRadius: 2,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Inner shadow
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                    topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
                        topRight: index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Текст с иконкой сортировки
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (currentOrder == 'desc')
                      const Icon(Icons.arrow_downward, size: 16, color: Color(0xFFEDEDED))
                    else if (currentOrder == 'asc')
                      const Icon(Icons.arrow_upward, size: 16, color: Color(0xFFEDEDED))
                    else
                      Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: Colors.white.withOpacity(0.3),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(Widget child, int index, bool isLastRow, int totalColumns) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: isLastRow && index == 0 ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLastRow && index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
        ),
      ),
      child: Stack(
        children: [
          // Текстура
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: isLastRow && index == 0 ? const Radius.circular(16) : Radius.zero,
                bottomRight: isLastRow && index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
              ),
              child: Image.asset(
                'assets/textures/graphite_noise.png',
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.04),
                colorBlendMode: BlendMode.softLight,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Затемнение снизу
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: isLastRow && index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isLastRow && index == totalColumns - 1 ? const Radius.circular(16) : Radius.zero,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Контент
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // Кастомный чекбокс в стиле program_exercise_sets_table
  Widget _RoundCheckbox({
    required bool value,
    ValueChanged<bool?>? onChanged,
  }) {
    return IgnorePointer(
      ignoring: onChanged == null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (onChanged != null) {
            onChanged(!value);
          }
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFC5D09D).withOpacity(0.8),
              width: 2.0,
            ),
            color: const Color(0xFF2B2B2B),
          ),
          child: value
              ? Center(
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: const Color(0xFFC5D09D).withOpacity(0.6),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Список пользователей',
            style: NinjaText.title.copyWith(fontSize: 24),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoading && _users.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              )
            : Column(
                children: [
                  // Фильтры
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Актуальные',
                                    style: NinjaText.caption.copyWith(
                                      color: NinjaColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  MetalDropdown<String?>(
                                    value: _actualFilter,
                                    items: [
                                      MetalDropdownItem<String?>(
                                        value: null,
                                        label: 'Не указано',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'true',
                                        label: 'Да',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'false',
                                        label: 'Нет',
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _actualFilter = value;
                                        _currentPage = 1;
                                      });
                                      _loadUsers();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Подтвержденный email',
                                    style: NinjaText.caption.copyWith(
                                      color: NinjaColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  MetalDropdown<String?>(
                                    value: _emailVerifiedFilter,
                                    items: [
                                      MetalDropdownItem<String?>(
                                        value: null,
                                        label: 'Не указано',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'true',
                                        label: 'Да',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'false',
                                        label: 'Нет',
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _emailVerifiedFilter = value;
                                        _currentPage = 1;
                                      });
                                      _loadUsers();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Разрешена отправка email',
                                    style: NinjaText.caption.copyWith(
                                      color: NinjaColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  MetalDropdown<String?>(
                                    value: _emailNotificationsEnabledFilter,
                                    items: [
                                      MetalDropdownItem<String?>(
                                        value: null,
                                        label: 'Не указано',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'true',
                                        label: 'Да',
                                      ),
                                      MetalDropdownItem<String?>(
                                        value: 'false',
                                        label: 'Нет',
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _emailNotificationsEnabledFilter = value;
                                        _currentPage = 1;
                                      });
                                      _loadUsers();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Таблица
                  Expanded(
                    child: _users.isEmpty
                        ? Center(
                            child: Text(
                              'Нет пользователей',
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                          )
                        : _buildUsersTable(),
                  ),

                  // Пагинация
                  if (_users.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DropdownButton<int>(
                                value: _pageSize,
                                items: _availablePageSizes.map((size) {
                                  return DropdownMenuItem<int>(
                                    value: size,
                                    child: Text('$size'),
                                  );
                                }).toList(),
                                onChanged: (newSize) {
                                  if (newSize != null) {
                                    _onPageSizeChanged(newSize);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              if (_totalPages > 1)
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: _currentPage > 1
                                            ? () => _onPageChanged(_currentPage - 1)
                                            : null,
                                        icon: const Icon(Icons.chevron_left),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Flexible(
                                        child: Text(
                                          'Страница $_currentPage из $_totalPages',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _currentPage < _totalPages
                                            ? () => _onPageChanged(_currentPage + 1)
                                            : null,
                                        icon: const Icon(Icons.chevron_right),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Всего пользователей: $_totalCount'),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

