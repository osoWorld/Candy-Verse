/// Step 4 preview board row count.
///
/// Source: ARCHITECTURE.md §4 and Step 4 — static BoardComponent render smoke grid.
const int previewBoardRows = 7;

/// Step 4 preview board column count.
///
/// Source: ARCHITECTURE.md §4 and Step 4 — static BoardComponent render smoke grid.
const int previewBoardColumns = 7;

/// Logical tile size for the static Flame board preview.
///
/// Source: DESIGN.md §11 — candy sprites target square 128x128 frames.
const double staticBoardTileSize = 64;

/// Logical gap between static Flame board tiles.
///
/// Source: Step 4 — stable board layout with no animation.
const double staticBoardTileGap = 4;

/// Minimum live gameplay board horizontal safe margin.
///
/// Source: DESIGN.md section 6 - horizontal safe margin is 12px minimum.
const double liveBoardHorizontalSafeMargin = 12;

/// Preferred live gameplay board tile size for readability.
///
/// DOC_CONFLICT: DESIGN.md section 5 says special candies must read at 44px,
/// but DESIGN.md section 6 also requires 9 columns to fit 360px phones. A
/// 9-column board cannot satisfy both with current gaps/padding, so no-overflow
/// wins and tile visuals must remain readable below this preferred size.
const double liveBoardPreferredMinimumTileSize = 44;

/// Maximum live gameplay board tile size before preview art scale becomes large.
///
/// Source: DESIGN.md section 17 - 128px atlas target supports a 64px live base.
const double liveBoardMaximumTileSize = 64;

/// Static board background padding.
///
/// Source: Step 4 — stable board layout with no animation.
const double staticBoardPadding = 12;

/// Static board rounded corner radius.
///
/// Source: DESIGN.md section 6 - 18px corner radius at 360px board width.
const double staticBoardCornerRadius = 18;

/// Static candy tile stroke width.
///
/// Source: DESIGN.md §1 — glossy crystal confection tile definition.
const double staticTileStrokeWidth = 2;

/// Static candy tile highlight stroke width.
///
/// Source: DESIGN.md §1 — glossy semi-translucent candy aesthetic.
const double staticTileHighlightStrokeWidth = 3;

/// Static candy icon box size for Reactive State accessibility overlays.
///
/// Source: DESIGN.md §2 and §10 — small state icon overlay.
const double staticTileIconSize = 16;

/// Static candy icon inset for Reactive State accessibility overlays.
///
/// Source: DESIGN.md §2 and §10 — small state icon overlay.
const double staticTileIconInset = 6;

/// Static candy icon stroke width.
///
/// Source: DESIGN.md §2 and §10 — icon overlay must be distinguishable.
const double staticTileIconStrokeWidth = 2;

/// Basic swap animation duration.
///
/// Source: DESIGN.md section 6 - valid swap uses 180ms easeOutCubic.
const double basicSwapDurationSeconds = 0.18;

/// Basic rejected swap return duration.
///
/// Source: DESIGN.md section 6 - invalid swap uses 150ms out and 150ms back.
const double rejectedSwapReturnDurationSeconds = 0.15;

/// Match clear animation duration.
///
/// Source: DESIGN.md §3 — match reaction is 220ms total.
const double matchClearDurationSeconds = 0.22;

/// Drag threshold as a fraction of tile size before a swap gesture commits.
///
/// Source: Step 5 — swap gesture ergonomics.
const double dragSwapThresholdTileFraction = 0.35;

/// Static selected tile stroke width.
///
/// Source: Step 5 — selected tile feedback.
const double staticSelectedTileStrokeWidth = 4;

/// Cascade gravity fall animation duration.
///
/// Source: DESIGN.md section 6 - refill fall base duration is 260ms.
const double cascadeFallBaseDurationSeconds = 0.26;

/// Additional fall duration per row of travel.
///
/// Source: DESIGN.md section 6 - refill fall adds 35ms per row distance.
const double cascadeFallPerRowDurationSeconds = 0.035;

/// Maximum refill fall duration.
///
/// Source: DESIGN.md section 6 - refill fall duration is capped at 520ms.
const double cascadeFallMaxDurationSeconds = 0.52;

/// Cascade landing squash duration.
///
/// Source: DESIGN.md section 6 - cascade bounce settle is 120ms.
const double cascadeLandingBounceDurationSeconds = 0.12;

/// Cascade landing squash strength.
///
/// Source: DESIGN.md section 11 - falling candies squash 4% on landing.
const double cascadeLandingSquashFraction = 0.04;

/// Sugar sparkle burst duration for standard matches.
///
/// Source: DESIGN.md section 11 - sugar sparkle burst lasts 260ms.
const double sugarSparkleDurationSeconds = 0.26;

/// Cascade combo label display duration.
///
/// Source: DESIGN.md section 11 - combo label duration is 650ms.
const double cascadeComboLabelDurationSeconds = 0.65;

/// Combo label starts at this scale.
///
/// Source: DESIGN.md section 11 - combo label scales from 70%.
const double cascadeComboLabelStartScale = 0.7;

/// Combo label overshoots to this scale.
///
/// Source: DESIGN.md section 11 - combo label overshoots to 112%.
const double cascadeComboLabelPeakScale = 1.12;

/// Combo label settles at this scale.
///
/// Source: DESIGN.md section 11 - combo label settles at 100%.
const double cascadeComboLabelEndScale = 1;

/// Pooled particle slots per reactive-state burst.
///
/// Source: DESIGN.md §4 — Frost uses 6-8 shards; 8 covers all state bursts.
const int reactiveStateParticlePoolSize = 8;

/// Molten ember burst duration.
///
/// Source: DESIGN_DEFAULT — no ember burst duration specified; follows clear timing.
const double moltenBurstDurationSeconds = 0.28;

/// Molten heat trail decal duration.
///
/// Source: DESIGN.md §4 — heat trail remains for 3s.
const double moltenHeatTrailDurationSeconds = 3;

/// Frost shard burst duration.
///
/// Source: DESIGN_DEFAULT — no shard burst duration specified; follows clear timing.
const double frostShardDurationSeconds = 0.32;

/// Frost neighbor tint duration.
///
/// Source: DESIGN.md §4 — orthogonal frost tint lasts 1.5s.
const double frostTintDurationSeconds = 1.5;

/// Living heart particle duration.
///
/// Source: DESIGN_DEFAULT — no heart pop duration specified; follows clear timing.
const double livingHeartDurationSeconds = 0.3;

/// Syrup splash particle duration.
///
/// Source: DESIGN_DEFAULT — no splash duration specified; follows clear timing.
const double syrupSplashDurationSeconds = 0.34;

/// Syrup slick column duration.
///
/// Source: DESIGN.md §4 — slick shimmer remains for 2s.
const double syrupSlickDurationSeconds = 2;

/// Spice ember puff duration.
///
/// Source: DESIGN_DEFAULT — no ember puff duration specified; follows clear timing.
const double spiceEmberDurationSeconds = 0.28;

/// Board decal render priority, below tiles but above the tray.
///
/// Source: Step 7 — state decals must sit under candy sprites.
const int reactiveStateDecalPriority = -1;

/// Particle burst render priority, above candy sprites.
///
/// Source: DESIGN.md §4 — match particles fly outward from cleared candies.
const int reactiveStateParticlePriority = 10;

/// Combo label render priority, above all normal board effects.
///
/// Source: DESIGN.md section 11 - combo text should sit above cascades.
const int cascadeComboLabelPriority = 30;

/// Tempered Shatter anticipation duration.
///
/// Source: DESIGN.md §5 — 150ms anticipation beat.
const double temperedShatterAnticipationDurationSeconds = 0.15;

/// Tempered Shatter flash ease-in duration.
///
/// Source: DESIGN.md §5 — 80ms flash in.
const double temperedShatterFlashInDurationSeconds = 0.08;

/// Tempered Shatter flash ease-out duration.
///
/// Source: DESIGN.md §5 — 70ms flash out.
const double temperedShatterFlashOutDurationSeconds = 0.07;

/// Tempered Shatter crack-line sweep duration.
///
/// Source: DESIGN.md §5 — 120ms fast linear sweep.
const double temperedShatterCrackDurationSeconds = 0.12;

/// Tempered Shatter row shatter duration.
///
/// Source: DESIGN.md §5 — 280ms glass-shatter row clear.
const double temperedShatterRowShatterDurationSeconds = 0.28;

/// Tempered Shatter total VFX duration.
///
/// Source: DESIGN.md §5 — total effect duration target is about 550ms.
const double temperedShatterTotalDurationSeconds = 0.55;

/// Delay before row tiles begin clearing during Tempered Shatter.
///
/// Source: DESIGN.md §5 — anticipation plus crack happen before row clear.
const double temperedShatterRowClearDelaySeconds =
    temperedShatterAnticipationDurationSeconds +
    temperedShatterCrackDurationSeconds;

/// Tempered Shatter camera shake duration.
///
/// Source: DESIGN.md §5 — 150ms decaying sine-wave shake.
const double temperedShatterCameraShakeDurationSeconds = 0.15;

/// Tempered Shatter camera shake peak offset in logical pixels.
///
/// Source: DESIGN.md §5 — 4px camera shake.
const double temperedShatterCameraShakePixels = 4;

/// Pooled shard slots for the Tempered Shatter row shatter.
///
/// Source: DESIGN.md §5 and §11 — reused tinted shard shapes.
const int temperedShatterShardPoolSize = 18;

/// Tempered Shatter effect render priority, above state particles.
///
/// Source: Step 8 — flagship reaction VFX must sit above normal clears.
const int temperedShatterEffectPriority = 20;

/// Row and column Special Candy sweep duration.
///
/// Source: DESIGN_DEFAULT - DESIGN.md section 11 requires special-candy
/// explosions but does not specify a per-type timing.
const double specialCandyLineSweepDurationSeconds = 0.36;

/// Wrapped Special Candy burst duration.
///
/// Source: DESIGN_DEFAULT - wrapped uses a stronger mid-weight pop burst.
const double specialCandyWrappedBurstDurationSeconds = 0.42;

/// Color Orb Special Candy ray duration.
///
/// Source: DESIGN_DEFAULT - colorOrb needs enough time for all target rays.
const double specialCandyColorOrbDurationSeconds = 0.52;

/// Fish Charm Special Candy travel duration.
///
/// Source: DESIGN_DEFAULT - fishCharm target trail should read clearly.
const double specialCandyFishCharmDurationSeconds = 0.48;

/// Alchemy Bomb Special Candy burst duration.
///
/// Source: DESIGN_DEFAULT - alchemyBomb uses a large mid-weight burst.
const double specialCandyAlchemyBombDurationSeconds = 0.52;

/// Cell flash duration shared by Special Candy effects.
///
/// Source: DESIGN_DEFAULT - follows the standard 300ms mid-weight animation.
const double specialCandyCellFlashDurationSeconds = 0.3;

/// Special Candy effect render priority.
///
/// Source: DESIGN.md section 11 - special-candy explosions sit above standard
/// match particles but below Tempered Shatter.
const int specialCandyEffectPriority = 18;
