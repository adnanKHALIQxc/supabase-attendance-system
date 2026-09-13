import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/section.dart';

class SectionService {
  final SupabaseClient _client = Supabase.instance.client;

  String buildId(String deptId, int year, String name) {
    return '$deptId-$year${name.toUpperCase()}';
  }

  Future<void> createSection({
    required String departmentId,
    required int year,
    required String name,
    required String academicYear,
  }) async {
    final sectionId = buildId(departmentId, year, name);

    // Duplicate check
    final existing = await _client
        .from('sections')
        .select('id')
        .eq('id', sectionId)
        .limit(1);

    if (existing.isNotEmpty) {
      throw Exception('Section "$sectionId" already exists');
    }

    await _client.from('sections').insert({
      'id': sectionId,
      'department_id': departmentId,
      'year': year,
      'name': name.toUpperCase(),
      'academic_year': academicYear,
      'total_students': 0,
      'is_active': true,
    });
  }

  Future<List<Section>> getSections(String departmentId, int year) async {
    final rows = await _client
        .from('sections')
        .select()
        .eq('department_id', departmentId)
        .eq('year', year)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (rows as List)
        .map((r) => Section.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetches sections matching a list of IDs.
  /// Supabase `inFilter` has no practical limit — safe for any size.
  Future<List<Section>> getSectionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final rows = await _client
        .from('sections')
        .select()
        .inFilter('id', ids);

    final list = (rows as List)
        .map((r) => Section.fromSupabase(r as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }
}