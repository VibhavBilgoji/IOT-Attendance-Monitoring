import 'package:hive_flutter/hive_flutter.dart';
import '../models/lecture.dart';
import '../models/attendance_record.dart';

class LocalDbService {
  static const String lecturesBoxName = 'lectures';
  static const String recordsBoxName = 'attendance_records';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters (These need to be generated via build_runner)
    // Hive.registerAdapter(LectureAdapter());
    // Hive.registerAdapter(AttendanceRecordAdapter());
    
    await Hive.openBox<Lecture>(lecturesBoxName);
    await Hive.openBox<AttendanceRecord>(recordsBoxName);
  }

  Box<Lecture> get lecturesBox => Hive.box<Lecture>(lecturesBoxName);
  Box<AttendanceRecord> get recordsBox => Hive.box<AttendanceRecord>(recordsBoxName);

  // --- Lectures ---
  Future<void> saveLecture(Lecture lecture) async {
    await lecturesBox.put(lecture.id, lecture);
  }

  Lecture? getActiveLecture() {
    try {
      return lecturesBox.values.firstWhere((l) => l.isActive);
    } catch (e) {
      return null;
    }
  }

  List<Lecture> getPendingLectures() {
    return lecturesBox.values.where((l) => l.isPendingSync).toList();
  }

  // --- Attendance Records ---
  Future<void> addRecord(AttendanceRecord record) async {
    // Generate a unique key based on uid and lectureId to prevent local duplicates
    final key = '${record.lectureId}_${record.uid}';
    if (!recordsBox.containsKey(key)) {
      await recordsBox.put(key, record);
    }
  }

  List<AttendanceRecord> getRecordsForLecture(String lectureId) {
    return recordsBox.values.where((r) => r.lectureId == lectureId).toList();
  }

  List<AttendanceRecord> getPendingRecordsForLecture(String lectureId) {
    return recordsBox.values
        .where((r) => r.lectureId == lectureId && !r.isSynced)
        .toList();
  }
}
