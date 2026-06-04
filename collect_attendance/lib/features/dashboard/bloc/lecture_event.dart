import 'package:equatable/equatable.dart';

abstract class LectureEvent extends Equatable {
  const LectureEvent();

  @override
  List<Object?> get props => [];
}

class StartLectureEvent extends LectureEvent {
  final String? professorId;
  const StartLectureEvent({this.professorId});
  @override
  List<Object?> get props => [professorId];
}

class EndLectureEvent extends LectureEvent {}

class UidScannedEvent extends LectureEvent {
  final String rfidUid;
  const UidScannedEvent(this.rfidUid);
  @override
  List<Object?> get props => [rfidUid];
}

class BluetoothStateChangedEvent extends LectureEvent {
  final bool isConnected;
  const BluetoothStateChangedEvent(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

class ConnectivityChangedEvent extends LectureEvent {
  final bool isConnected;
  const ConnectivityChangedEvent(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

class RequestManualSyncEvent extends LectureEvent {}

class LoadActiveSessionEvent extends LectureEvent {}

