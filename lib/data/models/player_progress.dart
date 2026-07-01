import '../../features/boosters/domain/booster_type.dart';

/// Aggregate player progress model in the data layer.
class PlayerProgress {
  /// Creates an immutable PlayerProgress aggregate.
  PlayerProgress({
    required this.playerId,
    required Map<String, int> levelStars,
    required this.currentChapter,
    required Map<BoosterType, int> boosterInventory,
  }) : levelStars = Map<String, int>.unmodifiable(levelStars),
       boosterInventory = Map<BoosterType, int>.unmodifiable(boosterInventory);

  /// Player id.
  final String playerId;

  /// Stars by level id.
  final Map<String, int> levelStars;

  /// Current unlocked chapter.
  final int currentChapter;

  /// Booster inventory counts.
  final Map<BoosterType, int> boosterInventory;
}
