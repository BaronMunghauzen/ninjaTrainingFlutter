import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../design/ninja_spacing.dart';

class FreeTrainingNameModal extends StatefulWidget {
  const FreeTrainingNameModal({super.key});

  @override
  State<FreeTrainingNameModal> createState() => _FreeTrainingNameModalState();
}

class _FreeTrainingNameModalState extends State<FreeTrainingNameModal> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetalTextField(
          controller: _nameController,
          hint: 'Например: Тренировка ног',
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
        ),
        const SizedBox(height: NinjaSpacing.lg),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () {
                  if (!mounted) return;
                  FocusScope.of(context).unfocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                },
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Создать',
                onPressed: () {
                  if (!mounted) return;
                  FocusScope.of(context).unfocus();
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    if (mounted) {
                      MetalMessage.show(
                        context: context,
                        message: 'Введите название тренировки',
                        type: MetalMessageType.error,
                      );
                    }
                    return;
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).pop(name);
                    }
                  });
                },
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
