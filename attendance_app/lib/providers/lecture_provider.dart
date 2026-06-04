import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lecture.dart';
import '../models/attendance_record.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import 'package:uuid/uuid.dart';

// Provider for LocalDbService
final localDbProvider = Provider<LocalDbService>((ref) {
  return LocalDbService(); // Should be initialized in main()
});

final lectureProvider = StateNotifierProvider<LectureNotifier, LectureState>((ref) {
  return LectureNotifier(ref, ref.watch(localDbProvider));
});

class LectureState {
  final Lecture? activeLecture;
  final List<AttendanceRecord> records;
  final bool isBluetoothConnected;
  final bool isInternetConnected;

  LectureState({
    this.activeLecture,
    this.records = const [],
    this.isBluetoothConnected = false,
    this.isInternetConnected = false,
  });

  LectureState copyWith({
    Lecture? activeLecture,
    List<AttendanceRecord>? records,
    bool? isBluetoothConnected,
    bool? isInternetConnected,
    bool clearActiveLecture = false,
  }) {
    return LectureState(
      activeLecture: clearActiveLecture ? null : (activeLecture ?? this.activeLecture),
      records: records ?? this.records,
      isBluetoothConnected: isBluetoothConnected ?? this.isBluetoothConnected,
      isInternetConnected: isInternetConnected ?? this.isInternetConnected,
    );
  }
}

class LectureNotifier extends StateNotifier<LectureState> {
  final Ref _ref;
  final LocalDbService _db;
  final Uuid _uuid = const Uuid();

  LectureNotifier(this._ref, this._db) : super(LectureState()) {
    _loadActiveLecture();
  }

  void _loadActiveLecture() {
    final lecture = _db.getActiveLecture();
    if (lecture != null) {
      final records = _db.getRecordsForLecture(lecture.id);
      state = state.copyWith(activeLecture: lecture, records: records);
    }
  }

  void setBluetoothConnected(bool connected) {
    state = state.copyWith(isBluetoothConnected: connected);
    // Rule B: If disconnected during active lecture, we do NOT end the lecture locally.
    // The state variable 'isBluetoothConnected' will be used by the UI to show "IOT Connection Lost".
  }

  void setInternetConnected(bool connected) {
    state = state.copyWith(isInternetConnected: connected);
  }

  Future<void> startLecture() async {
    if (state.activeLecture != null) return; // Already active

    final newLecture = Lecture(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      status: 'Active',
    );
    
    await _db.saveLecture(newLecture);
    state = state.copyWith(activeLecture: newLecture, records: []);
  }

  Future<void> endLecture() async {
    final lecture = state.activeLecture;
    if (lecture == null) return;

    lecture.endTime = DateTime.now();
    // Rule C: End & Sync Workflow
    // We initially mark it as Completed_Pending_Sync
    lecture.status = 'Completed_Pending_Sync';
    await _db.saveLecture(lecture);
    
    state = state.copyWith(clearActiveLecture: true, records: []);

    // Immediately trigger a sync attempt using the sync service
    _ref.read(syncServiceProvider).syncPendingData();
  }

  Future<void> handleScannedUid(String uid) async {
    // Rule A: Local-First Tapping
    final lecture = state.activeLecture;
    if (lecture == null) {
      // Ignore taps if no lecture is active, or auto-start one based on requirements.
      // Assuming manual start via UI or a specific professor card for now.
      return;
    }

    final record = AttendanceRecord(
      uid: uid,
      timestamp: DateTime.now(),
      lectureId: lecture.id,
    );

    await _db.addRecord(record);
    
    // Update local state to reflect UI
    final updatedRecords = _db.getRecordsForLecture(lecture.id);
    state = state.copyWith(records: updatedRecords);
  }
}
