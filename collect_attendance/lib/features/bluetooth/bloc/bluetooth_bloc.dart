import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../domain/repositories/bluetooth_repository.dart';

// --- Events ---
abstract class BluetoothEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartScan extends BluetoothEvent {}

class StopScan extends BluetoothEvent {}

class ConnectToDevice extends BluetoothEvent {
  final BluetoothDevice device;
  ConnectToDevice(this.device);
  @override
  List<Object?> get props => [device];
}

class DisconnectDevice extends BluetoothEvent {}

class _ConnectionStateChanged extends BluetoothEvent {
  final bool isConnected;
  _ConnectionStateChanged(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

// --- States ---
abstract class BluetoothState extends Equatable {
  final bool isConnected;
  const BluetoothState({this.isConnected = false});
  @override
  List<Object?> get props => [isConnected];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothScanning extends BluetoothState {}

class BluetoothError extends BluetoothState {
  final String message;
  const BluetoothError(this.message);
  @override
  List<Object?> get props => [message, isConnected];
}

class BluetoothConnected extends BluetoothState {
  const BluetoothConnected() : super(isConnected: true);
}

class BluetoothConnecting extends BluetoothState {}

// --- BLoC ---
class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothRepository _repository;
  StreamSubscription? _connectionSub;

  BluetoothBloc(this._repository) : super(BluetoothInitial()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectDevice>(_onDisconnectDevice);
    on<_ConnectionStateChanged>(_onConnectionStateChanged);

    _connectionSub = _repository.connectionStateStream.listen((isConnected) {
      add(_ConnectionStateChanged(isConnected));
    });
  }

  Future<void> _onStartScan(StartScan event, Emitter<BluetoothState> emit) async {
    emit(BluetoothScanning());
    try {
      await _repository.startScan();
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> _onStopScan(StopScan event, Emitter<BluetoothState> emit) async {
    await _repository.stopScan();
    emit(BluetoothInitial());
  }

  Future<void> _onConnectToDevice(ConnectToDevice event, Emitter<BluetoothState> emit) async {
    emit(BluetoothConnecting());
    try {
      await _repository.connectToDevice(event.device);
      emit(const BluetoothConnected());
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> _onDisconnectDevice(DisconnectDevice event, Emitter<BluetoothState> emit) async {
    await _repository.disconnect();
    emit(BluetoothInitial());
  }

  void _onConnectionStateChanged(_ConnectionStateChanged event, Emitter<BluetoothState> emit) {
    if (event.isConnected) {
      emit(const BluetoothConnected());
    } else {
      emit(BluetoothInitial());
    }
  }

  @override
  Future<void> close() {
    _connectionSub?.cancel();
    return super.close();
  }
}
