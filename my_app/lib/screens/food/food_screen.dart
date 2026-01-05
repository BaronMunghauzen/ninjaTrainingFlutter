import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/ninja_colors.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/subscription_error_dialog.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/macro_info_chip.dart';
import '../../utils/ninja_route.dart';
import 'photo_recognition/food_photo_selection_screen.dart';
import 'photo_recognition/food_recognition_history_screen.dart';
import 'photo_recognition/food_recognition_result_screen.dart';
import '../../models/food_recognition_model.dart';
import '../../services/api_service.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({Key? key}) : super(key: key);

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  FoodRecognition? _lastRecognition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLastRecognition();
  }

  Future<void> _loadLastRecognition() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/api/food-recognition/',
        queryParams: {'page': '1', 'size': '10', 'actual': 'true'},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final listResponse = FoodRecognitionListResponse.fromJson(
          data as Map<String, dynamic>,
        );

        if (mounted) {
          setState(() {
            _lastRecognition = listResponse.items.isNotEmpty
                ? listResponse.items.first
                : null;
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
      }
    }
  }

  void _checkSubscriptionAndScan() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null || userProfile.subscriptionStatus != 'active') {
      showDialog(
        context: context,
        builder: (context) => const SubscriptionErrorDialog(
          message:
              'Для использования функции сканирования еды необходима активная подписка',
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(ninjaRoute(const FoodPhotoSelectionScreen())).then((_) {
      _loadLastRecognition();
    });
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(ninjaRoute(const FoodRecognitionHistoryScreen())).then((_) {
      _loadLastRecognition();
    });
  }

  void _openLastRecognition() {
    if (_lastRecognition != null) {
      Navigator.of(context)
          .push(
            ninjaRoute(
              FoodRecognitionResultScreen(recognition: _lastRecognition!),
            ),
          )
          .then((_) {
            _loadLastRecognition();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Большая карточка с логотипом и кнопкой
                MetalCard(
                  padding: const EdgeInsets.all(NinjaSpacing.xl),
                  child: Column(
                    children: [
                      // Логотип food.png
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NinjaColors.metalEdgeSoft,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/food.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.xl),
                      // Кнопка "Загрузить фото"
                      MetalButton(
                        label: 'Загрузить фото',
                        icon: Icons.camera_alt,
                        onPressed: _checkSubscriptionAndScan,
                        height: 56,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),

                // Последнее сканирование
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(NinjaSpacing.xxl),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NinjaColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                else if (_lastRecognition != null)
                  _buildLastRecognitionCard()
                else
                  const SizedBox.shrink(),

                const SizedBox(height: NinjaSpacing.lg),

                // Кнопка истории
                MetalButton(
                  label: 'История',
                  icon: Icons.history,
                  onPressed: _openHistory,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastRecognitionCard() {
    final recognition = _lastRecognition!;
    return MetalListItem(
      leading: ClipOval(
        child: AuthImageWidget(
          imageUuid: recognition.imageUuid,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        recognition.name,
        style: NinjaText.title.copyWith(fontSize: 18),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Вес: ${recognition.weightG.toStringAsFixed(0)} г',
            style: NinjaText.caption,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              MacroInfoChip(
                label: 'К',
                value: recognition.caloriesTotal.toStringAsFixed(0),
              ),
              const SizedBox(width: 8),
              MacroInfoChip(
                label: 'Б',
                value: recognition.proteinsTotal.toStringAsFixed(1),
              ),
              const SizedBox(width: 8),
              MacroInfoChip(
                label: 'Ж',
                value: recognition.fatsTotal.toStringAsFixed(1),
              ),
              const SizedBox(width: 8),
              MacroInfoChip(
                label: 'У',
                value: recognition.carbsTotal.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: NinjaColors.textSecondary),
      onTap: _openLastRecognition,
    );
  }

}
