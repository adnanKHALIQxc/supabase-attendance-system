import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import '../models/section.dart';
import '../services/attendance_service.dart';
import 'subject_sessions_screen.dart';

class SectionAttendanceScreen extends StatefulWidget {
  final Section section;

  const SectionAttendanceScreen({super.key, required this.section});

  @override
  State<SectionAttendanceScreen> createState() =>
      _SectionAttendanceScreenState();
}

class _SectionAttendanceScreenState extends State<SectionAttendanceScreen> {
  final _service = AttendanceService();
  late Future<List<AttendanceSession>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _service.getSessionsForSection(widget.section.id);
  }

  Map<String, List<AttendanceSession>> _groupBySubject(
    List<AttendanceSession> sessions,
  ) {
    final map = <String, List<AttendanceSession>>{};
    for (final s in sessions) {
      map.putIfAbsent(s.subjectId, () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.slot.compareTo(a.slot);
      });
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance — ${widget.section.id}'),
      ),
      body: FutureBuilder<List<AttendanceSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No attendance recorded for this section yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final grouped = _groupBySubject(sessions);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: grouped.length,
              itemBuilder: (context, i) {
                final subjectId = grouped.keys.elementAt(i);
                final subjectSessions = grouped[subjectId]!;
                return _subjectTile(subjectId, subjectSessions);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _subjectTile(
    String subjectId,
    List<AttendanceSession> sessions,
  ) {
    final subjectName = sessions.first.subjectName;
    final totalSlots =
        sessions.fold<int>(0, (sum, s) => sum + s.slotCount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Text(
            subjectId.length >= 3
                ? subjectId.substring(subjectId.length - 3)
                : subjectId,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '$subjectId  •  ${sessions.length} session${sessions.length > 1 ? 's' : ''}  •  $totalSlots slot${totalSlots > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectSessionsScreen(
              subjectId: subjectId,
              subjectName: subjectName,
              sectionId: widget.section.id,
              sessions: sessions,
            ),
          ),
        ),
      ),
    );
  }
}