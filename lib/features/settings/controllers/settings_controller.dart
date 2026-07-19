import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/game_settings.dart';
import '../../../data/repositories/settings_repository.dart';

/// Settings controller in the GetX UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md section 4 does not list a settings feature;
/// pause/settings controls are shared UI state, so this lives under the nearest
/// feature parent.
class SettingsController extends GetxController {
  /// Creates a settings controller backed by [settingsRepository].
  SettingsController({required this.settingsRepository});

  /// Repository used to persist settings locally.
  final SettingsRepository settingsRepository;

  /// Current player settings.
  final Rx<GameSettings> settings = const GameSettings.defaults().obs;

  /// Whether sound hooks should play cues.
  bool get soundEnabled => settings.value.soundEnabled;

  /// Whether haptic feedback should play.
  bool get hapticsEnabled => settings.value.hapticsEnabled;

  /// Whether intense motion should be reduced.
  bool get reduceMotionEnabled => settings.value.reduceMotionEnabled;

  /// Loads persisted settings after GetX creates the controller.
  @override
  void onInit() {
    super.onInit();
    unawaited(loadSettings());
  }

  /// Loads settings from the repository.
  ///
  /// Inputs: none. Output: none. Side effects: updates [settings].
  Future<void> loadSettings() async {
    settings.value = await settingsRepository.loadSettings();
  }

  /// Enables or disables sound playback.
  ///
  /// Inputs: enabled flag. Output: none. Side effects: persists settings.
  Future<void> setSoundEnabled(bool enabled) {
    return _save(settings.value.copyWith(soundEnabled: enabled));
  }

  /// Enables or disables haptic feedback.
  ///
  /// Inputs: enabled flag. Output: none. Side effects: persists settings.
  Future<void> setHapticsEnabled(bool enabled) {
    return _save(settings.value.copyWith(hapticsEnabled: enabled));
  }

  /// Enables or disables reduced motion.
  ///
  /// Inputs: enabled flag. Output: none. Side effects: persists settings.
  Future<void> setReduceMotionEnabled(bool enabled) {
    return _save(settings.value.copyWith(reduceMotionEnabled: enabled));
  }

  Future<void> _save(GameSettings nextSettings) async {
    settings.value = nextSettings;
    await settingsRepository.saveSettings(nextSettings);
  }
}
