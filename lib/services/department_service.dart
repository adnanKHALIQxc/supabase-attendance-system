import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/department.dart';

class DepartmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createDepartment({
    required String id,
    required String name,
  }) async {
    final upperId = id.trim().toUpperCase();

    // Check for duplicates
    final existing = await _client
        .from('departments')
        .select('id')
        .eq('id', upperId)
        .limit(1);

    if (existing.isNotEmpty) {
      throw Exception('Department "$upperId" already exists');
    }

    await _client.from('departments').insert({
      'id': upperId,
      'name': name.trim(),
      'is_active': true,
    });
  }

  Future<List<Department>> getAllDepartments() async {
    final rows = await _client
        .from('departments')
        .select()
        .eq('is_active', true)
        .order('id', ascending: true);

    return (rows as List)
        .map((r) => Department.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }
}