import 'package:flutter/material.dart';

import '../models/department.dart';
import '../services/export_service.dart';
import 'export_helpers.dart';
import 'sections_list_screen.dart';

class YearsScreen extends StatelessWidget {
  final Department department;

  const YearsScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${department.id} — Years')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [1, 2, 3, 4].map((year) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('$year')),
              title: Text(_yearLabel(year)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Export year',
                    icon: const Icon(Icons.download),
                    onPressed: () => _handleExport(context, year),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionsListScreen(
                      department: department,
                      year: year,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, int year) async {
    final choice = await showExportMenu(context);
    if (choice == null) return;
    if (!context.mounted) return;

    final label = _yearLabel(year);
    final format = choice == 'excel' ? ExportFormat.excel : ExportFormat.png;
    final date = _dateStamp();
    final safeDept = department.id;
    final safeYear = year;
    final fileName =
        '${safeDept}_${safeYear}_${safeYear == 1 ? "1st" : safeYear == 2 ? "2nd" : safeYear == 3 ? "3rd" : "4th"}_Year_attendance_$date';

    await runExport(
      context: context,
      fileName: fileName,
      build: () async {
        final service = ExportService();
        return service.generateYearZip(
          departmentId: department.id,
          year: year,
          yearLabel: '$safeDept-$label',
          format: format,
        );
      },
    );
  }

  String _dateStamp() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _yearLabel(int year) {
    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      default:
        return 'Year $year';
    }
  }
}