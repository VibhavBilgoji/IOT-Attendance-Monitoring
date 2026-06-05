import 'package:hive_ce/hive.dart';

part 'professor_model.g.dart';

@HiveType(typeId: 0)
class ProfessorModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String rfidUid;

  @HiveField(3)
  final DateTime createdAt;

  ProfessorModel({
    required this.id,
    required this.fullName,
    required this.rfidUid,
    required this.createdAt,
  });

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    return ProfessorModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      rfidUid: json['rfid_uid'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'rfid_uid': rfidUid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
