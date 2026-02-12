import 'package:flutter/material.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_text_field.dart';
import '../../design/ninja_typography.dart';
import '../../services/api_service.dart';

class EmailBroadcastScreen extends StatefulWidget {
  const EmailBroadcastScreen({super.key});

  @override
  State<EmailBroadcastScreen> createState() => _EmailBroadcastScreenState();
}

class _EmailBroadcastScreenState extends State<EmailBroadcastScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_subjectController.text.trim().isEmpty) {
      MetalMessage.show(
        context: context,
        message: 'Введите тему письма',
        type: MetalMessageType.error,
      );
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      MetalMessage.show(
        context: context,
        message: 'Введите текст письма',
        type: MetalMessageType.error,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/broadcast-email/',
        body: {
          'subject': _subjectController.text.trim(),
          'body': _bodyController.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Рассылка успешно отправлена',
            type: MetalMessageType.success,
          );
          Navigator.of(context).pop();
        }
      } else {
        final errorData = ApiService.decodeJson(response.body);
        final errorMessage =
            errorData['detail'] ?? 'Ошибка при отправке рассылки';
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
        setState(() {
          _isSending = false;
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
            'Рассылка email',
            style: NinjaText.title.copyWith(fontSize: 24),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тема',
                      style: NinjaText.section.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MetalTextField(
                      controller: _subjectController,
                      hint: 'Введите тему письма',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MetalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текст',
                      style: NinjaText.section.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MetalTextField(
                      controller: _bodyController,
                      hint: 'Введите текст письма',
                      maxLines: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MetalButton(
                label: 'Отправить',
                onPressed: _isSending ? null : _sendBroadcast,
                isLoading: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
