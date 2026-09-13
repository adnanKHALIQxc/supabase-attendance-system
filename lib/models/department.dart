class Department {
  final String id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;

  Department({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
  });

  factory Department.fromSupabase(Map<String, dynamic> row) {
    return Department(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      isActive: (row['is_active'] as bool?) ?? true,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())
          : null,
    );
  }
}