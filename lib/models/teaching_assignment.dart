class TeachingAssignment {
  final String id;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String academicYear;
  final int semester;

  TeachingAssignment({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.academicYear,
    required this.semester,
  });

  factory TeachingAssignment.fromSupabase(Map<String, dynamic> row) {
    return TeachingAssignment(
      id: row['id'] as String,
      teacherId: (row['teacher_id'] as String?) ?? '',
      teacherName: (row['teacher_name'] as String?) ?? '',
      subjectId: (row['subject_id'] as String?) ?? '',
      subjectName: (row['subject_name'] as String?) ?? '',
      sectionId: (row['section_id'] as String?) ?? '',
      academicYear: (row['academic_year'] as String?) ?? '',
      semester: (row['semester'] as int?) ?? 1,
    );
  }
}