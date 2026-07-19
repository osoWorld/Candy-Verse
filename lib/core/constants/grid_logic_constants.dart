/// Minimum contiguous Base Candy count that forms a match.
///
/// Source: PRD.md §5 and ARCHITECTURE.md §7 — match-3 core loop.
const int minimumMatchLength = 3;

/// Edge length for a square Fish Charm match.
///
/// Source: PRD.md section 11 - fishCharm is created by a 2x2 square match.
const int fishCharmSquareEdgeLength = 2;

/// Wrapped special candy effect radius.
///
/// Source: PRD.md section 11 - wrapped clears a 3x3 area.
const int wrappedSpecialCandyRadius = 1;

/// Alchemy Bomb special candy effect radius.
///
/// Source: PRD.md section 11 - alchemyBomb triggers a large burst.
const int alchemyBombSpecialCandyRadius = 2;

/// Base value for deriving deterministic level GridState seeds from level ids.
///
/// Source: ARCHITECTURE.md section 13 - generated content uses stable seeds.
const int levelConfigGridSeedBase = 0x345678;

/// Multiplier for deriving deterministic level GridState seeds from level ids.
///
/// Source: ARCHITECTURE.md section 13 - generated content uses stable seeds.
const int levelConfigGridSeedMultiplier = 31;

/// Positive mask for deterministic level GridState seed values.
///
/// Source: ARCHITECTURE.md section 13 - generated content uses stable seeds.
const int levelConfigGridSeedMask = 0x7fffffff;

/// Chocolate blockers clear after one hit.
///
/// Source: ARCHITECTURE.md section 6 - BlockerType V1 blocker stacks.
const int chocolateBlockerHitPoints = 1;

/// Ice blockers clear after two hits.
///
/// Source: ARCHITECTURE.md section 6 - BlockerType V1 blocker stacks.
const int iceBlockerHitPoints = 2;

/// Wafer blockers clear after two hits.
///
/// Source: ARCHITECTURE.md section 6 - BlockerType V1 blocker stacks.
const int waferBlockerHitPoints = 2;

/// Syrup Lock blockers clear after one hit.
///
/// Source: ARCHITECTURE.md section 6 - BlockerType V1 blocker stacks.
const int syrupLockBlockerHitPoints = 1;

/// Spice Crate blockers clear after three hits.
///
/// Source: ARCHITECTURE.md section 6 - BlockerType V1 blocker stacks.
const int spiceCrateBlockerHitPoints = 3;

/// Generated jelly levels ask the player to clear this many blocker cells.
///
/// Source: PRD.md section 10 - V1 jelly LevelKind uses clearable board targets.
const int generatedJellyBlockerCount = 18;

/// Generated ingredientDrop levels use two exit blockers for V1 goal progress.
///
/// Source: PRD.md section 10 - ingredientDrop V1 goal target.
const int generatedIngredientExitBlockerCount = 2;

/// Generated candyOrder levels collect this many reactive-state candies.
///
/// Source: PRD.md section 10 - candyOrder V1 goal target.
const int generatedCandyOrderTargetCount = 12;

/// Generated mixed levels ask for this many blocker clears plus score pressure.
///
/// Source: PRD.md section 10 - mixed V1 goal target.
const int generatedMixedBlockerCount = 6;

/// Optional side blockers on generated score levels after the tutorial kingdom.
///
/// Source: ARCHITECTURE.md section 13 - deterministic generated V1 content.
const int generatedScoreSideBlockerCount = 4;

/// Optional side blockers on generated candyOrder levels after early lessons.
///
/// Source: ARCHITECTURE.md section 13 - deterministic generated V1 content.
const int generatedCandyOrderSideBlockerCount = 3;

/// Row multiplier for deterministic generated blocker placement.
///
/// Source: ARCHITECTURE.md section 13 - deterministic generated V1 content.
const int generatedBlockerRankRowMultiplier = 73856093;

/// Column multiplier for deterministic generated blocker placement.
///
/// Source: ARCHITECTURE.md section 13 - deterministic generated V1 content.
const int generatedBlockerRankColumnMultiplier = 19349663;

/// Level multiplier for deterministic generated blocker placement.
///
/// Source: ARCHITECTURE.md section 13 - deterministic generated V1 content.
const int generatedBlockerRankLevelMultiplier = 83492791;

/// HUD score awarded for each tile cleared by gameplay cascades.
///
/// Source: PRD.md section 10 - score and mixed LevelKind progression.
const int gameplayScorePerClearedTile = 50;

/// HUD score awarded for each cascade wave.
///
/// Source: PRD.md section 10 - cascades contribute to score progression.
const int gameplayScorePerCascadeStep = 100;

/// HUD score awarded for each Reaction Effect.
///
/// Source: PRD.md section 10 - Reactive Confections add scoring value.
const int gameplayScorePerReactionEffect = 500;
