class SubscriptionStatus {
  final String subscriptionStatus; // "pending" | "active" | "expired"
  final String? subscriptionUntil; // "2025-11-07" (YYYY-MM-DD)
  final bool isTrial;
  final bool trialUsed;
  final int? daysRemaining;

  SubscriptionStatus({
    required this.subscriptionStatus,
    this.subscriptionUntil,
    required this.isTrial,
    required this.trialUsed,
    this.daysRemaining,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionStatus: json['subscription_status'] as String,
      subscriptionUntil: json['subscription_until'] as String?,
      isTrial: json['is_trial'] as bool,
      trialUsed: json['trial_used'] as bool,
      daysRemaining: json['days_remaining'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_status': subscriptionStatus,
      'subscription_until': subscriptionUntil,
      'is_trial': isTrial,
      'trial_used': trialUsed,
      'days_remaining': daysRemaining,
    };
  }

  bool get isActive => subscriptionStatus == 'active';
  bool get isExpired => subscriptionStatus == 'expired';
  bool get isPending => subscriptionStatus == 'pending';

  /// Показывает, нужно ли предупредить о скором окончании подписки
  bool get needsRenewalWarning =>
      isActive && daysRemaining != null && daysRemaining! <= 3;

  /// Форматированная дата окончания подписки
  String? get formattedExpiryDate {
    if (subscriptionUntil == null) return null;
    try {
      final date = DateTime.parse(subscriptionUntil!);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return subscriptionUntil;
    }
  }
}

