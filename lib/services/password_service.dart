import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Calls the Edge Function `reset-teacher-password`.
  /// Returns the new plaintext password.
  Future<String> resetTeacherPassword(String teacherUid) async {
    try {
      final res = await _client.functions.invoke(
        'reset-teacher-password',
        body: {'teacherUid': teacherUid},
      );

      final data = res.data;
      if (data == null || data['password'] == null) {
        throw Exception(
          'Server returned no password. Response: ${data.toString()}',
        );
      }
      return data['password'] as String;
    } on FunctionException catch (e) {
      final details = e.details?.toString() ?? e.reasonPhrase ?? 'Reset failed';
      throw Exception(details);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}