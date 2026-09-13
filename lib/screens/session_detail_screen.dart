import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../services/attendance_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final AttendanceSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _service = AttendanceService();
  late Future<List<AttendanceRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getRecordsForSession(widget.session.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.subjectName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${s.date}  •  ${s.slot}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _summary(s),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<AttendanceRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(child: Text('No records found.'));
                }
                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = records[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(r.status)
                            .withValues(alpha: 0.15),
                        child: Icon(
                          _statusIcon(r.status),
                          color: _statusColor(r.status),
                          size: 20,
                        ),
                      ),
                      title: Text(r.studentName),
                      subtitle: Text(r.rollNo),
                      trailing: Text(
                        r.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _statusColor(r.status),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(AttendanceSession s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _chip('Total', s.totalStudents, Colors.blueGrey),
          const SizedBox(width: 8),
          _chip('Present', s.presentCount, Colors.green),
          const SizedBox(width: 8),
          _chip('Absent', s.absentCount, Colors.red),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check;
      case 'absent':
        return Icons.close;
      case 'excused':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }
}