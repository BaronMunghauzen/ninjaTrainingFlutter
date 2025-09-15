class MeasurementTypeModel {
  final String uuid;
  final String dataType;
  final String? userUuid;
  final String caption;
  final bool actual;
  final String createdAt;
  final String updatedAt;

  MeasurementTypeModel({
    required this.uuid,
    required this.dataType,
    this.userUuid,
    required this.caption,
    required this.actual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeasurementTypeModel.fromJson(Map<String, dynamic> json) {
    return MeasurementTypeModel(
      uuid: json['uuid'] ?? '',
      dataType: json['data_type'] ?? '',
      userUuid: json['user_uuid'],
      caption: json['caption'] ?? '',
      actual: json['actual'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'data_type': dataType,
      'user_uuid': userUuid,
      'caption': caption,
      'actual': actual,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
