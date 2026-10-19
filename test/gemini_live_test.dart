import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_app/services/audio_manager.dart';
import 'package:bible_app/services/gemini_live_client.dart';
import 'package:bible_app/services/scripture_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'gemini_api_key': 'test_api_key_123',
      'gemini_voice': 'Kore',
      'gemini_model': 'models/gemini-3.8-live',
      'bible_translation': 'ESV',
      'voice_persona': 'Biblical Scholar & Exegete',
    });
  });

  group('AudioManager WAV & PCM Tests', () {
    test('pcmToWav prepends valid 44-byte RIFF header for 24kHz mono PCM', () {
      final pcmSamples = Uint8List(4800); // 100ms of 24kHz 16-bit mono audio
      final wav = AudioManager.pcmToWav(
        pcmSamples,
        sampleRate: 24000,
        channels: 1,
        bitsPerSample: 16,
      );

      expect(wav.length, equals(44 + 4800));

      // RIFF header
      expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
      // WAVE header
      expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));
      // fmt subchunk
      expect(String.fromCharCodes(wav.sublist(12, 16)), equals('fmt '));
      // data subchunk
      expect(String.fromCharCodes(wav.sublist(36, 40)), equals('data'));

      // Check Sample Rate in byte offset 24..27
      final byteData = ByteData.sublistView(wav);
      expect(byteData.getUint32(24, Endian.little), equals(24000));
      // Check Byte Rate (24000 * 1 * 2 = 48000)
      expect(byteData.getUint32(28, Endian.little), equals(48000));
      // Check Bits per sample
      expect(byteData.getUint16(34, Endian.little), equals(16));
    });

    test('calculatePcmAmplitude handles silence and loud signals properly', () {
      final silence = Uint8List(200); // All zeros
      final silenceAmp = AudioManager.calculatePcmAmplitude(silence);
      expect(silenceAmp, inInclusiveRange(0.05, 0.06));

      // Loud signal (high amplitude int16 values)
      final loudBytes = ByteData(200);
      for (int i = 0; i < 100; i++) {
        loudBytes.setInt16(i * 2, 25000, Endian.little);
      }
      final loudAmp = AudioManager.calculatePcmAmplitude(
        loudBytes.buffer.asUint8List(),
      );
      expect(loudAmp, greaterThan(0.5));
    });
  });

  group('GeminiLiveClient audio frames', () {
    test('sends microphone PCM as a realtime audio blob', () {
      final pcm = Uint8List.fromList([0x00, 0x00, 0xFF, 0x7F]);
      final payload = GeminiLiveClient.buildRealtimeAudioPayload(pcm);
      final realtime = payload['realtimeInput'] as Map<String, dynamic>;

      expect(realtime.containsKey('mediaChunks'), isFalse);
      final audio = realtime['audio'] as Map<String, dynamic>;
      expect(audio['mimeType'], equals('audio/pcm;rate=16000'));
      expect(audio['data'], equals(base64Encode(pcm)));
    });
  });

  group('ScriptureParser Tests', () {
    test('detects and parses scripture references from assistant output', () {
      const text =
          'Paul reminds us in Romans 8:28 that “all things work together for good to those who love God.” '
          'We also find peace in Philippians 4:6-7 and Psalm 23:1.';

      final scriptures = ScriptureParser.parseScriptures(
        text,
        defaultTranslation: 'ESV',
      );

      expect(scriptures.length, equals(3));
      expect(scriptures[0].reference, equals('Romans 8:28'));
      expect(scriptures[0].text, contains('all things work together for good'));
      expect(scriptures[1].reference, equals('Philippians 4:6-7'));
      expect(scriptures[2].reference, equals('Psalm 23:1'));
    });
  });
}
