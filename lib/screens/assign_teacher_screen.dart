import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../services/assignment_service.dart';
import '../services/subject_service.dart';
import '../services/teacher_service.dart';

class AssignTeacherScreen extends StatefulWidget {
  final Section section;

  const AssignTeacherScreen({super.key, required this.section});

  @override
  State<AssignTeacherScreen> createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  final _subjectService = SubjectService();
  final _teacherService = TeacherService();
  final _assignmentService = AssignmentService();

  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Teacher>> _teachersFuture;

  Subject? _selectedSubject;
  Teacher? _selectedTeacher;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _subjectService.getSubjectsFor(
      departmentId: widget.section.departmentId,
      year: widget.section.year,
    );
    _teachersFuture = _teacherService.getAllTeachers();
  }

  Future<void> _save() async {
    if (_selectedSubject == null || _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both subject and teacher')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _assignmentService.createAssignment(
        teacherId: _selectedTeacher!.uid,
        teacherName: _selectedTeacher!.fullName,
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.name,
        sectionId: widget.section.id,
        academicYear: widget.section.academicYear,
        semester: _selectedSubject!.semester,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher assigned ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign to ${widget.section.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<Subject>>(
              future: _subjectsFuture,
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? [];
                return DropdownButtonFormField<Subject>(
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.id} — ${s.name}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v),
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Teacher>>(
              future: _teachersFuture,
              builder: (context, snapshot) {
                final teachers = snapshot.data ?? [];
                return DropdownButtonFormField<Teacher>(
                  initialValue: _selectedTeacher,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: teachers
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.fullName} (${t.id})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTeacher = v),
                );
              },
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.link),
                    label: const Text('Assign'),
                  ),
          ],
        ),
      ),
    );
  }
}