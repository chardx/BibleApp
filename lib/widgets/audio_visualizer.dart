import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/voice_session_controller.dart';
import '../theme/app_theme.dart';

class AudioVisualizer extends StatefulWidget {
  final VoiceSessionState state;
  final double amplitude;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.state,
    required this.amplitude,
    this.height = 140,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _HarmonicWavePainter(
            animationValue: _animController.value,
            amplitude: widget.amplitude,
            sessionState: widget.state,
          ),
        );
      },
    );
  }
}

class _HarmonicWavePainter extends CustomPainter {
  final double animationValue;
  final double amplitude;
  final VoiceSessionState sessionState;

  _HarmonicWavePainter({
    required this.animationValue,
    required this.amplitude,
    required this.sessionState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final width = size.width;

    // Background subtle glow in center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _getStateAccentColor().withValues(alpha: 0.22 * (amplitude.clamp(0.2, 1.0))),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(width / 2, midY),
        radius: width * 0.45,
      ));
    canvas.drawCircle(Offset(width / 2, midY), width * 0.45, glowPaint);

    // Number of harmonic sine wave layers
    final waveConfigs = [
      _WaveConfig(
        color: AppTheme.primaryGold.withValues(alpha: 0.85),
        strokeWidth: 2.8,
        frequency: 2.2,
        speedMultiplier: 1.2,
        phaseOffset: 0.0,
        ampScale: 1.0,
      ),
      _WaveConfig(
        color: AppTheme.brightGold.withValues(alpha: 0.65),
        strokeWidth: 2.0,
        frequency: 3.1,
        speedMultiplier: -1.0,
        phaseOffset: math.pi / 3,
        ampScale: 0.8,
      ),
      _WaveConfig(
        color: AppTheme.celestialCyan.withValues(alpha: 0.6),
        strokeWidth: 2.2,
        frequency: 1.8,
        speedMultiplier: 1.5,
        phaseOffset: math.pi / 2,
        ampScale: 0.75,
      ),
      _WaveConfig(
        color: AppTheme.sereneIndigo.withValues(alpha: 0.4),
        strokeWidth: 1.8,
        frequency: 4.0,
        speedMultiplier: -0.8,
        phaseOffset: math.pi,
        ampScale: 0.5,
      ),
    ];

    for (final config in waveConfigs) {
      _drawWave(canvas, size, midY, config);
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double midY,
    _WaveConfig config,
  ) {
    final path = Path();
    final paint = Paint()
      ..color = config.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.strokeWidth
      ..strokeCap = StrokeCap.round;

    final baseAmp = (size.height * 0.38) * (amplitude.clamp(0.12, 1.0)) * config.ampScale;
    final speed = animationValue * 2 * math.pi * config.speedMultiplier;

    path.moveTo(0, midY);

    for (double x = 0; x <= size.width; x += 3.0) {
      // Gaussian window attenuation on edges so wave tapers nicely at left/right borders
      final normalizedX = (x / size.width) * 2 - 1; // -1 to 1
      final window = math.exp(-3.5 * normalizedX * normalizedX);

      final y = midY +
          math.sin((x / size.width) * config.frequency * 2 * math.pi + speed + config.phaseOffset) *
              baseAmp *
              window;

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  Color _getStateAccentColor() {
    switch (sessionState) {
      case VoiceSessionState.listening:
        return AppTheme.amberAccent;
      case VoiceSessionState.speaking:
        return AppTheme.primaryGold;
      case VoiceSessionState.thinking:
        return AppTheme.celestialCyan;
      case VoiceSessionState.connecting:
        return AppTheme.sereneIndigo;
      case VoiceSessionState.idle:
      default:
        return AppTheme.primaryGold;
    }
  }

  @override
  bool shouldRepaint(covariant _HarmonicWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.sessionState != sessionState;
  }
}

class _WaveConfig {
  final Color color;
  final double strokeWidth;
  final double frequency;
  final double speedMultiplier;
  final double phaseOffset;
  final double ampScale;

  _WaveConfig({
    required this.color,
    required this.strokeWidth,
    required this.frequency,
    required this.speedMultiplier,
    required this.phaseOffset,
    required this.ampScale,
  });
}
