import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../models/scripture.dart';
import '../theme/app_theme.dart';
import 'scripture_card.dart';

class TranscriptView extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isThinking;
  final void Function(ScriptureQuote scripture)? onScriptureSpeak;

  const TranscriptView({
    super.key,
    required this.messages,
    this.isThinking = false,
    this.onScriptureSpeak,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        widget.isThinking != oldWidget.isThinking) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: widget.messages.length + (widget.isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.messages.length) {
          return _buildThinkingBubble();
        }

        final message = widget.messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'YOU',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.mic,
                  size: 13,
                  color: AppTheme.brightGold,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppTheme.brightGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // AI Agent Response
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Agent Badge
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldShimmerGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Color(0xFF0C101A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GEMINI LIVE SCRIPTURE AI',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.brightGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.celestialCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Live 3.8',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.celestialCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Message text bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppTheme.surfaceCardBorder,
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            // Embedded Scripture Cards if any cited
            if (message.scriptures.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...message.scriptures.map(
                (scripture) => ScriptureCard(
                  scripture: scripture,
                  onSpeakTap: widget.onScriptureSpeak != null
                      ? () => widget.onScriptureSpeak!(scripture)
                      : null,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.celestialCyan.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.celestialCyan),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Consulting Scripture & formulating voice...',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
