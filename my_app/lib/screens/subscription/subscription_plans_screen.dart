import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/subscription_status_model.dart';
import '../../services/subscription_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';

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
          MetalMessage.show(
            context: context,
            message: 'После оплаты вернитесь в приложение для проверки статуса',
            type: MetalMessageType.info,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        throw Exception('Не удалось открыть ссылку для оплаты');
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка создания платежа: $e',
          type: MetalMessageType.error,
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

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Выбор подписки',
            style: NinjaText.title.copyWith(fontSize: 20),
          ),
          leading: const MetalBackButton(),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: [
            // Кнопка с информацией о возврате
            IconButton(
              icon: const Icon(Icons.help_outline, color: NinjaColors.textPrimary),
              iconSize: 26,
              onPressed: () {
                MetalModal.show(
                  context: context,
                  title: 'Правила возврата',
                  children: [
                    Text(
                      'По закону «О защите прав потребителей» вы можете расторгнуть договор об оказании услуги в любое время. При этом часть услуг, которые уже были оказаны, нужно оплатить.',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Если вам не нравится качество обслуживания, мы бесплатно устраним недостатки или уменьшим цену услуги.',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'О недостатках оказанной услуги можно сообщить в течение срока гарантии, а если он не установлен, то в течение двух лет.',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'При оплате банковской картой деньги вернутся на ту карту, с которой был сделан платёж. Срок возврата — от 1 до 30 рабочих дней.',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    MetalButton(
                      label: 'Понятно',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
              tooltip: 'Правила возврата',
              splashRadius: 24,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: NinjaColors.error,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки',
                          style: NinjaText.title.copyWith(
                            color: NinjaColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: NinjaText.body.copyWith(
                              color: NinjaColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        MetalButton(
                          label: 'Попробовать снова',
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: NinjaColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Текущий статус подписки
                    if (_status != null && _status!.isActive) ...[
                      MetalCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: NinjaColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _status!.isTrial
                                    ? 'У вас активна триальная подписка до ${_status!.formattedExpiryDate}'
                                    : 'Текущая подписка до: ${_status!.formattedExpiryDate}\nПри покупке новой подписки срок продлится без разрыва',
                                style: NinjaText.body.copyWith(
                                  color: NinjaColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Способы оплаты
                    MetalCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payment,
                            color: NinjaColors.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Оплата: банковская карта или СБП',
                            style: NinjaText.caption.copyWith(
                              color: NinjaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Список тарифных планов
                    ..._plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(plan),
                        )),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final discount = plan.calculateDiscount();
    final isPopular = plan.isPopular;

    return MetalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с названием и бейджем выгоды
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: NinjaText.title.copyWith(fontSize: 20),
              ),
              if (discount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NinjaColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NinjaColors.success),
                  ),
                  child: Text(
                    'Выгода $discount%',
                    style: NinjaText.caption.copyWith(
                      color: NinjaColors.success,
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
                    color: NinjaColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NinjaColors.accent),
                  ),
                  child: Text(
                    'Популярный',
                    style: NinjaText.caption.copyWith(
                      color: NinjaColors.accent,
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
                style: NinjaText.title.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${SubscriptionService.formatPrice(plan.pricePerMonth)}/мес',
                  style: NinjaText.body.copyWith(
                    color: NinjaColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          if (plan.description != null) ...[
            const SizedBox(height: 12),
            Text(
              plan.description!,
              style: NinjaText.body.copyWith(
                color: NinjaColors.textSecondary,
              ),
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
          MetalButton(
            label: 'Купить за ${SubscriptionService.formatPrice(plan.price)}',
            onPressed: _isPurchasing ? null : () => _handlePurchase(plan),
            isLoading: _isPurchasing,
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
          const Icon(
            Icons.check_circle,
            color: NinjaColors.success,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: NinjaText.body,
          ),
        ],
      ),
    );
  }
}
