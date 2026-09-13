class Section {
  final String id;
  final String departmentId;
  final int year;
  final String name;
  final String academicYear;
  final int totalStudents;
  final bool isActive;

  Section({
    required this.id,
    required this.departmentId,
    required this.year,
    required this.name,
    required this.academicYear,
    this.totalStudents = 0,
    this.isActive = true,
  });

  factory Section.fromSupabase(Map<String, dynamic> row) {
    return Section(
      id: row['id'] as String,
      departmentId: (row['department_id'] as String?) ?? '',
      year: (row['year'] as int?) ?? 1,
      name: (row['name'] as String?) ?? '',
      academicYear: (row['academic_year'] as String?) ?? '',
      totalStudents: (row['total_students'] as int?) ?? 0,
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}