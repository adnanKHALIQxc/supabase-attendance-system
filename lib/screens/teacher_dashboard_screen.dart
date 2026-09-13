import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/teaching_assignment.dart';
import '../providers/auth_provider.dart';
import '../services/assignment_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'subject_attendance_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _assignmentService = AssignmentService();

  late Future<List<TeachingAssignment>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final uid = AuthService().currentUser?.id;
    _future = uid == null
        ? Future.value(<TeachingAssignment>[])
        : _assignmentService.getAssignmentsForTeacher(uid);
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<TeachingAssignment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No classes assigned yet.\nContact your admin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(a.subjectId)),
                  title: Text(a.subjectName),
                  subtitle: Text('Section ${a.sectionId}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectAttendanceScreen(assignment: a),
                      ),
                    );
                    if (updated == true) _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}