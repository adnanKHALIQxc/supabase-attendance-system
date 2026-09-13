import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/subject.dart';
import '../models/teaching_assignment.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import '../services/subject_service.dart';

/// A selectable class slot — either 1 period or 2 combined periods.
class ClassSlot {
  final String label;
  final String startTime;
  final String endTime;
  final int count;

  const ClassSlot({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.count,
  });
}

/// Single-period slots (8 total, breaks excluded)
const List<ClassSlot> kSingleSlots = [
  ClassSlot(label: '08:30 - 09:20', startTime: '08:30', endTime: '09:20', count: 1),
  ClassSlot(label: '09:20 - 10:10', startTime: '09:20', endTime: '10:10', count: 1),
  ClassSlot(label: '10:10 - 11:00', startTime: '10:10', endTime: '11:00', count: 1),
  ClassSlot(label: '11:30 - 12:20', startTime: '11:30', endTime: '12:20', count: 1),
  ClassSlot(label: '12:20 - 13:10', startTime: '12:20', endTime: '13:10', count: 1),
  ClassSlot(label: '14:00 - 14:50', startTime: '14:00', endTime: '14:50', count: 1),
  ClassSlot(label: '14:50 - 15:40', startTime: '14:50', endTime: '15:40', count: 1),
  ClassSlot(label: '15:40 - 16:30', startTime: '15:40', endTime: '16:30', count: 1),
];

/// Double-period slots (5 combined ranges)
const List<ClassSlot> kDoubleSlots = [
  ClassSlot(label: '08:30 - 10:10', startTime: '08:30', endTime: '10:10', count: 2),
  ClassSlot(label: '09:20 - 11:00', startTime: '09:20', endTime: '11:00', count: 2),
  ClassSlot(label: '11:30 - 13:10', startTime: '11:30', endTime: '13:10', count: 2),
  ClassSlot(label: '14:00 - 15:40', startTime: '14:00', endTime: '15:40', count: 2),
  ClassSlot(label: '14:50 - 16:30', startTime: '14:50', endTime: '16:30', count: 2),
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
  final _subjectService = SubjectService();

  int _slotCount = 1;
  ClassSlot _slot = kSingleSlots.first;

  List<Student> _students = [];
  final Map<String, String> _statuses = {};

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Load students
      final list =
          await _studentService.getStudents(widget.assignment.sectionId);

      // Check pre-conditions (today already marked? credit cap reached?)
      // We fetch the subject's credit hours first
      List<Subject> subjects;
      try {
        subjects = await _subjectService
            .getAllSubjects()
            .then((all) => all.where((s) => s.id == widget.assignment.subjectId).toList());
      } catch (_) {
        subjects = [];
      }
      final creditHours = subjects.isEmpty ? 3 : subjects.first.creditHours;

      final check = await _attendanceService.canMarkToday(
        subjectId: widget.assignment.subjectId,
        sectionId: widget.assignment.sectionId,
        creditHours: creditHours,
      );

      if (!mounted) return;

      if (!check.canMark) {
        setState(() {
          _loadError = check.reason ?? 'Cannot mark attendance now.';
          _loading = false;
        });
        return;
      }

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

  void _onSlotCountChanged(int? count) {
    if (count == null) return;
    setState(() {
      _slotCount = count;
      _slot = count == 1 ? kSingleSlots.first : kDoubleSlots.first;
    });
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
          '${widget.assignment.subjectName}\n'
          'Section ${widget.assignment.sectionId}\n\n'
          'Date: ${_todayString()}\n'
          'Slot: ${_slot.label}  ($_slotCount slot${_slotCount > 1 ? 's' : ''})\n\n'
          'Present: ${_countOf('present')}\n'
          'Absent: ${_countOf('absent')}',
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
        date: DateTime.now(),
        slot: _slot.label,
        slotCount: _slotCount,
        startTime: _slot.startTime,
        endTime: _slot.endTime,
        records: records,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
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

  String _todayString() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

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
              ? _blockedView(_loadError!)
              : _students.isEmpty
                  ? const Center(
                      child: Text('No students in this section yet.'),
                    )
                  : Column(
                      children: [
                        _controls(),
                        _summaryBar(),
                        _quickActions(),
                        const Divider(height: 1),
                        Expanded(child: _studentList()),
                      ],
                    ),
      bottomNavigationBar: _loading || _students.isEmpty || _loadError != null
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

  Widget _blockedView(String reason) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _todayString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: _slotCount,
              decoration: const InputDecoration(
                labelText: 'Slots',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 slot')),
                DropdownMenuItem(value: 2, child: Text('2 slots')),
              ],
              onChanged: _onSlotCountChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotDropdown() {
    final options = _slotCount == 1 ? kSingleSlots : kDoubleSlots;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<ClassSlot>(
        initialValue: options.contains(_slot) ? _slot : options.first,
        decoration: const InputDecoration(
          labelText: 'Time',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: options
            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
            .toList(),
        onChanged: (v) => setState(() => _slot = v ?? _slot),
      ),
    );
  }

  Widget _summaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statChip('Present', _countOf('present'), Colors.green),
          const SizedBox(width: 8),
          _statChip('Absent', _countOf('absent'), Colors.red),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    return Column(
      children: [
        _slotDropdown(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
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
          ),
        ),
      ],
    );
  }

  Widget _statusToggle(String studentId, String current) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleBtn(studentId, current, 'present', Icons.check, Colors.green),
        _toggleBtn(studentId, current, 'absent', Icons.close, Colors.red),
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