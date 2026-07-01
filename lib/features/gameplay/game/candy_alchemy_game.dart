import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../../core/utils/candy_alchemy_feedback.dart';
import '../components/board_component.dart';
import 'tempered_shatter_sound_hook.dart';
import 'preview_grid_state_factory.dart';

/// Flame game layer root for Candy Alchemy gameplay rendering.
class CandyAlchemyGame extends FlameGame {
  /// Creates the static Step 4 Candy Alchemy game.
  CandyAlchemyGame({
    PreviewGridStateFactory? previewGridStateFactory,
    this.onAcceptedSwap,
    this.onCascadeStepClear,
    this.onFrameTick,
    CandyAlchemyFeedback? feedback,
  }) : _previewGridStateFactory =
           previewGridStateFactory ?? PreviewGridStateFactory(),
       _feedback = feedback ?? PlatformCandyAlchemyFeedback();

  /// Callback invoked after an accepted swap is reported by the board.
  final void Function()? onAcceptedSwap;

  /// Callback invoked before a Cascade Step clear animation starts.
  final void Function(int cascadeStepIndex)? onCascadeStepClear;

  /// Callback invoked every Flame frame with elapsed seconds.
  final void Function(double elapsedSeconds)? onFrameTick;

  final CandyAlchemyFeedback _feedback;
  final PreviewGridStateFactory _previewGridStateFactory;
  BoardComponent? _boardComponent;

  /// Loads the static board renderer from a preview GridState.
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = size;
    camera.viewfinder.position = size / 2;
    camera.viewfinder.anchor = Anchor.center;

    final boardComponent = BoardComponent(
      gridState: _previewGridStateFactory.create(),
      tileSize: staticBoardTileSize,
      tileGap: staticBoardTileGap,
      onAcceptedSwap: onAcceptedSwap,
      onCascadeStepClear: onCascadeStepClear,
      temperedShatterSoundHook: TemperedShatterSoundHook(feedback: _feedback),
    );
    _boardComponent = boardComponent;
    _centerBoard();
    await world.add(boardComponent);
  }

  /// Keeps the static board centered when the GameWidget changes size.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.visibleGameSize = size;
    camera.viewfinder.position = size / 2;
    _centerBoard();
  }

  /// Pushes frame timing to UI controllers without exposing Flame internals.
  @override
  void update(double dt) {
    super.update(dt);
    onFrameTick?.call(dt);
  }

  /// Renders the gameplay background behind the world camera.
  @override
  Color backgroundColor() => CandyAlchemyColors.gameplayBackground;

  void _centerBoard() {
    final boardComponent = _boardComponent;
    if (boardComponent == null) {
      return;
    }
    boardComponent.position = (size - boardComponent.size) / 2;
  }
}
