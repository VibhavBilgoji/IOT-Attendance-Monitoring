import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/professor_model.dart';
import '../models/student_model.dart';
import '../models/lecture_model.dart';
import '../models/lecture_status.dart';
import '../models/attendance_record_model.dart';
import '../../core/constants.dart';
import '../../hive_registrar.g.dart';

class LocalDatabase {
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters via generated registrar
    Hive.registerAdapters();

    await Future.wait([
      Hive.openBox<ProfessorModel>(AppConstants.professorsBox),
      Hive.openBox<StudentModel>(AppConstants.studentsBox),
      Hive.openBox<LectureModel>(AppConstants.lecturesBox),
      Hive.openBox<AttendanceRecordModel>(AppConstants.attendanceRecordsBox),
    ]);
  }

  // --- Professors Cache ---
  Box<ProfessorModel> get professorsBox => Hive.box<ProfessorModel>(AppConstants.professorsBox);

  Future<void> saveProfessors(List<ProfessorModel> professors) async {
    await professorsBox.clear();
    final Map<String, ProfessorModel> map = {for (var p in professors) p.id: p};
    await professorsBox.putAll(map);
  }

  ProfessorModel? getProfessorByRfid(String rfid) {
    try {
      return professorsBox.values.firstWhere((p) => p.rfidUid == rfid);
    } catch (_) {
      return null;
    }
  }

  ProfessorModel? getProfessorById(String id) {
    return professorsBox.get(id);
  }

  // --- Students Cache ---
  Box<StudentModel> get studentsBox => Hive.box<StudentModel>(AppConstants.studentsBox);

  Future<void> saveStudents(List<StudentModel> students) async {
    await studentsBox.clear();
    final Map<String, StudentModel> map = {for (var s in students) s.id: s};
    await studentsBox.putAll(map);
  }

  StudentModel? getStudentByRfid(String rfid) {
    try {
      return studentsBox.values.firstWhere((s) => s.rfidUid == rfid);
    } catch (_) {
      return null;
    }
  }

  StudentModel? getStudentById(String id) {
    return studentsBox.get(id);
  }

  // --- Lectures ---
  Box<LectureModel> get lecturesBox => Hive.box<LectureModel>(AppConstants.lecturesBox);

  Future<void> saveLecture(LectureModel lecture) async {
    await lecturesBox.put(lecture.id, lecture);
  }

  LectureModel? getActiveLecture() {
    try {
      return lecturesBox.values.firstWhere((l) => l.status == LectureStatus.active);
    } catch (_) {
      return null;
    }
  }

  List<LectureModel> getPendingLectures() {
    return lecturesBox.values.where((l) => l.status == LectureStatus.completedPendingSync).toList();
  }

  // --- Attendance Records ---
  Box<AttendanceRecordModel> get recordsBox => Hive.box<AttendanceRecordModel>(AppConstants.attendanceRecordsBox);

  Future<void> addRecord(AttendanceRecordModel record) async {
    final key = '${record.lectureId}_${record.studentId}';
    if (!recordsBox.containsKey(key)) {
      await recordsBox.put(key, record);
    }
  }

  List<AttendanceRecordModel> getRecordsForLecture(String lectureId) {
    return recordsBox.values.where((r) => r.lectureId == lectureId).toList();
  }

  List<AttendanceRecordModel> getPendingRecordsForLecture(String lectureId) {
    return recordsBox.values
        .where((r) => r.lectureId == lectureId && !r.isSynced)
        .toList();
  }
}
