import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';

/// Type of pooled reactive-state particle burst in the Flame game layer.
enum ParticleEffectKind {
  moltenEmber,
  frostShard,
  livingHeart,
  syrupSplash,
  spiceEmber,
  sugarSparkle,
}

/// Pooled state-specific particle burst renderer in the Flame game layer.
class ParticleEffects extends PositionComponent {
  /// Creates a reusable particle effect with fixed particle slots.
  ParticleEffects()
    : _paint = Paint(),
      _particles = List<_ParticleSpec>.generate(
        reactiveStateParticlePoolSize,
        (index) => _ParticleSpec(index: index),
      );

  final Paint _paint;
  final List<_ParticleSpec> _particles;
  ParticleEffectKind _kind = ParticleEffectKind.moltenEmber;
  Color _color = CandyAlchemyColors.molten;
  double _elapsedSeconds = 0;
  double _durationSeconds = moltenBurstDurationSeconds;
  double _tileSize = staticBoardTileSize;

  /// Starts this pooled effect at [position] using [kind] and [tileSize].
  void play({
    required ParticleEffectKind kind,
    required Vector2 position,
    required double tileSize,
  }) {
    _kind = kind;
    _tileSize = tileSize;
    _elapsedSeconds = 0;
    this.position = position;
    size = Vector2.all(tileSize);
    _configureForKind(kind);
  }

  /// Advances this pooled effect until it removes itself for reuse.
  @override
  void update(double dt) {
    super.update(dt);

    // ARCHITECTURE.md section 9: fixed particle slots, no per-frame spawning.
    _elapsedSeconds += dt;
    if (_elapsedSeconds >= _durationSeconds) {
      removeFromParent();
    }
  }

  /// Renders the active pooled particle burst.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
    final center = Offset(_tileSize / 2, _tileSize / 2);
    for (final particle in _particles) {
      final distance = particle.travelDistance * progress;
      final particleCenter = Offset(
        center.dx + math.cos(particle.angleRadians) * distance,
        center.dy + math.sin(particle.angleRadians) * distance,
      );
      final opacity = (1 - progress).clamp(0.0, 1.0);
      _paint
        ..color = _color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill
        ..strokeWidth = 2;

      // DESIGN.md section 4: state-specific match particle silhouettes.
      switch (_kind) {
        case ParticleEffectKind.sugarSparkle:
          _drawSparkle(
            canvas,
            particleCenter,
            particle.radius * (1 - progress),
          );
        case ParticleEffectKind.frostShard:
          _drawShard(canvas, particleCenter, particle.radius * (1 - progress));
        case ParticleEffectKind.livingHeart:
          _drawHeart(canvas, particleCenter, particle.radius * (1 - progress));
        case ParticleEffectKind.syrupSplash:
          _drawDroplet(
            canvas,
            particleCenter,
            particle.radius * (1 - progress),
          );
        case ParticleEffectKind.moltenEmber:
        case ParticleEffectKind.spiceEmber:
          canvas.drawCircle(
            particleCenter,
            particle.radius * (1 - progress),
            _paint,
          );
      }
    }
  }

  void _configureForKind(ParticleEffectKind kind) {
    switch (kind) {
      case ParticleEffectKind.moltenEmber:
        _color = CandyAlchemyColors.molten;
        _durationSeconds = moltenBurstDurationSeconds;
        _configureParticles(spreadMultiplier: 0.72, radiusMultiplier: 0.065);
      case ParticleEffectKind.frostShard:
        _color = CandyAlchemyColors.frost;
        _durationSeconds = frostShardDurationSeconds;
        _configureParticles(spreadMultiplier: 0.84, radiusMultiplier: 0.08);
      case ParticleEffectKind.livingHeart:
        _color = CandyAlchemyColors.livingHeartParticle;
        _durationSeconds = livingHeartDurationSeconds;
        _configureParticles(spreadMultiplier: 0.68, radiusMultiplier: 0.07);
      case ParticleEffectKind.syrupSplash:
        _color = CandyAlchemyColors.syrup;
        _durationSeconds = syrupSplashDurationSeconds;
        _configureParticles(spreadMultiplier: 0.7, radiusMultiplier: 0.075);
      case ParticleEffectKind.spiceEmber:
        _color = CandyAlchemyColors.spice;
        _durationSeconds = spiceEmberDurationSeconds;
        _configureParticles(spreadMultiplier: 0.58, radiusMultiplier: 0.055);
      case ParticleEffectKind.sugarSparkle:
        _color = CandyAlchemyColors.sugarSparkle;
        _durationSeconds = sugarSparkleDurationSeconds;
        _configureParticles(spreadMultiplier: 0.78, radiusMultiplier: 0.055);
    }
  }

  void _configureParticles({
    required double spreadMultiplier,
    required double radiusMultiplier,
  }) {
    for (final particle in _particles) {
      final normalizedIndex = particle.index / _particles.length;
      particle
        ..angleRadians = math.pi * 2 * normalizedIndex
        ..travelDistance =
            _tileSize * spreadMultiplier * (0.58 + normalizedIndex * 0.42)
        ..radius =
            _tileSize * radiusMultiplier * (0.72 + normalizedIndex * 0.28);
    }
  }

  void _drawShard(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.65, center.dy + radius)
      ..lineTo(center.dx - radius * 0.65, center.dy + radius * 0.65)
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawDroplet(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius,
        center.dy,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius,
        center.dy,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..cubicTo(
        center.dx - radius * 1.4,
        center.dy,
        center.dx - radius * 0.8,
        center.dy - radius,
        center.dx,
        center.dy - radius * 0.35,
      )
      ..cubicTo(
        center.dx + radius * 0.8,
        center.dy - radius,
        center.dx + radius * 1.4,
        center.dy,
        center.dx,
        center.dy + radius,
      );
    canvas.drawPath(path, _paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.3)
      ..lineTo(center.dx + radius * 0.32, center.dy - radius * 0.32)
      ..lineTo(center.dx + radius * 1.3, center.dy)
      ..lineTo(center.dx + radius * 0.32, center.dy + radius * 0.32)
      ..lineTo(center.dx, center.dy + radius * 1.3)
      ..lineTo(center.dx - radius * 0.32, center.dy + radius * 0.32)
      ..lineTo(center.dx - radius * 1.3, center.dy)
      ..lineTo(center.dx - radius * 0.32, center.dy - radius * 0.32)
      ..close();
    canvas.drawPath(path, _paint);
  }
}

class _ParticleSpec {
  _ParticleSpec({required this.index});

  final int index;
  double angleRadians = 0;
  double travelDistance = 0;
  double radius = 0;
}
