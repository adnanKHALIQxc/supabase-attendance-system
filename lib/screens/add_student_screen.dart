import 'package:flutter/material.dart';
import '../models/section.dart';
import '../services/student_service.dart';

class AddStudentScreen extends StatefulWidget {
  final Section section;

  const AddStudentScreen({super.key, required this.section});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _enrollController = TextEditingController();
  final _service = StudentService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _enrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _service.addStudent(
        fullName: _nameController.text.trim(),
        rollNo: _rollController.text.trim(),
        enrollmentId: _enrollController.text.trim(),
        departmentId: widget.section.departmentId,
        sectionId: widget.section.id,
        year: widget.section.year,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added ✅')),
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
      appBar: AppBar(title: const Text('Add Student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number (e.g., CS-21-045)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _enrollController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Add Student'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}