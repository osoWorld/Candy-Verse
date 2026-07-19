import 'base_candy.dart';
import 'reactive_state.dart';

/// Spawn rule entity in the pure Dart core logic layer.
class SpawnRule {
  /// Creates deterministic candy spawn rules from available identities.
  ///
  /// Inputs: base candies, reactive states, and seed. Output: immutable rule.
  /// Side effects: none.
  SpawnRule({
    required Iterable<BaseCandy> baseCandies,
    required Iterable<ReactiveState> reactiveStates,
    required this.seed,
  }) : baseCandies = List<BaseCandy>.unmodifiable(baseCandies),
       reactiveStates = List<ReactiveState>.unmodifiable(reactiveStates) {
    if (this.baseCandies.isEmpty) {
      throw ArgumentError.value(
        this.baseCandies,
        'baseCandies',
        'SpawnRule requires at least one BaseCandy.',
      );
    }
    if (this.reactiveStates.isEmpty) {
      throw ArgumentError.value(
        this.reactiveStates,
        'reactiveStates',
        'SpawnRule requires at least one ReactiveState.',
      );
    }
  }

  /// Default refill rule used until level JSON spawn rules are wired.
  static final SpawnRule defaultRule = SpawnRule(
    baseCandies: BaseCandy.values,
    reactiveStates: const [ReactiveState.none],
    seed: 1,
  );

  /// Base Candy identities allowed for spawned tiles.
  final List<BaseCandy> baseCandies;

  /// Reactive State identities allowed for spawned tiles.
  final List<ReactiveState> reactiveStates;

  /// Stable seed used for deterministic tile generation.
  final int seed;
}
