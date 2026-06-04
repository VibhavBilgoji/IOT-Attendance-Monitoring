import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';
import '../providers/lecture_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref, ref.watch(localDbProvider));
});

class SyncService {
  final Ref _ref;
  final LocalDbService _db;
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._ref, this._db);

  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool isConnected = result != ConnectivityResult.none;
      
      _ref.read(lectureProvider.notifier).setInternetConnected(isConnected);

      if (isConnected) {
        syncPendingData();
      }
    });
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    // Check connectivity before proceeding
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    _isSyncing = true;
    try {
      final pendingLectures = _db.getPendingLectures();

      for (var lecture in pendingLectures) {
        final records = _db.getPendingRecordsForLecture(lecture.id);
        
        if (records.isNotEmpty) {
          // Prepare payload
          final payload = records.map((r) => r.toJson()).toList();
          
          try {
            // Upload to Supabase
            // Supabase should have a constraint `unique_student_lecture` to ignore duplicates
            await _supabase.from('attendance').upsert(payload, onConflict: 'student_uid,lecture_id');
            
            // Mark records as synced locally
            for (var record in records) {
              record.isSynced = true;
              await _db.addRecord(record); // Updates existing because it uses same key internally
            }
          } catch (e) {
            debugPrint('Error syncing lecture ${lecture.id}: $e');
            continue; // Skip marking this lecture as synced
          }
        }

        // If we reach here, records are synced or were already empty
        lecture.status = 'Synced';
        await _db.saveLecture(lecture);
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
