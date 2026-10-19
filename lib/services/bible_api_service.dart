import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/scripture.dart';
import 'bible_reference.dart';

class BiblePassageResult {
  const BiblePassageResult.found(this.quote) : error = null;
  const BiblePassageResult.failure(this.error) : quote = null;

  final ScriptureQuote? quote;
  final String? error;
}

/// Licensed NIV text from [API.Bible](https://api.bible/).
class BibleApiService {
  BibleApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _root = 'https://rest.api.bible/v1';

  final http.Client _client;
  String _apiKey = '';
  String? _nivBibleId;

  static const List<Map<String, dynamic>> liveTools = [
    {
      'functionDeclarations': [
        {
          'name': 'lookup_bible_passage',
          'description':
              'Look up the exact New International Version text of a Bible passage. Call this before quoting, reading, or citing any scripture so the spoken words and the verse card match the licensed NIV.',
          'parameters': {
            'type': 'object',
            'properties': {
              'reference': {
                'type': 'string',
                'description':
                    'Passage reference such as "John 3:16" or "Romans 8:28-30".',
              },
            },
            'required': ['reference'],
          },
        },
      ],
    },
  ];

  void setApiKey(String key) {
    final trimmed = key.trim();
    if (trimmed != _apiKey) _nivBibleId = null;
    _apiKey = trimmed;
  }

  Future<BiblePassageResult> lookup(String reference) async {
    final cleaned = reference.trim();
    if (_apiKey.isEmpty) {
      return const BiblePassageResult.failure(
        'API.Bible key is missing. Add it in Settings.',
      );
    }
    if (cleaned.isEmpty) {
      return const BiblePassageResult.failure('No Bible reference was given.');
    }

    try {
      _nivBibleId ??= await _findNivBibleId();
      final bibleId = _nivBibleId;
      if (bibleId == null) {
        return const BiblePassageResult.failure(
          'This API.Bible key does not include the NIV. Add the New International Version in the API.Bible dashboard.',
        );
      }

      final passageId = BibleReference.toPassageId(cleaned);
      if (passageId == null) {
        return BiblePassageResult.failure(
          'Could not read the reference "$cleaned".',
        );
      }

      final uri = Uri.parse('$_root/bibles/$bibleId/passages/$passageId').replace(
        queryParameters: const {
          'content-type': 'text',
          'include-notes': 'false',
          'include-titles': 'false',
          'include-chapter-numbers': 'false',
          'include-verse-numbers': 'true',
          'include-verse-spans': 'false',
        },
      );
      final response = await _client
          .get(uri, headers: {'api-key': _apiKey})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        debugPrint(
          '[BibleApi] Passage $passageId failed [${response.statusCode}]',
        );
        return BiblePassageResult.failure(
          'NIV passage "$cleaned" was not found.',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final text = _plainText(data['content']?.toString() ?? '');
      if (text.isEmpty) {
        return BiblePassageResult.failure('NIV returned no text for "$cleaned".');
      }

      _reportUsage(body['meta']);
      return BiblePassageResult.found(
        ScriptureQuote(
          reference: (data['reference'] as String?)?.trim().isNotEmpty == true
              ? data['reference'] as String
              : cleaned,
          text: text,
          translation: 'NIV',
          copyright: _plainText(data['copyright']?.toString() ?? ''),
        ),
      );
    } catch (e) {
      debugPrint('[BibleApi] Lookup failed: $e');
      return BiblePassageResult.failure('Could not reach API.Bible.');
    }
  }

  Future<String?> _findNivBibleId() async {
    final response = await _client
        .get(Uri.parse('$_root/bibles'), headers: {'api-key': _apiKey})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      debugPrint('[BibleApi] Bible list failed [${response.statusCode}]');
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final bibles = body['data'] as List? ?? const [];
    String? fallback;
    for (final bible in bibles) {
      if (bible is! Map) continue;
      final abbreviation = (bible['abbreviation'] as String? ?? '')
          .toUpperCase();
      final name = (bible['name'] as String? ?? '').toLowerCase();
      final id = bible['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final isNiv =
          abbreviation == 'NIV' || name.contains('new international version');
      if (!isNiv || abbreviation.contains('UK') || name.contains('reader')) {
        continue;
      }
      if (abbreviation == 'NIV') return id;
      fallback ??= id;
    }
    return fallback;
  }

  void _reportUsage(dynamic meta) {
    if (meta is! Map) return;
    final fums = meta['fums'] as String?;
    if (fums == null || fums.isEmpty) return;
    _client
        .get(Uri.parse(fums), headers: {'api-key': _apiKey})
        .timeout(const Duration(seconds: 5))
        .catchError((Object _) => http.Response('', 500));
  }

  static String _plainText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[^\S\n]+'), ' ')
        .trim();
  }
}
