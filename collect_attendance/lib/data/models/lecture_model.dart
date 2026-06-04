import 'package:hive_ce/hive.dart';
import 'lecture_status.dart';

part 'lecture_model.g.dart';

@HiveType(typeId: 3)
class LectureModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? professorId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  LectureStatus status;

  @HiveField(5)
  final DateTime createdAt;

  LectureModel({
    required this.id,
    this.professorId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.createdAt,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    return LectureModel(
      id: json['id'] as String,
      professorId: json['professor_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      status: _statusFromString(json['status'] as String?),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'start_time': startTime.toIso8601String(),
      'status': _statusToString(status),
      // we only want to send created_at if it was set explicitly
    };
    if (professorId != null) {
      data['professor_id'] = professorId;
    }
    if (endTime != null) {
      data['end_time'] = endTime!.toIso8601String();
    }
    return data;
  }

  static LectureStatus _statusFromString(String? status) {
    switch (status) {
      case 'Active':
        return LectureStatus.active;
      case 'Completed':
      case 'Auto-Ended':
        return LectureStatus.synced; // If it's already on server as completed, it's synced
      default:
        return LectureStatus.active;
    }
  }

  static String _statusToString(LectureStatus status) {
    switch (status) {
      case LectureStatus.active:
        return 'Active';
      case LectureStatus.completedPendingSync:
      case LectureStatus.synced:
        return 'Completed';
    }
  }
}
