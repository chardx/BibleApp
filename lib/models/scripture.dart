class ScriptureQuote {
  final String reference;
  final String text;
  final String translation;
  final String? book;
  final int? chapter;
  final String? contextNote;

  const ScriptureQuote({
    required this.reference,
    required this.text,
    this.translation = 'ESV',
    this.book,
    this.chapter,
    this.contextNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'reference': reference,
      'text': text,
      'translation': translation,
      'book': book,
      'chapter': chapter,
      'contextNote': contextNote,
    };
  }
}
