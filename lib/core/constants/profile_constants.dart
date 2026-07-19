/// Default local player display name.
///
/// Source: DESIGN_DEFAULT - profile copy is V1 placeholder until auth exists.
const String defaultPlayerProfileName = 'Pip Apprentice';

/// Seven-day daily reward cycle length.
///
/// Source: PRD.md section 2 - daily rewards are a return loop.
const int dailyRewardCycleLength = 7;

/// Initial unlocked level before progress exists.
///
/// Source: PRD.md section 15 - offline progress must work without Supabase.
const int profileInitialUnlockedLevel = 1;

/// V1 kingdom display names ordered by global level range.
///
/// Source: PRD.md section 6 - V1 contains five named kingdoms.
const List<String> profileKingdomNamesByIndex = [
  'Sugar Meadow',
  'Cocoa Castle',
  'Frosted Peaks',
  'Molten Bakery',
  'Syrup Lagoon',
];
