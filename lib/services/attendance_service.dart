import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';

class AttendanceService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Marks attendance via the `mark_attendance` RPC.
  /// Inserts one session row + all records atomically.
  /// Throws if a session for (subject, section, date, slot) already exists.
  Future<String> markAttendance({
    required String subjectId,
    required String subjectName,
    required String sectionId,
    required String teacherId,
    required String teacherName,
    required DateTime date,
    required String slot,
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
      'p_start_time': startTime,
      'p_end_time': endTime,
      'p_records': jsonRecords,
    });

    return result as String;
  }

  Future<List<AttendanceSession>> getSessionsForSection(
    String sectionId,
  ) async {
    final rows = await _client
        .from('attendance_sessions')
        .select()
        .eq('section_id', sectionId)
        .order('date', ascending: false)
        .order('slot', ascending: true);

    return (rows as List)
        .map((r) => AttendanceSession.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceSession>> getSessionsForTeacher(
    String teacherId,
  ) async {
    final rows = await _client
        .from('attendance_sessions')
        .select()
        .eq('teacher_id', teacherId)
        .order('date', ascending: false)
        .order('slot', ascending: true);

    return (rows as List)
        .map((r) => AttendanceSession.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceRecord>> getRecordsForSession(
    String sessionId,
  ) async {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('session_id', sessionId)
        .order('roll_no', ascending: true);

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