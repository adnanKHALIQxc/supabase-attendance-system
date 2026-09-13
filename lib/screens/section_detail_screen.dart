// import 'package:flutter/material.dart';
// import '../models/section.dart';
// import '../models/student.dart';
// import '../models/teacher.dart';
// import '../services/section_service.dart';
// import '../services/student_service.dart';
// import '../services/teacher_service.dart';
// import 'add_student_screen.dart';
// import 'assign_teachers_screen.dart';
// import 'import_students_screen.dart';

// class SectionDetailScreen extends StatefulWidget {
//   final Section section;

//   const SectionDetailScreen({super.key, required this.section});

//   @override
//   State<SectionDetailScreen> createState() => _SectionDetailScreenState();
// }

// class _SectionDetailScreenState extends State<SectionDetailScreen> {
//   final _studentService = StudentService();
//   final _teacherService = TeacherService();
//   final _sectionService = SectionService();

//   late Future<List<Student>> _studentsFuture;
//   late Future<List<Teacher>> _teachersFuture;
//   late Future<Section?> _sectionFuture;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   void _load() {
//     _studentsFuture = _studentService.getStudents(widget.section.id);
//     _teachersFuture = _teacherService.getAllTeachers().then((all) =>
//         all.where((t) => t.assignedSectionIds.contains(widget.section.id)).toList());
//     _sectionFuture = _sectionService.getSectionsByIds([widget.section.id])
//         .then((list) => list.isEmpty ? null : list.first);
//   }

//   void _refresh() {
//     setState(_load);
//   }

//   Future<void> _openAssignTeachers() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AssignTeachersScreen(section: widget.section),
//       ),
//     );
//     _refresh();
//   }

//   Future<void> _openImport() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ImportStudentsScreen(section: widget.section),
//       ),
//     );
//     _refresh();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Section ${widget.section.id}'),
//         actions: [
//           IconButton(
//             tooltip: 'Import students',
//             icon: const Icon(Icons.upload_file),
//             onPressed: _openImport,
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         icon: const Icon(Icons.person_add),
//         label: const Text('Add Student'),
//         onPressed: () async {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => AddStudentScreen(section: widget.section),
//             ),
//           );
//           _refresh();
//         },
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async => _refresh(),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _teachersSection(),
//             const SizedBox(height: 24),
//             _studentsSection(),
//             const SizedBox(height: 80), // leave room for FAB
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _teachersSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.school, size: 20),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Assigned Teachers',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 const Spacer(),
//                 TextButton.icon(
//                   icon: const Icon(Icons.edit, size: 18),
//                   label: const Text('Manage'),
//                   onPressed: _openAssignTeachers,
//                 ),
//               ],
//             ),
//             const Divider(),
//             FutureBuilder<List<Teacher>>(
//               future: _teachersFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 }
//                 if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 }
//                 final teachers = snapshot.data ?? [];
//                 if (teachers.isEmpty) {
//                   return const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Text(
//                       'No teachers assigned yet.',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   );
//                 }
//                 return Column(
//                   children: teachers.map((t) {
//                     return ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: const CircleAvatar(child: Icon(Icons.person)),
//                       title: Text(t.fullName),
//                       subtitle: Text('ID: ${t.id}'),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _studentsSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.people, size: 20),
//                 const SizedBox(width: 8),
//                 FutureBuilder<Section?>(
//                   future: _sectionFuture,
//                   builder: (context, snapshot) {
//                     final count = snapshot.data?.totalStudents ?? 0;
//                     return Text(
//                       'Students ($count)',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const Divider(),
//             FutureBuilder<List<Student>>(
//               future: _studentsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 }
//                 if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 }
//                 final students = snapshot.data ?? [];
//                 if (students.isEmpty) {
//                   return const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     child: Text(
//                       'No students yet.\nTap + or use the upload icon.',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   );
//                 }
//                 return Column(
//                   children: students.map((s) {
//                     return ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: const CircleAvatar(child: Icon(Icons.person)),
//                       title: Text(s.fullName),
//                       subtitle:
//                           Text('Roll: ${s.rollNo} • ${s.enrollmentId}'),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../models/teaching_assignment.dart';
import '../services/assignment_service.dart';
import '../services/section_service.dart';
import '../services/student_service.dart';
import 'add_student_screen.dart';
import 'assign_teacher_screen.dart';
import 'import_students_screen.dart';

class SectionDetailScreen extends StatefulWidget {
  final Section section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  final _studentService = StudentService();
  final _assignmentService = AssignmentService();
  final _sectionService = SectionService();

  late Future<List<Student>> _studentsFuture;
  late Future<List<TeachingAssignment>> _assignmentsFuture;
  late Future<Section?> _sectionFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _studentsFuture = _studentService.getStudents(widget.section.id);
    _assignmentsFuture =
        _assignmentService.getAssignmentsForSection(widget.section.id);
    _sectionFuture = _sectionService
        .getSectionsByIds([widget.section.id])
        .then((list) => list.isEmpty ? null : list.first);
  }

  void _refresh() => setState(_load);

  Future<void> _openAssign() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignTeacherScreen(section: widget.section),
      ),
    );
    _refresh();
  }

  Future<void> _openImport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportStudentsScreen(section: widget.section),
      ),
    );
    _refresh();
  }

  Future<void> _deleteAssignment(TeachingAssignment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove assignment?'),
        content: Text(
          '${a.teacherName} will no longer teach ${a.subjectName} '
          'in ${a.sectionId}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _assignmentService.deleteAssignment(a.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Section ${widget.section.id}'),
        actions: [
          IconButton(
            tooltip: 'Import students',
            icon: const Icon(Icons.upload_file),
            onPressed: _openImport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddStudentScreen(section: widget.section),
            ),
          );
          _refresh();
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _assignmentsCard(),
            const SizedBox(height: 16),
            _studentsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _assignmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Teaching Assignments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Assign'),
                  onPressed: _openAssign,
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<List<TeachingAssignment>>(
              future: _assignmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No teachers assigned yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return Column(
                  children: list.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(a.subjectName),
                      subtitle: Text(
                        '${a.teacherName} • ${a.subjectId}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteAssignment(a),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                FutureBuilder<Section?>(
                  future: _sectionFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.totalStudents ?? 0;
                    return Text(
                      'Students ($count)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final students = snapshot.data ?? [];
                if (students.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No students yet. Tap + or upload.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return Column(
                  children: students.map((s) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(s.fullName),
                      subtitle:
                          Text('Roll: ${s.rollNo} • ${s.enrollmentId}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}