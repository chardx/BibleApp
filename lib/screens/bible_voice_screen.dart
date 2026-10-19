import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/voice_session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/microphone_orb.dart';
import '../widgets/prompt_carousel.dart';
import '../widgets/text_input_sheet.dart';
import '../widgets/transcript_view.dart';
import '../widgets/voice_settings_modal.dart';

class BibleVoiceScreen extends StatefulWidget {
  const BibleVoiceScreen({super.key});

  @override
  State<BibleVoiceScreen> createState() => _BibleVoiceScreenState();
}

class _BibleVoiceScreenState extends State<BibleVoiceScreen> {
  late final VoiceSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VoiceSessionController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VoiceSettingsModal(controller: _controller),
    );
  }

  void _openTextMode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TextInputSheet(
        onSubmitted: (text) => _controller.submitPrompt(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgMidnight,
          appBar: _buildAppBar(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.deepSpaceGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Audio Wave Visualizer Area
                  _buildVisualizerSection(),

                  // Conversation / Scripture Transcript
                  Expanded(
                    child: TranscriptView(
                      messages: _controller.messages,
                      isThinking:
                          _controller.state == VoiceSessionState.thinking,
                      onScriptureSpeak: (scripture) =>
                          _controller.speakScripture(scripture),
                      geminiApiKey: _controller.apiKey,
                    ),
                  ),

                  // Prompt Starters Carousel
                  PromptCarousel(
                    onSelectPrompt: (prompt) =>
                        _controller.submitPrompt(prompt),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Dock: The Grand Microphone Orb
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: MicrophoneOrb(
                      controller: _controller,
                      onTextModeTap: _openTextMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.bgAbyss,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          // Sacred Emblem
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGold.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppTheme.brightGold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCRIPTURE LIVE',
                style: GoogleFonts.cinzel(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.isActive
                          ? AppTheme.livingGreen
                          : AppTheme.textMuted,
                      boxShadow: _controller.isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.livingGreen.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _controller.isActive
                        ? 'Gemini Live • ${_controller.selectedVoice}'
                        : _controller.hasApiKey
                            ? 'Gemini Live (${_controller.selectedVoice})'
                            : 'Set Gemini Key',
                    style: GoogleFonts.plusJakartaSans(
                      color: _controller.hasApiKey ? AppTheme.textMuted : AppTheme.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!_controller.hasApiKey)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ActionChip(
              avatar: const Icon(Icons.key, size: 13, color: AppTheme.brightGold),
              label: Text(
                'Set Key',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.brightGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
              side: BorderSide(
                color: AppTheme.primaryGold.withValues(alpha: 0.4),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: _openSettings,
            ),
          ),
        // Translation Chip
        ActionChip(
          label: Text(
            _controller.selectedTranslation,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.brightGold,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          backgroundColor: AppTheme.surfaceElevated,
          side: BorderSide(
            color: AppTheme.primaryGold.withValues(alpha: 0.4),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onPressed: _openSettings,
        ),
        const SizedBox(width: 4),

        // Settings Button
        IconButton(
          icon: const Icon(
            Icons.tune,
            color: AppTheme.textSecondary,
            size: 22,
          ),
          onPressed: _openSettings,
          tooltip: 'Settings & Voice Persona',
        ),

        // Menu (Clear Chat)
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppTheme.textSecondary,
            size: 22,
          ),
          color: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.surfaceCardBorder),
          ),
          onSelected: (val) {
            if (val == 'clear') {
              _controller.clearChat();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Reset Conversation',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVisualizerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Dynamic Wave Visualizer
          AudioVisualizer(
            state: _controller.state,
            amplitude: _controller.audioAmplitude,
            height: 90,
          ),

          // Real-time status text
          if (_controller.statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                _controller.statusMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
