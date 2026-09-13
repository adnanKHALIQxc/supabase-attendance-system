import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/teacher.dart';

class TeacherService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Teacher>> getAllTeachers() async {
    final rows = await _client
        .from('teachers')
        .select()
        .eq('is_active', true)
        .order('full_name', ascending: true);

    return (rows as List)
        .map((r) => Teacher.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<Teacher?> getTeacher(String uid) async {
    final rows = await _client
        .from('teachers')
        .select()
        .eq('id', uid)
        .limit(1);

    if (rows.isEmpty) return null;
    return Teacher.fromSupabase(rows.first);
  }
}