import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/password_service.dart';
import 'add_teacher_screen.dart';

class TeachersListScreen extends StatelessWidget {
  const TeachersListScreen({super.key});

  Future<void> _resetPassword(
    BuildContext context,
    String uid,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text(
          'Generate a new password for $name?\n\n'
          'Their current password will stop working immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final newPassword = await PasswordService().resetTeacherPassword(uid);
      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Password Reset ✅'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New password for $name:'),
              const SizedBox(height: 12),
              SelectableText(
                newPassword,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Copy this and share with the teacher.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTeacherScreen()),
          );
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('teachers')
            .stream(primaryKey: ['id'])
            .eq('is_active', true)
            .order('full_name'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No teachers yet'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i];
              final name = data['full_name'] ?? 'Unknown';
              final uid = data['id'] as String;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
                subtitle: Text('ID: ${data['login_code'] ?? '-'}'),
                trailing: IconButton(
                  tooltip: 'Reset password',
                  icon: const Icon(Icons.lock_reset),
                  onPressed: () => _resetPassword(context, uid, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}