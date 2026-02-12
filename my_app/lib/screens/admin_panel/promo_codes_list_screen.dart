import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_toggle_switch.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
import '../../design/ninja_spacing.dart';
import '../../services/api_service.dart';

class PromoCodesListScreen extends StatefulWidget {
  const PromoCodesListScreen({super.key});

  @override
  State<PromoCodesListScreen> createState() => _PromoCodesListScreenState();
}

class _PromoCodesListScreenState extends State<PromoCodesListScreen> {
  List<dynamic> _promoCodes = [];
  bool _isLoading = false;

  // Пагинация
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 0;
  final List<int> _availablePageSizes = [10, 20, 50, 75];

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/api/promo_codes/',
        queryParams: {
          'page': _currentPage,
          'size': _pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          _promoCodes = data['items'] ?? [];
          _totalCount = data['total'] ?? 0;
          _totalPages = data['pages'] ?? 0;
          _currentPage = data['page'] ?? 1;
        });
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при загрузке промокодов',
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

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadPromoCodes();
  }

  void _onPageSizeChanged(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    _loadPromoCodes();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      MetalMessage.show(
        context: context,
        message: 'Промокод скопирован',
        type: MetalMessageType.success,
      );
    }
  }

  Future<void> _showEditModal(Map<String, dynamic> promoCode) async {
    final codeController = TextEditingController(text: promoCode['code'] ?? '');
    final fullNameController = TextEditingController(text: promoCode['full_name'] ?? '');
    final discountController = TextEditingController(
      text: promoCode['discount_percent']?.toString() ?? '0',
    );
    bool actual = promoCode['actual'] ?? false;
    bool isSaving = false;

    await MetalModal.show(
      context: context,
      title: 'Редактировать промокод',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MetalTextField(
                  controller: codeController,
                  hint: 'Код промокода',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: fullNameController,
                  hint: 'Полное название',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: discountController,
                  hint: 'Процент скидки',
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Актуальный',
                      style: NinjaText.body,
                    ),
                    SizedBox(
                      width: 120,
                      child: MetalToggleSwitch(
                        value: actual,
                        onChanged: (value) {
                          setModalState(() {
                            actual = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MetalButton(
                      label: 'Отмена',
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    MetalButton(
                      label: 'Сохранить',
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                final discountPercent = int.tryParse(discountController.text) ?? 0;
                                final response = await ApiService.put(
                                  '/api/promo_codes/${promoCode['uuid']}',
                                  body: {
                                    'code': codeController.text.trim(),
                                    'full_name': fullNameController.text.trim(),
                                    'discount_percent': discountPercent,
                                    'actual': actual,
                                  },
                                );

                                if (response.statusCode == 200) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    _loadPromoCodes();
                                    MetalMessage.show(
                                      context: context,
                                      message: 'Промокод обновлен',
                                      type: MetalMessageType.success,
                                    );
                                  }
                                } else {
                                  final errorData = ApiService.decodeJson(response.body);
                                  final errorMessage = errorData['detail'] ?? 'Ошибка при обновлении';
                                  if (mounted) {
                                    MetalMessage.show(
                                      context: context,
                                      message: errorMessage.toString(),
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
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                }
                              }
                            },
                      isLoading: isSaving,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCreateModal() async {
    final codeController = TextEditingController();
    final fullNameController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    bool actual = true;
    bool isSaving = false;

    await MetalModal.show(
      context: context,
      title: 'Создать промокод',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MetalTextField(
                  controller: codeController,
                  hint: 'Код промокода',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: fullNameController,
                  hint: 'Полное название',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: discountController,
                  hint: 'Процент скидки',
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Актуальный',
                      style: NinjaText.body,
                    ),
                    SizedBox(
                      width: 120,
                      child: MetalToggleSwitch(
                        value: actual,
                        onChanged: (value) {
                          setModalState(() {
                            actual = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MetalButton(
                      label: 'Отмена',
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    MetalButton(
                      label: 'Создать',
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (codeController.text.trim().isEmpty) {
                                MetalMessage.show(
                                  context: context,
                                  message: 'Введите код промокода',
                                  type: MetalMessageType.error,
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                final discountPercent = int.tryParse(discountController.text) ?? 0;
                                final response = await ApiService.post(
                                  '/api/promo_codes/',
                                  body: {
                                    'code': codeController.text.trim(),
                                    'full_name': fullNameController.text.trim(),
                                    'discount_percent': discountPercent,
                                    'actual': actual,
                                  },
                                );

                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    _loadPromoCodes();
                                    MetalMessage.show(
                                      context: context,
                                      message: 'Промокод создан',
                                      type: MetalMessageType.success,
                                    );
                                  }
                                } else {
                                  final errorData = ApiService.decodeJson(response.body);
                                  final errorMessage = errorData['detail'] ?? 'Ошибка при создании';
                                  if (mounted) {
                                    MetalMessage.show(
                                      context: context,
                                      message: errorMessage.toString(),
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
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                }
                              }
                            },
                      isLoading: isSaving,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Промокоды',
            style: NinjaText.title.copyWith(fontSize: 24),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            _isLoading && _promoCodes.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                    ),
                  )
                : Column(
                    children: [
                      // Список промокодов
                      Expanded(
                    child: _promoCodes.isEmpty
                        ? Center(
                            child: Text(
                              'Нет промокодов',
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _promoCodes.length,
                            itemBuilder: (context, index) {
                              final promoCode = _promoCodes[index];
                              final isFirst = index == 0;
                              final isLast = index == _promoCodes.length - 1;

                              return MetalListItem(
                                isFirst: isFirst,
                                isLast: isLast,
                                removeSpacing: true,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: NinjaColors.metalMid,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      promoCode['code']?.toString().substring(0, 1).toUpperCase() ?? 'P',
                                      style: NinjaText.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      promoCode['code'] ?? '',
                                      style: NinjaText.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (promoCode['full_name'] != null &&
                                        promoCode['full_name'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        promoCode['full_name'],
                                        style: NinjaText.caption,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Скидка: ${promoCode['discount_percent'] ?? 0}%',
                                      style: NinjaText.caption,
                                    ),
                                    Text(
                                      'Актуальный: ${promoCode['actual'] == true ? 'Да' : 'Нет'}',
                                      style: NinjaText.caption,
                                    ),
                                    if (promoCode['created_at'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Создан: ${_formatDateTime(promoCode['created_at'])}',
                                        style: NinjaText.caption.copyWith(
                                          color: NinjaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () => _copyToClipboard(promoCode['code'] ?? ''),
                                      tooltip: 'Копировать',
                                      color: NinjaColors.textSecondary,
                                      iconSize: 20,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showEditModal(promoCode),
                                      tooltip: 'Редактировать',
                                      color: NinjaColors.textSecondary,
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                onTap: () {},
                              );
                            },
                          ),
                  ),

                  // Пагинация
                  if (_promoCodes.isNotEmpty)
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
                          Text('Всего промокодов: $_totalCount'),
                        ],
                      ),
                    ),
                    ],
                  ),
            // Кнопка создания внизу справа
            Positioned(
              bottom: _promoCodes.isNotEmpty ? 100 : 20,
              right: 20,
              child: SizedBox(
                width: 56,
                height: 56,
                child: MetalButton(
                  label: '',
                  icon: Icons.add,
                  onPressed: _showCreateModal,
                  height: 56,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

