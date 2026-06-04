// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecture_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LectureModelAdapter extends TypeAdapter<LectureModel> {
  @override
  final typeId = 3;

  @override
  LectureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LectureModel(
      id: fields[0] as String,
      professorId: fields[1] as String?,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
      status: fields[4] as LectureStatus,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LectureModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.professorId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LectureModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
