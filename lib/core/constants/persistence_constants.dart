/// Hive box for cached player progress rows.
///
/// Source: Step 12 — local Hive fallback for progress sync.
const String playerProgressBoxName = 'player_progress_cache';

/// Hive box for pending player progress rows.
///
/// Source: Step 12 — offline progress rows queue for later Supabase sync.
const String pendingPlayerProgressBoxName = 'player_progress_pending';

/// Hive box for cached leaderboard rows.
///
/// Source: Step 12 — local Hive fallback for leaderboard reads.
const String leaderboardBoxName = 'leaderboard_cache';

/// Hive box for pending leaderboard rows.
///
/// Source: Step 12 — offline leaderboard rows queue for later Supabase sync.
const String pendingLeaderboardBoxName = 'leaderboard_pending';

/// Default number of leaderboard entries to read.
///
/// Source: DESIGN_DEFAULT — leaderboard page size is not specified.
const int defaultLeaderboardLimit = 20;
