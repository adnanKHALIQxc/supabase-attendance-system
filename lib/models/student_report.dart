class SessionReport {
  final String date;
  final String slot;
  final int slotCount;
  final String status;

  SessionReport({
    required this.date,
    required this.slot,
    required this.slotCount,
    required this.status,
  });

  factory SessionReport.fromMap(Map<String, dynamic> m) {
    return SessionReport(
      date: (m['date'] as String?) ?? '',
      slot: (m['slot'] as String?) ?? '',
      slotCount: (m['slot_count'] as int?) ?? 1,
      status: (m['status'] as String?) ?? 'present',
    );
  }
}

class SubjectReport {
  final String subjectId;
  final String subjectName;
  final int conductedSlots;
  final int attendedSlots;
  final List<SessionReport> sessions;

  SubjectReport({
    required this.subjectId,
    required this.subjectName,
    required this.conductedSlots,
    required this.attendedSlots,
    required this.sessions,
  });

  double get percentage =>
      conductedSlots == 0 ? 0 : (attendedSlots / conductedSlots) * 100;

  factory SubjectReport.fromMap(Map<String, dynamic> m) {
    final sessionList = ((m['sessions'] as List?) ?? [])
        .map((e) => SessionReport.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return SubjectReport(
      subjectId: (m['subject_id'] as String?) ?? '',
      subjectName: (m['subject_name'] as String?) ?? '',
      conductedSlots: (m['conducted_slots'] as int?) ?? 0,
      attendedSlots: (m['attended_slots'] as int?) ?? 0,
      sessions: sessionList,
    );
  }
}

class StudentReport {
  final String id;
  final String fullName;
  final String rollNo;
  final String enrollmentId;
  final List<SubjectReport> subjects;

  StudentReport({
    required this.id,
    required this.fullName,
    required this.rollNo,
    required this.enrollmentId,
    required this.subjects,
  });

  factory StudentReport.fromMap(Map<String, dynamic> m) {
    final subjectList = ((m['subjects'] as List?) ?? [])
        .map((e) => SubjectReport.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return StudentReport(
      id: (m['id'] as String?) ?? '',
      fullName: (m['full_name'] as String?) ?? '',
      rollNo: (m['roll_no'] as String?) ?? '',
      enrollmentId: (m['enrollment_id'] as String?) ?? '',
      subjects: subjectList,
    );
  }
}

class SectionReport {
  final List<StudentReport> students;

  SectionReport({required this.students});

  factory SectionReport.fromSupabase(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final list = ((map['students'] as List?) ?? [])
        .map((e) => StudentReport.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return SectionReport(students: list);
  }
}