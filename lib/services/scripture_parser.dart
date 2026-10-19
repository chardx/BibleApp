import '../models/scripture.dart';

/// Helper to parse and extract scripture references from Gemini's live speech and text responses.
class ScriptureParser {
  static final RegExp _bibleRefRegex = RegExp(
    r'\b((?:1|2|3|I|II|III)\s+)?(Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|Samuel|Kings|Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song of Solomon|Song of Songs|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|Corinthians|Galatians|Ephesians|Philippians|Colossians|Thessalonians|Timothy|Titus|Philemon|Hebrews|James|Peter|Jude|Revelation)\s+(\d+):(\d+)(?:-(\d+))?\b',
    caseSensitive: false,
  );

  /// References mentioned in [content], in order, without invented verse text.
  static List<String> extractReferences(String content) {
    final results = <String>[];
    final seen = <String>{};
    for (final match in _bibleRefRegex.allMatches(content)) {
      final ref = match.group(0)?.trim() ?? '';
      final key = ref.toLowerCase();
      if (ref.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      results.add(ref);
    }
    return results;
  }

  /// Scans text for scripture references and attempts to extract quote excerpts.
  static List<ScriptureQuote> parseScriptures(String content, {String defaultTranslation = 'ESV'}) {
    final List<ScriptureQuote> results = [];
    final matches = _bibleRefRegex.allMatches(content);

    final Set<String> seenRefs = {};

    for (final match in matches) {
      final ref = match.group(0)?.trim() ?? '';
      if (ref.isEmpty || seenRefs.contains(ref.toLowerCase())) continue;
      seenRefs.add(ref.toLowerCase());

      // Attempt to find quoted text nearby (e.g. within quotes “...” or "...")
      String verseText = '';
      final quoteRegex = RegExp(r'''[“"']([^”"']{15,350})[”"']''');
      final quoteMatch = quoteRegex.firstMatch(content);
      if (quoteMatch != null) {
        verseText = quoteMatch.group(1)?.trim() ?? '';
      }

      if (verseText.isEmpty) {
        verseText = 'Cited in discussion: $ref';
      }

      results.add(
        ScriptureQuote(
          reference: ref,
          text: verseText,
          translation: defaultTranslation,
        ),
      );
    }

    return results;
  }
}
