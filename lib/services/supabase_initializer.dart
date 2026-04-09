import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      developer.log(
        '[DreamCatcher][Supabase] Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
        name: 'SupabaseInitializer',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      developer.log('[DreamCatcher][Supabase] Initialized successfully', name: 'SupabaseInitializer');
    } catch (e) {
      developer.log('[DreamCatcher][Supabase] Initialization failed: $e', name: 'SupabaseInitializer');
    }
  }
}
