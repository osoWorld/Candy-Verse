import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/level_config.dart';

/// Loads LevelConfig data from bundled assets in the data layer.
class LevelRepository {
  /// Creates an asset-backed LevelRepository.
  LevelRepository({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  /// Asset bundle used to load level JSON.
  final AssetBundle assetBundle;

  /// Loads a LevelConfig by [levelId] from assets/levels/.
  ///
  /// Inputs: level id without extension. Output: parsed LevelConfig. Side
  /// effects: reads from the configured asset bundle.
  Future<LevelConfig> loadLevelConfig(String levelId) {
    return loadFromAssetPath('assets/levels/$levelId.json');
  }

  /// Loads a LevelConfig from an explicit asset [path].
  ///
  /// Inputs: asset path. Output: parsed LevelConfig. Side effects: reads from
  /// the configured asset bundle.
  Future<LevelConfig> loadFromAssetPath(String path) async {
    try {
      final json = await assetBundle.loadString(path);
      return LevelConfig.fromJson(json);
    } on LevelConfigParseException {
      rethrow;
    } on FlutterError catch (error) {
      throw LevelConfigParseException(
        'Unable to load LevelConfig asset "$path": ${error.message}',
      );
    }
  }
}
