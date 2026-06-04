import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothState;
import 'package:permission_handler/permission_handler.dart';
import '../bloc/bluetooth_bloc.dart';
import '../../dashboard/view/dashboard_screen.dart';
import '../../../core/theme.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    setState(() {
      _permissionsGranted = allGranted;
    });

    if (allGranted) {
      if (mounted) {
        context.read<BluetoothBloc>().add(StartScan());
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
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
        ],
      ),
      body: BlocConsumer<BluetoothBloc, BluetoothState>(
        listener: (context, state) {
          if (state is BluetoothConnected) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (state is BluetoothError) {
            if (state.message == "Bluetooth is turned off") {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  icon: const Icon(Icons.bluetooth_disabled, size: 48),
                  title: const Text('Bluetooth Required'),
                  content: const Text(
                    'Bluetooth is currently turned off. The scanner requires Bluetooth to be enabled to connect.',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<BluetoothBloc>().add(StartScan());
                      },
                      child: const Text('TURN ON'),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (!_permissionsGranted) {
            return _buildPermissionWarning();
          }

          return Column(
            children: [
              _buildHeader(state),
              Expanded(
                child: _buildDeviceList(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Permissions Required',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bluetooth and Location permissions are required to scan for the HC-05 scanner.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BluetoothState state) {
    bool isScanning = state is BluetoothScanning;
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: isScanning ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: Icon(
                  Icons.bluetooth_searching,
                  size: 80,
                  color: isScanning 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            isScanning ? 'Scanning for scanner...' : 'Tap to start scanning',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (!isScanning && state is! BluetoothConnecting)
            ElevatedButton(
              onPressed: () => context.read<BluetoothBloc>().add(StartScan()),
              child: const Text('Scan Now'),
            ),
          if (isScanning)
            ElevatedButton(
              onPressed: () => context.read<BluetoothBloc>().add(StopScan()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Stop Scan'),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BluetoothState state) {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.scanResults,
      initialData: const [],
      builder: (c, snapshot) {
        final results = snapshot.data ?? [];
        if (results.isEmpty && state is! BluetoothScanning) {
          return const Center(child: Text('No devices found'));
        }

        return ListView.builder(
          itemCount: results.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final result = results[index];
            final device = result.device;
            final deviceName = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
            
            // Highlight likely targets
            bool isTarget = deviceName.toUpperCase().contains('HC-05') || deviceName.toUpperCase().contains('BLE');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isTarget ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 2,
                )
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: isTarget 
                      ? Theme.of(context).colorScheme.primaryContainer 
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.bluetooth, 
                      color: isTarget ? Theme.of(context).colorScheme.primary : null),
                ),
                title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(device.remoteId.str),
                trailing: state is BluetoothConnecting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => context.read<BluetoothBloc>().add(ConnectToDevice(device)),
                        child: const Text('Connect'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
