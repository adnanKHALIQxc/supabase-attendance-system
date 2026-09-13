import 'package:flutter/material.dart';
import '../models/department.dart';
import '../services/section_service.dart';

class AddSectionScreen extends StatefulWidget {
  final Department department;
  final int year;

  const AddSectionScreen({
    super.key,
    required this.department,
    required this.year,
  });

  @override
  State<AddSectionScreen> createState() => _AddSectionScreenState();
}

class _AddSectionScreenState extends State<AddSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController(text: '2025-2026');
  final _service = SectionService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _service.createSection(
        departmentId: widget.department.id,
        year: widget.year,
        name: _nameController.text.trim(),
        academicYear: _yearController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section added ✅')),
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
    final previewId = _service.buildId(
      widget.department.id,
      widget.year,
      _nameController.text.isEmpty ? '?' : _nameController.text,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Section')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Will be created as: $previewId',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Section Name (e.g., A, B)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length > 2) return 'Use 1-2 letters';
                  if (!RegExp(r'^[A-Za-z]+$').hasMatch(v.trim())) {
                    return 'Letters only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
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
                      child: const Text('Create Section'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}