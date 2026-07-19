import '../../features/boosters/domain/booster_type.dart';

/// Per-booster inventory row model in the data layer.
class BoosterInventoryRecord {
  /// Creates an immutable booster inventory row.
  const BoosterInventoryRecord({
    required this.playerId,
    required this.boosterType,
    required this.count,
    required this.updatedAt,
  });

  /// Player id, scoped by Supabase RLS to auth.uid().
  final String playerId;

  /// Booster represented by this inventory row.
  final BoosterType boosterType;

  /// Owned count for [boosterType].
  final int count;

  /// Last local or remote update timestamp.
  final DateTime updatedAt;

  /// Stable local key for Hive fallback storage.
  String get storageKey => '$playerId::${boosterType.name}';

  /// Parses a BoosterInventoryRecord from Supabase/Hive map data.
  ///
  /// Inputs: row map. Output: BoosterInventoryRecord. Side effects: none.
  factory BoosterInventoryRecord.fromMap(Map<String, dynamic> map) {
    return BoosterInventoryRecord(
      playerId: _requiredString(map, 'player_id'),
      boosterType: _requiredBoosterType(map, 'booster_type'),
      count: _requiredNonNegativeInt(map, 'count'),
      updatedAt: DateTime.parse(_requiredString(map, 'updated_at')),
    );
  }

  /// Converts this row to Supabase/Hive map data.
  ///
  /// Inputs: none. Output: serializable map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'booster_type': boosterType.name,
      'count': count,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is String) {
      return value;
    }
    throw FormatException(
      'BoosterInventoryRecord.$fieldName must be a string.',
    );
  }

  static int _requiredNonNegativeInt(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value is int && value >= 0) {
      return value;
    }
    throw FormatException(
      'BoosterInventoryRecord.$fieldName must be a non-negative int.',
    );
  }

  static BoosterType _requiredBoosterType(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = _requiredString(map, fieldName);
    for (final boosterType in BoosterType.values) {
      if (boosterType.name == value) {
        return boosterType;
      }
    }
    throw FormatException(
      'BoosterInventoryRecord.$fieldName has unsupported BoosterType "$value".',
    );
  }
}
