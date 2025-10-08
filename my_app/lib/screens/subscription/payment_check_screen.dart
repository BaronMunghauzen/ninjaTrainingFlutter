import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/payment_model.dart';
import '../../services/subscription_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class PaymentCheckScreen extends StatefulWidget {
  final String paymentUuid;

  const PaymentCheckScreen({super.key, required this.paymentUuid});

  @override
  State<PaymentCheckScreen> createState() => _PaymentCheckScreenState();
}

class _PaymentCheckScreenState extends State<PaymentCheckScreen> {
  String _status = 'checking';
  PaymentStatus? _paymentInfo;
  String? _planName;
  int _attempts = 0;
  static const int _maxAttempts = 15; // 30 секунд (15 * 2 сек)
  static const int _checkInterval = 2000; // 2 секунды

  @override
  void initState() {
    super.initState();
    _loadPlanName();
    _checkPaymentStatus();
  }

  Future<void> _loadPlanName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _planName = prefs.getString('payment_plan_name');
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final paymentStatus = await SubscriptionService.checkPaymentStatus(
        widget.paymentUuid,
      );

      print('Payment status: ${paymentStatus.status}');

      if (!mounted) return;

      if (paymentStatus.isSucceeded) {
        // ✅ Оплата прошла успешно
        setState(() {
          _status = 'succeeded';
          _paymentInfo = paymentStatus;
        });

        // Обновляем данные пользователя
        await _refreshUserData();

        // Очищаем сохраненные данные
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_payment_uuid');
        await prefs.remove('payment_plan_name');
      } else if (paymentStatus.isProcessing) {
        // ⏳ Еще в процессе
        _attempts++;

        if (_attempts < _maxAttempts) {
          // Проверяем снова через 2 секунды
          await Future.delayed(const Duration(milliseconds: _checkInterval));
          if (mounted) {
            _checkPaymentStatus();
          }
        } else {
          // Превышен лимит попыток
          setState(() {
            _status = 'timeout';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Оплата обрабатывается. Проверьте статус позже в истории платежей.',
                ),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } else if (paymentStatus.isFailed) {
        // ❌ Оплата не прошла
        setState(() {
          _status = 'failed';
          _paymentInfo = paymentStatus;
        });
      }
    } catch (e) {
      print('Error checking payment: $e');
      if (mounted) {
        setState(() {
          _status = 'error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка проверки платежа: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchUserProfile();
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _openReceipt() async {
    if (_paymentInfo?.receiptUrl == null) return;

    final Uri url = Uri.parse(_paymentInfo!.receiptUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть чек'),
            backgroundColor: AppColors.error,
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
        title: const Text(
          'Проверка оплаты',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _status == 'checking'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case 'checking':
        return _buildCheckingState();
      case 'succeeded':
        return _buildSuccessState();
      case 'failed':
        return _buildFailedState();
      case 'timeout':
        return _buildTimeoutState();
      case 'error':
        return _buildErrorState();
      default:
        return _buildCheckingState();
    }
  }

  Widget _buildCheckingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
        const SizedBox(height: 32),
        const Text(
          'Проверка оплаты...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Это может занять несколько секунд',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Попытка $_attempts из $_maxAttempts',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 60,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Оплата успешна!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_planName != null) ...[
          Text(
            'Подписка "$_planName" активирована',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        if (_paymentInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Сумма:',
                  SubscriptionService.formatPrice(_paymentInfo!.amount),
                ),
                if (_paymentInfo!.paidAt != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Оплачено:',
                    _formatDateTime(_paymentInfo!.paidAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_paymentInfo?.receiptUrl != null) ...[
          CustomButton(
            text: 'Скачать чек',
            onPressed: _openReceipt,
            icon: Icons.receipt_long,
            isSecondary: true,
          ),
          const SizedBox(height: 16),
        ],
        CustomButton(
          text: 'Вернуться в профиль',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 60,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Оплата не прошла',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Попробуйте снова или выберите другой способ оплаты',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Выбрать другой тариф',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildTimeoutState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule, color: AppColors.primary, size: 60),
        ),
        const SizedBox(height: 32),
        const Text(
          'Платеж обрабатывается',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Проверка статуса заняла слишком много времени.\nПроверьте результат позже в истории платежей.',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Вернуться в профиль',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 64),
        const SizedBox(height: 24),
        const Text(
          'Ошибка проверки',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Не удалось проверить статус платежа',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Попробовать снова',
          onPressed: () {
            setState(() {
              _status = 'checking';
              _attempts = 0;
            });
            _checkPaymentStatus();
          },
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Вернуться назад',
          onPressed: () => Navigator.pop(context),
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
