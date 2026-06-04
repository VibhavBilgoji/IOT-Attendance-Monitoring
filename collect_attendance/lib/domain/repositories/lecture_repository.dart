import 'package:uuid/uuid.dart';
import '../../data/datasources/local_database.dart';
import '../../data/models/lecture_model.dart';
import '../../data/models/lecture_status.dart';
import '../../data/models/attendance_record_model.dart';
import '../../data/models/professor_model.dart';

class LectureRepository {
  final LocalDatabase _localDb;
  final _uuid = const Uuid();

  LectureRepository(this._localDb);

  Future<LectureModel?> getActiveSession() async {
    return _localDb.getActiveLecture();
  }

  List<LectureModel> getPendingLectures() {
    return _localDb.getPendingLectures();
  }

  ProfessorModel? getProfessorByRfid(String rfidUid) {
    return _localDb.getProfessorByRfid(rfidUid);
  }

  Future<LectureModel> startLecture({String? professorId}) async {
    final active = _localDb.getActiveLecture();
    if (active != null) return active;

    final lecture = LectureModel(
      id: _uuid.v4(),
      professorId: professorId,
      startTime: DateTime.now(),
      status: LectureStatus.active,
      createdAt: DateTime.now(),
    );

    await _localDb.saveLecture(lecture);
    return lecture;
  }

  Future<LectureModel?> endLecture() async {
    final active = _localDb.getActiveLecture();
    if (active == null) return null;

    active.endTime = DateTime.now();
    active.status = LectureStatus.completedPendingSync;
    
    await _localDb.saveLecture(active);
    return active;
  }

  Future<AttendanceRecordModel?> processScannedUid(String rfidUid, String lectureId) async {
    // Attempt to resolve student
    final student = _localDb.getStudentByRfid(rfidUid);
    
    // If the student is not registered in the database, we cannot add an attendance record
    // because it will violate the foreign key constraint on the remote database.
    if (student == null) {
      return null;
    }

    final record = AttendanceRecordModel(
      id: _uuid.v4(),
      lectureId: lectureId,
      studentId: student.id,
      studentRfidUid: rfidUid,
      tappedAt: DateTime.now(),
      isSynced: false,
    );

    await _localDb.addRecord(record);
    return record;
  }

  List<AttendanceRecordModel> getRecordsForLecture(String lectureId) {
    return _localDb.getRecordsForLecture(lectureId);
  }
}
