import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      _idController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final route = auth.role == 'admin'
          ? const AdminDashboardScreen()
          : const TeacherDashboardScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => route),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '6-Digit ID'),
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}