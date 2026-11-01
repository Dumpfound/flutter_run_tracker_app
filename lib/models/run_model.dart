class RunModel {
  final String id;
  final String runWhere;
  final String runPerson;
  final int runDistance;
  final String? runImageUrl;
  final DateTime createdAt;

  RunModel({
    required this.id,
    required this.runWhere,
    required this.runPerson,
    required this.runDistance,
    this.runImageUrl,
    required this.createdAt,
  });

  factory RunModel.fromJson(Map<String, dynamic> json) {
    return RunModel(
      id: json['id'] as String,
      runWhere: json['runWhere']?.toString() ?? '',
      runPerson: json['runPerson']?.toString() ?? '',
      runDistance: int.tryParse(json['runDistance'].toString()) ?? 0,  // ← แก้ตรงนี้
      runImageUrl: json['runImageUrl'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runWhere': runWhere,
      'runPerson': runPerson,
      'runDistance': runDistance,
      'runImageUrl': runImageUrl,
    };
  }
}