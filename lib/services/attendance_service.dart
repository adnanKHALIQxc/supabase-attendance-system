import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/attendance_summary.dart';

class AttendanceService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Marks attendance via the `mark_attendance` RPC.
  /// One session per (subject, section, day). Subject credit-hour cap enforced.
  Future<String> markAttendance({
    required String subjectId,
    required String subjectName,
    required String sectionId,
    required String teacherId,
    required String teacherName,
    required DateTime date,
    required String slot,
    required int slotCount,
    required String startTime,
    required String endTime,
    required List<
            ({
              String studentId,
              String studentName,
              String rollNo,
              String status,
            })>
        records,
  }) async {
    final dateStr = _formatDate(date);

    final jsonRecords = records
        .map((r) => {
              'student_id': r.studentId,
              'student_name': r.studentName,
              'roll_no': r.rollNo,
              'status': r.status,
            })
        .toList();

    final result = await _client.rpc('mark_attendance', params: {
      'p_subject_id': subjectId,
      'p_subject_name': subjectName,
      'p_section_id': sectionId,
      'p_teacher_id': teacherId,
      'p_teacher_name': teacherName,
      'p_date': dateStr,
      'p_slot': slot,
      'p_slot_count': slotCount,
      'p_start_time': startTime,
      'p_end_time': endTime,
      'p_records': jsonRecords,
    });

    return result as String;
  }

  /// Returns the summary: total slots conducted + per-student attendance.
  Future<AttendanceSummary> getSummary({
    required String subjectId,
    required String sectionId,
  }) async {
    final res = await _client.rpc('get_attendance_summary', params: {
      'p_subject_id': subjectId,
      'p_section_id': sectionId,
    });
    return AttendanceSummary.fromSupabase(res);
  }

  /// Whether the teacher can still mark attendance today for this class.
  /// Checks: today already marked? credit-hour cap reached?
  Future<({bool canMark, String? reason})> canMarkToday({
    required String subjectId,
    required String sectionId,
    required int creditHours,
  }) async {
    final today = _formatDate(DateTime.now());

    // Already marked today?
    final todayRows = await _client
        .from('attendance_sessions')
        .select('id')
        .eq('subject_id', subjectId)
        .eq('section_id', sectionId)
        .eq('date', today)
        .limit(1);

    if (todayRows.isNotEmpty) {
      return (canMark: false, reason: 'Already marked for today.');
    }

    // Credit-hour cap
    final sessions = await _client
        .from('attendance_sessions')
        .select('slot_count')
        .eq('subject_id', subjectId)
        .eq('section_id', sectionId);

    final conducted = (sessions as List)
        .fold<int>(0, (sum, r) => sum + ((r['slot_count'] as int?) ?? 1));

    final maxSlots = creditHours * 15;
    if (conducted >= maxSlots) {
      return (
        canMark: false,
        reason: 'Slot limit reached ($conducted / $maxSlots).',
      );
    }

    return (canMark: true, reason: null);
  }

  Future<List<AttendanceSession>> getSessionsForSection(String sectionId) async {
    final rows = await _client
        .from('attendance_sessions')
        .select()
        .eq('section_id', sectionId)
        .order('date', ascending: false);

    return (rows as List)
        .map((r) => AttendanceSession.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceSession>> getSessionsForTeacher(String teacherId) async {
    final rows = await _client
        .from('attendance_sessions')
        .select()
        .eq('teacher_id', teacherId)
        .order('date', ascending: false);

    return (rows as List)
        .map((r) => AttendanceSession.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) async {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('session_id', sessionId)
        .order('roll_no', ascending: true);

    return (rows as List)
        .map((r) => AttendanceRecord.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

    /// Per-subject breakdown of a single student's attendance in a section.
  Future<List<({String subjectId, String subjectName, int totalSlots, int attendedSlots})>>
      getStudentAttendanceBreakdown({
    required String studentId,
    required String sectionId,
  }) async {
    final res = await _client.rpc('get_student_attendance_breakdown', params: {
      'p_student_id': studentId,
      'p_section_id': sectionId,
    });

    final list = (res as List? ?? []);
    return list
        .map((e) => (
              subjectId: (e['subject_id'] as String?) ?? '',
              subjectName: (e['subject_name'] as String?) ?? '',
              totalSlots: (e['total_slots'] as int?) ?? 0,
              attendedSlots: (e['attended_slots'] as int?) ?? 0,
            ))
        .toList();
  }

  /// Get all attendance records for a single student in a section.
  Future<List<AttendanceRecord>> getStudentRecords({
    required String studentId,
    required String sectionId,
  }) async {
    // Get session IDs for this section
    final sessionRows = await _client
        .from('attendance_sessions')
        .select('id')
        .eq('section_id', sectionId);

    final sessionIds =
        (sessionRows as List).map((r) => r['id'] as String).toList();
    if (sessionIds.isEmpty) return [];

    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('student_id', studentId)
        .inFilter('session_id', sessionIds)
        .order('marked_at', ascending: false);

    return (rows as List)
        .map((r) => AttendanceRecord.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}