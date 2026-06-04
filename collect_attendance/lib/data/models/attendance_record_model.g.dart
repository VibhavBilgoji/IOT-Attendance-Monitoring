// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordModelAdapter extends TypeAdapter<AttendanceRecordModel> {
  @override
  final typeId = 4;

  @override
  AttendanceRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecordModel(
      id: fields[0] as String,
      lectureId: fields[1] as String,
      studentId: fields[2] as String,
      studentRfidUid: fields[3] as String,
      tappedAt: fields[4] as DateTime,
      isSynced: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecordModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lectureId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.studentRfidUid)
      ..writeByte(4)
      ..write(obj.tappedAt)
      ..writeByte(5)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
