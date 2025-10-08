class PaymentResponse {
  final String paymentUuid;
  final String paymentUrl;
  final String paymentLinkId;
  final String operationId;

  PaymentResponse({
    required this.paymentUuid,
    required this.paymentUrl,
    required this.paymentLinkId,
    required this.operationId,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      paymentUuid: json['payment_uuid'] as String,
      paymentUrl: json['payment_url'] as String,
      paymentLinkId: json['payment_link_id'] as String,
      operationId: json['operation_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_uuid': paymentUuid,
      'payment_url': paymentUrl,
      'payment_link_id': paymentLinkId,
      'operation_id': operationId,
    };
  }
}

class PaymentStatus {
  final String status; // "pending" | "processing" | "succeeded" | "failed" | "cancelled"
  final double amount;
  final String createdAt; // ISO datetime
  final String? paidAt; // ISO datetime or null
  final String? receiptUrl;

  PaymentStatus({
    required this.status,
    required this.amount,
    required this.createdAt,
    this.paidAt,
    this.receiptUrl,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      paidAt: json['paid_at'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'amount': amount,
      'created_at': createdAt,
      'paid_at': paidAt,
      'receipt_url': receiptUrl,
    };
  }

  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed' || status == 'cancelled';
  bool get isProcessing => status == 'processing' || status == 'pending';

  String get statusText {
    switch (status) {
      case 'succeeded':
        return 'Оплачен';
      case 'failed':
        return 'Ошибка';
      case 'cancelled':
        return 'Отменен';
      case 'processing':
        return 'В обработке';
      case 'pending':
        return 'Ожидает оплаты';
      default:
        return status;
    }
  }
}

class PaymentHistoryItem {
  final String uuid;
  final double amount;
  final String status;
  final String planName;
  final String createdAt; // ISO datetime
  final String? paidAt; // ISO datetime or null
  final String? receiptUrl;

  PaymentHistoryItem({
    required this.uuid,
    required this.amount,
    required this.status,
    required this.planName,
    required this.createdAt,
    this.paidAt,
    this.receiptUrl,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      uuid: json['uuid'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      planName: json['plan_name'] as String,
      createdAt: json['created_at'] as String,
      paidAt: json['paid_at'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'amount': amount,
      'status': status,
      'plan_name': planName,
      'created_at': createdAt,
      'paid_at': paidAt,
      'receipt_url': receiptUrl,
    };
  }

  String get statusText {
    switch (status) {
      case 'succeeded':
        return 'Оплачен';
      case 'failed':
        return 'Ошибка';
      case 'cancelled':
        return 'Отменен';
      case 'processing':
        return 'В обработке';
      case 'pending':
        return 'Ожидает оплаты';
      default:
        return status;
    }
  }

  /// Форматированная дата создания
  String get formattedCreatedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  /// Форматированная дата и время оплаты
  String? get formattedPaidDateTime {
    if (paidAt == null) return null;
    try {
      final date = DateTime.parse(paidAt!);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return paidAt;
    }
  }
}

