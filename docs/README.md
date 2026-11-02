# Pocket AI developer documentation

Pocket AI is a Flutter application that runs a GGUF language model locally with
`llamadart` (llama.cpp). This documentation describes the current implementation;
for planned work, see the [project roadmap](../FUTURE_ROADMAP.md).

## Documentation

- [Architecture and runtime flows](architecture.md) — component diagram, model
  setup, chat and voice flows, and local persistence.
- [Project README](../README.md) — prerequisites, installation, and running the
  app.

## Source layout

```text
lib/
├── main.dart                         # Flutter and notification initialization
├── app.dart                          # App shell and theme selection
├── provider/theme_provider.dart      # Riverpod theme state
├── utils/                            # App theme and model constants
├── tools/                            # Reminder parsing/scheduling and torch control
├── llm/                              # LLM tool schema definitions
└── features/
    ├── model/presentation/           # Model download/load and startup UI
    ├── home/presentation/            # Chat/voice navigation
    ├── chat/
    │   ├── models/                   # Chat and performance data
    │   ├── presentation/             # Chat UI and message orchestration
    │   ├── service/                  # Local inference, SQLite, and chat utilities
    │   └── widgets/                  # Chat-specific widgets
    ├── assistant/presentation/       # Voice assistant and voice utilities
    └── settings/presentation/        # Appearance settings

test/
├── widget_test.dart
└── think_filter_test.dart
```

## Runtime dependencies

The main integrations are:

| Concern | Implementation |
| --- | --- |
| Local model inference | `llamadart`, backed by llama.cpp |
| Initial model download | `dio` |
| Model and database file locations | `path_provider`, `path` |
| Chat and reminder persistence | `sqflite` |
| Theme state | `flutter_riverpod` |
| Speech input and output | `speech_to_text`, `flutter_tts` |
| Scheduled reminder notifications | `flutter_local_notifications`, `timezone` |
| Flashlight actions | `torch_light` |

Dependency versions and SDK constraints are defined in [`pubspec.yaml`](../pubspec.yaml).

## Local data and network use

- The Qwen3 0.6B Q8_0 GGUF is downloaded from Hugging Face when no valid cached
  model is present. The app stores it under the platform's application support
  directory in `models/`.
- The model is accepted when its first four bytes match the GGUF magic header.
  The current code does not perform a checksum or full-file integrity check.
- Model inference and chat-history storage are local. Chat history and reminders
  are stored in the `chat_history.db` SQLite database.
- Speech recognition behavior depends on the platform speech service and its
  configuration; it is separate from LLM inference.

## Development checks

Run these commands from the repository root after installing the Flutter SDK
version required by `pubspec.yaml`:

```bash
flutter pub get
flutter analyze
flutter test
```

The checked-in automated tests cover app startup's model-setup screen and the
streaming `ThinkFilter`.
