/// Standard screen padding for Flutter UI screens.
///
/// Source: DESIGN_DEFAULT — no screen padding specified for Step 11.
const double uiScreenPadding = 24;

/// Compact UI control gap.
///
/// Source: DESIGN_DEFAULT — no control gap specified for Step 11.
const double uiControlGap = 12;

/// Larger section gap for Flutter UI screens.
///
/// Source: DESIGN_DEFAULT — no section gap specified for Step 11.
const double uiSectionGap = 24;

/// Standard compact panel corner radius.
///
/// Source: Design instructions — cards and panels stay at 8px radius or less.
const double uiPanelCornerRadius = 8;

/// Gameplay HUD edge padding.
///
/// Source: PRD.md §9 — HUD overlays live around the gameplay board.
const double gameplayHudPadding = 16;

/// Gameplay HUD compact stat width.
///
/// Source: Step 11 — stable dimensions prevent HUD shift.
const double gameplayHudStatWidth = 108;

/// Gameplay HUD compact stat height.
///
/// Source: Step 11 — stable dimensions prevent HUD shift.
const double gameplayHudStatHeight = 54;

/// Level map node size.
///
/// Source: DESIGN.md §7 — each level is represented by an ingredient icon.
const double levelMapNodeSize = 56;

/// Menu to Level Map transition duration.
///
/// Source: DESIGN.md §8 — Menu to Level Map transition is 350ms.
const int menuToLevelMapTransitionMilliseconds = 350;

/// Gameplay to Win Overlay transition duration.
///
/// Source: DESIGN.md §8 — Win Overlay slides up over 400ms.
const int gameplayToWinOverlayTransitionMilliseconds = 400;

/// Gameplay final-state freeze before the Win Overlay enters.
///
/// Source: DESIGN.md §8 — board freezes for 200ms before win overlay.
const int gameplayFinalStateFreezeMilliseconds = 200;

/// Gameplay to Lose Overlay fade duration.
///
/// Source: DESIGN.md §8 — Lose Overlay uses a 250ms dim fade.
const int gameplayToLoseOverlayTransitionMilliseconds = 250;

/// Lose Overlay retry prompt fade duration.
///
/// Source: DESIGN_DEFAULT — prompt fade duration follows the 250ms dim timing.
const int loseOverlayPromptFadeMilliseconds = 250;

/// Lose Overlay board dim opacity.
///
/// Source: DESIGN_DEFAULT — DESIGN.md §8 gives timing but not dim strength.
const double loseOverlayDimOpacity = 0.64;

/// Level complete liquid morph duration.
///
/// Source: DESIGN.md §8 — level complete to next screen morph is 600ms.
const int levelCompleteLiquidMorphMilliseconds = 600;

/// Preview level count shown before progression persistence exists.
///
/// Source: Step 11 — local level map shell before Step 12 progress sync.
const int previewLevelCount = 9;
