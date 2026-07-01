/// Default charge needed to fill the Tempo Meter.
///
/// Source: Step 9 — Tempo Meter must fill and trigger burst.
const int tempoMeterChargeCapacity = 100;

/// Base Tempo Meter charge gained from any accepted swap.
///
/// Source: DESIGN_DEFAULT — exact swap charge value is not specified.
const int tempoMeterBaseSwapCharge = 20;

/// Bonus Tempo Meter charge gained from fast consecutive swaps.
///
/// Source: PRD.md §8 — Tempo Meter fills based on swap speed/skill.
const int tempoMeterQuickSwapBonusCharge = 15;

/// Fast-swap timing window for Tempo Meter skill charge.
///
/// Source: DESIGN_DEFAULT — exact fast-swap window is not specified.
const double tempoMeterQuickSwapWindowSeconds = 0.8;

/// Tempo Meter burst duration.
///
/// Source: DESIGN_DEFAULT — exact burst duration is not specified.
const double tempoMeterBurstDurationSeconds = 6;

/// Tempo Meter score multiplier during burst.
///
/// Source: PRD.md §8 and DESIGN.md §6 — burst scores double.
const int tempoMeterBurstScoreMultiplier = 2;

/// Tempo Meter fall-speed multiplier during burst.
///
/// Source: DESIGN.md §6 — burst communicates double speed/score.
const double tempoMeterBurstFallSpeedMultiplier = 2;

/// Fusion Booster area radius around the activation position.
///
/// Source: DESIGN_DEFAULT — exact hybrid area footprint is not specified.
const int fusionBoosterAreaRadius = 1;

/// Tempo Meter preview vial width.
///
/// Source: Step 9 — persistent HUD vial preview.
const double tempoMeterVialWidth = 42;

/// Tempo Meter preview vial height.
///
/// Source: Step 9 — persistent HUD vial preview.
const double tempoMeterVialHeight = 128;

/// Fusion Booster preview button size.
///
/// Source: DESIGN.md §6 — half-and-half booster tile appearance.
const double fusionBoosterButtonSize = 56;

/// Booster preview overlay outer padding.
///
/// Source: Step 9 — compact booster UI preview over gameplay.
const double boosterPreviewOverlayPadding = 16;

/// Booster preview overlay control gap.
///
/// Source: Step 9 — compact booster UI preview over gameplay.
const double boosterPreviewControlGap = 12;

/// Architect Tile wireframe sweep duration.
///
/// Source: DESIGN.md §6 — 200ms wireframe before topology snap.
const double architectTileWireframeDurationSeconds = 0.2;

/// Architect Tile snap duration.
///
/// Source: DESIGN.md §6 — 150ms snap after wireframe.
const double architectTileSnapDurationSeconds = 0.15;

/// Architect Tile rotation section size.
///
/// Source: PRD.md §8 — rotates a 3x3 section.
const int architectTileSectionSize = 3;

/// Echo Candy replay delay.
///
/// Source: DESIGN.md §6 — replay starts 400ms after the original.
const double echoCandyReplayDelaySeconds = 0.4;

/// Echo Candy replay opacity.
///
/// Source: DESIGN.md §6 — replay uses 70% opacity.
const double echoCandyReplayOpacity = 0.7;
