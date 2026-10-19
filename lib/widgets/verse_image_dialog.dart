import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scripture.dart';
import '../services/verse_image_service.dart';
import '../theme/app_theme.dart';

class VerseImageDialog extends StatefulWidget {
  final ScriptureQuote scripture;
  final String apiKey;

  const VerseImageDialog({
    super.key,
    required this.scripture,
    required this.apiKey,
  });

  static Future<void> show(
    BuildContext context, {
    required ScriptureQuote scripture,
    required String apiKey,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close illustration',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      pageBuilder: (context, _, _) {
        return VerseImageDialog(scripture: scripture, apiKey: apiKey);
      },
    );
  }

  @override
  State<VerseImageDialog> createState() => _VerseImageDialogState();
}

class _VerseImageDialogState extends State<VerseImageDialog> {
  final VerseImageService _service = VerseImageService();
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await _service.generate(
        apiKey: widget.apiKey,
        scripture: widget.scripture,
      );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width > 760 ? 520 : size.width - 32,
            constraints: BoxConstraints(maxHeight: size.height * 0.9),
            decoration: BoxDecoration(
              color: AppTheme.bgAbyss,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.scripture.reference,
                          style: GoogleFonts.cinzel(
                            color: AppTheme.brightGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Flexible(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: AppTheme.brightGold),
            const SizedBox(height: 18),
            Text(
              'Painting this passage…',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nano Banana is illustrating the NIV lines and a setting that belongs to them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _generate,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_bytes!, fit: BoxFit.contain),
      ),
    );
  }
}
