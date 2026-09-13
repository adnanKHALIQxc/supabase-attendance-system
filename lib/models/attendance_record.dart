class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String rollNo;
  final String status; // present | absent | late | excused
  final String? remarks;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.status,
    this.remarks,
  });

  factory AttendanceRecord.fromSupabase(Map<String, dynamic> row) {
    return AttendanceRecord(
      id: row['id'] as String,
      sessionId: (row['session_id'] as String?) ?? '',
      studentId: (row['student_id'] as String?) ?? '',
      studentName: (row['student_name'] as String?) ?? '',
      rollNo: (row['roll_no'] as String?) ?? '',
      status: (row['status'] as String?) ?? 'present',
      remarks: row['remarks'] as String?,
    );
  }
}