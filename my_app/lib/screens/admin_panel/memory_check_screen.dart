import 'package:flutter/material.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
import '../../services/api_service.dart';

class MemoryCheckScreen extends StatefulWidget {
  const MemoryCheckScreen({super.key});

  @override
  State<MemoryCheckScreen> createState() => _MemoryCheckScreenState();
}

class _MemoryCheckScreenState extends State<MemoryCheckScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _memoryData;

  @override
  void initState() {
    super.initState();
    _checkMemory();
  }

  Future<void> _checkMemory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.get('/health/memory');
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          _memoryData = data;
        });
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при получении данных о памяти',
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

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Проверка памяти',
            style: NinjaText.title.copyWith(fontSize: 24),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              )
            : _memoryData == null
                ? Center(
                    child: Text(
                      'Нет данных',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Кнопка "Проверить еще раз"
                        MetalButton(
                          label: 'Проверить еще раз',
                          onPressed: _isLoading ? null : _checkMemory,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 20),
                        // Статус
                        if (_memoryData!['status'] != null)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Статус',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _memoryData!['status'],
                                  style: NinjaText.body,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Память процесса
                        if (_memoryData!['process_memory'] != null)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Память процесса',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'RSS',
                                  '${_memoryData!['process_memory']['rss_mb']} МБ',
                                ),
                                _buildInfoRow(
                                  'VMS',
                                  '${_memoryData!['process_memory']['vms_mb']} МБ',
                                ),
                                _buildInfoRow(
                                  'Процент',
                                  '${_memoryData!['process_memory']['percent']}%',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Системная память
                        if (_memoryData!['system_memory'] != null)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Системная память',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Всего',
                                  '${_memoryData!['system_memory']['total_mb']} МБ',
                                ),
                                _buildInfoRow(
                                  'Доступно',
                                  '${_memoryData!['system_memory']['available_mb']} МБ',
                                ),
                                _buildInfoRow(
                                  'Использовано',
                                  '${_memoryData!['system_memory']['used_mb']} МБ',
                                ),
                                _buildInfoRow(
                                  'Процент',
                                  '${_memoryData!['system_memory']['percent']}%',
                                ),
                                if (_memoryData!['system_memory']['warning'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Предупреждение: ${_memoryData!['system_memory']['warning']}',
                                      style: NinjaText.caption.copyWith(
                                        color: NinjaColors.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Тренд памяти
                        if (_memoryData!['memory_trend'] != null)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Тренд памяти',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Статус: ${_memoryData!['memory_trend']['status']}',
                                  style: NinjaText.body,
                                ),
                                if (_memoryData!['memory_trend']['message'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _memoryData!['memory_trend']['message'],
                                    style: NinjaText.caption.copyWith(
                                      color: NinjaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Топ процессов
                        if (_memoryData!['top_processes'] != null &&
                            (_memoryData!['top_processes'] as List).isNotEmpty)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Топ процессов',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...(_memoryData!['top_processes'] as List)
                                    .map((process) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${process['name']} (PID: ${process['pid']})',
                                                style: NinjaText.body.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              _buildInfoRow(
                                                'RSS',
                                                '${process['rss_mb']} МБ',
                                              ),
                                              _buildInfoRow(
                                                'Процент',
                                                '${process['percent']}%',
                                              ),
                                              if (process !=
                                                  (_memoryData!['top_processes']
                                                          as List)
                                                      .last)
                                                const Divider(
                                                  color: NinjaColors.metalEdgeSoft,
                                                  height: 16,
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Пул БД
                        if (_memoryData!['db_pool'] != null)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Пул базы данных',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Размер',
                                  '${_memoryData!['db_pool']['size']}',
                                ),
                                _buildInfoRow(
                                  'Проверено',
                                  '${_memoryData!['db_pool']['checked_in']}',
                                ),
                                _buildInfoRow(
                                  'Используется',
                                  '${_memoryData!['db_pool']['checked_out']}',
                                ),
                                _buildInfoRow(
                                  'Переполнение',
                                  '${_memoryData!['db_pool']['overflow']}',
                                ),
                                _buildInfoRow(
                                  'Макс. переполнение',
                                  '${_memoryData!['db_pool']['max_overflow']}',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Рекомендации
                        if (_memoryData!['recommendations'] != null &&
                            (_memoryData!['recommendations'] as List).isNotEmpty)
                          MetalCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Рекомендации',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...(_memoryData!['recommendations'] as List)
                                    .map((rec) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            rec,
                                            style: NinjaText.body,
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: NinjaText.body.copyWith(
              color: NinjaColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: NinjaText.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

