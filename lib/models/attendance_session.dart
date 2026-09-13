class AttendanceSession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String teacherId;
  final String teacherName;
  final String date; // YYYY-MM-DD
  final String slot;
  final String? startTime;
  final String? endTime;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final String status;

  AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.slot,
    this.startTime,
    this.endTime,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.status,
  });

  factory AttendanceSession.fromSupabase(Map<String, dynamic> row) {
    return AttendanceSession(
      id: row['id'] as String,
      subjectId: (row['subject_id'] as String?) ?? '',
      subjectName: (row['subject_name'] as String?) ?? '',
      sectionId: (row['section_id'] as String?) ?? '',
      teacherId: (row['teacher_id'] as String?) ?? '',
      teacherName: (row['teacher_name'] as String?) ?? '',
      date: row['date']?.toString() ?? '',
      slot: (row['slot'] as String?) ?? '',
      startTime: row['start_time'] as String?,
      endTime: row['end_time'] as String?,
      totalStudents: (row['total_students'] as int?) ?? 0,
      presentCount: (row['present_count'] as int?) ?? 0,
      absentCount: (row['absent_count'] as int?) ?? 0,
      lateCount: (row['late_count'] as int?) ?? 0,
      status: (row['status'] as String?) ?? 'finalized',
    );
  }
}