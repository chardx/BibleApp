import 'dart:convert';
import 'dart:typed_data';

import 'package:bible_app/models/scripture.dart';
import 'package:bible_app/services/verse_image_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const passage = ScriptureQuote(
    reference: 'Psalm 119:105',
    text: 'Your word is a lamp for my feet, a light on my path.',
    translation: 'NIV',
  );

  test('illustration prompt includes the API verse and its reference', () {
    final prompt = VerseImageService.buildPrompt(passage);

    expect(prompt, contains('Psalm 119:105'));
    expect(
      prompt,
      contains('Your word is a lamp for my feet, a light on my path.'),
    );
    expect(prompt, contains('center'));
    expect(prompt, contains('highlighted'));
    expect(prompt, isNot(contains('Do not print the verse')));
  });

  test('reads Nano Banana image bytes from the interactions response', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final parsed = VerseImageService.imageBytesFromResponse({
      'output_image': {
        'mime_type': 'image/jpeg',
        'data': base64Encode(bytes),
      },
    });

    expect(parsed, bytes);
  });
}
