import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'departments_list_screen.dart';
import 'teachers_list_screen.dart';
import 'subjects_list_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              context,
              icon: Icons.account_balance,
              title: 'Departments',
              subtitle: 'Manage departments, years, sections, students',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DepartmentsListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              icon: Icons.book,
              title: 'Subjects',
              subtitle: 'Manage courses offered',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubjectsListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              icon: Icons.person,
              title: 'Teachers',
              subtitle: 'Add and manage teachers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeachersListScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}