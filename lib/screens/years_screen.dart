import 'package:flutter/material.dart';
import '../models/department.dart';
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
              trailing: const Icon(Icons.chevron_right),
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