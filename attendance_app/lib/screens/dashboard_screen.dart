import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecture_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/sync_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureState = ref.watch(lectureProvider);
    final isLectureActive = lectureState.activeLecture != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              ref.read(bluetoothProvider.notifier).disconnect();
              Navigator.of(context).pop(); // Go back to discovery
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Connection Status Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusIndicator(
                  label: 'HC-05',
                  isConnected: lectureState.isBluetoothConnected,
                  icon: Icons.bluetooth,
                ),
                _StatusIndicator(
                  label: 'Internet',
                  isConnected: lectureState.isInternetConnected,
                  icon: Icons.cloud,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Lecture Controls
          if (!isLectureActive)
            ElevatedButton.icon(
              onPressed: () => ref.read(lectureProvider.notifier).startLecture(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Lecture Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => ref.read(lectureProvider.notifier).endLecture(),
              icon: const Icon(Icons.stop),
              label: const Text('End Lecture Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

          const SizedBox(height: 10),
          
          if (isLectureActive)
            Text(
              lectureState.isBluetoothConnected 
                  ? 'Lecture Active - Scanning for Cards...'
                  : '⚠️ IOT Connection Lost - Data preserved locally',
              style: TextStyle(
                color: lectureState.isBluetoothConnected ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          
          const SizedBox(height: 20),
          const Text(
            'Scanned UIDs (Current Session)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // Live Attendance List
          Expanded(
            child: ListView.builder(
              itemCount: lectureState.records.length,
              itemBuilder: (context, index) {
                final record = lectureState.records[index];
                return ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: Text(record.uid),
                  subtitle: Text(record.timestamp.toString()),
                  trailing: Icon(
                    record.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    color: record.isSynced ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ),

          // Manual Sync Button (if there are pending records, though SyncService handles it mostly)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                 ref.read(syncServiceProvider).syncPendingData();
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Manual sync triggered')),
                 );
              },
              icon: const Icon(Icons.sync),
              label: const Text('Manual Sync'),
            ),
          )
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isConnected;
  final IconData icon;

  const _StatusIndicator({
    required this.label,
    required this.isConnected,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${isConnected ? 'Online' : 'Offline'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
