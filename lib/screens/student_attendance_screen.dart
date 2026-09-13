import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/attendance_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final Student student;
  final String sectionId;

  const StudentAttendanceScreen({
    super.key,
    required this.student,
    required this.sectionId,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final _service = AttendanceService();

  late Future<
      List<
          ({
            String subjectId,
            String subjectName,
            int totalSlots,
            int attendedSlots,
          })>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getStudentAttendanceBreakdown(
      studentId: widget.student.id,
      sectionId: widget.sectionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return Scaffold(
      appBar: AppBar(title: Text(s.fullName)),
      body: FutureBuilder<
          List<
              ({
                String subjectId,
                String subjectName,
                int totalSlots,
                int attendedSlots,
              })>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final breakdown = snapshot.data ?? [];

          return Column(
            children: [
              _header(s),
              const Divider(height: 1),
              Expanded(
                child: breakdown.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No attendance data available yet.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: breakdown.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _subjectCard(breakdown[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(Student s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Text(
              s.rollNo.substring(0, 1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                s.rollNo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                s.enrollmentId,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(
    ({
      String subjectId,
      String subjectName,
      int totalSlots,
      int attendedSlots,
    }) b,
  ) {
    final pct =
        b.totalSlots == 0 ? 0.0 : (b.attendedSlots / b.totalSlots) * 100;
    final color = _pctColor(pct);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                b.subjectId.length >= 2
                    ? b.subjectId.substring(b.subjectId.length - 3)
                    : b.subjectId,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.subjectName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    b.subjectId,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${b.attendedSlots} / ${b.totalSlots}',
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