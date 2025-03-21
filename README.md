# Lullie App

A Flutter application designed to help users improve their sleep quality through music therapy and mood-based playlists.

## Features

- 🎵 Mood-based music recommendations
- 😴 Sleep tracking and analytics
- 📊 Statistics and progress monitoring
- 🎨 Beautiful and intuitive UI
- 🌙 Dark mode optimized for bedtime use
- 🎧 Seamless audio playback
- 💾 Persistent state management
- 📱 Cross-platform support (iOS & Android)

## Technologies Used

- Flutter
- Dart
- just_audio for audio playback
- OpenAI API for music recommendations
- SharedPreferences for local storage
- Provider for state management
- Google Fonts
- SVG rendering
- Custom animations and transitions

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- iOS Simulator/Android Emulator
- OpenAI API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/sillymoonie/lullie-app.git
```

2. Navigate to the project directory:
```bash
cd lullie-app
```

3. Install dependencies:
```bash
flutter pub get
```

4. Create a `.env` file in the root directory and add your OpenAI API key:
```
token=your_openai_api_key_here
```

5. Run the app:
```bash
flutter run
```

## Architecture

The app follows a clean architecture pattern with:
- Services for business logic
- Widgets for UI components
- Models for data structures
- Providers for state management

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenAI for the GPT API
- Flutter team for the amazing framework
- Contributors and users of the app
