import 'dart:convert';

/// Kingdom metadata data model in the data layer.
class KingdomConfig {
  /// Creates an immutable KingdomConfig.
  ///
  /// Inputs: required metadata fields from assets/kingdoms. Output: validated
  /// KingdomConfig. Side effects: none.
  KingdomConfig({
    required this.kingdomId,
    required this.name,
    required this.levelStart,
    required this.levelEnd,
    required this.palette,
    required this.story,
    required Iterable<String> characters,
    required Iterable<String> mapMotifs,
  }) : characters = List<String>.unmodifiable(characters),
       mapMotifs = List<String>.unmodifiable(mapMotifs) {
    if (kingdomId.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.kingdomId must not be empty.',
      );
    }
    if (name.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.name must not be empty.',
      );
    }
    if (levelStart <= 0) {
      throw KingdomConfigParseException(
        'KingdomConfig.levelStart must be positive.',
      );
    }
    if (levelEnd < levelStart) {
      throw KingdomConfigParseException(
        'KingdomConfig.levelEnd must be greater than or equal to levelStart.',
      );
    }
    if (characters.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.characters must contain at least one value.',
      );
    }
    if (mapMotifs.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.mapMotifs must contain at least one value.',
      );
    }
  }

  /// Stable kingdom id.
  final String kingdomId;

  /// User-facing kingdom name.
  final String name;

  /// First global level number in this kingdom.
  final int levelStart;

  /// Last global level number in this kingdom.
  final int levelEnd;

  /// Visual palette for map rendering.
  final KingdomPalette palette;

  /// Intro and outro story copy for the map section.
  final KingdomStory story;

  /// Original character names featured by this kingdom.
  final List<String> characters;

  /// Map motif ids used by code-drawn map art.
  final List<String> mapMotifs;

  /// Parses a KingdomConfig from a JSON string.
  ///
  /// Inputs: JSON text. Output: validated KingdomConfig. Side effects: none.
  factory KingdomConfig.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw KingdomConfigParseException(
        'KingdomConfig JSON root must be an object.',
      );
    }
    return KingdomConfig.fromMap(decoded);
  }

  /// Parses a KingdomConfig from decoded JSON map data.
  ///
  /// Inputs: decoded JSON map. Output: validated KingdomConfig. Side effects:
  /// none.
  factory KingdomConfig.fromMap(Map<String, dynamic> map) {
    return KingdomConfig(
      kingdomId: _requiredString(map, 'kingdomId'),
      name: _requiredString(map, 'name'),
      levelStart: _requiredInt(map, 'levelStart'),
      levelEnd: _requiredInt(map, 'levelEnd'),
      palette: KingdomPalette.fromMap(_requiredMap(map, 'palette')),
      story: KingdomStory.fromMap(_requiredMap(map, 'story')),
      characters: _requiredStringList(map, 'characters'),
      mapMotifs: _requiredStringList(map, 'mapMotifs'),
    );
  }

  /// Converts this KingdomConfig to JSON-compatible map data.
  ///
  /// Inputs: none. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'kingdomId': kingdomId,
      'name': name,
      'levelStart': levelStart,
      'levelEnd': levelEnd,
      'palette': palette.toMap(),
      'story': story.toMap(),
      'characters': characters,
      'mapMotifs': mapMotifs,
    };
  }

  static String _requiredString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is String) {
      return value;
    }
    throw KingdomConfigParseException(
      'KingdomConfig.$fieldName is required and must be a string.',
    );
  }

  static int _requiredInt(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is int) {
      return value;
    }
    throw KingdomConfigParseException(
      'KingdomConfig.$fieldName is required and must be an integer.',
    );
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw KingdomConfigParseException(
      'KingdomConfig.$fieldName is required and must be an object.',
    );
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value is List && value.every((entry) => entry is String)) {
      return value.cast<String>();
    }
    throw KingdomConfigParseException(
      'KingdomConfig.$fieldName is required and must be a list of strings.',
    );
  }
}

/// Kingdom palette values in the data layer.
class KingdomPalette {
  /// Creates a validated KingdomPalette.
  ///
  /// Inputs: DESIGN.md §3 hex colors. Output: palette value object. Side
  /// effects: none.
  KingdomPalette({
    required this.sky,
    required this.ground,
    required this.accent,
  }) : skyColorValue = _parseHexColor(sky, 'palette.sky'),
       groundColorValue = _parseHexColor(ground, 'palette.ground'),
       accentColorValue = _parseHexColor(accent, 'palette.accent');

  /// Sky/background hex color string.
  final String sky;

  /// Ground/secondary hex color string.
  final String ground;

  /// Accent hex color string.
  final String accent;

  /// Parsed sky/background ARGB color value.
  final int skyColorValue;

  /// Parsed ground/secondary ARGB color value.
  final int groundColorValue;

  /// Parsed accent ARGB color value.
  final int accentColorValue;

  /// Parses a KingdomPalette from decoded JSON map data.
  ///
  /// Inputs: decoded JSON map. Output: validated KingdomPalette. Side effects:
  /// none.
  factory KingdomPalette.fromMap(Map<String, dynamic> map) {
    return KingdomPalette(
      sky: KingdomConfig._requiredString(map, 'sky'),
      ground: KingdomConfig._requiredString(map, 'ground'),
      accent: KingdomConfig._requiredString(map, 'accent'),
    );
  }

  /// Converts this KingdomPalette to JSON-compatible map data.
  ///
  /// Inputs: none. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {'sky': sky, 'ground': ground, 'accent': accent};
  }

  static int _parseHexColor(String value, String fieldName) {
    final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!hexPattern.hasMatch(value)) {
      throw KingdomConfigParseException(
        'KingdomConfig.$fieldName must be a #RRGGBB hex color.',
      );
    }
    return int.parse('FF${value.substring(1)}', radix: 16);
  }
}

/// Kingdom intro and outro story text in the data layer.
class KingdomStory {
  /// Creates a validated KingdomStory.
  ///
  /// Inputs: intro and outro strings. Output: story value object. Side effects:
  /// none.
  KingdomStory({required this.intro, required this.outro}) {
    if (intro.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.story.intro must not be empty.',
      );
    }
    if (outro.isEmpty) {
      throw KingdomConfigParseException(
        'KingdomConfig.story.outro must not be empty.',
      );
    }
  }

  /// Intro story copy shown at the top of a kingdom.
  final String intro;

  /// Outro story copy shown at the bottom of a kingdom.
  final String outro;

  /// Parses a KingdomStory from decoded JSON map data.
  ///
  /// Inputs: decoded JSON map. Output: validated KingdomStory. Side effects:
  /// none.
  factory KingdomStory.fromMap(Map<String, dynamic> map) {
    return KingdomStory(
      intro: KingdomConfig._requiredString(map, 'intro'),
      outro: KingdomConfig._requiredString(map, 'outro'),
    );
  }

  /// Converts this KingdomStory to JSON-compatible map data.
  ///
  /// Inputs: none. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {'intro': intro, 'outro': outro};
  }
}

/// Descriptive exception for invalid KingdomConfig JSON in the data layer.
class KingdomConfigParseException implements Exception {
  /// Creates a parse exception with a human-readable [message].
  const KingdomConfigParseException(this.message);

  /// Human-readable parse failure.
  final String message;

  /// Formats the parse failure for diagnostics and tests.
  @override
  String toString() => 'KingdomConfigParseException: $message';
}
