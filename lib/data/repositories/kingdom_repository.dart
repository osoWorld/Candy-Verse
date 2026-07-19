import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/kingdom_constants.dart';
import '../models/kingdom_config.dart';

/// Loads KingdomConfig data from bundled assets in the data layer.
class KingdomRepository {
  /// Creates an asset-backed KingdomRepository.
  KingdomRepository({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  /// Asset bundle used to load kingdom JSON.
  final AssetBundle assetBundle;

  /// Loads all bundled V1 KingdomConfig records in map order.
  ///
  /// Inputs: none. Output: ordered kingdom configs. Side effects: reads from
  /// the configured asset bundle.
  Future<List<KingdomConfig>> loadKingdomConfigs() async {
    final configs = <KingdomConfig>[];
    for (final kingdomId in v1KingdomIds) {
      configs.add(await loadKingdomConfig(kingdomId));
    }
    return configs;
  }

  /// Loads one KingdomConfig by [kingdomId] from assets/kingdoms/.
  ///
  /// Inputs: kingdom id without extension. Output: parsed KingdomConfig. Side
  /// effects: reads from the configured asset bundle.
  Future<KingdomConfig> loadKingdomConfig(String kingdomId) {
    return loadFromAssetPath('$kingdomAssetDirectory/$kingdomId.json');
  }

  /// Loads a KingdomConfig from an explicit asset [path].
  ///
  /// Inputs: asset path. Output: parsed KingdomConfig. Side effects: reads from
  /// the configured asset bundle.
  Future<KingdomConfig> loadFromAssetPath(String path) async {
    try {
      final json = await assetBundle.loadString(path);
      return KingdomConfig.fromJson(json);
    } on KingdomConfigParseException {
      rethrow;
    } on FlutterError catch (error) {
      throw KingdomConfigParseException(
        'Unable to load KingdomConfig asset "$path": ${error.message}',
      );
    }
  }
}
