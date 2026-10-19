import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scripture.dart';
import '../theme/app_theme.dart';
import 'scripture_focus_view.dart';
import 'verse_image_dialog.dart';

class ScriptureCard extends StatefulWidget {
  final ScriptureQuote scripture;
  final VoidCallback? onChapterTap;
  final VoidCallback? onSpeakTap;
  final String geminiApiKey;

  const ScriptureCard({
    super.key,
    required this.scripture,
    this.onChapterTap,
    this.onSpeakTap,
    this.geminiApiKey = '',
  });

  @override
  State<ScriptureCard> createState() => _ScriptureCardState();
}

class _ScriptureCardState extends State<ScriptureCard> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final scripture = widget.scripture;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        gradient: AppTheme.scriptureCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Watermark Cross / Sacred Icon in background
            Positioned(
              right: -10,
              bottom: -15,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.menu_book,
                  size: 130,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Reference & Translation Tag + Action Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryGold.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_stories,
                                  size: 14,
                                  color: AppTheme.brightGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  scripture.reference.toUpperCase(),
                                  style: GoogleFonts.cinzel(
                                    color: AppTheme.brightGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            scripture.translation,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Actions: Listen, Bookmark, Copy
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_full,
                              size: 18,
                              color: AppTheme.brightGold,
                            ),
                            onPressed: () => ScriptureFocusView.open(
                              context,
                              scripture,
                              onSpeak: widget.onSpeakTap,
                              geminiApiKey: widget.geminiApiKey,
                            ),
                            tooltip: 'Read full passage',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          if (widget.onSpeakTap != null) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up_outlined,
                                size: 20,
                                color: AppTheme.brightGold,
                              ),
                              onPressed: widget.onSpeakTap,
                              tooltip: 'Listen with Gemini Voice',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                          ],
                          IconButton(
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: _isBookmarked
                                  ? AppTheme.brightGold
                                  : AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBookmarked = !_isBookmarked;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.surfaceElevated,
                                  content: Text(
                                    _isBookmarked
                                        ? 'Saved "${scripture.reference}" to Bookmarks'
                                        : 'Removed from Bookmarks',
                                    style: const TextStyle(color: AppTheme.textPrimary),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Save verse',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      '"${scripture.text}" - ${scripture.reference} (${scripture.translation})',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppTheme.surfaceElevated,
                                  content: Text(
                                    'Copied scripture to clipboard',
                                    style: TextStyle(color: AppTheme.brightGold),
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy verse',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // The Scripture Text (Ornate Serif typography)
                  Text(
                    '“${scripture.text}”',
                    style: GoogleFonts.cormorantGaramond(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => VerseImageDialog.show(
                        context,
                        scripture: scripture,
                        apiKey: widget.geminiApiKey,
                      ),
                      icon: const Icon(Icons.palette_outlined, size: 18),
                      label: const Text('Illustrate verse'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.brightGold,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),

                  // Context note if present
                  if (scripture.contextNote != null &&
                      scripture.contextNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scripture.contextNote!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (scripture.copyright != null &&
                      scripture.copyright!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      scripture.copyright!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
