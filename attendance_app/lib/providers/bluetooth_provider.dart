import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'lecture_provider.dart';

final bluetoothProvider = StateNotifierProvider<BluetoothNotifier, BluetoothStateData>((ref) {
  return BluetoothNotifier(ref);
});

class BluetoothStateData {
  final BluetoothConnection? connection;
  final bool isConnected;
  final bool isConnecting;
  final String? errorMessage;

  BluetoothStateData({
    this.connection,
    this.isConnected = false,
    this.isConnecting = false,
    this.errorMessage,
  });

  BluetoothStateData copyWith({
    BluetoothConnection? connection,
    bool? isConnected,
    bool? isConnecting,
    String? errorMessage,
  }) {
    return BluetoothStateData(
      connection: connection ?? this.connection,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage, // Notice we don't fallback to this.errorMessage to allow clearing
    );
  }
}

class BluetoothNotifier extends StateNotifier<BluetoothStateData> {
  final Ref _ref;
  StreamSubscription<Uint8List>? _streamSubscription;
  String _buffer = '';

  BluetoothNotifier(this._ref) : super(BluetoothStateData());

  Future<void> connectToDevice(BluetoothDevice device) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      state = state.copyWith(
        connection: connection,
        isConnected: true,
        isConnecting: false,
      );

      _streamSubscription = connection.input!.listen(_onDataReceived, onDone: () {
        _handleDisconnect();
      }, onError: (error) {
        _handleDisconnect();
      });
      
      // Notify lecture provider that HC-05 connected
      _ref.read(lectureProvider.notifier).setBluetoothConnected(true);
      
    } catch (e) {
      state = state.copyWith(isConnecting: false, errorMessage: 'Failed to connect: $e');
    }
  }

  void _onDataReceived(Uint8List data) {
    // Assuming data comes as ASCII characters
    String dataString = String.fromCharCodes(data);
    _buffer += dataString;

    // Assuming Arduino sends UIDs ending with a newline character (\n)
    if (_buffer.contains('\n')) {
      List<String> parts = _buffer.split('\n');
      // The last part might be incomplete
      _buffer = parts.removeLast();

      for (String uid in parts) {
        String cleanUid = uid.trim();
        if (cleanUid.isNotEmpty) {
          _ref.read(lectureProvider.notifier).handleScannedUid(cleanUid);
        }
      }
    }
  }

  void _handleDisconnect() {
    state = state.copyWith(isConnected: false, connection: null);
    _streamSubscription?.cancel();
    _ref.read(lectureProvider.notifier).setBluetoothConnected(false);
  }

  void disconnect() {
    state.connection?.close();
    _handleDisconnect();
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    state.connection?.close();
    super.dispose();
  }
}
