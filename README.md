# RiceWatch

**RiceWatch** is an AI-powered mobile app for Filipino rice farmers. It helps farmers monitor crops, identify diseases, and get practical farming advice in Cebuano/Bisaya.

## Features

- **Scan & Analyze** — Capture rice leaf photos with your camera and get AI-powered disease identification with risk levels (Low, Moderate, High)
- **Weather Forecast** — Location-based 7-day forecast and interactive map (Windy) for planning field work
- **AI Assistant** — Chat with rice farming advice in Cebuano/Bisaya, with text-to-speech support
- **Scan History** — View and manage past scan results with detailed disease information
- **Dark/Light Mode** — Theme support with system preference option

## Requirements

- Flutter SDK 3.10.8 or higher
- OpenAI API key (for AI Assistant and Scan & Analyze)
- Location permission (for weather forecasts)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tugz05/ricewatch.git
   cd ricewatch
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure OpenAI API key**
   
   Add your API key in one of these ways:
   
   - **Option A:** Edit `lib/core/config/openai_secrets.dart` and set `openAiApiKeyFromFile`
   - **Option B:** Run with dart-define:
     ```bash
     flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # Theme, config, constants, utils
├── components/     # Reusable UI (buttons, cards, navigation)
├── controllers/    # State management (Provider)
├── models/         # Data models
├── services/       # API, database, TTS
├── views/          # Screens (Home, Weather, AI Assistant, Scan, Settings)
└── main.dart
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| provider | State management |
| image_picker | Camera capture for leaf scanning |
| sqflite | Local scan history storage |
| flutter_tts | Text-to-speech for AI responses |
| webview_flutter | Weather map embed |
| connectivity_plus | Network status for online/offline features |
| geolocator | Location for weather |

## Building for Release

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## Platform Notes

- **Web:** Scan & Analyze uses the camera; image analysis requires an internet connection. SQLite is not supported on web—scan history uses in-memory storage.
- **Android/iOS:** Full feature support including local SQLite storage for scan history.

## License

Private project. Not for public distribution.
