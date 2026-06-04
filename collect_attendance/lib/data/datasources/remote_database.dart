import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professor_model.dart';
import '../models/student_model.dart';
import '../models/lecture_model.dart';

class RemoteDatabase {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProfessorModel>> fetchProfessors() async {
    final response = await _client.from('professors').select();
    return (response as List).map((e) => ProfessorModel.fromJson(e)).toList();
  }

  Future<List<StudentModel>> fetchStudents() async {
    final response = await _client.from('students').select();
    return (response as List).map((e) => StudentModel.fromJson(e)).toList();
  }

  Future<void> upsertLecture(LectureModel lecture) async {
    await _client.from('lectures').upsert(lecture.toJson(), onConflict: 'id');
  }

  Future<void> upsertAttendanceRecords(List<Map<String, dynamic>> records) async {
    // Expected to have unique_student_lecture constraint handle deduplication
    await _client.from('attendance_records').upsert(records, onConflict: 'lecture_id, student_id');
  }
}
