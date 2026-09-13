import 'package:flutter/material.dart';
import '../models/department.dart';
import '../services/department_service.dart';
import '../services/subject_service.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController(text: '3');
  final _semesterController = TextEditingController(text: '5');

  final _subjectService = SubjectService();
  final _deptService = DepartmentService();

  late Future<List<Department>> _deptFuture;
  String? _selectedDept;
  int _selectedYear = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deptFuture = _deptService.getAllDepartments();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a department')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _subjectService.createSubject(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        creditHours: int.parse(_creditsController.text.trim()),
        departmentId: _selectedDept!,
        year: _selectedYear,
        semester: int.parse(_semesterController.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subject')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code (e.g., CS301)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(v.trim())) {
                    return 'Letters and digits only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Credit Hours',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 6) {
                    return 'Enter 1-6';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Department>>(
                future: _deptFuture,
                builder: (context, snapshot) {
                  final depts = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedDept,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: depts
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.id} — ${d.name}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDept = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4]
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v ?? 1),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 8) return 'Enter 1-8';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Subject'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}