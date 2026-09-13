import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';
import 'add_subject_screen.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  final _service = SubjectService();
  late Future<List<Subject>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllSubjects();
  }

  void _refresh() {
    setState(() => _future = _service.getAllSubjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
          );
          _refresh();
        },
      ),
      body: FutureBuilder<List<Subject>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const Center(child: Text('No subjects yet'));
          }
          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final s = subjects[i];
              return ListTile(
                leading: CircleAvatar(child: Text(s.id)),
                title: Text(s.name),
                subtitle: Text(
                  '${s.departmentId} • Year ${s.year} • ${s.creditHours} CH',
                ),
              );
            },
          );
        },
      ),
    );
  }
}