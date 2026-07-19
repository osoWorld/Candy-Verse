/// Booster inventory type in the boosters domain layer.
enum BoosterType { fusionBooster, tempoMeter, architectTile, echoCandy }

/// Returns the user-facing label for [boosterType].
///
/// Inputs: booster type. Output: stable display label. Side effects: none.
String boosterTypeLabel(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => 'Fusion Booster',
    BoosterType.tempoMeter => 'Tempo Meter',
    BoosterType.architectTile => 'Architect Tile',
    BoosterType.echoCandy => 'Echo Candy',
  };
}

/// Parses [label] into a BoosterType when it is one of the V1 boosters.
///
/// Inputs: display label. Output: matching BoosterType or null. Side effects:
/// none.
BoosterType? tryParseBoosterType(String label) {
  return switch (label) {
    'Fusion Booster' => BoosterType.fusionBooster,
    'Tempo Meter' => BoosterType.tempoMeter,
    'Architect Tile' => BoosterType.architectTile,
    'Echo Candy' => BoosterType.echoCandy,
    _ => null,
  };
}
