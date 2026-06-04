import 'package:hive_ce/hive.dart';

part 'lecture_status.g.dart';

@HiveType(typeId: 2)
enum LectureStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  completedPendingSync,

  @HiveField(2)
  synced,
}
