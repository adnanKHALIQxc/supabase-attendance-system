import 'package:flutter/material.dart';
import '../models/department.dart';
import '../services/department_service.dart';
import 'add_department_screen.dart';
import 'years_screen.dart';

class DepartmentsListScreen extends StatefulWidget {
  const DepartmentsListScreen({super.key});

  @override
  State<DepartmentsListScreen> createState() => _DepartmentsListScreenState();
}

class _DepartmentsListScreenState extends State<DepartmentsListScreen> {
  final _service = DepartmentService();
  late Future<List<Department>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllDepartments();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getAllDepartments();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDepartmentScreen()),
          );
          _refresh();
        },
      ),
      body: FutureBuilder<List<Department>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final departments = snapshot.data ?? [];
          if (departments.isEmpty) {
            return const Center(child: Text('No departments yet'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: departments.length,
              itemBuilder: (context, i) {
                final dept = departments[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(dept.id)),
                  title: Text(dept.name),
                  subtitle: Text('Code: ${dept.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YearsScreen(department: dept),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}