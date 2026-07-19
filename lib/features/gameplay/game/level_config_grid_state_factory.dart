import '../../../data/models/level_config.dart';
import '../../../data/generators/level_config_starting_grid_factory.dart';
import '../../grid_logic/domain/entities/grid_state.dart';

/// Builds an initial GridState from LevelConfig data in the gameplay game layer.
///
/// PLACEMENT_NOTE: The data-to-domain adapter lives beside CandyAlchemyGame
/// because ARCHITECTURE.md section 3 keeps grid_logic/domain pure and
/// ARCHITECTURE.md section 12 keeps LevelConfig in the data layer.
class LevelConfigGridStateFactory {
  /// Creates a stateless LevelConfig GridState factory.
  const LevelConfigGridStateFactory();

  static const LevelConfigStartingGridFactory _startingGridFactory =
      LevelConfigStartingGridFactory();

  /// Creates a deterministic, full starting board for [levelConfig].
  ///
  /// Inputs: parsed LevelConfig. Output: GridState with no empty cells. Side
  /// effects: none.
  GridState create(LevelConfig levelConfig) {
    return _startingGridFactory.create(levelConfig);
  }
}
