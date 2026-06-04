import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 1)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  String lectureId;

  @HiveField(3)
  bool isSynced;

  AttendanceRecord({
    required this.uid,
    required this.timestamp,
    required this.lectureId,
    this.isSynced = false,
  });

  // Convert to JSON for Supabase upload
  Map<String, dynamic> toJson() => {
        'student_uid': uid,
        'lecture_id': lectureId,
        'tapped_at': timestamp.toIso8601String(),
      };
}
