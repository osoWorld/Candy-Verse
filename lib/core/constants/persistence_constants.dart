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

/// Hive box for cached booster inventory rows.
///
/// Source: ARCHITECTURE.md section 12 - Hive stores booster inventory.
const String boosterInventoryBoxName = 'booster_inventory_cache';

/// Hive box for pending booster inventory rows.
///
/// Source: ARCHITECTURE.md section 12 - offline inventory sync queue.
const String pendingBoosterInventoryBoxName = 'booster_inventory_pending';

/// Hive box for player settings.
///
/// Source: PRD.md section 15 - Hive stores settings for offline play.
const String gameSettingsBoxName = 'game_settings';

/// Storage key for the single player settings record.
///
/// Source: PRD.md section 15 - V1 keeps one local settings payload.
const String gameSettingsStorageKey = 'local_settings';

/// Hive box for seen kingdom story panel keys.
///
/// Source: PRD.md section 7 - story panels appear on the Kingdom Map.
const String storyProgressBoxName = 'story_progress';

/// Storage key for seen kingdom story panel keys.
///
/// Source: DESIGN.md section 8 - story panels are short replayable moments.
const String seenStoryPanelsStorageKey = 'seen_story_panels';

/// Hive box for claimed kingdom checkpoint gate rewards.
///
/// Source: PRD.md section 7 - gates and bridges are part of the Kingdom Map.
const String kingdomGateRewardBoxName = 'kingdom_gate_rewards';

/// Storage key for claimed kingdom checkpoint gate rewards.
///
/// Source: PRD.md section 15 - Hive stores offline map progress state.
const String claimedKingdomGateRewardsStorageKey =
    'claimed_kingdom_gate_rewards';

/// Hive box for offline daily reward claim state.
///
/// Source: PRD.md section 2 - return loop includes daily rewards.
const String dailyRewardBoxName = 'daily_rewards';

/// Storage key for the single local daily reward state.
///
/// Source: PRD.md section 15 - Hive stores offline progression systems.
const String dailyRewardStateStorageKey = 'daily_reward_state';

/// Hive box for first-time tutorial progress.
///
/// Source: PRD.md section 4 - first levels must teach the game quickly.
const String tutorialProgressBoxName = 'tutorial_progress';

/// Storage key for seen tutorial prompt keys.
///
/// Source: PRD.md section 15 - Hive stores offline progression systems.
const String seenTutorialsStorageKey = 'seen_tutorials';

/// Default number of leaderboard entries to read.
///
/// Source: DESIGN_DEFAULT — leaderboard page size is not specified.
const int defaultLeaderboardLimit = 20;

/// Starter inventory count for each consumable V1 booster.
///
/// Source: PRD.md section 13 - V1 tracks inventory locally before Supabase.
const int defaultInitialBoosterInventoryCount = 3;

/// Local player id used before Supabase auth credentials are configured.
///
/// Source: PRD.md section 15 - offline progress must work without Supabase.
const String defaultLocalPlayerId = 'local-player';
