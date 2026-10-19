import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

/// AudioManager handles both live microphone streaming (16kHz PCM)
/// and real-time audio playback (24kHz PCM).
class AudioManager {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _recordSubscription;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSpeakerOn = true;

  // Live Gemini voice. Chunks are played as they arrive instead of waiting
  // for the whole turn to finish.
  Future<void> _audioOps = Future<void>.value();
  AudioSource? _liveSource;
  SoundHandle? _liveHandle;
  StreamSubscription<void>? _liveEndSub;
  bool _turnOpen = false;
  bool _generationEnded = false;
  bool _liveFinished = false;
  bool _suppressComplete = false;
  bool _engineStarted = false;

  // Callbacks
  void Function(Uint8List chunk)? onMicChunk;
  void Function(double amplitude)? onInputAmplitude;
  void Function(double amplitude)? onOutputAmplitude;
  void Function()? onPlaybackComplete;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isSpeakerOn => _isSpeakerOn;

  AudioManager() {
    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      if (_turnOpen) return;
      _isPlaying = (state == PlayerState.playing);
      if (state == PlayerState.completed) {
        onOutputAmplitude?.call(0.05);
        onPlaybackComplete?.call();
      }
    });
  }

  // -------------------------------------------------------------
  // MICROPHONE STREAMING (INPUT)
  // -------------------------------------------------------------
  /// Starts recording 16kHz 16-bit mono PCM chunks and streams them.
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[AudioManager] Microphone permission denied');
        return false;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;
      _recordSubscription?.cancel();
      _recordSubscription = stream.listen(
        (chunk) {
          if (!_isRecording) return;
          final amp = calculatePcmAmplitude(chunk);
          onInputAmplitude?.call(amp);
          onMicChunk?.call(chunk);
        },
        onError: (err) {
          debugPrint('[AudioManager] Recording stream error: $err');
          stopRecording();
        },
        cancelOnError: true,
      );

      debugPrint('[AudioManager] Microphone recording stream started (16kHz PCM)');
      return true;
    } catch (e) {
      debugPrint('[AudioManager] Failed to start microphone recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stops microphone recording stream.
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _recordSubscription?.cancel();
    _recordSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    onInputAmplitude?.call(0.05);
    debugPrint('[AudioManager] Microphone recording stopped');
  }

  // -------------------------------------------------------------
  // AUDIO PLAYBACK (OUTPUT)
  // -------------------------------------------------------------
  /// Plays an incoming 24kHz PCM chunk as soon as it arrives.
  /// Returns control immediately; playback is queued in order.
  void feedPcmChunk(Uint8List pcm24kBytes) {
    if (pcm24kBytes.length < 2) return;

    final evenLength = pcm24kBytes.length - (pcm24kBytes.length % 2);
    final chunk = Uint8List.fromList(pcm24kBytes.sublist(0, evenLength));
    _turnOpen = true;
    onOutputAmplitude?.call(calculatePcmAmplitude(chunk));
    _enqueue(() => _pushLivePcm(chunk));
  }

  /// Marks the model's audio generation as finished.
  /// Playback continues through audio already received.
  /// Returns true when a spoken turn is still draining.
  bool completeLiveTurn() {
    if (!_turnOpen) return false;
    _generationEnded = true;
    _enqueue(() async {
      final source = _liveSource;
      if (source == null) return;

      SoLoud.instance.setDataIsEnded(source);
      final handle = _liveHandle;
      final alive =
          handle != null && SoLoud.instance.getIsValidVoiceHandle(handle);
      if (!alive) {
        _finishLivePlayback();
      }
    });
    return true;
  }

  /// Plays arbitrary 24kHz PCM bytes directly (e.g. from TTS)
  Future<void> playPcmBytes(Uint8List pcm24kBytes) async {
    if (pcm24kBytes.isEmpty) return;

    final wavBytes = pcmToWav(
      pcm24kBytes,
      sampleRate: 24000,
      channels: 1,
      bitsPerSample: 16,
    );

    try {
      if (!_isSpeakerOn) {
        await _player.setVolume(0.0);
      } else {
        await _player.setVolume(1.0);
      }

      await _player.stop();
      await _player.play(BytesSource(wavBytes));
      _isPlaying = true;
      onOutputAmplitude?.call(0.7);
    } catch (e) {
      debugPrint('[AudioManager] Error playing PCM bytes: $e');
    }
  }

  /// Stops current playback immediately and wipes the live audio queue.
  Future<void> stopPlayback() {
    _suppressComplete = true;
    final done = Completer<void>();
    _enqueue(() async {
      try {
        try {
          await _player.stop();
        } catch (_) {}
        await _tearDownLive();
      } finally {
        _suppressComplete = false;
        if (!done.isCompleted) done.complete();
      }
    });
    debugPrint('[AudioManager] Playback stopped & buffer cleared (Interrupted)');
    return done.future;
  }

  void setSpeaker(bool enabled) {
    _isSpeakerOn = enabled;
    _player.setVolume(enabled ? 1.0 : 0.0);
    if (!_engineStarted) return;
    final handle = _liveHandle;
    if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
      SoLoud.instance.setVolume(handle, enabled ? 1 : 0);
    }
  }

  void _enqueue(Future<void> Function() action) {
    _audioOps = _audioOps.then((_) => action()).catchError((
      Object error,
      StackTrace stack,
    ) {
      debugPrint('[AudioManager] Live playback error: $error\n$stack');
      if (!_suppressComplete) {
        _finishLivePlayback();
      }
    });
  }

  Future<void> _ensureEngine() async {
    if (_engineStarted) return;
    await SoLoud.instance.init(
      sampleRate: 48000,
      bufferSize: 1024,
      channels: Channels.stereo,
    );
    _engineStarted = true;
  }

  Future<void> _pushLivePcm(Uint8List pcm) async {
    await _ensureEngine();
    final source = _liveSource ??= _openLiveSource();
    SoLoud.instance.addAudioDataStream(source, pcm);

    final handle = _liveHandle;
    final alive =
        handle != null && SoLoud.instance.getIsValidVoiceHandle(handle);
    if (alive) return;

    _liveHandle = SoLoud.instance.play(
      source,
      volume: _isSpeakerOn ? 1 : 0,
    );
    _isPlaying = true;
    debugPrint('[AudioManager] Live voice playing (24kHz PCM stream)');
  }

  AudioSource _openLiveSource() {
    _liveFinished = false;
    final source = SoLoud.instance.setBufferStream(
      maxBufferSizeDuration: const Duration(minutes: 2),
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0.08,
      sampleRate: 24000,
      channels: Channels.mono,
      format: BufferType.s16le,
    );
    _liveEndSub = source.allInstancesFinished.listen((_) {
      if (_suppressComplete || !identical(_liveSource, source)) return;
      if (!_generationEnded) {
        _liveHandle = null;
        _isPlaying = false;
        return;
      }
      _finishLivePlayback();
    });
    return source;
  }

  void _finishLivePlayback() {
    if (_liveFinished) return;
    _liveFinished = true;
    _isPlaying = false;
    _turnOpen = false;
    _generationEnded = false;
    final subscription = _liveEndSub;
    _liveEndSub = null;
    subscription?.cancel();
    final source = _liveSource;
    _liveSource = null;
    _liveHandle = null;
    if (source != null && _engineStarted) {
      unawaited(
        SoLoud.instance.disposeSource(source).catchError((Object _) {}),
      );
    }
    onOutputAmplitude?.call(0.05);
    if (!_suppressComplete) {
      onPlaybackComplete?.call();
    }
  }

  Future<void> _tearDownLive() async {
    _liveFinished = true;
    _turnOpen = false;
    _generationEnded = false;
    _isPlaying = false;
    final subscription = _liveEndSub;
    _liveEndSub = null;
    await subscription?.cancel();
    final handle = _liveHandle;
    final source = _liveSource;
    _liveHandle = null;
    _liveSource = null;
    if (_engineStarted) {
      if (handle != null && SoLoud.instance.getIsValidVoiceHandle(handle)) {
        await SoLoud.instance.stop(handle);
      }
      if (source != null) {
        try {
          await SoLoud.instance.disposeSource(source);
        } catch (e) {
          debugPrint('[AudioManager] dispose stream failed: $e');
        }
      }
    }
    onOutputAmplitude?.call(0.05);
    _liveFinished = false;
  }

  // -------------------------------------------------------------
  // AUDIO MATH & UTILITIES
  // -------------------------------------------------------------
  /// Calculates normalized Root-Mean-Square (RMS) amplitude from 16-bit PCM bytes.
  static double calculatePcmAmplitude(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty || pcmBytes.length < 2) return 0.05;

    final byteData = ByteData.sublistView(pcmBytes);
    final int sampleCount = pcmBytes.length ~/ 2;
    double sumSquares = 0.0;

    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += (sample * sample);
    }

    final double rms = math.sqrt(sumSquares / sampleCount);
    // Normalize 16-bit range (0 to 32767) to 0.0 - 1.0, with a floor of 0.08
    final double normalized = (rms / 32767.0) * 2.8; // Boost sensitivity
    return normalized.clamp(0.05, 1.0);
  }

  /// Converts raw Linear PCM bytes to a standard RIFF WAV format by adding a 44-byte header.
  static Uint8List pcmToWav(
    Uint8List pcmData, {
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final int blockAlign = channels * (bitsPerSample ~/ 8);
    final int dataSize = pcmData.length;
    final int chunkSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, chunkSize, Endian.little);
    // WAVE format
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    // 'fmt ' subchunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // audioFormat: 1 = Linear PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // 'data' subchunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());
    wavBytes.setRange(44, 44 + dataSize, pcmData);
    return wavBytes;
  }

  void dispose() {
    stopRecording();
    unawaited(stopPlayback());
    _player.dispose();
    _recorder.dispose();
    if (_engineStarted) {
      SoLoud.instance.deinit();
    }
  }
}
