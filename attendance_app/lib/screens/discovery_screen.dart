import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    _getPairedDevices();
    setState(() {});
  }

  void _getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (ex) {
      debugPrint("Error getting paired devices: $ex");
    }
    setState(() {
      _devicesList = devices;
    });
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
