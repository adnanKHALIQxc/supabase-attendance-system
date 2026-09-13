import 'package:flutter/material.dart';

import '../models/attendance_summary.dart';
import '../models/teaching_assignment.dart';
import '../services/attendance_service.dart';
import '../services/subject_service.dart';
import 'mark_attendance_screen.dart';

class SubjectAttendanceScreen extends StatefulWidget {
  final TeachingAssignment assignment;

  const SubjectAttendanceScreen({super.key, required this.assignment});

  @override
  State<SubjectAttendanceScreen> createState() =>
      _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  final _attendanceService = AttendanceService();
  final _subjectService = SubjectService();

  late Future<AttendanceSummary> _future;
  int _creditHours = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _fetch();
  }

  Future<AttendanceSummary> _fetch() async {
    try {
      final all = await _subjectService.getAllSubjects();
      final match =
          all.where((s) => s.id == widget.assignment.subjectId).toList();
      if (match.isNotEmpty) _creditHours = match.first.creditHours;
    } catch (_) {}

    return _attendanceService.getSummary(
      subjectId: widget.assignment.subjectId,
      sectionId: widget.assignment.sectionId,
    );
  }

  Future<void> _openMark() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(assignment: widget.assignment),
      ),
    );
    if (done == true) {
      // Reload summary
      setState(_load);
      // Also pop back to teacher dashboard per requirement
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final maxSlots = _creditHours * 15;

    return Scaffold(
      appBar: AppBar(
        title: Text(a.subjectName),
        actions: [
          IconButton(
            tooltip: 'Mark attendance',
            icon: const Icon(Icons.add_task),
            onPressed: _openMark,
          ),
        ],
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
      body: FutureBuilder<AttendanceSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final summary = snapshot.data!;

          return Column(
            children: [
              _header(summary.totalSlots, maxSlots),
              const Divider(height: 1),
              Expanded(
                child: summary.students.isEmpty
                    ? const Center(
                        child: Text('No students in this section yet.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: summary.students.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _studentCard(
                            summary.students[i],
                            summary.totalSlots,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int conducted, int maxSlots) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          const Icon(Icons.event_available, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Slots Conducted',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                '$conducted / $maxSlots',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _studentCard(StudentAttendance s, int totalSlots) {
    final pct = s.percentage(totalSlots);
    final color = _pctColor(pct);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(child: Text(s.rollNo.substring(0, 1))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    s.rollNo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${s.attended} / $totalSlots',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return Colors.green.shade700;
    if (pct >= 60) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}