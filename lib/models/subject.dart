class Subject {
  final String id;         // e.g. "CS301"
  final String name;       // e.g. "Data Structures"
  final int creditHours;
  final String departmentId;
  final int year;
  final int semester;
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    required this.creditHours,
    required this.departmentId,
    required this.year,
    required this.semester,
    this.isActive = true,
  });

  factory Subject.fromSupabase(Map<String, dynamic> row) {
    return Subject(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      creditHours: (row['credit_hours'] as int?) ?? 0,
      departmentId: (row['department_id'] as String?) ?? '',
      year: (row['year'] as int?) ?? 1,
      semester: (row['semester'] as int?) ?? 1,
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}