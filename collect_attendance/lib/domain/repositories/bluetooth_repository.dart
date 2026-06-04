import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothRepository {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  
  final _dataController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(license: License.nonprofit);
      _connectedDevice = device;
      
      _connectionStateController.add(true);

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionStateController.add(false);
          _cleanupConnection();
        }
      });

      await _discoverServicesAndSubscribe(device);
    } catch (e) {
      _connectionStateController.add(false);
      rethrow;
    }
  }

  Future<void> _discoverServicesAndSubscribe(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    
    // Look for a characteristic that supports notify or indicate
    BluetoothCharacteristic? notifyChar;
    
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        // Skip standard GATT Service Changed characteristic
        if (characteristic.uuid.toString().toLowerCase().contains('2a05')) {
          continue;
        }
        
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          notifyChar = characteristic;
          break;
        }
      }
      if (notifyChar != null) break;
    }

    if (notifyChar != null) {
      await notifyChar.setNotifyValue(true);
      
      String buffer = '';
      _characteristicSubscription = notifyChar.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          String strValue = String.fromCharCodes(value);
          debugPrint("BLE Data Received: '$strValue'");
          buffer += strValue;
          
          // Assuming newline delimited from Arduino
          if (buffer.contains('\n')) {
            List<String> parts = buffer.split('\n');
            buffer = parts.removeLast(); // keep the incomplete part
            
            for (String part in parts) {
              String cleanData = part.trim();
              if (cleanData.isNotEmpty) {
                _dataController.add(cleanData);
              }
            }
          }
        }
      });
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanupConnection();
  }

  void _cleanupConnection() {
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _connectedDevice = null;
  }
}
