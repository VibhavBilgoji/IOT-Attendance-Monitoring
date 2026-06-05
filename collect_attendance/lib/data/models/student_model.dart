import 'package:hive_ce/hive.dart';

part 'student_model.g.dart';

@HiveType(typeId: 1)
class StudentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String rollNumber;

  @HiveField(3)
  final String rfidUid;

  @HiveField(4)
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.rollNumber,
    required this.rfidUid,
    required this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      rollNumber: json['roll_number'] as String? ?? '',
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
      'roll_number': rollNumber,
      'rfid_uid': rfidUid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
