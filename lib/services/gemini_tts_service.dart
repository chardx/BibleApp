import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Direct Gemini Text-to-Speech (TTS) Service using Gemini 2.0 Flash Audio Generation.
/// Allows speaking any custom text or Scripture verse with prebuilt voices.
class GeminiTtsService {
  final String apiKey;

  GeminiTtsService({required this.apiKey});

  /// Synthesizes speech for the provided text using Gemini's native audio modality.
  /// Returns raw 24,000Hz 16-bit PCM bytes.
  Future<Uint8List?> synthesizeSpeech({
    required String text,
    String voiceName = 'Kore',
    String model = 'gemini-3.8-live',
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('[GeminiTtsService] Cannot synthesize: API key is empty');
      return null;
    }

    final sanitizedModel = model.replaceFirst('models/', '');
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$sanitizedModel:generateContent?key=$apiKey',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Please read the following text aloud with natural inflection, warm presence, and clear pronunciation. Output audio only:\n\n$text',
            },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': voiceName},
          },
        },
      },
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[GeminiTtsService] TTS Request failed [${response.statusCode}]: ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      for (final part in parts) {
        if (part is Map && part['inlineData'] != null) {
          final base64Audio = part['inlineData']['data'] as String?;
          if (base64Audio != null && base64Audio.isNotEmpty) {
            return base64Decode(base64Audio);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('[GeminiTtsService] Exception during speech synthesis: $e');
      return null;
    }
  }
}
