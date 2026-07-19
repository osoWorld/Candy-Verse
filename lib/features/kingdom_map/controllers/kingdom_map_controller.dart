import 'dart:async';

import 'package:get/get.dart';

import '../../../core/constants/kingdom_constants.dart';
import '../../../core/constants/persistence_constants.dart';
import '../../../data/generators/level_config_generator.dart';
import '../../../data/models/kingdom_config.dart';
import '../../../data/models/player_progress_record.dart';
import '../../../data/repositories/booster_inventory_repository.dart';
import '../../../data/repositories/kingdom_gate_reward_repository.dart';
import '../../../data/repositories/kingdom_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/story_progress_repository.dart';
import '../../boosters/domain/booster_type.dart';
import '../domain/kingdom_definition.dart';
import '../domain/kingdom_gate_definition.dart';
import '../domain/kingdom_level_definition.dart';
import '../domain/kingdom_story_moment.dart';

/// Kingdom Map state controller in the GetX UI layer.
class KingdomMapController extends GetxController {
  /// Creates a KingdomMapController backed by [kingdomRepository].
  KingdomMapController({
    KingdomRepository? kingdomRepository,
    this.progressRepository,
    this.storyProgressRepository,
    this.kingdomGateRewardRepository,
    this.boosterInventoryRepository,
  }) : kingdomRepository = kingdomRepository ?? KingdomRepository();

  /// Repository used to load bundled kingdom metadata.
  final KingdomRepository kingdomRepository;

  /// Repository used to restore offline or synced player progress.
  final ProgressRepository? progressRepository;

  /// Repository used to persist seen story panels.
  final StoryProgressRepository? storyProgressRepository;

  /// Repository used to persist claimed checkpoint gate rewards.
  final KingdomGateRewardRepository? kingdomGateRewardRepository;

  /// Repository used to grant checkpoint booster rewards.
  final BoosterInventoryRepository? boosterInventoryRepository;

  /// Current highest unlocked level number.
  final RxInt highestUnlockedLevel = 1.obs;

  /// Completed level stars keyed by global level number.
  final RxMap<int, int> completedLevelStars = <int, int>{}.obs;

  /// Best score keyed by global level number.
  final RxMap<int, int> bestScoresByLevel = <int, int>{}.obs;

  /// Kingdom definitions shown by the journey map.
  final RxList<KingdomDefinition> kingdoms = <KingdomDefinition>[].obs;

  /// Whether the kingdom metadata assets are still loading.
  final RxBool isLoadingKingdoms = true.obs;

  /// User-facing load error when kingdom metadata cannot be read.
  final RxString kingdomLoadError = ''.obs;

  /// Seen kingdom story panel keys.
  final RxSet<String> seenStoryPanelKeys = <String>{}.obs;

  /// Claimed kingdom checkpoint reward keys.
  final RxSet<String> claimedGateRewardKeys = <String>{}.obs;

  /// Pending checkpoint reward that should be presented on the map.
  final Rxn<KingdomGateDefinition> pendingGateReward =
      Rxn<KingdomGateDefinition>();

  var _isPresentingGateReward = false;

  static const LevelConfigGenerator _levelConfigGenerator =
      LevelConfigGenerator();

  /// Starts loading kingdom metadata when the controller enters GetX.
  ///
  /// Inputs: none. Output: none. Side effects: schedules asset loading through
  /// [kingdomRepository].
  @override
  void onInit() {
    super.onInit();
    unawaited(loadKingdoms());
  }

  /// Loads all KingdomConfig JSON assets and rebuilds map definitions.
  ///
  /// Inputs: none. Output: completion future. Side effects: updates GetX map
  /// metadata state.
  Future<void> loadKingdoms() async {
    isLoadingKingdoms.value = true;
    kingdomLoadError.value = '';
    try {
      final kingdomConfigs = await kingdomRepository.loadKingdomConfigs();
      kingdoms.assignAll(definitionsFromConfigs(kingdomConfigs));
      await restoreProgress();
      await restoreSeenStoryPanels();
      await restoreClaimedGateRewards();
    } on Object catch (error) {
      kingdoms.clear();
      kingdomLoadError.value = 'Unable to load kingdom map: $error';
    } finally {
      isLoadingKingdoms.value = false;
    }
  }

  /// Returns whether [levelNumber] is unlocked.
  ///
  /// Inputs: one-based level number. Output: unlocked state. Side effects:
  /// none.
  bool isLevelUnlocked(int levelNumber) {
    return levelNumber <= highestUnlockedLevel.value;
  }

  /// Returns stars earned for [levelNumber].
  ///
  /// Inputs: one-based level number. Output: stars from 0 to 3. Side effects:
  /// none.
  int starsForLevel(int levelNumber) {
    return completedLevelStars[levelNumber] ?? 0;
  }

  /// Returns the best score earned for [levelNumber].
  ///
  /// Inputs: one-based level number. Output: best score or 0. Side effects:
  /// none.
  int bestScoreForLevel(int levelNumber) {
    return bestScoresByLevel[levelNumber] ?? 0;
  }

  /// Returns a stable story panel key for [kingdomId] and [moment].
  ///
  /// Inputs: kingdom id and story moment. Output: storage key. Side effects:
  /// none.
  String storyPanelKey({
    required String kingdomId,
    required KingdomStoryMoment moment,
  }) {
    return '$kingdomId:${kingdomStoryMomentStorageValue(moment)}';
  }

  /// Returns whether [kingdomId]'s [moment] story panel has been seen.
  ///
  /// Inputs: kingdom id and story moment. Output: seen flag. Side effects:
  /// none.
  bool isStoryPanelSeen({
    required String kingdomId,
    required KingdomStoryMoment moment,
  }) {
    return seenStoryPanelKeys.contains(
      storyPanelKey(kingdomId: kingdomId, moment: moment),
    );
  }

  /// Returns whether [gate] is open.
  ///
  /// Inputs: gate definition. Output: open state. Side effects: none.
  bool isGateUnlocked(KingdomGateDefinition gate) {
    return starsForLevel(gate.checkpointLevel) > 0;
  }

  /// Returns whether [gate]'s reward has already been claimed.
  ///
  /// Inputs: gate definition. Output: claimed state. Side effects: none.
  bool isGateRewardClaimed(KingdomGateDefinition gate) {
    return claimedGateRewardKeys.contains(gate.gateKey);
  }

  /// Returns whether a kingdom story [moment] can currently be read.
  ///
  /// Inputs: kingdom definition and story moment. Output: availability flag.
  /// Side effects: none.
  bool isStoryMomentAvailable(
    KingdomDefinition kingdom,
    KingdomStoryMoment moment,
  ) {
    return switch (moment) {
      KingdomStoryMoment.intro => isLevelUnlocked(kingdom.levelStart),
      KingdomStoryMoment.outro => starsForLevel(kingdom.levelEnd) > 0,
    };
  }

  /// Marks [kingdomId]'s [moment] story panel as seen.
  ///
  /// Inputs: kingdom id and story moment. Output: completion future. Side
  /// effects: updates GetX state and persists the story key locally.
  Future<void> markStoryPanelSeen({
    required String kingdomId,
    required KingdomStoryMoment moment,
  }) async {
    final key = storyPanelKey(kingdomId: kingdomId, moment: moment);
    if (seenStoryPanelKeys.contains(key)) {
      return;
    }
    seenStoryPanelKeys.add(key);
    await _registeredStoryProgressRepository()?.markStoryPanelSeen(key);
  }

  /// Reserves the current pending gate reward for one UI presentation.
  ///
  /// Inputs: none. Output: pending gate or null. Side effects: marks a reward
  /// dialog as presenting until [releaseGateRewardPresentation] is called.
  KingdomGateDefinition? reservePendingGateRewardForPresentation() {
    if (_isPresentingGateReward) {
      return null;
    }
    final gate = pendingGateReward.value;
    if (gate == null) {
      return null;
    }
    _isPresentingGateReward = true;
    return gate;
  }

  /// Releases the pending reward presentation lock.
  ///
  /// Inputs: none. Output: none. Side effects: allows another reward dialog.
  void releaseGateRewardPresentation() {
    _isPresentingGateReward = false;
  }

  /// Clears [gate] from the pending reward slot.
  ///
  /// Inputs: gate definition. Output: none. Side effects: updates
  /// [pendingGateReward].
  void clearPendingGateReward(KingdomGateDefinition gate) {
    if (pendingGateReward.value?.gateKey == gate.gateKey) {
      pendingGateReward.value = null;
    }
  }

  /// Claims [gate]'s reward and adds it to booster inventory when available.
  ///
  /// Inputs: gate definition. Output: completion future. Side effects:
  /// persists claim state and grants booster inventory.
  Future<void> claimGateReward(KingdomGateDefinition gate) async {
    if (isGateRewardClaimed(gate)) {
      clearPendingGateReward(gate);
      return;
    }
    claimedGateRewardKeys.add(gate.gateKey);
    await _registeredKingdomGateRewardRepository()
        ?.markKingdomGateRewardClaimed(gate.gateKey);
    final inventoryRepository = _registeredBoosterInventoryRepository();
    if (inventoryRepository != null) {
      await inventoryRepository.addBooster(
        playerId: defaultLocalPlayerId,
        boosterType: gate.rewardBoosterType,
        quantity: gate.rewardQuantity,
      );
    }
    clearPendingGateReward(gate);
  }

  /// Marks [levelNumber] as completed and unlocks the next level.
  ///
  /// Inputs: one-based level number and optional stars. Output: none. Side
  /// effects: updates GetX map progression state.
  void completeLevel(int levelNumber, {int stars = 1, int bestScore = 0}) {
    final currentStars = completedLevelStars[levelNumber] ?? 0;
    if (stars > currentStars) {
      completedLevelStars[levelNumber] = stars.clamp(0, 3).toInt();
    }
    final currentBestScore = bestScoresByLevel[levelNumber] ?? 0;
    if (bestScore > currentBestScore) {
      bestScoresByLevel[levelNumber] = bestScore;
    }
    if (levelNumber >= highestUnlockedLevel.value) {
      highestUnlockedLevel.value = levelNumber + 1;
    }
    _queueGateRewardForCompletedLevel(levelNumber);
  }

  /// Restores completed stars, best scores, and unlock progress from cache.
  ///
  /// Inputs: none. Output: completion future. Side effects: reads repository
  /// progress and updates GetX map progression state.
  Future<void> restoreProgress() async {
    final repository = progressRepository ?? _registeredProgressRepository();
    if (repository == null) {
      return;
    }
    final records = await repository.loadProgress(defaultLocalPlayerId);
    applyProgressRecords(records);
  }

  /// Restores seen kingdom story panels from local storage.
  ///
  /// Inputs: none. Output: completion future. Side effects: updates
  /// [seenStoryPanelKeys].
  Future<void> restoreSeenStoryPanels() async {
    final repository = _registeredStoryProgressRepository();
    if (repository == null) {
      return;
    }
    final keys = await repository.loadSeenStoryPanelKeys();
    seenStoryPanelKeys
      ..clear()
      ..addAll(keys);
  }

  /// Restores claimed checkpoint gate rewards from local storage.
  ///
  /// Inputs: none. Output: completion future. Side effects: updates
  /// [claimedGateRewardKeys].
  Future<void> restoreClaimedGateRewards() async {
    final repository = _registeredKingdomGateRewardRepository();
    if (repository == null) {
      return;
    }
    final keys = await repository.loadClaimedKingdomGateRewardKeys();
    claimedGateRewardKeys
      ..clear()
      ..addAll(keys);
  }

  /// Applies persisted progress [records] to map state.
  ///
  /// Inputs: progress rows. Output: none. Side effects: updates unlocked level,
  /// completed stars, and best score observables.
  void applyProgressRecords(List<PlayerProgressRecord> records) {
    var nextHighestUnlockedLevel = highestUnlockedLevel.value;
    for (final record in records) {
      final levelNumber = _levelNumberForId(record.levelId);
      if (levelNumber == null) {
        continue;
      }
      final currentStars = completedLevelStars[levelNumber] ?? 0;
      if (record.stars > currentStars) {
        completedLevelStars[levelNumber] = record.stars.clamp(0, 3).toInt();
      }
      final currentBestScore = bestScoresByLevel[levelNumber] ?? 0;
      if (record.bestScore > currentBestScore) {
        bestScoresByLevel[levelNumber] = record.bestScore;
      }
      if (levelNumber + 1 > nextHighestUnlockedLevel) {
        nextHighestUnlockedLevel = levelNumber + 1;
      }
    }
    highestUnlockedLevel.value = nextHighestUnlockedLevel
        .clamp(1, LevelConfigGenerator.totalLevelCount + 1)
        .toInt();
  }

  /// Finds a level definition by [levelNumber].
  ///
  /// Inputs: one-based level number. Output: matching level. Side effects:
  /// none.
  KingdomLevelDefinition levelByNumber(int levelNumber) {
    for (final kingdom in kingdoms) {
      for (final level in kingdom.levels) {
        if (level.levelNumber == levelNumber) {
          return level;
        }
      }
    }
    throw RangeError('No KingdomLevelDefinition for level $levelNumber.');
  }

  /// Converts loaded KingdomConfig records into map domain definitions.
  ///
  /// Inputs: ordered kingdom configs. Output: map definitions with 20 level
  /// nodes per kingdom. Side effects: none.
  static List<KingdomDefinition> definitionsFromConfigs(
    List<KingdomConfig> kingdomConfigs,
  ) {
    return [
      for (final kingdomConfig in kingdomConfigs)
        KingdomDefinition(
          kingdomId: kingdomConfig.kingdomId,
          name: kingdomConfig.name,
          levelStart: kingdomConfig.levelStart,
          levelEnd: kingdomConfig.levelEnd,
          backgroundColorValue: kingdomConfig.palette.skyColorValue,
          secondaryColorValue: kingdomConfig.palette.groundColorValue,
          accentColorValue: kingdomConfig.palette.accentColorValue,
          introStory: kingdomConfig.story.intro,
          outroStory: kingdomConfig.story.outro,
          characterName: kingdomConfig.characters.first,
          characterNames: kingdomConfig.characters,
          mapMotifs: kingdomConfig.mapMotifs,
          gates: _buildGates(kingdomConfig),
          levels: [
            for (var offset = 0; offset < v1LevelsPerKingdom; offset += 1)
              _buildLevel(kingdomConfig: kingdomConfig, offset: offset),
          ],
        ),
    ];
  }

  static KingdomLevelDefinition _buildLevel({
    required KingdomConfig kingdomConfig,
    required int offset,
  }) {
    final levelNumber = kingdomConfig.levelStart + offset;
    final levelConfig = _levelConfigGenerator.generateLevel(levelNumber);
    return KingdomLevelDefinition(
      kingdomId: kingdomConfig.kingdomId,
      kingdomName: kingdomConfig.name,
      levelNumber: levelNumber,
      difficulty: levelConfig.difficulty!,
      goalLabel: levelConfig.goalLabel,
      moveLimit: levelConfig.moveLimit!,
      friendScoreSeed: levelConfig.friendScoreSeed!,
      preGameBoosters: [
        for (final boosterType in levelConfig.preLevelBoosters)
          boosterTypeLabel(boosterType),
      ],
    );
  }

  static List<KingdomGateDefinition> _buildGates(KingdomConfig kingdomConfig) {
    return [
      for (var gateIndex = 1; gateIndex <= 4; gateIndex += 1)
        _buildGate(kingdomConfig: kingdomConfig, gateIndex: gateIndex),
    ];
  }

  static KingdomGateDefinition _buildGate({
    required KingdomConfig kingdomConfig,
    required int gateIndex,
  }) {
    final checkpointLevel = kingdomConfig.levelStart + gateIndex * 5 - 1;
    final rewardBoosterType = switch (gateIndex) {
      1 => BoosterType.fusionBooster,
      2 => BoosterType.echoCandy,
      3 => BoosterType.architectTile,
      _ => BoosterType.echoCandy,
    };
    return KingdomGateDefinition(
      gateKey: '${kingdomConfig.kingdomId}:gate$gateIndex',
      kingdomId: kingdomConfig.kingdomId,
      kingdomName: kingdomConfig.name,
      checkpointLevel: checkpointLevel,
      gateIndex: gateIndex,
      title: gateIndex == 4
          ? '${kingdomConfig.name} Gate'
          : 'Checkpoint $gateIndex',
      rewardBoosterType: rewardBoosterType,
      rewardQuantity: 1,
      isFinalGate: gateIndex == 4,
    );
  }

  ProgressRepository? _registeredProgressRepository() {
    if (!Get.isRegistered<ProgressRepository>()) {
      return null;
    }
    return Get.find<ProgressRepository>();
  }

  StoryProgressRepository? _registeredStoryProgressRepository() {
    if (storyProgressRepository != null) {
      return storyProgressRepository;
    }
    if (!Get.isRegistered<StoryProgressRepository>()) {
      return null;
    }
    return Get.find<StoryProgressRepository>();
  }

  KingdomGateRewardRepository? _registeredKingdomGateRewardRepository() {
    if (kingdomGateRewardRepository != null) {
      return kingdomGateRewardRepository;
    }
    if (!Get.isRegistered<KingdomGateRewardRepository>()) {
      return null;
    }
    return Get.find<KingdomGateRewardRepository>();
  }

  BoosterInventoryRepository? _registeredBoosterInventoryRepository() {
    if (boosterInventoryRepository != null) {
      return boosterInventoryRepository;
    }
    if (!Get.isRegistered<BoosterInventoryRepository>()) {
      return null;
    }
    return Get.find<BoosterInventoryRepository>();
  }

  void _queueGateRewardForCompletedLevel(int levelNumber) {
    for (final kingdom in kingdoms) {
      for (final gate in kingdom.gates) {
        if (gate.checkpointLevel != levelNumber ||
            !isGateUnlocked(gate) ||
            isGateRewardClaimed(gate) ||
            pendingGateReward.value?.gateKey == gate.gateKey) {
          continue;
        }
        pendingGateReward.value ??= gate;
        return;
      }
    }
  }

  int? _levelNumberForId(String levelId) {
    final markerIndex = levelId.lastIndexOf('_level');
    if (markerIndex == -1) {
      return null;
    }
    final levelNumber = int.tryParse(levelId.substring(markerIndex + 6));
    if (levelNumber == null ||
        levelNumber < 1 ||
        levelNumber > LevelConfigGenerator.totalLevelCount) {
      return null;
    }
    return levelNumber;
  }
}
