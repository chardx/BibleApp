import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TextInputSheet extends StatefulWidget {
  final Function(String text) onSubmitted;

  const TextInputSheet({
    super.key,
    required this.onSubmitted,
  });

  @override
  State<TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<TextInputSheet> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmitted(text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.bgAbyss,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      hintText: 'Ask or type your prayer/question...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.surfaceCardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: const Color(0xFF0C101A),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: _handleSubmit,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
