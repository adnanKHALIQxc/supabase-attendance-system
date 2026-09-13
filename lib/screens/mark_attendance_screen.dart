import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/teaching_assignment.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';

class ClassSlot {
  final String label;
  final String startTime;
  final String endTime;

  const ClassSlot(this.label, this.startTime, this.endTime);
}

const List<ClassSlot> kClassSlots = [
  ClassSlot('08:30 - 09:20', '08:30', '09:20'),
  ClassSlot('09:30 - 10:20', '09:30', '10:20'),
  ClassSlot('10:30 - 11:20', '10:30', '11:20'),
  ClassSlot('11:30 - 12:20', '11:30', '12:20'),
  ClassSlot('13:00 - 13:50', '13:00', '13:50'),
  ClassSlot('14:00 - 14:50', '14:00', '14:50'),
];

class MarkAttendanceScreen extends StatefulWidget {
  final TeachingAssignment assignment;

  const MarkAttendanceScreen({super.key, required this.assignment});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _studentService = StudentService();
  final _attendanceService = AttendanceService();

  DateTime _date = DateTime.now();
  ClassSlot _slot = kClassSlots.first;

  List<Student> _students = [];
  final Map<String, String> _statuses = {}; // studentId → present/absent/late

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final list =
          await _studentService.getStudents(widget.assignment.sectionId);
      if (!mounted) return;
      setState(() {
        _students = list;
        _statuses.clear();
        for (final s in list) {
          _statuses[s.id] = 'present';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _setStatus(String studentId, String status) {
    setState(() => _statuses[studentId] = status);
  }

  void _setAll(String status) {
    setState(() {
      for (final s in _students) {
        _statuses[s.id] = status;
      }
    });
  }

  int _countOf(String status) =>
      _statuses.values.where((v) => v == status).length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_students.isEmpty) {
      _snack('No students to mark.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Text(
          'Submit attendance for ${widget.assignment.subjectName}\n'
          'Section ${widget.assignment.sectionId}\n\n'
          'Date: ${_formatDate(_date)}\n'
          'Slot: ${_slot.label}\n\n'
          'Present: ${_countOf('present')}\n'
          'Absent: ${_countOf('absent')}\n'
          'Late: ${_countOf('late')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);

    try {
      final records = _students
          .map((s) => (
                studentId: s.id,
                studentName: s.fullName,
                rollNo: s.rollNo,
                status: _statuses[s.id] ?? 'present',
              ))
          .toList();

      await _attendanceService.markAttendance(
        subjectId: widget.assignment.subjectId,
        subjectName: widget.assignment.subjectName,
        sectionId: widget.assignment.sectionId,
        teacherId: widget.assignment.teacherId,
        teacherName: widget.assignment.teacherName,
        date: _date,
        slot: _slot.label,
        startTime: _slot.startTime,
        endTime: _slot.endTime,
        records: records,
      );

      if (!mounted) return;
      _snack('Attendance marked ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;

    return Scaffold(
      appBar: AppBar(
        title: Text(a.subjectName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Section ${a.sectionId}  •  ${a.subjectId}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text('Error: $_loadError'))
              : _students.isEmpty
                  ? const Center(
                      child: Text('No students in this section yet.'),
                    )
                  : Column(
                      children: [
                        _topControls(),
                        _summaryBar(),
                        _quickActions(),
                        const Divider(height: 1),
                        Expanded(child: _studentList()),
                      ],
                    ),
      bottomNavigationBar: _loading || _students.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _submitting ? 'Submitting...' : 'Submit Attendance',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _topControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_formatDate(_date)),
              onPressed: _pickDate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<ClassSlot>(
              initialValue: _slot,
              decoration: const InputDecoration(
                labelText: 'Slot',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: kClassSlots
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _slot = v ?? _slot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _statChip('Present', _countOf('present'), Colors.green),
          const SizedBox(width: 8),
          _statChip('Absent', _countOf('absent'), Colors.red),
          const SizedBox(width: 8),
          _statChip('Late', _countOf('late'), Colors.orange),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('All Present'),
              onPressed: () => _setAll('present'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('All Absent'),
              onPressed: () => _setAll('absent'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentList() {
    return ListView.separated(
      itemCount: _students.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = _students[i];
        final status = _statuses[s.id] ?? 'present';

        return ListTile(
          leading: CircleAvatar(child: Text(s.rollNo.substring(0, 1))),
          title: Text(s.fullName),
          subtitle: Text(s.rollNo),
          trailing: _statusToggle(s.id, status),
        );
      },
    );
  }

  Widget _statusToggle(String studentId, String current) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleBtn(studentId, current, 'present', Icons.check, Colors.green),
        _toggleBtn(studentId, current, 'absent', Icons.close, Colors.red),
        _toggleBtn(studentId, current, 'late', Icons.schedule, Colors.orange),
      ],
    );
  }

  Widget _toggleBtn(
    String studentId,
    String current,
    String status,
    IconData icon,
    Color color,
  ) {
    final selected = current == status;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _setStatus(studentId, status),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: selected ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}