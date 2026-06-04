import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/service_locator.dart';
import 'app.dart';

import '../domain/repositories/sync_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Setup Dependency Injection (also initializes Hive)
  await setupServiceLocator();

  // Pull latest students & professors from Supabase
  sl<SyncRepository>().refreshCache();

  runApp(const CollectAttendanceApp());
}
