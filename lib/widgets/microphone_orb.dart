import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/voice_session_controller.dart';
import '../theme/app_theme.dart';

class MicrophoneOrb extends StatefulWidget {
  final VoiceSessionController controller;
  final VoidCallback? onTextModeTap;

  const MicrophoneOrb({
    super.key,
    required this.controller,
    this.onTextModeTap,
  });

  @override
  State<MicrophoneOrb> createState() => _MicrophoneOrbState();
}

class _MicrophoneOrbState extends State<MicrophoneOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state;
    final isThinking = state == VoiceSessionState.thinking;
    final isActive = controller.isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator chip
        _buildStatusChip(state, controller.isMuted),
        const SizedBox(height: 18),

        // Main Orb and Flanking Action Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Action: Mute / Speaker Toggle
            _buildAuxiliaryButton(
              icon: controller.isMuted ? Icons.mic_off : Icons.mic_none,
              label: controller.isMuted ? 'Muted' : 'Mute',
              isActive: controller.isMuted,
              activeColor: AppTheme.pulseRed,
              onTap: isActive ? controller.toggleMute : null,
              tooltip: 'Mute / Unmute Microphone',
            ),

            const SizedBox(width: 24),

            // Centerpiece: The Grand Microphone Orb
            GestureDetector(
              onTap: () {
                controller.toggleSession();
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = isActive ? _scaleAnimation.value : 1.0;
                  final dynamicAmp = controller.audioAmplitude.clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outermost pulsating ring
                        if (isActive)
                          Container(
                            width: 130 + (dynamicAmp * 30),
                            height: 130 + (dynamicAmp * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getGlowColor(state).withValues(
                                alpha: 0.15 + (dynamicAmp * 0.15),
                              ),
                            ),
                          ),

                        // Mid glowing aura
                        Container(
                          width: 108 + (dynamicAmp * 16),
                          height: 108 + (dynamicAmp * 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _getGlowColor(state).withValues(alpha: 0.4),
                                _getGlowColor(state).withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Decorative Filigree Outer Rim
                        RotationTransition(
                          turns: isThinking
                              ? _rotationController
                              : const AlwaysStoppedAnimation(0),
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isThinking
                                    ? AppTheme.celestialCyan
                                    : AppTheme.brightGold.withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        // Core Solid Orb
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _getOrbGradient(state, controller.isMuted),
                            boxShadow: isActive
                                ? AppTheme.activePulseGlow
                                : AppTheme.goldOrbGlow,
                          ),
                          child: Center(
                            child: Icon(
                              _getCenterIcon(state, controller.isMuted),
                              size: 36,
                              color: const Color(0xFF0D121F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 24),

            // Right Action: Text Mode / Keyboard Input
            _buildAuxiliaryButton(
              icon: Icons.keyboard_alt_outlined,
              label: 'Text',
              isActive: false,
              activeColor: AppTheme.celestialCyan,
              onTap: widget.onTextModeTap,
              tooltip: 'Type a message',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(VoiceSessionState state, bool isMuted) {
    String label;
    Color dotColor;
    IconData? stateIcon;

    if (isMuted) {
      label = 'MICROPHONE MUTED';
      dotColor = AppTheme.pulseRed;
      stateIcon = Icons.mic_off;
    } else {
      switch (state) {
        case VoiceSessionState.connecting:
          label = 'CONNECTING TO GEMINI LIVE';
          dotColor = AppTheme.sereneIndigo;
          stateIcon = Icons.sync;
          break;
        case VoiceSessionState.listening:
          label = 'LISTENING • SPEAK FREELY';
          dotColor = AppTheme.amberAccent;
          stateIcon = Icons.graphic_eq;
          break;
        case VoiceSessionState.thinking:
          label = 'SEARCHING SCRIPTURE & REFLECTING';
          dotColor = AppTheme.celestialCyan;
          stateIcon = Icons.auto_awesome;
          break;
        case VoiceSessionState.speaking:
          label = 'GEMINI LIVE IS SPEAKING';
          dotColor = AppTheme.brightGold;
          stateIcon = Icons.volume_up;
          break;
        case VoiceSessionState.error:
          label = widget.controller.statusMessage ?? 'ERROR • TAP TO CONFIGURE';
          dotColor = AppTheme.pulseRed;
          stateIcon = Icons.warning_amber_rounded;
          break;
        case VoiceSessionState.idle:
        default:
          label = 'TAP MIC TO BEGIN CONVERSATION';
          dotColor = AppTheme.primaryGold.withValues(alpha: 0.6);
          stateIcon = Icons.mic;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dotColor.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(stateIcon, size: 14, color: dotColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuxiliaryButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    final isEnabled = onTap != null;
    final buttonColor = isActive ? activeColor : AppTheme.surfaceCardBorder;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.45,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceElevated,
                    border: Border.all(
                      color: buttonColor.withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
                      color: isActive ? activeColor : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: isActive ? activeColor : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getOrbGradient(VoiceSessionState state, bool isMuted) {
    if (isMuted) {
      return const LinearGradient(
        colors: [Color(0xFFF87171), Color(0xFFEF4444)],
      );
    }
    switch (state) {
      case VoiceSessionState.listening:
        return const LinearGradient(
          colors: [Color(0xFFFFDF7D), Color(0xFFFF9F1C)],
        );
      case VoiceSessionState.thinking:
        return const LinearGradient(
          colors: [Color(0xFF90E0EF), Color(0xFF4EA8DE)],
        );
      case VoiceSessionState.speaking:
        return const LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFE5B352)],
        );
      case VoiceSessionState.connecting:
        return const LinearGradient(
          colors: [Color(0xFFA5B4FC), Color(0xFF6366F1)],
        );
      case VoiceSessionState.error:
        return const LinearGradient(
          colors: [Color(0xFFFCA5A5), Color(0xFFDC2626)],
        );
      case VoiceSessionState.idle:
      default:
        return AppTheme.goldShimmerGradient;
    }
  }

  Color _getGlowColor(VoiceSessionState state) {
    switch (state) {
      case VoiceSessionState.listening:
        return AppTheme.amberAccent;
      case VoiceSessionState.thinking:
        return AppTheme.celestialCyan;
      case VoiceSessionState.speaking:
        return AppTheme.primaryGold;
      case VoiceSessionState.connecting:
        return AppTheme.sereneIndigo;
      case VoiceSessionState.error:
        return AppTheme.pulseRed;
      case VoiceSessionState.idle:
      default:
        return AppTheme.primaryGold;
    }
  }

  IconData _getCenterIcon(VoiceSessionState state, bool isMuted) {
    if (isMuted) return Icons.mic_off;
    switch (state) {
      case VoiceSessionState.listening:
        return Icons.mic;
      case VoiceSessionState.thinking:
        return Icons.auto_awesome;
      case VoiceSessionState.speaking:
        return Icons.graphic_eq;
      case VoiceSessionState.connecting:
        return Icons.sync;
      case VoiceSessionState.error:
        return Icons.error_outline;
      case VoiceSessionState.idle:
      default:
        return Icons.mic;
    }
  }
}
