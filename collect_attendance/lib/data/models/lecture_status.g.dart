// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecture_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LectureStatusAdapter extends TypeAdapter<LectureStatus> {
  @override
  final typeId = 2;

  @override
  LectureStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LectureStatus.active;
      case 1:
        return LectureStatus.completedPendingSync;
      case 2:
        return LectureStatus.synced;
      default:
        return LectureStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, LectureStatus obj) {
    switch (obj) {
      case LectureStatus.active:
        writer.writeByte(0);
      case LectureStatus.completedPendingSync:
        writer.writeByte(1);
      case LectureStatus.synced:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LectureStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
