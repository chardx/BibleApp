import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/scripture.dart';
import '../services/audio_manager.dart';
import '../services/bible_api_service.dart';
import '../services/bible_reference.dart';
import '../services/gemini_live_client.dart';
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
  String _bibleApiKey = '';
  String _selectedVoice = 'Kore';
  String _selectedModel = 'models/gemini-2.0-flash-live-001';
  String _selectedTranslation = 'NIV';
  String _selectedPersona = 'Biblical Scholar & Exegete';
  String? _statusMessage = 'Tap microphone to speak';
  String _heldAssistantText = '';
  bool _voiceHasStarted = false;

  final List<ChatMessage> _messages = [];
  Timer? _amplitudeFallbackTimer;

  // Core Services
  late final AudioManager _audioManager;
  late final BibleApiService _bibleApi;
  GeminiLiveClient? _liveClient;
  String? _pendingLivePrompt;

  // Getters
  VoiceSessionState get state => _state;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  double get audioAmplitude => _audioAmplitude;
  String get apiKey => _apiKey;
  String get bibleApiKey => _bibleApiKey;
  String get selectedVoice => _selectedVoice;
  String get selectedModel => _selectedModel;
  String get selectedTranslation => _selectedTranslation;
  String get selectedPersona => _selectedPersona;
  String? get statusMessage => _statusMessage;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasApiKey => _apiKey.trim().isNotEmpty;
  bool get hasBibleApiKey => _bibleApiKey.trim().isNotEmpty;

  bool get isActive =>
      _state == VoiceSessionState.listening ||
      _state == VoiceSessionState.thinking ||
      _state == VoiceSessionState.speaking ||
      _state == VoiceSessionState.connecting;

  VoiceSessionController() {
    _audioManager = AudioManager();
    _bibleApi = BibleApiService();
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

    // Playback finished — chat is already on screen; reopen the mic.
    _audioManager.onPlaybackComplete = () async {
      if (_state == VoiceSessionState.speaking) {
        await _finalizeCurrentAssistantTurn();
        _state = VoiceSessionState.listening;
        _statusMessage = 'Listening • Speak anytime to reply';
        _audioAmplitude = 0.05;
        _resetAssistantHold();
        _audioManager.startRecording();
        notifyListeners();
      }
    };
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key') ?? '';
      _bibleApiKey = prefs.getString('api_bible_key') ?? '';
      _bibleApi.setApiKey(_bibleApiKey);
      _selectedVoice = prefs.getString('gemini_voice') ?? 'Kore';
      _selectedModel =
          prefs.getString('gemini_model') ?? 'models/gemini-2.0-flash-live-001';
      _selectedTranslation = prefs.getString('bible_translation') ?? 'NIV';
      _selectedPersona =
          prefs.getString('voice_persona') ?? 'Biblical Scholar & Exegete';

      notifyListeners();
      if (_bibleApiKey.isNotEmpty) {
        unawaited(_loadWelcomeVerse());
      }
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
        isVoice: true,
      ),
    );
  }

  Future<void> _loadWelcomeVerse() async {
    final result = await _bibleApi.lookup('Psalm 119:105');
    final quote = result.quote;
    if (quote == null || _messages.isEmpty) return;
    _messages[0] = _messages.first.copyWith(scriptures: [quote]);
    notifyListeners();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKey);
    _statusMessage = 'API Key saved';
    notifyListeners();
  }

  Future<void> setBibleApiKey(String key) async {
    _bibleApiKey = key.trim();
    _bibleApi.setApiKey(_bibleApiKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_bible_key', _bibleApiKey);
    _statusMessage = _bibleApiKey.isEmpty
        ? 'API.Bible key cleared'
        : 'API.Bible key saved';
    notifyListeners();
    if (_bibleApiKey.isNotEmpty) {
      unawaited(_loadWelcomeVerse());
    }
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
    _resetAssistantHold();

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
      final pendingPrompt = _pendingLivePrompt;
      _pendingLivePrompt = null;
      if (pendingPrompt != null) {
        _state = VoiceSessionState.thinking;
        _statusMessage = 'Consulting Scripture & formulating voice...';
        notifyListeners();
        _liveClient?.sendText(pendingPrompt);
      } else {
        _state = VoiceSessionState.listening;
        _statusMessage = 'Listening \u2022 Speak your thought or question';
        notifyListeners();
      }

      // Automatically activate microphone streaming
      final micStarted = await _audioManager.startRecording();
      if (!micStarted) {
        _state = VoiceSessionState.error;
        _statusMessage = 'Microphone permission denied. Check app settings.';
        notifyListeners();
      }
    };

    _liveClient!.onAudioChunk = (pcm24kBytes) {
      final canSpeak =
          _state == VoiceSessionState.listening ||
          _state == VoiceSessionState.thinking ||
          _state == VoiceSessionState.connecting;
      if (canSpeak && _state != VoiceSessionState.speaking) {
        _audioManager.stopRecording();
        _state = VoiceSessionState.speaking;
        _statusMessage = 'Speaking...';
        _releaseHeldAssistantText();
        notifyListeners();
      }
      _audioManager.feedPcmChunk(pcm24kBytes);
    };

    _liveClient!.onTextDelta = _holdOrAppendAssistant;

    _liveClient!.onInputTranscript = (userSpeech) {
      _appendUserTranscript(userSpeech);
      // Once user speech is transcribed, we're waiting for Gemini's response
      if (_state == VoiceSessionState.listening) {
        _state = VoiceSessionState.thinking;
        _statusMessage = 'Thinking...';
        notifyListeners();
      }
    };

    _liveClient!.onOutputTranscript = _holdOrAppendAssistant;

    _liveClient!.onToolCall = _handleToolCall;

    _liveClient!.onTurnComplete = () async {
      debugPrint(
        '[VoiceSessionController] Turn complete — voice keeps playing',
      );
      if (!_voiceHasStarted) {
        _releaseHeldAssistantText();
      }
      await _finalizeCurrentAssistantTurn();
      final waitingForPlayback = _audioManager.completeLiveTurn();
      if (waitingForPlayback) return;

      if (_state == VoiceSessionState.speaking ||
          _state == VoiceSessionState.thinking) {
        _state = VoiceSessionState.listening;
        _statusMessage = 'Listening • Speak anytime to reply';
        _audioAmplitude = 0.05;
        _resetAssistantHold();
        notifyListeners();
        await _audioManager.startRecording();
      }
    };

    _liveClient!.onInterrupted = () async {
      debugPrint('[VoiceSessionController] Gemini Live Interrupted by User');
      _resetAssistantHold();
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
      tools: BibleApiService.liveTools,
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
    _pendingLivePrompt = null;
    _resetAssistantHold();
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
  // TEXT PROMPT & SCRIPTURE READING
  // -------------------------------------------------------------
  Future<void> submitPrompt(String text, {String? chatText}) async {
    if (_apiKey.trim().isEmpty) {
      _state = VoiceSessionState.error;
      _statusMessage = 'Please enter your Gemini API Key in Settings';
      notifyListeners();
      return;
    }

    _messages.add(
      ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.user,
        content: chatText ?? text,
        isVoice: true,
      ),
    );
    _state = VoiceSessionState.thinking;
    _statusMessage = 'Consulting Scripture & formulating voice...';
    notifyListeners();
    await _dispatchLivePrompt(text);
  }

  /// Asks the live session to read a verse aloud.
  Future<void> speakScripture(ScriptureQuote scripture) {
    return submitPrompt(
      'Read ${scripture.reference} aloud from the ${scripture.translation} translation, word for word, then stop. Verse text: "${scripture.text}"',
      chatText: 'Read ${scripture.reference}',
    );
  }

  Future<void> _dispatchLivePrompt(String text) async {
    if (_liveClient != null && _liveClient!.isConnected) {
      _liveClient!.sendText(text);
      return;
    }

    _pendingLivePrompt = text;
    if (!isActive) {
      await startSession();
    }
  }

  // -------------------------------------------------------------
  // TRANSCRIPT & STREAMING HELPERS
  // -------------------------------------------------------------
  void _holdOrAppendAssistant(String delta) {
    if (delta.isEmpty) return;
    if (!_voiceHasStarted) {
      _heldAssistantText += delta;
      return;
    }
    _appendStreamingAssistantDelta(delta);
  }

  void _releaseHeldAssistantText() {
    _voiceHasStarted = true;
    final held = _heldAssistantText;
    _heldAssistantText = '';
    if (held.isNotEmpty) {
      _appendStreamingAssistantDelta(held);
    }
  }

  void _resetAssistantHold() {
    _voiceHasStarted = false;
    _heldAssistantText = '';
  }

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

  Future<void> _handleToolCall(Map<String, dynamic> toolCall) async {
    final calls = toolCall['functionCalls'] as List? ?? const [];
    for (final call in calls) {
      if (call is! Map) continue;
      final name = call['name'] as String? ?? '';
      final id = call['id'] as String? ?? '';
      if (name != 'lookup_bible_passage') continue;

      final args = call['args'];
      final reference = args is Map
          ? args['reference']?.toString() ?? ''
          : '';
      final result = await _bibleApi.lookup(reference);
      final quote = result.quote;
      if (quote != null) {
        _attachScripture(quote);
        _liveClient?.sendToolResponse(
          id: id,
          name: name,
          response: {
            'reference': quote.reference,
            'translation': 'NIV',
            'text': quote.text,
            'result':
                '${quote.reference} (NIV): ${quote.text}. Read this wording verbatim.',
          },
        );
      } else {
        _liveClient?.sendToolResponse(
          id: id,
          name: name,
          response: {
            'error': result.error ?? 'Passage not found.',
            'result': result.error ?? 'Passage not found.',
          },
        );
      }
    }
  }

  void _attachScripture(ScriptureQuote quote) {
    _releaseHeldAssistantText();
    if (_messages.isNotEmpty && _messages.last.isAssistant) {
      final existing = _messages.last.scriptures;
      if (existing.any(
        (item) => BibleReference.samePassage(item.reference, quote.reference),
      )) {
        return;
      }
      _messages[_messages.length - 1] = _messages.last.copyWith(
        scriptures: [...existing, quote],
      );
    } else {
      _voiceHasStarted = true;
      _messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: '',
          scriptures: [quote],
          isVoice: true,
          isStreaming: true,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _finalizeCurrentAssistantTurn() async {
    if (_messages.isEmpty || !_messages.last.isAssistant) return;

    final message = _messages.last;
    final scriptures = [...message.scriptures];
    for (final reference in ScriptureParser.extractReferences(message.content)) {
      if (scriptures.any(
        (item) => BibleReference.samePassage(item.reference, reference),
      )) {
        continue;
      }
      final result = await _bibleApi.lookup(reference);
      final quote = result.quote;
      if (quote != null) scriptures.add(quote);
    }

    _messages[_messages.length - 1] = message.copyWith(
      scriptures: scriptures,
      isStreaming: false,
    );
    notifyListeners();
  }

  String _buildSystemInstruction() {
    return '''
You are "Scripture Live", an empathetic, profound, and reverent biblical AI companion powered by Gemini Live audio.
You are speaking directly to the user through real-time audio voice.

Current Persona: $_selectedPersona
Licensed Bible text: New International Version (NIV), retrieved with lookup_bible_passage.

Guidelines:
1. Speak in a warm, contemplative, and engaging tone suitable for spoken conversation.
2. Before you quote, read, or cite any Bible passage, call lookup_bible_passage with the reference. Speak the returned NIV text verbatim. Never invent, paraphrase, or recall verse wording from memory.
3. Say the reference clearly, then read the verse, for example "In John 3:16, the New International Version says...".
4. Keep spoken replies concise, impactful, and conversational (usually 2 to 4 sentences unless asked for an in-depth exposition).
5. Address user questions about grief, joy, anxiety, doubt, theology, prayer, and daily Christian living with Christ-centered encouragement, historical depth, and hope.
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
