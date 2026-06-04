import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'core/service_locator.dart';
import 'features/bluetooth/bloc/bluetooth_bloc.dart';
import 'features/bluetooth/view/discovery_screen.dart';
import 'features/dashboard/bloc/lecture_bloc.dart';

class CollectAttendanceApp extends StatelessWidget {
  const CollectAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BluetoothBloc(sl()),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => LectureBloc(
            lectureRepo: sl(),
            syncRepo: sl(),
            btRepo: sl(),
          ),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppTheme.themeNotifier,
        builder: (context, themeMode, child) {
          return MaterialApp(
            title: 'RollCall',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DiscoveryScreen(),
          );
        },
      ),
    );
  }
}
