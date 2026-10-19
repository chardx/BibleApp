import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PromptItem {
  final String text;
  final IconData icon;
  final String category;

  const PromptItem({
    required this.text,
    required this.icon,
    required this.category,
  });
}

class PromptCarousel extends StatelessWidget {
  final Function(String prompt) onSelectPrompt;

  const PromptCarousel({
    super.key,
    required this.onSelectPrompt,
  });

  static const List<PromptItem> defaultPrompts = [
    PromptItem(
      text: "Find peace for my anxiety",
      icon: Icons.spa_outlined,
      category: "COMFORT",
    ),
    PromptItem(
      text: "Explain the deeper meaning of Psalm 23",
      icon: Icons.auto_stories,
      category: "EXEGESIS",
    ),
    PromptItem(
      text: "Lead me in a prayer for strength",
      icon: Icons.volunteer_activism_outlined,
      category: "PRAYER",
    ),
    PromptItem(
      text: "What does Jesus teach about forgiveness?",
      icon: Icons.favorite_border,
      category: "TEACHING",
    ),
    PromptItem(
      text: "Scriptures for hope in difficult times",
      icon: Icons.wb_sunny_outlined,
      category: "DEVOTIONAL",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppTheme.brightGold,
              ),
              const SizedBox(width: 6),
              Text(
                'ASK OR SPEAK ABOUT',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: defaultPrompts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = defaultPrompts[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectPrompt(prompt.text),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.surfaceCardBorder.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          prompt.icon,
                          size: 16,
                          color: AppTheme.brightGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prompt.text,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
