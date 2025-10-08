import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/subscription_status_model.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_button.dart';
import 'payment_check_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<SubscriptionPlan> _plans = [];
  SubscriptionStatus? _status;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Загружаем планы и статус подписки параллельно
      final results = await Future.wait([
        SubscriptionService.getPlans(),
        SubscriptionService.getStatus(),
      ]);

      if (mounted) {
        setState(() {
          _plans = results[0] as List<SubscriptionPlan>;
          _status = results[1] as SubscriptionStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePurchase(SubscriptionPlan plan) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Создаем платёжную ссылку
      final response = await SubscriptionService.createPayment(
        planUuid: plan.uuid,
        returnUrl: 'https://ninjatraining.ru/payment/callback',
        paymentMode: ['card', 'sbp'],
      );

      // Сохраняем payment_uuid для проверки после возврата
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_payment_uuid', response.paymentUuid);
      await prefs.setString('payment_plan_name', plan.name);

      // Открываем браузер для оплаты
      final Uri url = Uri.parse(response.paymentUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // Показываем подсказку пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'После оплаты вернитесь в приложение для проверки статуса',
              ),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('Не удалось открыть ссылку для оплаты');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания платежа: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  // Проверка ожидающего платежа при возврате на экран
  Future<void> _checkPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentUuid = prefs.getString('current_payment_uuid');

    if (paymentUuid != null && mounted) {
      // Переходим на экран проверки платежа
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCheckScreen(paymentUuid: paymentUuid),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Выбор подписки',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        actions: [
          // Кнопка проверки ожидающего платежа
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              iconSize: 28,
              onPressed: _checkPendingPayment,
              tooltip: 'Проверить платеж',
              splashRadius: 24,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(text: 'Попробовать снова', onPressed: _loadData),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Текущий статус подписки
                    if (_status != null && _status!.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _status!.isTrial
                                    ? 'У вас активна триальная подписка до ${_status!.formattedExpiryDate}'
                                    : 'Текущая подписка до: ${_status!.formattedExpiryDate}\nПри покупке новой подписки срок продлится без разрыва',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Список тарифных планов
                    ..._plans.map((plan) => _buildPlanCard(plan)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final discount = plan.calculateDiscount();
    final isPopular = plan.isPopular;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с названием и бейджем выгоды
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (discount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Text(
                    'Выгода $discount%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (isPopular) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Text(
                    'Популярный',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Цена
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                SubscriptionService.formatPrice(plan.price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${SubscriptionService.formatPrice(plan.pricePerMonth)}/мес',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ),
            ],
          ),

          if (plan.description != null) ...[
            const SizedBox(height: 12),
            Text(
              plan.description!,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],

          const SizedBox(height: 20),

          // Функции подписки
          _buildFeature('Доступ ко всем тренировкам'),
          _buildFeature('Персональные программы'),
          _buildFeature('Отслеживание прогресса'),
          _buildFeature('Достижения и награды'),

          const SizedBox(height: 20),

          // Кнопка покупки
          CustomButton(
            text: 'Купить за ${SubscriptionService.formatPrice(plan.price)}',
            onPressed: _isPurchasing ? null : () => _handlePurchase(plan),
            isLoading: _isPurchasing,
            height: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
