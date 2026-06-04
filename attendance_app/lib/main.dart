import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/local_db_service.dart';
import 'services/sync_service.dart';
import 'screens/discovery_screen.dart';
import 'providers/lecture_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final localDb = LocalDbService();
  await localDb.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fqstwjsofbskdgzrnoqn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxc3R3anNvZmJza2RnenJub3FuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1NDk1NjMsImV4cCI6MjA5NjEyNTU2M30.UeQs_2NW9e77_a1k2g6oJ_VHd2XycXJAu3_qgmPYSdc',
  );

  runApp(
    ProviderScope(
      overrides: [
        localDbProvider.overrideWithValue(localDb),
      ],
      child: const AttendanceApp(),
    ),
  );
}

class AttendanceApp extends ConsumerStatefulWidget {
  const AttendanceApp({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends ConsumerState<AttendanceApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the sync service to start listening for connectivity changes
    ref.read(syncServiceProvider).init();
  }

  @override
  void dispose() {
    ref.read(syncServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DiscoveryScreen(),
    );
  }
}
