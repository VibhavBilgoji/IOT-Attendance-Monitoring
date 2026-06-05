import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bluetooth/bloc/bluetooth_bloc.dart';
import '../bloc/lecture_bloc.dart';
import '../bloc/lecture_event.dart';
import '../bloc/lecture_state.dart';
import '../widgets/connection_status_bar.dart';
import '../../../core/theme.dart';
import '../../../core/service_locator.dart';
import '../../../data/datasources/local_database.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark || 
                  (currentMode == ThemeMode.system && 
                   MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                   
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  AppTheme.themeNotifier.value = isDark 
                      ? ThemeMode.light 
                      : ThemeMode.dark;
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.bluetooth),
              tooltip: 'Disconnect Bluetooth',
              onPressed: () {
                context.read<BluetoothBloc>().add(DisconnectDevice());
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          )
        ],
      ),
      body: BlocBuilder<LectureBloc, LectureState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConnectionStatusBar(
                  isBluetoothConnected: state.isBluetoothConnected,
                  isInternetConnected: state.isInternetConnected,
                ),
                const SizedBox(height: 24),
                _buildLectureCard(context, state),
                const SizedBox(height: 24),
                Text(
                  'Scanned Tags (${state.records.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildRecordsList(context, state),
                ),
                if (state.appState == LectureAppState.completedPendingSync || state.appState == LectureAppState.syncing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: state.appState == LectureAppState.syncing
                          ? null
                          : () {
                              context.read<LectureBloc>().add(RequestManualSyncEvent());
                            },
                      icon: state.appState == LectureAppState.syncing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync),
                      label: Text(state.appState == LectureAppState.syncing ? 'Syncing...' : 'Manual Sync'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<LectureBloc, LectureState>(
        builder: (context, state) {
          if (state.appState == LectureAppState.active) {
            return FloatingActionButton.extended(
              onPressed: () => context.read<LectureBloc>().add(EndLectureEvent()),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              icon: const Icon(Icons.stop),
              label: const Text('End Lecture'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLectureCard(BuildContext context, LectureState state) {
    Color cardColor;
    String title;
    String subtitle;
    IconData icon;

    switch (state.appState) {
      case LectureAppState.idle:
      case LectureAppState.synced:
        cardColor = Theme.of(context).colorScheme.surfaceContainer;
        title = 'Ready';
        subtitle = 'Tap a Professor\'s card to start a lecture';
        icon = Icons.school_outlined;
        break;
      case LectureAppState.active:
        cardColor = Theme.of(context).colorScheme.primaryContainer;
        title = 'Lecture Active';
        if (state.activeLecture?.professorId != null) {
          final prof = sl<LocalDatabase>().getProfessorById(state.activeLecture!.professorId!);
          if (prof != null) {
            title = 'Lecture Active (${prof.fullName})';
          }
        }
        subtitle = state.isBluetoothConnected 
            ? 'Scanning for tags...'
            : '⚠️ IOT Connection Lost - Data is safe locally';
        icon = state.isBluetoothConnected ? Icons.sensors : Icons.warning_amber;
        break;
      case LectureAppState.syncing:
        cardColor = Theme.of(context).colorScheme.secondaryContainer;
        title = 'Submitting Attendance...';
        subtitle = 'Please wait while records are uploaded.';
        icon = Icons.cloud_sync_outlined;
        break;
      case LectureAppState.completedPendingSync:
        cardColor = Theme.of(context).colorScheme.tertiaryContainer;
        title = 'Awaiting Network';
        subtitle = 'Data saved locally. Will sync when online.';
        icon = Icons.cloud_upload_outlined;
        break;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, LectureState state) {
    if (state.records.isEmpty) {
      return Center(
        child: Text(
          'No tags scanned yet.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    // Sort descending by tappedAt
    final sortedRecords = List.of(state.records)
      ..sort((a, b) => b.tappedAt.compareTo(a.tappedAt));

    return ListView.builder(
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        final student = sl<LocalDatabase>().getStudentById(record.studentId);
        final displayName = student?.fullName ?? 'Unknown Student';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.person),
            ),
            title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'UID: ${record.studentRfidUid} • ${record.tappedAt.hour.toString().padLeft(2, '0')}:${record.tappedAt.minute.toString().padLeft(2, '0')}:${record.tappedAt.second.toString().padLeft(2, '0')}',
            ),
            trailing: Icon(
              record.isSynced ? Icons.cloud_done : Icons.cloud_off,
              color: record.isSynced ? Theme.of(context).colorScheme.secondary : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
