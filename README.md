# Scripture Live - Gemini Bible AI

A real-time voice-powered Bible companion app that uses Google's Gemini 2.0 Live API to enable natural, spoken conversations about scripture, theology, and Christian living. Speak your questions and receive thoughtful, scripture-grounded responses with live audio streaming and licensed NIV text integration.

## Features

- **Real-Time Voice Conversations**: Bidirectional audio streaming with Google Gemini Live API using WebSocket connections
- **Voice-First Interface**: Speak naturally to ask questions, explore passages, or seek spiritual guidance
- **Licensed Scripture Integration**: Automatic NIV text lookup via API.Bible with accurate verse references
- **Live Audio Streaming**: 16kHz microphone input and 24kHz PCM audio output for natural voice interactions
- **Interactive Scripture Cards**: Visual display of referenced verses with full NIV text and copyright
- **Multiple Voice Personas**: Choose from different AI personalities (Biblical Scholar, Exegete, etc.)
- **Voice Selection**: Select from multiple Gemini voice options (Kore, Puck, Charon, Fenrir, Aoede)
- **Conversation Transcription**: Real-time transcription of both user speech and AI responses
- **Interruption Support**: Barge-in capability to interrupt the AI mid-response
- **Audio Visualization**: Dynamic waveform visualization showing conversation states
- **Cross-Platform**: Built with Flutter for Android, iOS, macOS, Windows, Linux, and Web

## Tech Stack

- **Framework**: Flutter 3.x with Dart SDK ^3.11.0
- **AI Engine**: Google Gemini 2.0 Flash Live (multimodal live API)
- **Bible API**: API.Bible for licensed New International Version text
- **Audio**: 
  - `record` package for microphone input
  - `flutter_soloud` for PCM audio playback
  - `audioplayers` for additional audio capabilities
- **Networking**: WebSocket via `web_socket_channel` for real-time streaming
- **UI**: Material Design with `google_fonts` (Cinzel, Plus Jakarta Sans)
- **Storage**: `shared_preferences` for API keys and user settings

## Prerequisites

- Flutter SDK 3.x or later
- Dart SDK ^3.11.0
- A **Gemini API key** from [Google AI Studio](https://aistudio.google.com/apikey)
- An **API.Bible key** from [API.Bible](https://scripture.api.bible/) with NIV access (required for licensed scripture text)
- Microphone permissions on target platform

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd bible_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

   Or for a specific platform:
   ```bash
   flutter run -d android
   flutter run -d ios
   flutter run -d macos
   flutter run -d windows
   flutter run -d linux
   flutter run -d chrome
   ```

## Configuration

### Required API Keys

The app requires two API keys, which you must enter through the in-app Settings interface (accessed via the settings icon in the app bar):

1. **Gemini API Key**
   - Obtain from: [Google AI Studio](https://aistudio.google.com/apikey)
   - Used for: Gemini Live voice AI conversations
   - Stored in: `shared_preferences` as `gemini_api_key`

2. **API.Bible Key**
   - Obtain from: [API.Bible Dashboard](https://scripture.api.bible/)
   - Used for: Licensed NIV scripture text lookup
   - Required permissions: Access to New International Version (NIV)
   - Stored in: `shared_preferences` as `api_bible_key`

### Customizable Settings

All settings are configurable through the in-app Settings modal:

- **Gemini Voice**: Select from Kore, Puck, Charon, Fenrir, or Aoede
- **Gemini Model**: Default is `models/gemini-2.0-flash-live-001`
- **Bible Translation**: Currently supports NIV
- **Voice Persona**: Choose the AI's personality (Biblical Scholar & Exegete, etc.)

Settings are persisted locally using `shared_preferences`.

## Usage

### Starting a Conversation

1. Launch the app
2. Tap the settings icon (first launch) to enter your API keys
3. Tap the large microphone orb at the bottom of the screen
4. Speak your question or request (e.g., "What does John 3:16 say?")
5. The AI will respond with voice and display any referenced scriptures

### Voice Commands & Prompts

The app includes a carousel of prompt suggestions:

- Scripture lookup (e.g., "What is Romans 8:28?")
- Theological questions
- Devotional guidance
- Scripture study and exegesis

### Text Input Mode

Tap the keyboard icon on the microphone orb to type your question instead of speaking.

### Reading Scripture Aloud

Tap the speaker icon on any scripture card to have the AI read that verse aloud in the selected translation.

### Managing Conversations

- **Mute/Unmute**: Tap the microphone icon to toggle microphone input
- **Clear Chat**: Use the menu (three dots) in the app bar to reset the conversation
- **Change Settings**: Tap the tune icon to adjust voice, model, or persona mid-conversation

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── controllers/
│   └── voice_session_controller.dart  # State management for voice sessions
├── models/
│   ├── chat_message.dart              # Message data model
│   └── scripture.dart                 # Scripture quote data model
├── screens/
│   └── bible_voice_screen.dart        # Main conversation screen
├── services/
│   ├── audio_manager.dart             # Audio recording and playback
│   ├── bible_api_service.dart         # API.Bible integration
│   ├── bible_reference.dart           # Scripture reference parsing
│   ├── gemini_live_client.dart        # Gemini Live WebSocket client
│   ├── scripture_parser.dart          # Extract scripture references from text
│   └── verse_image_service.dart       # Scripture image generation
├── theme/
│   └── app_theme.dart                 # App-wide theme definitions
└── widgets/
    ├── audio_visualizer.dart          # Waveform visualization
    ├── microphone_orb.dart            # Main microphone control
    ├── prompt_carousel.dart           # Suggested prompts carousel
    ├── scripture_card.dart            # Scripture display card
    ├── scripture_focus_view.dart      # Full-screen scripture view
    ├── text_input_sheet.dart          # Text input modal
    ├── transcript_view.dart           # Conversation history
    ├── verse_image_dialog.dart        # AI-generated verse imagery
    └── voice_settings_modal.dart      # Settings configuration
```

## How It Works

### Audio Pipeline

1. **Microphone Input**: Captures audio at 16kHz mono PCM using the `record` package
2. **Real-Time Streaming**: Sends audio chunks to Gemini Live via WebSocket as base64-encoded PCM
3. **AI Processing**: Gemini transcribes user speech, processes the request, and generates audio responses
4. **Audio Playback**: Receives 24kHz PCM audio chunks from Gemini and plays them using `flutter_soloud`
5. **Transcription**: Both user input and AI output are transcribed and displayed in the conversation view

### Scripture Lookup Flow

1. User mentions a Bible reference (e.g., "John 3:16")
2. AI calls the `lookup_bible_passage` function tool
3. App queries API.Bible for the licensed NIV text
4. Scripture card is rendered with reference, text, and copyright
5. AI speaks the exact NIV wording returned by the API

### WebSocket Protocol

The app implements Google's BidiGenerateContent protocol:
- Sends `setup` frame with model, voice, and system instructions
- Streams `realtimeInput` frames with audio data
- Receives `serverContent` frames with audio, transcripts, and tool calls
- Handles `turnComplete`, `interrupted`, and `setupComplete` signals

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

### Linting

```bash
flutter analyze
```

## Troubleshooting

### "Please enter your Gemini API Key"
- Open Settings and enter a valid Gemini API key from Google AI Studio
- Ensure the key is saved (status message will confirm)

### "API.Bible key is missing"
- Scripture lookup requires an API.Bible key with NIV access
- Register at https://scripture.api.bible/ and enable NIV in your account

### "Microphone permission denied"
- Grant microphone permissions in your device/OS settings
- On iOS: Settings → Privacy → Microphone → Scripture Live
- On Android: Settings → Apps → Scripture Live → Permissions

### "Connection Error" or WebSocket failures
- Verify your Gemini API key is correct and active
- Check your internet connection
- Ensure the selected model is available (`gemini-2.0-flash-live-001`)

### No audio playback
- Check that speaker/output device is enabled
- Tap the speaker toggle in the UI to ensure it's not muted
- Verify system audio permissions

## License

This project is private and not published to pub.dev.

## Credits

- **AI**: Powered by Google Gemini 2.0 Live API
- **Scripture**: New International Version (NIV) text from API.Bible
- **UI Fonts**: Cinzel and Plus Jakarta Sans via Google Fonts
