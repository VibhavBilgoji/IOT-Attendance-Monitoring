import 'package:equatable/equatable.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/lecture_model.dart';

enum LectureAppState { idle, active, completedPendingSync, syncing, synced }

class LectureState extends Equatable {
  final LectureAppState appState;
  final LectureModel? activeLecture;
  final List<AttendanceRecordModel> records;
  final bool isBluetoothConnected;
  final bool isInternetConnected;

  const LectureState({
    this.appState = LectureAppState.idle,
    this.activeLecture,
    this.records = const [],
    this.isBluetoothConnected = false,
    this.isInternetConnected = false,
  });

  LectureState copyWith({
    LectureAppState? appState,
    LectureModel? activeLecture,
    List<AttendanceRecordModel>? records,
    bool? isBluetoothConnected,
    bool? isInternetConnected,
    bool clearActiveLecture = false,
  }) {
    return LectureState(
      appState: appState ?? this.appState,
      activeLecture: clearActiveLecture ? null : (activeLecture ?? this.activeLecture),
      records: records ?? this.records,
      isBluetoothConnected: isBluetoothConnected ?? this.isBluetoothConnected,
      isInternetConnected: isInternetConnected ?? this.isInternetConnected,
    );
  }

  @override
  List<Object?> get props => [
        appState,
        activeLecture,
        records,
        isBluetoothConnected,
        isInternetConnected,
      ];
}
