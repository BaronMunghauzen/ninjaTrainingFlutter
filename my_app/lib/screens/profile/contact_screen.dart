import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedType = 'Сообщить об ошибке';
  bool _isSending = false;

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
    if (!_formKey.currentState!.validate()) return;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка: пользователь не найден'),
              backgroundColor: Colors.red,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Сообщение успешно отправлено',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              backgroundColor: const Color(0xFF1F2121),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final data = ApiService.decodeJson(response.body);
        final errorMessage =
            data['detail']?.toString() ?? 'Ошибка отправки сообщения';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сети: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Связаться с нами',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Тип обращения
                const Text(
                  'Тип обращения',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _contactTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Сообщение
                const Text(
                  'Сообщение',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  label: '',
                  hint: 'Опишите вашу проблему или предложение...',
                  controller: _messageController,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Поле обязательно для заполнения';
                    }
                    if (value.trim().length < 10) {
                      return 'Минимум 10 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Кнопка отправки с увеличенной высотой
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isSending ? 'Отправка...' : 'Отправить',
                    height: 64, // Увеличиваем высоту с 56 до 64
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),

                const SizedBox(height: 40),

                // Реквизиты компании (ненавязчиво)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'ИП Маглатова Валерия Максимовна',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ИНН 503829337132',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ОГРНИП 325508100238252',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
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
