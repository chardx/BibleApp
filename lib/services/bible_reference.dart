/// Converts spoken Bible references into API.Bible passage ids.
class BibleReference {
  static const Map<String, String> _bookIds = {
    'genesis': 'GEN',
    'gen': 'GEN',
    'exodus': 'EXO',
    'exo': 'EXO',
    'leviticus': 'LEV',
    'lev': 'LEV',
    'numbers': 'NUM',
    'num': 'NUM',
    'deuteronomy': 'DEU',
    'deut': 'DEU',
    'joshua': 'JOS',
    'judges': 'JDG',
    'ruth': 'RUT',
    '1 samuel': '1SA',
    '2 samuel': '2SA',
    '1 kings': '1KI',
    '2 kings': '2KI',
    '1 chronicles': '1CH',
    '2 chronicles': '2CH',
    'ezra': 'EZR',
    'nehemiah': 'NEH',
    'esther': 'EST',
    'job': 'JOB',
    'psalm': 'PSA',
    'psalms': 'PSA',
    'proverbs': 'PRO',
    'prov': 'PRO',
    'ecclesiastes': 'ECC',
    'song of solomon': 'SNG',
    'song of songs': 'SNG',
    'isaiah': 'ISA',
    'jeremiah': 'JER',
    'lamentations': 'LAM',
    'ezekiel': 'EZK',
    'daniel': 'DAN',
    'hosea': 'HOS',
    'joel': 'JOL',
    'amos': 'AMO',
    'obadiah': 'OBA',
    'jonah': 'JON',
    'micah': 'MIC',
    'nahum': 'NAM',
    'habakkuk': 'HAB',
    'zephaniah': 'ZEP',
    'haggai': 'HAG',
    'zechariah': 'ZEC',
    'malachi': 'MAL',
    'matthew': 'MAT',
    'matt': 'MAT',
    'mark': 'MRK',
    'luke': 'LUK',
    'john': 'JHN',
    'acts': 'ACT',
    'romans': 'ROM',
    'rom': 'ROM',
    '1 corinthians': '1CO',
    '2 corinthians': '2CO',
    'galatians': 'GAL',
    'ephesians': 'EPH',
    'philippians': 'PHP',
    'colossians': 'COL',
    '1 thessalonians': '1TH',
    '2 thessalonians': '2TH',
    '1 timothy': '1TI',
    '2 timothy': '2TI',
    'titus': 'TIT',
    'philemon': 'PHM',
    'hebrews': 'HEB',
    'james': 'JAS',
    '1 peter': '1PE',
    '2 peter': '2PE',
    '1 john': '1JN',
    '2 john': '2JN',
    '3 john': '3JN',
    'jude': 'JUD',
    'revelation': 'REV',
    'rev': 'REV',
  };

  /// `JHN.3.16` or `ROM.8.28-ROM.8.30`. Null when the reference cannot be read.
  static String? toPassageId(String reference) {
    final match = RegExp(
      r'^(.+?)\s+(\d+):(\d+)(?:-(?:(\d+):)?(\d+))?$',
    ).firstMatch(_normalize(reference));
    if (match == null) return null;

    final bookId = _bookIds[_bookKey(match.group(1)!)];
    if (bookId == null) return null;

    final chapter = match.group(2)!;
    final verse = match.group(3)!;
    final endChapter = match.group(4) ?? chapter;
    final endVerse = match.group(5);
    final start = '$bookId.$chapter.$verse';
    if (endVerse == null || (endChapter == chapter && endVerse == verse)) {
      return start;
    }
    return '$start-$bookId.$endChapter.$endVerse';
  }

  static bool samePassage(String a, String b) {
    final left = toPassageId(a);
    final right = toPassageId(b);
    if (left != null && right != null) return left == right;
    return _normalize(a) == _normalize(b);
  }

  static String _normalize(String reference) {
    return reference
        .trim()
        .replaceAll(RegExp(r'[.,;]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _bookKey(String book) {
    var key = book.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    key = key
        .replaceFirst(RegExp(r'^(first|1st|i)\s+'), '1 ')
        .replaceFirst(RegExp(r'^(second|2nd|ii)\s+'), '2 ')
        .replaceFirst(RegExp(r'^(third|3rd|iii)\s+'), '3 ');
    return key;
  }
}
