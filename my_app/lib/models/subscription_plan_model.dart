class SubscriptionPlan {
  final String uuid;
  final String planType; // "month_1" | "month_3" | "month_6" | "month_12"
  final String name;
  final int durationMonths;
  final double price;
  final double pricePerMonth;
  final String? description;
  final bool isActive;

  SubscriptionPlan({
    required this.uuid,
    required this.planType,
    required this.name,
    required this.durationMonths,
    required this.price,
    required this.pricePerMonth,
    this.description,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      uuid: json['uuid'] as String,
      planType: json['plan_type'] as String,
      name: json['name'] as String,
      durationMonths: json['duration_months'] as int,
      price: (json['price'] as num).toDouble(),
      pricePerMonth: (json['price_per_month'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'plan_type': planType,
      'name': name,
      'duration_months': durationMonths,
      'price': price,
      'price_per_month': pricePerMonth,
      'description': description,
      'is_active': isActive,
    };
  }

  /// Рассчитать процент скидки относительно базового тарифа (990₽/мес)
  int calculateDiscount() {
    const basePricePerMonth = 990.0;
    if (pricePerMonth >= basePricePerMonth) return 0;
    final discount =
        ((basePricePerMonth - pricePerMonth) / basePricePerMonth) * 100;
    return discount.round();
  }

  /// Проверить, является ли тариф самым выгодным (обычно 3 месяца)
  bool get isPopular => durationMonths == 3;
}

