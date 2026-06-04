import 'package:hive_ce/hive.dart';

part 'attendance_record_model.g.dart';

@HiveType(typeId: 4)
class AttendanceRecordModel extends HiveObject {
  @HiveField(0)
  final String id; // local or remote id

  @HiveField(1)
  final String lectureId;

  @HiveField(2)
  final String studentId; // resolved from RFID uid

  @HiveField(3)
  final String studentRfidUid; // keep track of the scanned tag

  @HiveField(4)
  final DateTime tappedAt;

  @HiveField(5)
  bool isSynced;

  AttendanceRecordModel({
    required this.id,
    required this.lectureId,
    required this.studentId,
    required this.studentRfidUid,
    required this.tappedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'lecture_id': lectureId,
      'student_id': studentId,
      'timestamp': tappedAt.toIso8601String(),
    };
  }
}
