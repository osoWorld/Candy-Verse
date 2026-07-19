/// Score goal cap granularity used by generated LevelConfig targets.
///
/// Source: ARCHITECTURE.md section 13 - generated content is deterministic.
const int generatedScoreTargetStep = 250;

/// Starting score goal before difficulty caps are applied.
///
/// Source: PRD.md section 10 - score levels need a readable target score.
const int generatedScoreBaseTarget = 3000;

/// Per-level score goal growth before difficulty caps are applied.
///
/// Source: DESIGN_DEFAULT - V1 generated score pacing heuristic.
const int generatedScorePerLevelTargetStep = 250;

/// Simple score levels cap below the playtest warning threshold.
///
/// Source: DESIGN_DEFAULT - V1 generated score target balance heuristic.
const double generatedSimpleScorePressureCap = 1.25;

/// Hard score levels cap below the playtest warning threshold.
///
/// Source: DESIGN_DEFAULT - V1 generated score target balance heuristic.
const double generatedHardScorePressureCap = 1.45;

/// Super Hard score levels cap below the playtest warning threshold.
///
/// Source: DESIGN_DEFAULT - V1 generated score target balance heuristic.
const double generatedSuperHardScorePressureCap = 1.65;

/// Nightmarishly Hard score levels cap below the playtest warning threshold.
///
/// Source: DESIGN_DEFAULT - V1 generated score target balance heuristic.
const double generatedNightmareScorePressureCap = 1.85;

/// Legendary score levels cap below the playtest warning threshold.
///
/// Source: DESIGN_DEFAULT - V1 generated score target balance heuristic.
const double generatedLegendaryScorePressureCap = 2.05;

/// Simple jelly levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated blocker objective balance heuristic.
const double generatedSimpleJellyPressure = 0.42;

/// Hard jelly levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated blocker objective balance heuristic.
const double generatedHardJellyPressure = 0.62;

/// Super Hard jelly levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated blocker objective balance heuristic.
const double generatedSuperHardJellyPressure = 0.78;

/// Nightmarishly Hard jelly levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated blocker objective balance heuristic.
const double generatedNightmareJellyPressure = 0.9;

/// Legendary jelly levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated blocker objective balance heuristic.
const double generatedLegendaryJellyPressure = 0.96;

/// Simple ingredientDrop levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated ingredient path balance heuristic.
const double generatedSimpleIngredientPressure = 0.16;

/// Hard ingredientDrop levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated ingredient path balance heuristic.
const double generatedHardIngredientPressure = 0.28;

/// Super Hard ingredientDrop levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated ingredient path balance heuristic.
const double generatedSuperHardIngredientPressure = 0.4;

/// Nightmarishly Hard ingredientDrop levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated ingredient path balance heuristic.
const double generatedNightmareIngredientPressure = 0.48;

/// Legendary ingredientDrop levels target this clear density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated ingredient path balance heuristic.
const double generatedLegendaryIngredientPressure = 0.58;

/// Simple mixed levels target this blocker objective density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated mixed-goal balance heuristic.
const double generatedSimpleMixedPressure = 0.34;

/// Hard mixed levels target this blocker objective density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated mixed-goal balance heuristic.
const double generatedHardMixedPressure = 0.44;

/// Super Hard mixed levels target this blocker objective density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated mixed-goal balance heuristic.
const double generatedSuperHardMixedPressure = 0.52;

/// Nightmarishly Hard mixed levels target this blocker objective density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated mixed-goal balance heuristic.
const double generatedNightmareMixedPressure = 0.66;

/// Legendary mixed levels target this blocker objective density per move.
///
/// Source: DESIGN_DEFAULT - V1 generated mixed-goal balance heuristic.
const double generatedLegendaryMixedPressure = 0.78;

/// Simple generated blocker objectives stay under this board density.
///
/// Source: DESIGN_DEFAULT - kept below playtest high-density warning threshold.
const double generatedSimpleBlockerDensityCap = 0.22;

/// Hard generated blocker objectives stay under this board density.
///
/// Source: DESIGN_DEFAULT - kept below playtest high-density warning threshold.
const double generatedHardBlockerDensityCap = 0.3;

/// Super Hard generated blocker objectives stay under this board density.
///
/// Source: DESIGN_DEFAULT - kept below playtest high-density warning threshold.
const double generatedSuperHardBlockerDensityCap = 0.36;

/// Nightmarishly Hard generated blocker objectives stay under this board density.
///
/// Source: DESIGN_DEFAULT - kept below playtest high-density warning threshold.
const double generatedNightmareBlockerDensityCap = 0.42;

/// Legendary generated blocker objectives stay under this board density.
///
/// Source: DESIGN_DEFAULT - kept below playtest high-density warning threshold.
const double generatedLegendaryBlockerDensityCap = 0.48;
