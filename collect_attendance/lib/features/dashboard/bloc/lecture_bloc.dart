import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/bluetooth_repository.dart';
import '../../../domain/repositories/lecture_repository.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'lecture_event.dart';
import 'lecture_state.dart';

class LectureBloc extends Bloc<LectureEvent, LectureState> {
  final LectureRepository lectureRepo;
  final SyncRepository syncRepo;
  final BluetoothRepository btRepo;

  StreamSubscription? _btStateSub;
  StreamSubscription? _btDataSub;
  StreamSubscription? _syncSub;

  LectureBloc({
    required this.lectureRepo,
    required this.syncRepo,
    required this.btRepo,
  }) : super(const LectureState()) {
    on<LoadActiveSessionEvent>(_onLoadActiveSession);
    on<StartLectureEvent>(_onStartLecture);
    on<EndLectureEvent>(_onEndLecture);
    on<UidScannedEvent>(_onUidScanned);
    on<BluetoothStateChangedEvent>(_onBluetoothStateChanged);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);
    on<RequestManualSyncEvent>(_onRequestManualSync);

    _initSubscriptions();
    add(LoadActiveSessionEvent());
  }

  void _initSubscriptions() {
    _btStateSub = btRepo.connectionStateStream.listen((isConnected) {
      add(BluetoothStateChangedEvent(isConnected));
    });

    _btDataSub = btRepo.dataStream.listen((uid) {
      add(UidScannedEvent(uid));
    });

    _syncSub = syncRepo.connectivityStream.listen((isConnected) {
      add(ConnectivityChangedEvent(isConnected));
    });
  }

  Future<void> _onLoadActiveSession(LoadActiveSessionEvent event, Emitter<LectureState> emit) async {
    final active = await lectureRepo.getActiveSession();
    if (active != null) {
      final records = lectureRepo.getRecordsForLecture(active.id);
      emit(state.copyWith(
        appState: LectureAppState.active,
        activeLecture: active,
        records: records,
      ));
    } else {
      // Check if there are pending syncs
      // We could use LocalDatabase directly here or through LectureRepo
      // For simplicity, we just set idle.
      emit(state.copyWith(appState: LectureAppState.idle));
    }
  }

  Future<void> _onStartLecture(StartLectureEvent event, Emitter<LectureState> emit) async {
    final lecture = await lectureRepo.startLecture(professorId: event.professorId);
    emit(state.copyWith(
      appState: LectureAppState.active,
      activeLecture: lecture,
      records: [],
    ));
  }

  Future<void> _onEndLecture(EndLectureEvent event, Emitter<LectureState> emit) async {
    await lectureRepo.endLecture();
    
    // Show Submitting Attendance...
    emit(state.copyWith(
      appState: LectureAppState.syncing,
      clearActiveLecture: true,
      records: [],
    ));
    
    // Trigger sync
    await syncRepo.syncPendingData();
    
    // Check if we have any pending lectures left. If none, we are idle.
    final pending = lectureRepo.getPendingLectures();
    if (pending.isEmpty && state.appState != LectureAppState.active) {
      emit(state.copyWith(appState: LectureAppState.idle));
    } else if (state.appState != LectureAppState.active) {
      emit(state.copyWith(appState: LectureAppState.completedPendingSync));
    }
  }

  Future<void> _onUidScanned(UidScannedEvent event, Emitter<LectureState> emit) async {
    if (state.appState != LectureAppState.active || state.activeLecture == null) {
      // Check if it's a professor tapping to start
      final professor = lectureRepo.getProfessorByRfid(event.rfidUid);
      if (professor != null) {
        add(StartLectureEvent(professorId: professor.id));
      }
      return;
    }

    // If lecture is active, check if a professor is tapping to end it
    final professor = lectureRepo.getProfessorByRfid(event.rfidUid);
    if (professor != null) {
      final isDifferentProfessor = state.activeLecture!.professorId != professor.id;
      
      if (isDifferentProfessor) {
        // End current lecture
        await lectureRepo.endLecture();
        
        // Show Submitting Attendance state
        emit(state.copyWith(
          appState: LectureAppState.syncing,
          clearActiveLecture: true,
          records: [],
        ));
        
        await syncRepo.syncPendingData(); // wait for sync
        
        // Start new lecture seamlessly
        final newLecture = await lectureRepo.startLecture(professorId: professor.id);
        emit(state.copyWith(
          appState: LectureAppState.active,
          activeLecture: newLecture,
          records: [],
        ));
      } else {
        // Same professor tapping ends their lecture
        add(EndLectureEvent());
      }
      return;
    }

    final record = await lectureRepo.processScannedUid(event.rfidUid, state.activeLecture!.id);
    if (record != null) {
      final records = lectureRepo.getRecordsForLecture(state.activeLecture!.id);
      emit(state.copyWith(records: records));
    }
  }

  void _onBluetoothStateChanged(BluetoothStateChangedEvent event, Emitter<LectureState> emit) {
    emit(state.copyWith(isBluetoothConnected: event.isConnected));
  }

  void _onConnectivityChanged(ConnectivityChangedEvent event, Emitter<LectureState> emit) {
    emit(state.copyWith(isInternetConnected: event.isConnected));
  }

  Future<void> _onRequestManualSync(RequestManualSyncEvent event, Emitter<LectureState> emit) async {
    emit(state.copyWith(appState: LectureAppState.syncing));
    await syncRepo.syncPendingData();
    // After sync, check if there are still pending
    // For now just back to idle or completed pending
    emit(state.copyWith(appState: LectureAppState.idle));
  }

  @override
  Future<void> close() {
    _btStateSub?.cancel();
    _btDataSub?.cancel();
    _syncSub?.cancel();
    return super.close();
  }
}
