import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../providers/bluetooth_provider.dart';
import 'dashboard_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  bool _isDiscovering = false;
  String? _permissionError;

  // MethodChannel to request Android runtime permissions
  static const _permissionChannel = MethodChannel('com.example.attendance_app/permissions');

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  /// Request Bluetooth runtime permissions required on Android 12+ (API 31+).
  /// Returns true if all permissions are granted.
  Future<bool> _requestBluetoothPermissions() async {
    try {
      final result = await _permissionChannel.invokeMethod<bool>('requestBluetoothPermissions');
      return result ?? false;
    } on MissingPluginException {
      // If the native handler isn't set up, we're likely on an older Android
      // where manifest permissions are enough, so proceed.
      return true;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  Future<void> _initBluetooth() async {
    // First, request runtime permissions (Android 12+)
    final granted = await _requestBluetoothPermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _permissionError = 'Bluetooth permissions are required to use this app. '
              'Please grant them in Settings.';
        });
      }
      return;
    }

    try {
      _bluetoothState = await FlutterBluetoothSerial.instance.state;
      if (_bluetoothState == BluetoothState.STATE_OFF) {
        try {
          await FlutterBluetoothSerial.instance.requestEnable();
        } catch (e) {
          // The plugin has a known bug where it crashes with "Reply already submitted"
          // when the user denies the enable request. Catch and continue gracefully.
          debugPrint('Bluetooth enable request failed (user may have denied): $e');
        }
      }
      _getPairedDevices();
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
      if (mounted) {
        setState(() {
          _permissionError = 'Failed to initialize Bluetooth: $e';
        });
      }
    }
    if (mounted) setState(() {});
  }

  void _getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (ex) {
      debugPrint("Error getting paired devices: $ex");
    }
    if (mounted) {
      setState(() {
        _devicesList = devices;
      });
    }
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
    });

    FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = _devicesList
            .indexWhere((element) => element.address == r.device.address);
        if (existingIndex >= 0) {
          _devicesList[existingIndex] = r.device;
        } else {
          _devicesList.add(r.device);
        }
      });
    }).onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final btState = ref.watch(bluetoothProvider);

    // Listen to changes to navigate on successful connection
    ref.listen<BluetoothStateData>(bluetoothProvider, (previous, next) {
      if (next.isConnected && !next.isConnecting) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to HC-05'),
        actions: [
          IconButton(
            icon: Icon(_isDiscovering ? Icons.stop : Icons.search),
            onPressed: _isDiscovering ? null : _startDiscovery,
          ),
        ],
      ),
      body: Column(
        children: [
          if (btState.isConnecting) const LinearProgressIndicator(),
          if (_permissionError != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.bluetooth_disabled, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  Text(
                    _permissionError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _permissionError = null;
                      });
                      _initBluetooth();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                final device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed: btState.isConnecting
                        ? null
                        : () {
                            ref
                                .read(bluetoothProvider.notifier)
                                .connectToDevice(device);
                          },
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
