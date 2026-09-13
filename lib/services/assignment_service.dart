import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/teaching_assignment.dart';

class AssignmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createAssignment({
    required String teacherId,
    required String teacherName,
    required String subjectId,
    required String subjectName,
    required String sectionId,
    required String academicYear,
    required int semester,
  }) async {
        // Duplicate check — only one teacher per subject per section
    final existing = await _client
        .from('teaching_assignments')
        .select('id')
        .eq('subject_id', subjectId)
        .eq('section_id', sectionId)
        .limit(1);

    if (existing.isNotEmpty) {
      throw Exception(
        'This teacher is already assigned to teach '
        '$subjectName in $sectionId.',
      );
    }

    await _client.from('teaching_assignments').insert({
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'section_id': sectionId,
      'academic_year': academicYear,
      'semester': semester,
    });
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _client
        .from('teaching_assignments')
        .delete()
        .eq('id', assignmentId);
  }

  Future<List<TeachingAssignment>> getAssignmentsForSection(
    String sectionId,
  ) async {
    final rows = await _client
        .from('teaching_assignments')
        .select()
        .eq('section_id', sectionId)
        .order('subject_id', ascending: true);

    return (rows as List)
        .map((r) => TeachingAssignment.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeachingAssignment>> getAssignmentsForTeacher(
    String teacherId,
  ) async {
    final rows = await _client
        .from('teaching_assignments')
        .select()
        .eq('teacher_id', teacherId);

    final list = (rows as List)
        .map((r) => TeachingAssignment.fromSupabase(r as Map<String, dynamic>))
        .toList();

    list.sort((a, b) {
      final c = a.sectionId.compareTo(b.sectionId);
      return c != 0 ? c : a.subjectId.compareTo(b.subjectId);
    });
    return list;
  }
}