import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/scripture.dart';

/// Illustrates a passage with Gemini Nano Banana.
class VerseImageService {
  VerseImageService({http.Client? client}) : _client = client ?? http.Client();

  static const model = 'gemini-nano-banana-2.1';

  final http.Client _client;

  static String buildPrompt(ScriptureQuote scripture) {
    final verse = scripture.text.trim();
    return '''
Create a portrait scripture image. The words of the verse are the subject, not a scene without text.

Render this exact ${scripture.translation} text in the center of the image, large, centered, and highlighted so it is the first thing the eye reads. Spell every word exactly. Do not paraphrase, omit, or add words:

"$verse"

Place the reference "${scripture.reference}" in smaller type directly above or below the verse. Keep the lettering in a warm cream or gold serif, with a soft glow or a dark translucent panel behind it so every line stays readable.

Behind the text, paint a biblical background that belongs to this passage: the place, light, and mood these lines suggest. If they name people, water, a path, wilderness, or an act of care, let that appear softly behind the words. If they are a promise, prayer, or psalm, use lamplight, olive hills, temple courts, or dawn over still water. The background must stay quieter than the highlighted verse.

No logos, no modern objects, no extra captions, and no misspelled scripture.
''';
  }

  Future<Uint8List> generate({
    required String apiKey,
    required ScriptureQuote scripture,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('Add your Gemini API key in Settings to illustrate verses.');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/interactions',
    );
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey.trim(),
          },
          body: jsonEncode({
            'model': model,
            'input': buildPrompt(scripture),
            'response_format': {
              'type': 'image',
              'mime_type': 'image/jpeg',
              'aspect_ratio': '4:5',
              'image_size': '1K',
            },
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      debugPrint(
        '[VerseImage] Nano Banana failed [${response.statusCode}] ${response.body}',
      );
      throw StateError(_errorMessage(response.body));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw StateError('Nano Banana returned an unexpected response.');
    }

    final bytes = imageBytesFromResponse(body);
    if (bytes == null || bytes.isEmpty) {
      debugPrint('[VerseImage] No image field in response keys: ${body.keys}');
      throw StateError('Nano Banana did not return an image.');
    }
    return bytes;
  }

  static Uint8List? imageBytesFromResponse(Map<String, dynamic> body) {
    final direct = _bytesOf(body['output_image'] ?? body['outputImage']);
    if (direct != null) return direct;

    final collections = [
      body['steps'],
      body['outputs'],
      body['output'],
    ];
    for (final collection in collections) {
      final found = _search(collection);
      if (found != null) return found;
    }
    return _search(body['candidates']);
  }

  static Uint8List? _search(dynamic node) {
    final direct = _bytesOf(node);
    if (direct != null) return direct;
    if (node is List) {
      for (final item in node) {
        final found = _search(item);
        if (found != null) return found;
      }
    } else if (node is Map) {
      for (final value in node.values) {
        final found = _search(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  static Uint8List? _bytesOf(dynamic node) {
    if (node is! Map) return null;
    final inline = node['inlineData'];
    final type = (node['type'] ?? node['kind'])?.toString();
    final mime = (node['mime_type'] ??
            node['mimeType'] ??
            (inline is Map ? inline['mimeType'] : null) ??
            '')
        .toString();
    final data = node['data'] ?? (inline is Map ? inline['data'] : null);
    if (data is! String || data.isEmpty) return null;

    final looksLikeImage =
        type == 'image' || mime.startsWith('image/') || inline is Map;
    if (!looksLikeImage) return null;

    try {
      final payload = data.contains(',') ? data.split(',').last : data;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } catch (_) {}
    return 'Could not illustrate this verse.';
  }
}
