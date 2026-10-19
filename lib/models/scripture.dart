class ScriptureQuote {
  final String reference;
  final String text;
  final String translation;
  final String? book;
  final int? chapter;
  final String? contextNote;
  final String? copyright;

  const ScriptureQuote({
    required this.reference,
    required this.text,
    this.translation = 'NIV',
    this.book,
    this.chapter,
    this.contextNote,
    this.copyright,
  });

  Map<String, dynamic> toMap() {
    return {
      'reference': reference,
      'text': text,
      'translation': translation,
      'book': book,
      'chapter': chapter,
      'contextNote': contextNote,
      'copyright': copyright,
    };
  }
}
