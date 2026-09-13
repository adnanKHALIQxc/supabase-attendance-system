class Teacher {
  final String uid;          // Supabase auth UID (= table PK)
  final String id;           // 6-digit login code
  final String fullName;
  final String contactEmail;
  final String role;
  final bool isActive;

  Teacher({
    required this.uid,
    required this.id,
    required this.fullName,
    required this.contactEmail,
    required this.role,
    required this.isActive,
  });

  factory Teacher.fromSupabase(Map<String, dynamic> row) {
    return Teacher(
      uid: row['id'] as String,
      id: (row['login_code'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      contactEmail: (row['contact_email'] as String?) ?? '',
      role: (row['role'] as String?) ?? 'teacher',
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}