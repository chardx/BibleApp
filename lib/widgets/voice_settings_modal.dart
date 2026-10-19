import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/voice_session_controller.dart';
import '../theme/app_theme.dart';

class VoiceSettingsModal extends StatefulWidget {
  final VoiceSessionController controller;

  const VoiceSettingsModal({super.key, required this.controller});

  @override
  State<VoiceSettingsModal> createState() => _VoiceSettingsModalState();
}

class _VoiceSettingsModalState extends State<VoiceSettingsModal> {
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  String _activeTab = 'voice'; // 'voice', 'model', 'bible', 'api'

  static const List<String> translations = [
    'ESV',
    'NIV',
    'KJV',
    'NLT',
    'NASB',
    'CSB',
  ];

  static const List<Map<String, String>> geminiVoices = [
    {
      'id': 'Kore',
      'name': 'Kore',
      'desc':
          'Warm, empathetic and friendly (Recommended for devotional study)',
      'tone': 'Warm & Friendly',
    },
    {
      'id': 'Aoede',
      'name': 'Aoede',
      'desc': 'Melodic, serene and pleasant',
      'tone': 'Melodic & Serene',
    },
    {
      'id': 'Charon',
      'name': 'Charon',
      'desc': 'Deep, resonant and authoritative',
      'tone': 'Deep & Resonant',
    },
    {
      'id': 'Fenrir',
      'name': 'Fenrir',
      'desc': 'Strong, steady and confident',
      'tone': 'Strong & Confident',
    },
    {
      'id': 'Puck',
      'name': 'Puck',
      'desc': 'Playful, lively and energetic',
      'tone': 'Lively & Upbeat',
    },
    {
      'id': 'Leda',
      'name': 'Leda',
      'desc': 'Gentle, calm and peaceful',
      'tone': 'Gentle & Calm',
    },
    {
      'id': 'Orus',
      'name': 'Orus',
      'desc': 'Clear, articulate and instructive',
      'tone': 'Clear & Articulate',
    },
    {
      'id': 'Zephyr',
      'name': 'Zephyr',
      'desc': 'Light, airy and contemplative',
      'tone': 'Light & Contemplative',
    },
  ];

  static const List<Map<String, String>> geminiModels = [
    {
      'id': 'models/gemini-3.8-live',
      'name': 'Gemini 2.0 Flash Live (Default)',
      'desc': 'Real-time bidirectional audio streaming with ultra-low latency.',
      'badge': 'Optimal',
    },
    {
      'id': 'models/gemini-3.8-live',
      'name': 'Gemini 2.0 Flash Live 001',
      'desc': 'Stable production real-time voice endpoint.',
      'badge': 'Stable',
    },
    {
      'id': 'models/gemini-2.5-flash-preview-native-audio-dialog',
      'name': 'Gemini 2.5 Flash Native Audio',
      'desc': 'Enhanced dialogue model with emotional nuance.',
      'badge': '2.5 Preview',
    },
    {
      'id': 'gemini-3.1-flash-live-preview',
      'name': 'Gemini 3.1 Flash Live',
      'desc': 'Lowest latency audio-to-audio model with live transcription.',
      'badge': 'New 3.1',
    },
    {
      'id': 'gemini-3.8-live',
      'name': 'Gemini 3.8 Live',
      'desc': 'Low-latency audio model with interleaved theological reasoning.',
      'badge': 'Next-Gen',
    },
  ];

  static const List<Map<String, String>> personas = [
    {
      'title': 'Biblical Scholar & Exegete',
      'desc':
          'Deep historical context, cross-references, and original text nuances.',
    },
    {
      'title': 'Pastoral Counselor',
      'desc':
          'Empathetic spiritual care, prayerful reassurance, and comforting verses.',
    },
    {
      'title': 'Daily Devotional Guide',
      'desc':
          'Practical daily walk, reflections, and morning/evening meditations.',
    },
    {
      'title': 'Original Greek & Hebrew',
      'desc': 'Detailed morphological breakdown and root word theology.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.controller.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKey() {
    final key = _apiKeyController.text.trim();
    widget.controller.setApiKey(key);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.surfaceElevated,
        content: Text(
          'Gemini API Key updated successfully',
          style: TextStyle(color: AppTheme.brightGold),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.bgAbyss,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.settings_voice,
                      color: AppTheme.brightGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'GEMINI LIVE & VOICE SETTINGS',
                      style: GoogleFonts.cinzel(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Segmented Tabs
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceCardBorder),
              ),
              child: Row(
                children: [
                  _buildTabButton('voice', 'Voice', Icons.record_voice_over),
                  _buildTabButton('model', 'Model', Icons.psychology),
                  _buildTabButton('bible', 'Scripture', Icons.menu_book),
                  _buildTabButton('api', 'API Key', Icons.key),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content Area (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildActiveTabContent(controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String id, String label, IconData icon) {
    final isSelected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFF0C101A)
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected
                      ? const Color(0xFF0C101A)
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(VoiceSessionController controller) {
    switch (_activeTab) {
      case 'voice':
        return _buildVoiceTab(controller);
      case 'model':
        return _buildModelTab(controller);
      case 'bible':
        return _buildBibleTab(controller);
      case 'api':
      default:
        return _buildApiKeyTab(controller);
    }
  }

  // -------------------------------------------------------------
  // TAB 1: GEMINI VOICES
  // -------------------------------------------------------------
  Widget _buildVoiceTab(VoiceSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GEMINI NATURAL SPEECH VOICES (TTS)',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        ...geminiVoices.map((v) {
          final isSelected = controller.selectedVoice == v['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => controller.setVoice(v['id']!),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGold.withValues(alpha: 0.12)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGold
                        : AppTheme.surfaceCardBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryGold.withValues(alpha: 0.2)
                            : AppTheme.surfaceElevated,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.brightGold
                              : AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isSelected
                              ? Icons.graphic_eq
                              : Icons.volume_up_outlined,
                          size: 18,
                          color: isSelected
                              ? AppTheme.brightGold
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v['name']!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v['tone']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            v['desc']!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppTheme.brightGold,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: GEMINI MODELS
  // -------------------------------------------------------------
  Widget _buildModelTab(VoiceSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GEMINI LIVE AUDIO ARCHITECTURE',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        ...geminiModels.map((m) {
          final isSelected = controller.selectedModel == m['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => controller.setModel(m['id']!),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.celestialCyan.withValues(alpha: 0.12)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.celestialCyan
                        : AppTheme.surfaceCardBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: isSelected
                          ? AppTheme.celestialCyan
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m['name']!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.celestialCyan.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  m['badge']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.celestialCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            m['desc']!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: BIBLE TRANSLATION & PERSONA
  // -------------------------------------------------------------
  Widget _buildBibleTab(VoiceSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation Chips
        Text(
          'PREFERRED SCRIPTURE TRANSLATION',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: translations.map((tr) {
            final isSelected = controller.selectedTranslation == tr;
            return ChoiceChip(
              label: Text(tr),
              selected: isSelected,
              selectedColor: AppTheme.primaryGold,
              backgroundColor: AppTheme.surfaceElevated,
              labelStyle: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? const Color(0xFF0A0F1D)
                    : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              onSelected: (val) {
                if (val) controller.setTranslation(tr);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // Persona
        Text(
          'VOICE THEOLOGICAL PERSONA',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        ...personas.map((persona) {
          final isSelected = controller.selectedPersona == persona['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => controller.setPersona(persona['title']!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGold.withValues(alpha: 0.12)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGold
                        : AppTheme.surfaceCardBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: isSelected
                          ? AppTheme.brightGold
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona['title']!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            persona['desc']!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: API KEY CONFIGURATION
  // -------------------------------------------------------------
  Widget _buildApiKeyTab(VoiceSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOOGLE GEMINI API KEY',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A Google AI Studio API key enables low-latency bidirectional voice and Gemini TTS audio streaming directly on your device.',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Key Input Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: controller.hasApiKey
                  ? AppTheme.livingGreen.withValues(alpha: 0.5)
                  : AppTheme.primaryGold.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.vpn_key_rounded,
                color: controller.hasApiKey
                    ? AppTheme.livingGreen
                    : AppTheme.brightGold,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              'Save & Activate Key',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: const Color(0xFF0C101A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            onPressed: _saveApiKey,
          ),
        ),
        const SizedBox(height: 20),

        // Status Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: controller.hasApiKey
                  ? AppTheme.livingGreen.withValues(alpha: 0.3)
                  : AppTheme.surfaceCardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                controller.hasApiKey ? Icons.verified_user : Icons.info_outline,
                color: controller.hasApiKey
                    ? AppTheme.livingGreen
                    : AppTheme.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.hasApiKey
                      ? 'Gemini Live is active with your saved credentials.'
                      : 'No API key set. Free keys are available from Google AI Studio (aistudio.google.com).',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
