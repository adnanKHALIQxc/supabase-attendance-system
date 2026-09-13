import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subject.dart';

class SubjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createSubject({
    required String id,
    required String name,
    required int creditHours,
    required String departmentId,
    required int year,
    required int semester,
  }) async {
    final upperId = id.trim().toUpperCase();

    // Duplicate check
    final existing = await _client
        .from('subjects')
        .select('id')
        .eq('id', upperId)
        .limit(1);

    if (existing.isNotEmpty) {
      throw Exception('Subject "$upperId" already exists');
    }

    await _client.from('subjects').insert({
      'id': upperId,
      'name': name.trim(),
      'credit_hours': creditHours,
      'department_id': departmentId,
      'year': year,
      'semester': semester,
      'is_active': true,
    });
  }

  Future<List<Subject>> getAllSubjects() async {
    final rows = await _client
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('id', ascending: true);

    return (rows as List)
        .map((r) => Subject.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subject>> getSubjectsFor({
    required String departmentId,
    required int year,
  }) async {
    final rows = await _client
        .from('subjects')
        .select()
        .eq('department_id', departmentId)
        .eq('year', year)
        .eq('is_active', true)
        .order('id', ascending: true);

    return (rows as List)
        .map((r) => Subject.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }
}