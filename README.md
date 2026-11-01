# Pocket AI

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38%2B-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/Model-GGUF-FF6B6B" alt="GGUF" />
  <img src="https://img.shields.io/badge/Local-AI-6C63FF" alt="Local AI" />
</p>

Pocket AI is a Flutter-based local AI chat app that downloads a GGUF language model on first use and runs inference directly on the device. It keeps the model in the app support directory so it can be reused later without downloading it again.

## Overview

The app uses the Qwen3 0.6B Q8_0 model from Hugging Face and loads it with `llamadart` / llama.cpp. On launch, a model setup screen checks for a valid cached model, downloads it if needed, and displays download progress. Once the model is loaded, the app opens chat and reuses the same loaded service.

## Features

- **Local-first AI chat**: Text conversation with streaming inference and SQLite chat history persistence.
- **Dedicated offline voice assistant**: Interactive voice mode (STT ➔ on-device LLM ➔ TTS) featuring multi-state pulsing UI (Idle, Listening, Thinking, Speaking).
- **On-device speech recognition & synthesis**: Speech-to-text dictation and voice audio playback powered completely offline.
- **Automatic model download & caching**: Downloads GGUF model on first launch, validates headers, and reuses local storage for subsequent launches.
- **100% private inference**: Processes all text and voice prompts completely on-device without sending data to cloud servers.
- **Diagnostics & telemetry**: Detailed TTFT (Time-To-First-Token), download, preparation, and token throughput logging.

## How it works

1. The model setup screen checks the application support directory for a cached model.
2. If no valid model is present, it downloads the GGUF file from Hugging Face and reports progress.
3. The downloaded file is validated and stored locally for future launches.
4. The app loads the model and opens chat. Prompts are processed on-device, and conversations are saved locally.

## Requirements

- Flutter SDK 3.38.0 or newer (Dart 3.10.7 or newer)
- Android Studio / Android SDK
- An Android device or emulator
- Internet connection for the initial model download
- Enough device storage for the Qwen3 0.6B Q8_0 model

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/SubramanyaKS/PocketAI.git
cd PocketAI
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

## Project structure

```text
.
├── android/
├── assets/
│   └── icons/
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── features/
│   │   ├── assistant/
│   │   │   └── presentation/
│   │   │       └── voice_assistant_screen.dart
│   │   ├── chat/
│   │   │   ├── models/
│   │   │   │   ├── chat_message.dart
│   │   │   │   └── performance_metrics.dart
│   │   │   ├── presentation/
│   │   │   │   └── chat_screen.dart
│   │   │   ├── service/
│   │   │   │   ├── chat_database.dart
│   │   │   │   ├── local_ai_service.dart
│   │   │   │   └── think_filter.dart
│   │   │   └── widgets/
│   │   │       ├── chat_empty_widget.dart
│   │   │       └── prompt_suggestion.dart
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart
│   │   └── model/
│   │       └── presentation/
│   │           └── model_setup_screen.dart
│   └── utils/
│       └── constant.dart
├── test/
│   ├── think_filter_test.dart
│   └── widget_test.dart
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```


## Future Roadmap

Pocket AI is actively evolving towards a full-featured offline assistant:
- **Offline Alarms & Timers**: Trigger system alarms and countdown timers via native Android intents directly from voice commands.
- **Offline Reminders & To-Dos**: Save and schedule local reminders in SQLite with device push notifications.
- **Low-Latency Streaming TTS**: Sentence-by-sentence audio playback for instant voice replies.
- **Multi-Model Catalog**: Choose and manage GGUF models on-device (0.5B, 1.5B, 3B).
- **Offline Document Chat (RAG)**: Private on-device Q&A for local PDFs and notes.
- **Markdown & Code Highlighting**: Rich formatting and syntax highlighting in chat.

## Model behavior

The current implementation downloads `Qwen3-0.6B-Q8_0.gguf` on first launch and caches it in the app support directory under `models/`. The service validates the GGUF header before loading the model with llamadart. Inference uses a 2,048-token context, four generation threads, and streamed output with a 128-token limit. Subsequent launches reuse the cached file; model download and initialization timing and file size are written to debug logs.

## Inference package migration

The inference service uses `llamadart` for model loading and streamed generation; `llama_flutter_android` has been removed. The existing Dio-based model download, progress reporting, GGUF validation, and cache location are unchanged. `llamadart` requires Dart 3.10.7 or newer and Flutter 3.38.0 or newer.

## Contributing

Contributions are welcome. If you want to improve the app, please open an issue or submit a pull request with a clear description of the change.

## License

This project is currently unlicensed. If you plan to share or distribute it publicly, consider adding an appropriate license file such as MIT or Apache 2.0.
