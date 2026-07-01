import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes Supabase client wiring for the data layer.
class SupabaseBootstrap {
  /// Creates a Supabase bootstrap helper.
  const SupabaseBootstrap();

  /// Initializes Supabase with the public publishable key.
  ///
  /// Inputs: project [url] and public [publishableKey]. Output: initialized client.
  /// Side effects: initializes SupabaseFlutter global client.
  Future<SupabaseClient> initialize({
    required String url,
    required String publishableKey,
  }) async {
    // ARCHITECTURE.md §10 and PROMPT.md §4.8: client uses anon key only; RLS
    // must protect player-specific tables server-side.
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    return Supabase.instance.client;
  }
}
