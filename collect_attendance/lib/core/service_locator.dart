import 'package:get_it/get_it.dart';
import '../data/datasources/local_database.dart';
import '../data/datasources/remote_database.dart';
import '../domain/repositories/bluetooth_repository.dart';
import '../domain/repositories/lecture_repository.dart';
import '../domain/repositories/sync_repository.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Data Sources
  final localDb = LocalDatabase();
  await localDb.init();
  sl.registerLazySingleton<LocalDatabase>(() => localDb);
  sl.registerLazySingleton<RemoteDatabase>(() => RemoteDatabase());

  // Repositories
  sl.registerLazySingleton<BluetoothRepository>(() => BluetoothRepository());
  sl.registerLazySingleton<LectureRepository>(() => LectureRepository(sl()));
  sl.registerLazySingleton<SyncRepository>(() => SyncRepository(sl(), sl()));
}
