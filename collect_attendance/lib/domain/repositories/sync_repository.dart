import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/datasources/local_database.dart';
import '../../data/datasources/remote_database.dart';
import '../../data/models/lecture_status.dart';

class SyncRepository {
  final LocalDatabase _localDb;
  final RemoteDatabase _remoteDb;
  
  bool _isSyncing = false;
  
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  SyncRepository(this._localDb, this._remoteDb) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      _connectivityController.add(isConnected);
      if (isConnected) {
        syncPendingData();
      }
    });
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingLectures = _localDb.getPendingLectures();

      for (var lecture in pendingLectures) {
        try {
          // Upload Lecture
          await _remoteDb.upsertLecture(lecture);

          // Upload Records
          final records = _localDb.getPendingRecordsForLecture(lecture.id);
          if (records.isNotEmpty) {
            final payload = records.map((r) => r.toJson()).toList();
            await _remoteDb.upsertAttendanceRecords(payload);

            // Mark records synced locally
            for (var record in records) {
              record.isSynced = true;
              await _localDb.addRecord(record);
            }
          }

          // Mark lecture synced
          lecture.status = LectureStatus.synced;
          await _localDb.saveLecture(lecture);
        } catch (e) {
          debugPrint("Sync Error for lecture ${lecture.id}: $e");
          if (e.toString().contains('23503')) {
            // Foreign key violation (corrupted data). Mark as synced to clear the queue.
            lecture.status = LectureStatus.synced;
            await _localDb.saveLecture(lecture);
          }
        }
      }
    } catch (e) {
      debugPrint("General Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshCache() async {
    try {
      final students = await _remoteDb.fetchStudents();
      await _localDb.saveStudents(students);

      final professors = await _remoteDb.fetchProfessors();
      await _localDb.saveProfessors(professors);
    } catch (e) {
      // Failed to refresh cache
    }
  }
}
