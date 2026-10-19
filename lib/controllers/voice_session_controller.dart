import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/scripture.dart';
import '../services/audio_manager.dart';
import '../services/gemini_live_client.dart';
import '../services/gemini_tts_service.dart';
import '../services/scripture_parser.dart';

enum VoiceSessionState {
  idle,
  connecting,
  listening,
  thinking,
  speaking,
  paused,
  error,
}

class VoiceSessionController extends ChangeNotifier {
  VoiceSessionState _state = VoiceSessionState.idle;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  double _audioAmplitude = 0.05;

  String _apiKey = '';
  String _selectedVoice = 'Kore';
  String _selectedModel = 'models/gemini-2.0-flash-live-001';
  String _selectedTranslation = 'ESV';
  String _selectedPersona = 'Biblical Scholar & Exegete';
  String? _statusMessage = 'Tap microphone to speak';

  final List<ChatMessage> _messages = [];
  Timer? _amplitudeFallbackTimer;

  // Core Services
  late final AudioManager _audioManager;
  GeminiLiveClient? _liveClient;
  GeminiTtsService? _ttsService;

  // Getters
  VoiceSessionState get state => _state;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  double get audioAmplitude => _audioAmplitude;
  String get apiKey => _apiKey;
  String get selectedVoice => _selectedVoice;
  String get selectedModel => _selectedModel;
  String get selectedTranslation => _selectedTranslation;
  String get selectedPersona => _selectedPersona;
  String? get statusMessage => _statusMessage;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  bool get isActive =>
      _state == VoiceSessionState.listening ||
      _state == VoiceSessionState.thinking ||
      _state == VoiceSessionState.speaking ||
      _state == VoiceSessionState.connecting;

  VoiceSessionController() {
    _audioManager = AudioManager();
    _setupAudioListeners();
    _loadPreferences();
    _initSampleConversation();
    _startFallbackAmplitudeTimer();
  }

  void _setupAudioListeners() {
    // When microphone records chunks, stream them to Gemini Live
    _audioManager.onMicChunk = (chunk) {
      if (_state == VoiceSessionState.listening && !_isMuted) {
        _liveClient?.sendRealtimeAudio(chunk);
      }
    };

    // Real-time amplitude from mic
    _audioManager.onInputAmplitude = (amp) {
      if (_state == VoiceSessionState.listening && !_isMuted) {
        _audioAmplitude = amp;
        notifyListeners();
      }
    };

    // Real-time amplitude from Gemini PCM speaker playback
    _audioManager.onOutputAmplitude = (amp) {
      if (_state == VoiceSessionState.speaking) {
        _audioAmplitude = amp;
        notifyListeners();
      }
    };

    // Playback finished
    _audioManager.onPlaybackComplete = () {
      if (_state == VoiceSessionState.speaking) {
        _state = VoiceSessionState.listening;
        _statusMessage = 'Listening • Speak anytime to reply';
        _audioAmplitude = 0.05;
        _audioManager.startRecording();
        notifyListeners();
      }
    };
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key') ?? '';
      _selectedVoice = prefs.getString('gemini_voice') ?? 'Kore';
      _selectedModel =
          prefs.getString('gemini_model') ?? 'models/gemini-2.0-flash-live-001';
      _selectedTranslation = prefs.getString('bible_translation') ?? 'ESV';
      _selectedPersona =
          prefs.getString('voice_persona') ?? 'Biblical Scholar & Exegete';

      if (_apiKey.isNotEmpty) {
        _ttsService = GeminiTtsService(apiKey: _apiKey);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceSessionController] Error loading preferences: $e');
    }
  }

  void _initSampleConversation() {
    _messages.add(
      ChatMessage(
        id: 'msg_welcome',
        role: MessageRole.assistant,
        content:
            "Grace and peace to you. I am your biblical companion powered by Gemini Live. Speak to me anytime to explore scripture, seek devotional guidance, or study deep theological passages together.",
        scriptures: [
          const ScriptureQuote(
            reference: 'Psalm 119:105',
            text: 'Your word is a lamp to my feet and a light to my path.',
            translation: 'ESV',
            contextNote: 'The enduring light of God’s guidance',
          ),
        ],
        isVoice: true,
      ),
    );
  }

  void _startFallbackAmplitudeTimer() {
    _amplitudeFallbackTimer?.cancel();
    _amplitudeFallbackTimer = Timer.periodic(const Duration(milliseconds: 70), (
      _,
    ) {
      if (_state == VoiceSessionState.thinking) {
        _audioAmplitude =
            0.18 +
            (0.12 * math.sin(DateTime.now().millisecondsSinceEpoch / 180));
        notifyListeners();
      } else if (_state == VoiceSessionState.idle) {
        _audioAmplitude =
            0.06 +
            (0.03 * math.sin(DateTime.now().millisecondsSinceEpoch / 450));
        notifyListeners();
      }
    });
  }

  // -------------------------------------------------------------
  // CONFIGURATION & PERSISTENCE
  // -------------------------------------------------------------
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    _ttsService = GeminiTtsService(apiKey: _apiKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKey);
    _statusMessage = 'API Key saved';
    notifyListeners();
  }

  Future<void> setVoice(String voice) async {
    _selectedVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_voice', voice);
    if (isActive) {
      _statusMessage = 'Voice changed to $voice. Reconnecting...';
      startSession();
    }
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_model', model);
    if (isActive) {
      _statusMessage = 'Model changed. Reconnecting...';
      startSession();
    }
    notifyListeners();
  }

  Future<void> setTranslation(String translation) async {
    _selectedTranslation = translation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_translation', translation);
    notifyListeners();
  }

  Future<void> setPersona(String persona) async {
    _selectedPersona = persona;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_persona', persona);
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initSampleConversation();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // LIVE GEMINI BI-DIRECTIONAL SESSION
  // -------------------------------------------------------------
  void toggleSession() {
    if (isActive) {
      endSession();
    } else {
      startSession();
    }
  }

  Future<void> startSession() async {
    if (_apiKey.trim().isEmpty) {
      _state = VoiceSessionState.error;
      _statusMessage = 'Please enter your Gemini API Key in Settings';
      notifyListeners();
      return;
    }

    _audioManager.stopPlayback();
    _audioManager.stopRecording();

    _state = VoiceSessionState.connecting;
    _statusMessage = 'Connecting to Gemini Live...';
    notifyListeners();

    // Null callbacks BEFORE disconnect so stale onClose won't corrupt state
    if (_liveClient != null) {
      _liveClient!.onOpen = null;
      _liveClient!.onClose = null;
      _liveClient!.onError = null;
      _liveClient!.onSetupComplete = null;
      _liveClient!.onAudioChunk = null;
      _liveClient!.onTextDelta = null;
      _liveClient!.onInputTranscript = null;
      _liveClient!.onOutputTranscript = null;
      _liveClient!.onTurnComplete = null;
      _liveClient!.onInterrupted = null;
      _liveClient!.onToolCall = null;
      _liveClient!.disconnect();
      _liveClient = null;
    }
    _liveClient = GeminiLiveClient(apiKey: _apiKey);

    // Build specialized Biblical system instruction
    final systemInstruction = _buildSystemInstruction();

    _liveClient!.onOpen = () {
      _statusMessage = 'WebSocket connected • Handshaking...';
      notifyListeners();
    };

    _liveClient!.onSetupComplete = () async {
      _state = VoiceSessionState.listening;
      _statusMessage = 'Listening \u2022 Speak your thought or question';
      notifyListeners();

      // Automatically activate microphone streaming
      final micStarted = await _audioManager.startRecording();
      if (!micStarted) {
        _state = VoiceSessionState.error;
        _statusMessage = 'Microphone permission denied. Check app settings.';
        notifyListeners();
      }
    };

    _liveClient!.onAudioChunk = (pcm24kBytes) {
      // Feed PCM to buffer — state stays thinking until turnComplete triggers playback
      if (_state == VoiceSessionState.listening ||
          _state == VoiceSessionState.thinking ||
          _state == VoiceSessionState.connecting) {
        _state = VoiceSessionState.thinking;
      }
      _audioManager.feedPcmChunk(pcm24kBytes);
      notifyListeners();
    };

    _liveClient!.onTextDelta = (delta) {
      _appendStreamingAssistantDelta(delta);
    };

    _liveClient!.onInputTranscript = (userSpeech) {
      _appendUserTranscript(userSpeech);
      // Once user speech is transcribed, we're waiting for Gemini's response
      if (_state == VoiceSessionState.listening) {
        _state = VoiceSessionState.thinking;
        _statusMessage = 'Thinking...';
        notifyListeners();
      }
    };

    _liveClient!.onOutputTranscript = (modelSpeech) {
      _appendStreamingAssistantDelta(modelSpeech);
    };

    _liveClient!.onTurnComplete = () async {
      debugPrint('[VoiceSessionController] Turn complete — playing audio turn');
      _finalizeCurrentAssistantTurn();
      _state = VoiceSessionState.speaking;
      _statusMessage = 'Speaking...';
      notifyListeners();
      await _audioManager.playAccumulatedTurn();
    };

    _liveClient!.onInterrupted = () async {
      debugPrint('[VoiceSessionController] Gemini Live Interrupted by User');
      await _audioManager.stopPlayback();
      _state = VoiceSessionState.listening;
      _statusMessage = 'Interrupted \u2022 Listening...';
      notifyListeners();
      await _audioManager.startRecording();
    };

    _liveClient!.onError = (err) {
      debugPrint('[VoiceSessionController] Gemini Live Error: $err');
      _state = VoiceSessionState.error;
      _statusMessage = 'Connection Error: $err';
      _audioManager.stopPlayback();
      _audioManager.stopRecording();
      notifyListeners();
    };

    _liveClient!.onClose = (reason) {
      if (_state != VoiceSessionState.idle) {
        _state = VoiceSessionState.idle;
        _statusMessage = 'Session disconnected: $reason';
        _audioManager.stopPlayback();
        _audioManager.stopRecording();
        notifyListeners();
      }
    };

    final ok = await _liveClient!.connect(
      model: _selectedModel,
      voiceName: _selectedVoice,
      systemInstruction: systemInstruction,
    );

    if (!ok) {
      _state = VoiceSessionState.error;
      _statusMessage = 'Failed to establish Gemini Live WebSocket connection';
      notifyListeners();
    }
  }

  void endSession() {
    _state = VoiceSessionState.idle;
    _statusMessage = 'Session ended • Tap mic to converse';
    _audioAmplitude = 0.05;
    _liveClient?.disconnect();
    _liveClient = null;
    _audioManager.stopRecording();
    _audioManager.stopPlayback();
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _statusMessage = 'Microphone muted';
      _audioManager.stopRecording();
    } else if (_state == VoiceSessionState.listening) {
      _statusMessage = 'Listening • Speak now';
      _audioManager.startRecording();
    }
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _audioManager.setSpeaker(_isSpeakerOn);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // TEXT PROMPT & SCRIPTURE TTS
  // -------------------------------------------------------------
  Future<void> submitPrompt(String text) async {
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      isVoice: true,
    );
    _messages.add(userMsg);

    _state = VoiceSessionState.thinking;
    _statusMessage = 'Consulting Scripture & formulating voice...';
    notifyListeners();

    // If live client is active, send directly through live WebSocket
    if (_liveClient != null && _liveClient!.isConnected) {
      _liveClient!.sendText(text);
      return;
    }

    // If not connected, start the live session or use Gemini TTS
    if (_apiKey.isEmpty) {
      _state = VoiceSessionState.error;
      _statusMessage = 'Gemini API Key required to generate live voice';
      notifyListeners();
      return;
    }

    // Auto-connect live session and send
    await startSession();
    // Wait briefly for handshake then send
    Timer(const Duration(milliseconds: 1000), () {
      if (_liveClient != null && _liveClient!.isConnected) {
        _liveClient!.sendText(text);
      }
    });
  }

  /// Synthesizes and speaks a specific Scripture verse on-demand using Gemini TTS
  Future<void> speakScripture(ScriptureQuote scripture) async {
    if (_apiKey.isEmpty) {
      _statusMessage = 'Gemini API Key required for voice reading';
      notifyListeners();
      return;
    }

    _state = VoiceSessionState.thinking;
    _statusMessage = 'Preparing vocal recitation of ${scripture.reference}...';
    notifyListeners();

    _ttsService ??= GeminiTtsService(apiKey: _apiKey);
    final textToRead =
        '${scripture.reference}. From the ${scripture.translation} translation: "${scripture.text}"';

    final pcmBytes = await _ttsService!.synthesizeSpeech(
      text: textToRead,
      voiceName: _selectedVoice,
      model: 'gemini-2.0-flash-live-001',
    );

    if (pcmBytes != null && pcmBytes.isNotEmpty) {
      _state = VoiceSessionState.speaking;
      _statusMessage = 'Reading ${scripture.reference}...';
      notifyListeners();
      await _audioManager.playPcmBytes(pcmBytes);
    } else {
      _state = VoiceSessionState.idle;
      _statusMessage = 'Unable to synthesize audio. Check API key.';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // TRANSCRIPT & STREAMING HELPERS
  // -------------------------------------------------------------
  void _appendStreamingAssistantDelta(String delta) {
    if (delta.isEmpty) return;

    if (_messages.isNotEmpty &&
        _messages.last.isAssistant &&
        _messages.last.isStreaming) {
      final updatedContent = _messages.last.content + delta;
      final scriptures = ScriptureParser.parseScriptures(
        updatedContent,
        defaultTranslation: _selectedTranslation,
      );
      _messages[_messages.length - 1] = _messages.last.copyWith(
        content: updatedContent,
        scriptures: scriptures,
      );
    } else {
      final assistantMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        content: delta,
        isVoice: true,
        isStreaming: true,
      );
      _messages.add(assistantMsg);
    }
    notifyListeners();
  }

  void _appendUserTranscript(String userText) {
    if (userText.trim().isEmpty) return;

    // Check if last user message can be updated or add new
    if (_messages.isNotEmpty && _messages.last.isUser) {
      _messages[_messages.length - 1] = _messages.last.copyWith(
        content: '${_messages.last.content} $userText'.trim(),
      );
    } else {
      _messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: userText,
          isVoice: true,
        ),
      );
    }
    notifyListeners();
  }

  void _finalizeCurrentAssistantTurn() {
    if (_messages.isNotEmpty && _messages.last.isAssistant) {
      final finalContent = _messages.last.content;
      final parsedScriptures = ScriptureParser.parseScriptures(
        finalContent,
        defaultTranslation: _selectedTranslation,
      );
      _messages[_messages.length - 1] = _messages.last.copyWith(
        scriptures: parsedScriptures,
        isStreaming: false,
      );
    }
    notifyListeners();
  }

  String _buildSystemInstruction() {
    return '''
You are "Scripture Live", an empathetic, profound, and reverent biblical AI companion powered by Gemini Live audio.
You are speaking directly to the user through real-time audio voice.

Current Persona: $_selectedPersona
Preferred Bible Translation: $_selectedTranslation

Guidelines:
1. Speak in a warm, contemplative, and engaging tone suitable for spoken conversation.
2. Quote scripture verbatim using the $_selectedTranslation translation whenever citing God's Word. Always state the Book, Chapter, and Verse reference clearly (e.g. "In Romans 8:28, the apostle Paul writes...").
3. Keep spoken replies concise, impactful, and conversational (usually 2 to 4 sentences unless asked for an in-depth exposition).
4. Address user questions about grief, joy, anxiety, doubt, theology, prayer, and daily Christian living with Christ-centered encouragement, historical depth, and hope.
''';
  }

  @override
  void dispose() {
    _amplitudeFallbackTimer?.cancel();
    _audioManager.dispose();
    _liveClient?.disconnect();
    super.dispose();
  }
}
