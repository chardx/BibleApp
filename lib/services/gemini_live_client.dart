import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// Gemini Multimodal Live API Client for direct WebSocket connection.
/// Implements Google's BidiGenerateContent bidirectional protocol:
/// - Audio Input: Linear PCM 16-bit 16,000Hz mono
/// - Audio Output: Linear PCM 16-bit 24,000Hz mono
class GeminiLiveClient {
  final String apiKey;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // _isDisconnecting prevents onClose from firing when WE initiated the close
  bool _isDisconnecting = false;

  String _status = 'disconnected'; // 'disconnected', 'connecting', 'connected'
  String? _model;
  Map<String, dynamic>? _config;

  // Event callbacks
  void Function()? onOpen;
  void Function(String reason)? onClose;
  void Function(dynamic error)? onError;
  void Function()? onSetupComplete;
  void Function(Uint8List pcm24kBytes)? onAudioChunk;
  void Function(String textDelta)? onTextDelta;
  void Function(String userTranscript)? onInputTranscript;
  void Function(String modelTranscript)? onOutputTranscript;
  void Function(String thought)? onThought;
  void Function()? onTurnComplete;
  void Function()? onInterrupted;
  void Function(Map<String, dynamic> toolCall)? onToolCall;

  GeminiLiveClient({required this.apiKey});

  String get status => _status;
  bool get isConnected => _status == 'connected';
  String? get model => _model;
  Map<String, dynamic>? get config => _config;

  /// Connects to the Gemini Live WebSocket endpoint and sends initial setup.
  Future<bool> connect({
    required String model,
    required String voiceName,
    required String systemInstruction,
  }) async {
    if (_status != 'disconnected') {
      debugPrint('[GeminiLiveClient] Already connecting/connected — aborting stale session first.');
      _forceClose();
    }

    _status = 'connecting';
    _isDisconnecting = false;
    _model = model;

    // Ensure model name includes 'models/' prefix
    final String sanitizedModel = model.startsWith('models/') ? model : 'models/$model';
    final uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    debugPrint('[GeminiLiveClient] Connecting to Gemini Live: ${uri.host} | model=$sanitizedModel | voice=$voiceName');

    try {
      _channel = WebSocketChannel.connect(uri);

      // Await the WebSocket handshake — this throws if the connection is refused
      await _channel!.ready;

      // Listen to incoming messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (err) {
          debugPrint('[GeminiLiveClient] WebSocket stream error: $err');
          if (!_isDisconnecting) {
            _status = 'disconnected';
            onError?.call(err);
          }
        },
        onDone: () {
          debugPrint('[GeminiLiveClient] WebSocket stream closed (onDone)');
          final wasDisconnecting = _isDisconnecting;
          _status = 'disconnected';
          _isDisconnecting = false;
          if (!wasDisconnecting) {
            // Server-initiated close — notify controller
            onClose?.call('Server closed connection');
          }
        },
        cancelOnError: true,
      );

      // --- Build Setup Payload ---
      final setupPayload = {
        'setup': {
          'model': sanitizedModel,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': voiceName,
                },
              },
            },
          },
          'inputAudioTranscription': {},  // Enable user-speech transcription
          'outputAudioTranscription': {}, // Enable model-speech transcription
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
        },
      };

      _config = setupPayload;

      // Send setup frame — Gemini responds with { "setupComplete": {} }
      final setupJson = jsonEncode(setupPayload);
      _channel!.sink.add(setupJson);
      debugPrint('[GeminiLiveClient] Setup payload sent — waiting for setupComplete...');

      // Mark as connected (WebSocket is open, setup is in-flight)
      _status = 'connected';
      onOpen?.call();
      return true;
    } catch (e) {
      debugPrint('[GeminiLiveClient] Connection failed: $e');
      _status = 'disconnected';
      onError?.call(e);
      return false;
    }
  }

  void _onMessage(dynamic rawMessage) {
    try {
      final Map<String, dynamic> message = (rawMessage is String)
          ? jsonDecode(rawMessage) as Map<String, dynamic>
          : jsonDecode(utf8.decode(rawMessage as List<int>)) as Map<String, dynamic>;

      debugPrint('[GeminiLiveClient] Received message keys: ${message.keys.toList()}');

      // 1. Setup Complete
      if (message.containsKey('setupComplete')) {
        debugPrint('[GeminiLiveClient] ✓ Setup acknowledged by Gemini server');
        onSetupComplete?.call();
        return;
      }

      // 2. Tool Calls
      if (message.containsKey('toolCall')) {
        debugPrint('[GeminiLiveClient] Tool call received: ${message['toolCall']}');
        onToolCall?.call(Map<String, dynamic>.from(message['toolCall'] as Map));
        return;
      }

      // 3. Server Content
      if (message.containsKey('serverContent')) {
        final serverContent = message['serverContent'] as Map<String, dynamic>;

        // Interrupted by user (barge-in)
        if (serverContent['interrupted'] == true) {
          debugPrint('[GeminiLiveClient] Barge-in / Interruption signal received');
          onInterrupted?.call();
          return;
        }

        // Input transcription (user speech transcribed by Gemini)
        if (serverContent['inputTranscription'] != null) {
          final transcription = serverContent['inputTranscription'] as Map<String, dynamic>;
          final text = transcription['text'] as String? ?? '';
          if (text.isNotEmpty) {
            debugPrint('[GeminiLiveClient] User transcript: $text');
            onInputTranscript?.call(text);
          }
        }

        // Output transcription (model speech transcribed by Gemini)
        if (serverContent['outputTranscription'] != null) {
          final transcription = serverContent['outputTranscription'] as Map<String, dynamic>;
          final text = transcription['text'] as String? ?? '';
          if (text.isNotEmpty) {
            debugPrint('[GeminiLiveClient] Model transcript: $text');
            onOutputTranscript?.call(text);
          }
        }

        // Model Turn: audio parts, text, thoughts
        if (serverContent['modelTurn'] != null) {
          final parts = serverContent['modelTurn']['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map) {
                // Audio data: base64 encoded 24kHz PCM
                if (part['inlineData'] != null) {
                  final mimeType = part['inlineData']['mimeType'] as String? ?? '';
                  final base64Audio = part['inlineData']['data'] as String? ?? '';

                  if (base64Audio.isNotEmpty && mimeType.startsWith('audio/')) {
                    try {
                      final pcmBytes = base64Decode(base64Audio);
                      debugPrint('[GeminiLiveClient] Audio chunk: ${pcmBytes.length} bytes (mime=$mimeType)');
                      onAudioChunk?.call(pcmBytes);
                    } catch (e) {
                      debugPrint('[GeminiLiveClient] Error decoding PCM audio chunk: $e');
                    }
                  }
                }

                // Thought text (reasoning models)
                if (part['thought'] == true && part['text'] != null) {
                  onThought?.call(part['text'] as String);
                } else if (part['text'] != null) {
                  // Direct text delta
                  onTextDelta?.call(part['text'] as String);
                }
              }
            }
          }
        }

        // Turn Complete
        if (serverContent['turnComplete'] == true) {
          debugPrint('[GeminiLiveClient] ✓ Agent turn complete');
          onTurnComplete?.call();
        }
      }
    } catch (e, stack) {
      debugPrint('[GeminiLiveClient] Error parsing message: $e\n$stack');
    }
  }

  /// Sends real-time microphone audio chunk (Linear PCM 16-bit 16kHz mono)
  void sendRealtimeAudio(Uint8List pcm16kBytes) {
    if (_channel == null || _status != 'connected') return;

    try {
      final base64Data = base64Encode(pcm16kBytes);
      final payload = {
        'realtimeInput': {
          'mediaChunks': [
            {
              'mimeType': 'audio/pcm;rate=16000',
              'data': base64Data,
            },
          ],
        },
      };

      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[GeminiLiveClient] Error sending audio chunk: $e');
    }
  }

  /// Sends a text prompt/message as client conversational turn
  void sendText(String text) {
    if (_channel == null || _status != 'connected') {
      debugPrint('[GeminiLiveClient] Cannot send text: not connected (status=$_status)');
      return;
    }

    try {
      final payload = {
        'clientContent': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text},
              ],
            },
          ],
          'turnComplete': true,
        },
      };

      _channel!.sink.add(jsonEncode(payload));
      debugPrint('[GeminiLiveClient] Sent text turn: "$text"');
    } catch (e) {
      debugPrint('[GeminiLiveClient] Error sending text: $e');
    }
  }

  /// Sends tool call response back to Gemini
  void sendToolResponse({
    required String id,
    required String name,
    required Map<String, dynamic> response,
  }) {
    if (_channel == null || _status != 'connected') return;

    final payload = {
      'toolResponse': {
        'functionResponses': [
          {
            'response': response,
            'id': id,
          },
        ],
      },
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Closes the WebSocket session cleanly (user-initiated — suppresses onClose callback)
  void disconnect() {
    debugPrint('[GeminiLiveClient] Disconnecting session (user-initiated)');
    _isDisconnecting = true;
    _forceClose();
  }

  /// Internal: cancel subscription and close the channel
  void _forceClose() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close(ws_status.goingAway);
    _channel = null;
    _status = 'disconnected';
  }
}
