import 'kingdom_gate_definition.dart';
import 'kingdom_level_definition.dart';

/// Kingdom section data for the Kingdom Map domain layer.
class KingdomDefinition {
  /// Creates an immutable kingdom section definition.
  const KingdomDefinition({
    required this.kingdomId,
    required this.name,
    required this.levelStart,
    required this.levelEnd,
    required this.backgroundColorValue,
    required this.secondaryColorValue,
    required this.accentColorValue,
    required this.introStory,
    required this.outroStory,
    required this.characterName,
    required this.characterNames,
    required this.mapMotifs,
    required this.gates,
    required this.levels,
  });

  /// Stable kingdom id.
  final String kingdomId;

  /// User-facing kingdom name.
  final String name;

  /// First global level number in this kingdom.
  final int levelStart;

  /// Last global level number in this kingdom.
  final int levelEnd;

  /// Background color value from DESIGN.md section 3.
  final int backgroundColorValue;

  /// Secondary color value from DESIGN.md section 3.
  final int secondaryColorValue;

  /// Accent color value from DESIGN.md section 3.
  final int accentColorValue;

  /// Short kingdom intro story.
  final String introStory;

  /// Short kingdom outro story.
  final String outroStory;

  /// Original guide or kingdom character name.
  final String characterName;

  /// Original guide or kingdom character names.
  final List<String> characterNames;

  /// Metadata motif ids used by the code-drawn kingdom map.
  final List<String> mapMotifs;

  /// Checkpoint gates in this kingdom.
  final List<KingdomGateDefinition> gates;

  /// Level nodes in this kingdom.
  final List<KingdomLevelDefinition> levels;
}
