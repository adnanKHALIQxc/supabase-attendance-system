import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student.dart';

class StudentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> addStudent({
    required String fullName,
    required String rollNo,
    required String enrollmentId,
    required String departmentId,
    required String sectionId,
    required int year,
  }) async {
    // 1. Insert student
    await _client.from('students').insert({
      'full_name': fullName.trim(),
      'roll_no': rollNo.trim(),
      'enrollment_id': enrollmentId.trim(),
      'department_id': departmentId,
      'section_id': sectionId,
      'year': year,
      'is_active': true,
    });

    // 2. Increment section total_students
    await _client.rpc('increment_section_students', params: {
      'p_section_id': sectionId,
      'p_delta': 1,
    });
  }

  Future<List<Student>> getStudents(String sectionId) async {
    final rows = await _client
        .from('students')
        .select()
        .eq('section_id', sectionId)
        .eq('is_active', true)
        .order('roll_no', ascending: true);

    return (rows as List)
        .map((r) => Student.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }
}