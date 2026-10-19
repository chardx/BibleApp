import 'package:bible_app/services/bible_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleReference', () {
    test('converts a single verse to an API.Bible passage id', () {
      expect(BibleReference.toPassageId('John 3:16'), 'JHN.3.16');
      expect(BibleReference.toPassageId('Psalm 23:1'), 'PSA.23.1');
      expect(BibleReference.toPassageId('Song of Solomon 2:1'), 'SNG.2.1');
    });

    test('converts a verse range, including numbered books', () {
      expect(BibleReference.toPassageId('Romans 8:28-30'), 'ROM.8.28-ROM.8.30');
      expect(
        BibleReference.toPassageId('1 Corinthians 13:4-7'),
        '1CO.13.4-1CO.13.7',
      );
      expect(BibleReference.toPassageId('John 3:16-4:2'), 'JHN.3.16-JHN.4.2');
    });

    test('treats equivalent references as the same passage', () {
      expect(
        BibleReference.samePassage('john 3:16', 'John 3:16'),
        isTrue,
      );
      expect(BibleReference.toPassageId('not a verse'), isNull);
    });
  });
}
