class StudentAttendance {
  final String studentId;
  final String fullName;
  final String rollNo;
  final int attended;

  StudentAttendance({
    required this.studentId,
    required this.fullName,
    required this.rollNo,
    required this.attended,
  });

  factory StudentAttendance.fromMap(Map<String, dynamic> m) {
    return StudentAttendance(
      studentId: (m['student_id'] as String?) ?? '',
      fullName: (m['full_name'] as String?) ?? '',
      rollNo: (m['roll_no'] as String?) ?? '',
      attended: (m['attended'] as int?) ?? 0,
    );
  }

  double percentage(int totalSlots) {
    if (totalSlots <= 0) return 0;
    return (attended / totalSlots) * 100;
  }
}

class AttendanceSummary {
  final int totalSlots;
  final List<StudentAttendance> students;

  AttendanceSummary({
    required this.totalSlots,
    required this.students,
  });

  factory AttendanceSummary.fromSupabase(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final list = (map['students'] as List? ?? [])
        .map((e) => StudentAttendance.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    return AttendanceSummary(
      totalSlots: (map['total_slots'] as int?) ?? 0,
      students: list,
    );
  }
}