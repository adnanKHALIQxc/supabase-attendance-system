import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Returns role ('admin' | 'teacher') if login succeeds, else null.
  Future<({String? role, String? error})> login(
    String id,
    String password,
  ) async {
    try {
      final email = '$id@uniattend.app';

      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final uid = res.user?.id;
      if (uid == null) {
        return (role: null, error: 'Sign-in failed — no user returned.');
      }

      // Check teachers table FIRST (RLS allows authenticated read)
      final teacherRows = await _client
          .from('teachers')
          .select('role, login_code')
          .eq('id', uid)
          .limit(1);

      if (teacherRows.isNotEmpty) {
        final role = (teacherRows.first['role'] as String?) ?? 'teacher';
        return (role: role, error: null);
      }

      // Then check admins
      final adminRows = await _client
          .from('admins')
          .select('id')
          .eq('id', uid)
          .limit(1);

      if (adminRows.isNotEmpty) {
        return (role: 'admin', error: null);
      }

      await _client.auth.signOut();
      return (
        role: null,
        error: 'Signed in but no profile found. Check tables.',
      );
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      return (role: null, error: 'Auth error: ${e.message}');
    } catch (e) {
      debugPrint('Login error: $e');
      return (role: null, error: 'Unknown: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Creates a teacher account with an auto-generated 6-digit ID + password.
  /// Uses a secondary Supabase client so the admin stays signed in.
  Future<({String id, String password})> createTeacher({
    required String fullName,
    required String contactEmail,
  }) async {
    final teacherId = (100000 + Random().nextInt(900000)).toString();
    final generatedEmail = '$teacherId@uniattend.app';
    final generatedPassword = _generatePassword();

    // Secondary client — separate session, doesn't touch admin's auth
    final secondary = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    try {
      final res = await secondary.auth.signUp(
        email: generatedEmail,
        password: generatedPassword,
      );

      final newUid = res.user?.id;
      if (newUid == null) {
        throw Exception('Sign-up failed — no user returned.');
      }

      // Insert teacher row using the PRIMARY (admin) client
            await _client.from('teachers').insert({
        'id': newUid,
        'login_code': teacherId,
        'full_name': fullName,
        'contact_email': contactEmail,
        'auth_email': generatedEmail,
        'role': 'teacher',
        'is_active': true,
      });

      // Sign out the secondary client so it doesn't hold a session
      await secondary.auth.signOut();

      debugPrint('Created teacher: id=$teacherId uid=$newUid');
      return (id: teacherId, password: generatedPassword);
    } catch (e) {
      debugPrint('Create teacher error: $e');
      rethrow;
    }
  }

  String _generatePassword() {
    const chars =
        'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}





// 