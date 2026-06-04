import 'package:hive/hive.dart';

part 'lecture.g.dart';

@HiveType(typeId: 0)
class Lecture extends HiveObject {
  @HiveField(0)
  String id; // Usually UUID

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  String status; // 'Active', 'Completed_Pending_Sync', 'Synced'

  Lecture({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  bool get isActive => status == 'Active';
  bool get isPendingSync => status == 'Completed_Pending_Sync';
  bool get isSynced => status == 'Synced';
}
