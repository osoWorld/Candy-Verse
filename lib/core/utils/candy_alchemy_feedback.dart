import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/feedback_constants.dart';

/// Audio cue names for Candy Alchemy feedback.
enum CandyAlchemySoundCue {
  standardMatch,
  temperedShatter,
  tempoMeterFull,
  architectTile,
  levelComplete,
}

/// Feedback contract for sound and haptics in the UI/game layer.
abstract class CandyAlchemyFeedback {
  /// Plays the standard match chime for [cascadeStepIndex].
  void playStandardMatch({required int cascadeStepIndex});

  /// Plays the Tempered Shatter chime/crack cue and impact haptic.
  void playTemperedShatter();

  /// Plays the Tempo Meter full cue and soft haptic.
  void playTempoMeterFull();

  /// Plays the Architect Tile mechanical shift cue.
  void playArchitectTile();

  /// Plays level-complete feedback.
  void playLevelComplete();

  /// Releases feedback resources.
  Future<void> dispose();
}

/// Platform feedback implementation with optional just_audio asset cues.
class PlatformCandyAlchemyFeedback implements CandyAlchemyFeedback {
  /// Creates platform feedback with optional [assetPaths] keyed by cue.
  PlatformCandyAlchemyFeedback({Map<CandyAlchemySoundCue, String>? assetPaths})
    : assetPaths = Map<CandyAlchemySoundCue, String>.unmodifiable(
        assetPaths ?? const {},
      );

  /// Asset paths for sound cues when bundled audio assets exist.
  final Map<CandyAlchemySoundCue, String> assetPaths;

  final Map<CandyAlchemySoundCue, AudioPlayer> _players = {};

  /// Plays the standard match chime for [cascadeStepIndex].
  @override
  void playStandardMatch({required int cascadeStepIndex}) {
    final wrappedStep = cascadeStepIndex % standardMatchPitchResetStepCount;
    final playbackSpeed =
        standardMatchBasePlaybackSpeed +
        wrappedStep * standardMatchPlaybackSpeedStep;
    unawaited(
      _playCue(
        CandyAlchemySoundCue.standardMatch,
        playbackSpeed: playbackSpeed,
      ),
    );
  }

  /// Plays the Tempered Shatter chime/crack cue and impact haptic.
  @override
  void playTemperedShatter() {
    unawaited(_playCue(CandyAlchemySoundCue.temperedShatter));
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Plays the Tempo Meter full cue and soft haptic.
  @override
  void playTempoMeterFull() {
    unawaited(_playCue(CandyAlchemySoundCue.tempoMeterFull));
    unawaited(HapticFeedback.lightImpact());
  }

  /// Plays the Architect Tile mechanical shift cue.
  @override
  void playArchitectTile() {
    unawaited(_playCue(CandyAlchemySoundCue.architectTile));
  }

  /// Plays level-complete feedback.
  @override
  void playLevelComplete() {
    unawaited(_playCue(CandyAlchemySoundCue.levelComplete));
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Releases just_audio players.
  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> _playCue(
    CandyAlchemySoundCue cue, {
    double playbackSpeed = standardMatchBasePlaybackSpeed,
  }) async {
    final assetPath = assetPaths[cue];
    if (assetPath == null) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }

    final player = _players.putIfAbsent(cue, AudioPlayer.new);
    await player.setAsset(assetPath);
    await player.setSpeed(playbackSpeed);
    await player.seek(Duration.zero);
    await player.play();
  }
}
