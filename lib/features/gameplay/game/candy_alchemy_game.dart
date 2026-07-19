import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../core/theme/candy_alchemy_colors.dart';
import '../../../core/utils/candy_alchemy_feedback.dart';
import '../../boosters/domain/booster_type.dart';
import '../../grid_logic/domain/entities/cascade_step_result.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../components/board_component.dart';
import 'board_layout_calculator.dart';
import 'tempered_shatter_sound_hook.dart';

/// Flame game layer root for Candy Alchemy gameplay rendering.
class CandyAlchemyGame extends FlameGame {
  /// Creates the Candy Alchemy game for [initialGridState].
  CandyAlchemyGame({
    required this.initialGridState,
    BoardLayoutCalculator? boardLayoutCalculator,
    this.onAcceptedSwap,
    this.onCascadeStepClear,
    this.onCascadeStepResolved,
    this.onCascadeSettled,
    this.isInputEnabledProvider,
    this.onFrameTick,
    this.selectedBoosterProvider,
    this.onBoosterActivated,
    this.reduceMotionProvider,
    CandyAlchemyFeedback? feedback,
  }) : _boardLayoutCalculator =
           boardLayoutCalculator ?? const BoardLayoutCalculator(),
       _feedback = feedback ?? PlatformCandyAlchemyFeedback();

  /// Initial board state loaded from LevelConfig JSON.
  final GridState initialGridState;

  /// Callback invoked after an accepted swap is reported by the board.
  final void Function()? onAcceptedSwap;

  /// Callback invoked before a Cascade Step clear animation starts.
  final void Function(int cascadeStepIndex)? onCascadeStepClear;

  /// Callback invoked with the full Cascade Step payload for scoring/goals.
  final void Function(int cascadeStepIndex, CascadeStepResult cascadeStep)?
  onCascadeStepResolved;

  /// Callback invoked after the board has finished resolving cascades.
  final void Function()? onCascadeSettled;

  /// Returns whether board gestures should currently be accepted.
  final bool Function()? isInputEnabledProvider;

  /// Callback invoked every Flame frame with elapsed seconds.
  final void Function(double elapsedSeconds)? onFrameTick;

  /// Returns whether intense gameplay motion should be reduced.
  final bool Function()? reduceMotionProvider;

  /// Returns the selected booster waiting for a board target, if any.
  final BoosterType? Function()? selectedBoosterProvider;

  /// Callback invoked after a board booster activation succeeds.
  final bool Function(BoosterType boosterType)? onBoosterActivated;

  final CandyAlchemyFeedback _feedback;
  final BoardLayoutCalculator _boardLayoutCalculator;
  BoardComponent? _boardComponent;

  /// Loads the board renderer from the LevelConfig-backed GridState.
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = size;
    camera.viewfinder.position = size / 2;
    camera.viewfinder.anchor = Anchor.center;

    final boardLayout = _boardLayoutCalculator.calculate(
      viewportSize: size,
      gridState: initialGridState,
    );
    final boardComponent = BoardComponent(
      gridState: initialGridState,
      tileSize: boardLayout.tileSize,
      tileGap: boardLayout.tileGap,
      onAcceptedSwap: onAcceptedSwap,
      onCascadeStepClear: onCascadeStepClear,
      onCascadeStepResolved: onCascadeStepResolved,
      onCascadeSettled: onCascadeSettled,
      isInputEnabledProvider: isInputEnabledProvider,
      selectedBoosterProvider: selectedBoosterProvider,
      onBoosterActivated: onBoosterActivated,
      reduceMotionProvider: reduceMotionProvider,
      temperedShatterSoundHook: TemperedShatterSoundHook(feedback: _feedback),
    );
    _boardComponent = boardComponent;
    boardComponent.position = boardLayout.position;
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
    final boardLayout = _boardLayoutCalculator.calculate(
      viewportSize: size,
      gridState: boardComponent.gridState,
    );
    boardComponent.position = boardLayout.position;
  }
}
