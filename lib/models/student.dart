class Student {
  final String id;
  final String fullName;
  final String rollNo;
  final String enrollmentId;
  final String departmentId;
  final String sectionId;
  final int year;

  Student({
    required this.id,
    required this.fullName,
    required this.rollNo,
    required this.enrollmentId,
    required this.departmentId,
    required this.sectionId,
    required this.year,
  });

  factory Student.fromSupabase(Map<String, dynamic> row) {
    return Student(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      rollNo: (row['roll_no'] as String?) ?? '',
      enrollmentId: (row['enrollment_id'] as String?) ?? '',
      departmentId: (row['department_id'] as String?) ?? '',
      sectionId: (row['section_id'] as String?) ?? '',
      year: (row['year'] as int?) ?? 1,
    );
  }
}