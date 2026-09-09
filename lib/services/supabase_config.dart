/// Supabase project connection details. The anon key is meant to be
/// public — access control is enforced entirely by the row-level security
/// policies in supabase/schema.sql, not by keeping this secret.
class SupabaseConfig {
  static const String url = 'https://dbjmtktmeasqrdgrdzln.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRiam10a3RtZWFzcXJkZ3JkemxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5MzQ2ODMsImV4cCI6MjEwNDUxMDY4M30.Z-bZwhfaskS2G9mMvey-sraJ8gsxGJ3PET4Y4Pi70io';
}
