import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import 'session_detail_screen.dart';

class SubjectSessionsScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final List<AttendanceSession> sessions;

  const SubjectSessionsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final totalSlots =
        sessions.fold<int>(0, (sum, s) => sum + s.slotCount);

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$subjectId  •  Section $sectionId',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _header(totalSlots),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _sessionCard(context, sessions[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(int totalSlots) {
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
                'Total slots conducted',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                '$totalSlots',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Sessions',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                '${sessions.length}',
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

  Widget _sessionCard(BuildContext context, AttendanceSession s) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: s),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${s.slotCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.slot,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.teacherName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${s.presentCount}/${s.totalStudents}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'present',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}