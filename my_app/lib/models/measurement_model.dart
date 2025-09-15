class MeasurementModel {
  final String uuid;
  final String userUuid;
  final String measurementTypeUuid;
  final String measurementDate;
  final double value;
  final bool actual;
  final String createdAt;
  final String updatedAt;

  MeasurementModel({
    required this.uuid,
    required this.userUuid,
    required this.measurementTypeUuid,
    required this.measurementDate,
    required this.value,
    required this.actual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      uuid: json['uuid'] ?? '',
      userUuid: json['user_uuid'] ?? '',
      measurementTypeUuid: json['measurement_type_uuid'] ?? '',
      measurementDate: json['measurement_date'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      actual: json['actual'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user_uuid': userUuid,
      'measurement_type_uuid': measurementTypeUuid,
      'measurement_date': measurementDate,
      'value': value,
      'actual': actual,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class MeasurementResponseModel {
  final List<MeasurementModel> items;
  final PaginationModel pagination;

  MeasurementResponseModel({required this.items, required this.pagination});

  factory MeasurementResponseModel.fromJson(Map<String, dynamic> json) {
    return MeasurementResponseModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => MeasurementModel.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationModel {
  final int page;
  final int size;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationModel({
    required this.page,
    required this.size,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}
