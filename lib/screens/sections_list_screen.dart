import 'package:flutter/material.dart';
import '../models/department.dart';
import '../models/section.dart';
import '../services/section_service.dart';
import 'add_section_screen.dart';
import 'section_detail_screen.dart';

class SectionsListScreen extends StatefulWidget {
  final Department department;
  final int year;

  const SectionsListScreen({
    super.key,
    required this.department,
    required this.year,
  });

  @override
  State<SectionsListScreen> createState() => _SectionsListScreenState();
}

class _SectionsListScreenState extends State<SectionsListScreen> {
  final _service = SectionService();
  late Future<List<Section>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSections(widget.department.id, widget.year);
  }

  void _refresh() {
    setState(() {
      _future = _service.getSections(widget.department.id, widget.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department.id} — Year ${widget.year}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSectionScreen(
                department: widget.department,
                year: widget.year,
              ),
            ),
          );
          _refresh();
        },
      ),
      body: FutureBuilder<List<Section>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sections = snapshot.data ?? [];
          if (sections.isEmpty) {
            return const Center(
              child: Text('No sections yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, i) {
              final s = sections[i];
              return ListTile(
                leading: CircleAvatar(child: Text(s.name)),
                title: Text('Section ${s.name}'),
                subtitle:
                    Text('${s.totalStudents} students • ${s.academicYear}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionDetailScreen(section: s),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}