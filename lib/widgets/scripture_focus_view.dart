import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scripture.dart';
import '../theme/app_theme.dart';
import 'verse_image_dialog.dart';

class ScriptureFocusView extends StatelessWidget {
  final ScriptureQuote scripture;
  final VoidCallback? onSpeak;
  final String geminiApiKey;

  const ScriptureFocusView({
    super.key,
    required this.scripture,
    this.onSpeak,
    this.geminiApiKey = '',
  });

  static Future<void> open(
    BuildContext context,
    ScriptureQuote scripture, {
    VoidCallback? onSpeak,
    String geminiApiKey = '',
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close scripture',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      pageBuilder: (context, _, _) {
        return ScriptureFocusView(
          scripture: scripture,
          onSpeak: onSpeak,
          geminiApiKey: geminiApiKey,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width > 760 ? 680 : size.width - 32,
            constraints: BoxConstraints(maxHeight: size.height * 0.88),
            decoration: BoxDecoration(
              gradient: AppTheme.scriptureCardGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scripture.translation,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.brightGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Illustrate verse',
                        onPressed: () => VerseImageDialog.show(
                          context,
                          scripture: scripture,
                          apiKey: geminiApiKey,
                        ),
                        icon: const Icon(
                          Icons.palette_outlined,
                          color: AppTheme.brightGold,
                        ),
                      ),
                      if (onSpeak != null)
                        IconButton(
                          tooltip: 'Listen',
                          onPressed: () {
                            Navigator.of(context).pop();
                            onSpeak!();
                          },
                          icon: const Icon(
                            Icons.volume_up_outlined,
                            color: AppTheme.brightGold,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${scripture.reference} (${scripture.translation})\n${scripture.text}',
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(36, 12, 36, 28),
                    child: Column(
                      children: [
                        Text(
                          scripture.reference,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            color: AppTheme.brightGold,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          scripture.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            color: AppTheme.paleGold,
                            fontSize: 26,
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (scripture.copyright != null &&
                            scripture.copyright!.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            scripture.copyright!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
