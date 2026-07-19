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

/// Gameplay HUD top status bar minimum height.
///
/// Source: PRD.md section 9 - upgraded gameplay HUD with stars and goal.
const double gameplayHudTopBarMinHeight = 108;

/// Gameplay HUD stat pill height.
///
/// Source: PRD.md section 9 - compact score, moves, and goal widgets.
const double gameplayHudPillHeight = 42;

/// Gameplay HUD icon button size.
///
/// Source: PRD.md section 9 - pause/settings control in the gameplay HUD.
const double gameplayHudIconButtonSize = 40;

/// Gameplay HUD star progress height.
///
/// Source: DESIGN.md section 10 - readable star meter in the top HUD.
const double gameplayHudStarProgressHeight = 8;

/// Gameplay HUD bottom booster tray height.
///
/// Source: PRD.md section 9 - visible in-game booster tray.
const double gameplayHudBoosterTrayHeight = 88;

/// Gameplay HUD booster button size.
///
/// Source: DESIGN.md section 10 - touch-friendly booster tray buttons.
const double gameplayHudBoosterButtonSize = 58;

/// Gameplay HUD compact booster badge size.
///
/// Source: DESIGN.md section 10 - visible booster inventory count.
const double gameplayHudBoosterBadgeSize = 22;

/// Level map node size.
///
/// Source: DESIGN.md §7 — each level is represented by an ingredient icon.
const double levelMapNodeSize = 56;

/// Kingdom Map section height for 20 vertical level nodes.
///
/// Source: DESIGN.md section 7 - each kingdom occupies one vertical segment.
const double kingdomMapSectionHeight = 1280;

/// Kingdom Map section top padding.
///
/// Source: DESIGN.md section 7 - each kingdom segment keeps visual breathing
/// room around story and level nodes.
const double kingdomMapSectionPaddingTop = 10;

/// Kingdom Map section bottom padding.
///
/// Source: DESIGN.md section 7 - each kingdom segment keeps visual breathing
/// room around story and level nodes.
const double kingdomMapSectionPaddingBottom = 18;

/// Kingdom Map fixed sliver extent including section padding.
///
/// Source: ARCHITECTURE.md section 14 - code-generated map art must stay
/// smooth while scrolling.
const double kingdomMapSectionSliverExtent =
    kingdomMapSectionHeight +
    kingdomMapSectionPaddingTop +
    kingdomMapSectionPaddingBottom;

/// Kingdom Map scroll cache distance.
///
/// Source: PRD.md section 17 - Kingdom Map must preserve 60fps scrolling.
const double kingdomMapScrollCacheExtent = kingdomMapSectionSliverExtent * 2;

/// Kingdom Map first node top position.
///
/// Source: DESIGN.md section 7 - vertical path with story panel at start.
const double kingdomMapNodeStartY = 210;

/// Kingdom Map vertical spacing between level nodes.
///
/// Source: DESIGN.md section 7 - readable 20-node journey path.
const double kingdomMapNodeStepY = 52;

/// Kingdom Map section corner radius.
///
/// Source: DESIGN.md section 7 - playful rounded kingdom panels.
const double kingdomMapSectionRadius = 28;

/// Kingdom Map character portrait size.
///
/// Source: DESIGN.md section 8 - code-drawn simple readable characters.
const double kingdomMapCharacterPortraitSize = 52;

/// Kingdom Map checkpoint gate width.
///
/// Source: PRD.md section 7 - gates are code-drawn map moments.
const double kingdomMapGateWidth = 172;

/// Kingdom Map checkpoint gate height.
///
/// Source: PRD.md section 7 - gates must read beside level nodes.
const double kingdomMapGateHeight = 54;

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

/// Win Overlay star fill duration per star.
///
/// Source: DESIGN.md section 14 - stars fill one by one, 220ms each.
const int winOverlayStarFillPerStarMilliseconds = 220;

/// Win Overlay reward reveal duration.
///
/// Source: DESIGN_DEFAULT - reward reveal follows the 220ms star celebration beat.
const int winOverlayRewardRevealMilliseconds = 220;

/// Preview level count shown before progression persistence exists.
///
/// Source: Step 11 — local level map shell before Step 12 progress sync.
const int previewLevelCount = 9;
