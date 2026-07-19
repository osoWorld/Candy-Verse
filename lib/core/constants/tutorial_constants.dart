/// Number of Sugar Meadow levels with first-time tutorial prompts.
///
/// Source: PRD.md section 6 - Sugar Meadow has tutorial tone.
const int tutorialLevelCount = 5;

/// Tutorial overlay backdrop opacity.
///
/// Source: DESIGN_DEFAULT - onboarding overlay opacity is not specified.
const double tutorialBackdropOpacity = 0.68;

/// Tutorial prompt maximum width.
///
/// Source: DESIGN_DEFAULT - keeps onboarding cards readable on phones.
const double tutorialPromptMaxWidth = 380;

/// Tutorial prompt corner radius.
///
/// Source: DESIGN_DEFAULT - tutorial panels use playful rounded prompts.
const double tutorialPromptCornerRadius = 24;

/// Tutorial highlight border width.
///
/// Source: DESIGN_DEFAULT - guided highlights need clear focus.
const double tutorialHighlightBorderWidth = 4;

/// Tutorial highlight pop animation duration.
///
/// Source: DESIGN_DEFAULT - follows Level Detail booster selection pop timing.
const int tutorialHighlightPopMilliseconds = 260;
