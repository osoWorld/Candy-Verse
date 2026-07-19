import 'dart:async';

import 'package:get/get.dart';

import '../../../core/constants/kingdom_constants.dart';
import '../../../core/constants/persistence_constants.dart';
import '../../../data/generators/level_config_generator.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/repositories/booster_inventory_repository.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../boosters/domain/booster_type.dart';
import '../../kingdom_map/domain/friend_score.dart';
import '../../kingdom_map/domain/kingdom_level_definition.dart';

/// Level Detail Modal state controller in the GetX UI layer.
class LevelIntroController extends GetxController {
  /// Creates level-intro state for [level].
  LevelIntroController({
    required this.level,
    int initialBestScore = 0,
    int initialBestStars = 0,
    ProgressRepository? progressRepository,
    LeaderboardRepository? leaderboardRepository,
    BoosterInventoryRepository? boosterInventoryRepository,
  }) : progressRepository = progressRepository ?? _registeredProgress(),
       leaderboardRepository =
           leaderboardRepository ?? _registeredLeaderboard(),
       boosterInventoryRepository =
           boosterInventoryRepository ?? _registeredBoosterInventory() {
    bestScore.value = initialBestScore;
    bestStars.value = initialBestStars;
    friendScores.assignAll(_buildFriendScores(level.friendScoreSeed));
    boosterCounts.assignAll(_starterCountsForLevel());
    unawaited(loadScoreData());
    unawaited(loadBoosterInventory());
  }

  /// Level shown by this modal.
  final KingdomLevelDefinition level;

  /// Repository used to restore the player's best score.
  final ProgressRepository? progressRepository;

  /// Repository used to load cached or remote friend leaderboard rows.
  final LeaderboardRepository? leaderboardRepository;

  /// Repository used to load and consume pre-game booster inventory.
  final BoosterInventoryRepository? boosterInventoryRepository;

  /// Offline fallback or remote friend scores for this level.
  final RxList<FriendScore> friendScores = <FriendScore>[].obs;

  /// Best score known for the current local player.
  final RxInt bestScore = 0.obs;

  /// Best stars known for the current local player.
  final RxInt bestStars = 0.obs;

  /// Label explaining whether friend rows are synced or fallback data.
  final RxString friendScoreSourceLabel = 'Local friends'.obs;

  /// Booster inventory counts keyed by BoosterType.
  final RxMap<BoosterType, int> boosterCounts = <BoosterType, int>{}.obs;

  /// Whether selected pre-game boosters are being consumed for Play.
  final RxBool isConsumingBoosters = false.obs;

  /// Selected pre-game booster names.
  final RxList<String> selectedPreGameBoosters = <String>[].obs;

  var _boosterInventoryRequestId = 0;

  /// Loads player progress and friend scores from available repositories.
  ///
  /// Inputs: none. Output: completion future. Side effects: updates reactive
  /// best-score, best-star, friend-score, and source-label state.
  Future<void> loadScoreData() async {
    await _loadPlayerProgress();
    await _loadFriendScores();
  }

  /// Loads pre-game booster counts from the inventory repository.
  ///
  /// Inputs: none. Output: completion future. Side effects: updates
  /// [boosterCounts].
  Future<void> loadBoosterInventory() async {
    final requestId = _boosterInventoryRequestId + 1;
    _boosterInventoryRequestId = requestId;
    final repository = boosterInventoryRepository;
    if (repository == null) {
      _assignBoosterCountsIfCurrent(requestId, _starterCountsForLevel());
      return;
    }
    try {
      final inventory = await repository.loadInventory(defaultLocalPlayerId);
      _assignBoosterCountsIfCurrent(requestId, inventory);
    } on Object {
      _assignBoosterCountsIfCurrent(requestId, _starterCountsForLevel());
    }
  }

  /// Toggles [boosterName] in the selected booster list.
  ///
  /// Inputs: booster name. Output: none. Side effects: updates reactive
  /// selected booster state.
  void toggleBooster(String boosterName) {
    if (selectedPreGameBoosters.contains(boosterName)) {
      selectedPreGameBoosters.remove(boosterName);
      return;
    }
    if (!canSelectBooster(boosterName)) {
      return;
    }
    selectedPreGameBoosters.add(boosterName);
  }

  /// Returns whether [boosterName] is selected.
  ///
  /// Inputs: booster name. Output: selection state. Side effects: none.
  bool isBoosterSelected(String boosterName) {
    return selectedPreGameBoosters.contains(boosterName);
  }

  /// Returns whether [boosterName] has inventory available.
  ///
  /// Inputs: booster name. Output: selectable state. Side effects: none.
  bool canSelectBooster(String boosterName) {
    final boosterType = tryParseBoosterType(boosterName);
    if (boosterType == null) {
      return false;
    }
    return (boosterCounts[boosterType] ?? 0) > 0;
  }

  /// Returns inventory count for [boosterName].
  ///
  /// Inputs: booster name. Output: count, or 0 for unknown boosters. Side
  /// effects: none.
  int boosterCountForName(String boosterName) {
    final boosterType = tryParseBoosterType(boosterName);
    if (boosterType == null) {
      return 0;
    }
    return boosterCounts[boosterType] ?? 0;
  }

  /// Consumes selected pre-game boosters before gameplay starts.
  ///
  /// Inputs: none. Output: whether consumption succeeded. Side effects: writes
  /// inventory repository state and refreshes local counts.
  Future<bool> consumeSelectedBoosters() async {
    final selectedBoosters = [
      for (final boosterName in selectedPreGameBoosters)
        if (tryParseBoosterType(boosterName) case final BoosterType boosterType)
          boosterType,
    ];
    if (selectedBoosters.isEmpty) {
      return true;
    }
    final repository = boosterInventoryRepository;
    if (repository == null) {
      return true;
    }
    isConsumingBoosters.value = true;
    try {
      final didConsume = await repository.consumeBoosters(
        playerId: defaultLocalPlayerId,
        boosterTypes: selectedBoosters,
      );
      await loadBoosterInventory();
      if (!didConsume) {
        _removeUnavailableSelections();
      }
      return didConsume;
    } finally {
      isConsumingBoosters.value = false;
    }
  }

  Future<void> _loadPlayerProgress() async {
    final repository = progressRepository;
    if (repository == null) {
      return;
    }
    try {
      final records = await repository.loadProgress(defaultLocalPlayerId);
      final levelId = LevelConfigGenerator.levelIdForNumber(level.levelNumber);
      for (final record in records) {
        if (record.levelId != levelId) {
          continue;
        }
        if (record.bestScore > bestScore.value) {
          bestScore.value = record.bestScore;
        }
        if (record.stars > bestStars.value) {
          bestStars.value = record.stars.clamp(0, 3).toInt();
        }
      }
    } on Object {
      // Offline modal progress lookup falls back to the map-provided values.
    }
  }

  Future<void> _loadFriendScores() async {
    final repository = leaderboardRepository;
    if (repository == null) {
      return;
    }
    try {
      final entries = await repository.fetchLeaderboard(
        chapter: _chapterForLevel(level.levelNumber),
        limit: 3,
      );
      if (entries.isEmpty) {
        return;
      }
      final fallbackScores = _buildFriendScores(level.friendScoreSeed);
      friendScores.assignAll(
        [
          for (final entry in entries.take(3)) _friendScoreForEntry(entry),
          ...fallbackScores,
        ].take(3),
      );
      friendScoreSourceLabel.value = 'Cached leaderboard';
    } on Object {
      // Keep the deterministic fallback rows when friend scores are offline.
    }
  }

  int _chapterForLevel(int levelNumber) {
    return ((levelNumber - 1) ~/ v1LevelsPerKingdom) + 1;
  }

  FriendScore _friendScoreForEntry(LeaderboardEntry entry) {
    return FriendScore(
      name: entry.playerId == defaultLocalPlayerId
          ? 'You'
          : _displayNameForPlayerId(entry.playerId),
      score: entry.score,
    );
  }

  String _displayNameForPlayerId(String playerId) {
    final normalized = playerId.trim();
    if (normalized.isEmpty) {
      return 'Friend';
    }
    final parts = normalized
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'Friend';
    }
    return parts
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Map<BoosterType, int> _starterCountsForLevel() {
    final starterInventory = BoosterInventoryRepository.starterInventory();
    return {
      for (final boosterName in level.preGameBoosters)
        if (tryParseBoosterType(boosterName) case final BoosterType boosterType)
          boosterType: starterInventory[boosterType] ?? 0,
    };
  }

  void _removeUnavailableSelections() {
    selectedPreGameBoosters.removeWhere(
      (boosterName) => !canSelectBooster(boosterName),
    );
  }

  void _assignBoosterCountsIfCurrent(
    int requestId,
    Map<BoosterType, int> inventory,
  ) {
    if (requestId != _boosterInventoryRequestId) {
      return;
    }
    boosterCounts.assignAll(inventory);
  }

  static List<FriendScore> _buildFriendScores(int seed) {
    const names = ['Amina', 'Bilal', 'Sara', 'Hamza', 'Noor', 'Zain'];
    final firstIndex = seed % names.length;
    return [
      for (var index = 0; index < 3; index += 1)
        FriendScore(
          name: names[(firstIndex + index) % names.length],
          score: 9000 + ((seed * (index + 3)) % 7000) + (2 - index) * 1200,
        ),
    ]..sort((first, second) => second.score.compareTo(first.score));
  }

  static ProgressRepository? _registeredProgress() {
    if (!Get.isRegistered<ProgressRepository>()) {
      return null;
    }
    return Get.find<ProgressRepository>();
  }

  static LeaderboardRepository? _registeredLeaderboard() {
    if (!Get.isRegistered<LeaderboardRepository>()) {
      return null;
    }
    return Get.find<LeaderboardRepository>();
  }

  static BoosterInventoryRepository? _registeredBoosterInventory() {
    if (!Get.isRegistered<BoosterInventoryRepository>()) {
      return null;
    }
    return Get.find<BoosterInventoryRepository>();
  }
}
