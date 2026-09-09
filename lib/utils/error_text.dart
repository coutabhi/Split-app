import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any thrown error into a message worth showing the user (and worth
/// reading ourselves while debugging) instead of a generic "try again".
String describeError(Object error) {
  if (error is PostgrestException) {
    final code = error.code != null ? ' (${error.code})' : '';
    return '${error.message}$code';
  }
  return error.toString();
}
