import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_dropdown.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _messageController = TextEditingController();
  String _selectedType = 'Сообщить об ошибке';
  bool _isSending = false;
  String? _messageError;

  final List<String> _contactTypes = [
    'Сообщить об ошибке',
    'Предложение по улучшению',
    'Другое',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    // Валидация
    setState(() {
      _messageError = null;
    });

    if (_messageController.text.trim().isEmpty) {
      setState(() {
        _messageError = 'Поле обязательно для заполнения';
      });
      return;
    }

    if (_messageController.text.trim().length < 10) {
      setState(() {
        _messageError = 'Минимум 10 символов';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      // Получаем AuthProvider для получения user_uuid
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка: пользователь не найден',
            type: MetalMessageType.error,
          );
        }
        return;
      }

      // Подготавливаем данные для отправки
      final body = {
        'request_type': _selectedType,
        'message': _messageController.text.trim(),
        'user_uuid': userUuid,
      };

      // Отправляем POST запрос
      final response = await ApiService.post(
        '/service/support-request/',
        body: body,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Сообщение успешно отправлено',
            type: MetalMessageType.success,
          );
          Navigator.pop(context);
        }
      } else {
        final data = ApiService.decodeJson(response.body);
        final errorMessage =
            data['detail']?.toString() ?? 'Ошибка отправки сообщения';

        if (mounted) {
          MetalMessage.show(
            context: context,
            message: errorMessage,
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        MetalMessage.show(
          context: context,
          message: 'Ошибка сети: $e',
          type: MetalMessageType.error,
        );
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
          leading: const MetalBackButton(),
          title: Text(
            'Связаться с нами',
            style: NinjaText.title.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Тип обращения
                Text('Тип обращения', style: NinjaText.section),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: MetalDropdown<String>(
                    value: _selectedType,
                    items: _contactTypes.map((String type) {
                      return MetalDropdownItem<String>(
                        value: type,
                        label: type,
                      );
                    }).toList(),
                    onChanged: (String newValue) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Сообщение
                Text('Сообщение', style: NinjaText.section),
                const SizedBox(height: 8),
                MetalTextField(
                  controller: _messageController,
                  hint: 'Опишите вашу проблему или предложение...',
                  maxLines: 5,
                ),
                if (_messageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _messageError!,
                      style: NinjaText.caption.copyWith(
                        color: NinjaColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: MetalButton(
                    label: _isSending ? 'Отправка...' : 'Отправить',
                    onPressed: _isSending ? null : _sendMessage,
                    isLoading: _isSending,
                  ),
                ),

                const SizedBox(height: 40),

                // Реквизиты компании (ненавязчиво)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'ИП Маглатова Валерия Максимовна',
                        style: NinjaText.caption.copyWith(
                          color: NinjaColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ИНН 503829337132',
                        style: NinjaText.caption.copyWith(
                          color: NinjaColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ОГРНИП 325508100238252',
                        style: NinjaText.caption.copyWith(
                          color: NinjaColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
