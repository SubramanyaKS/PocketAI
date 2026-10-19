# Pocket AI

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/Model-GGUF-FF6B6B" alt="GGUF" />
  <img src="https://img.shields.io/badge/Local-AI-6C63FF" alt="Local AI" />
</p>

Pocket AI is a Flutter-based local AI chat app that downloads a GGUF language model on first use and runs inference directly on the device. It keeps the model in the app support directory so it can be reused later without downloading it again.

## Overview

This app uses a lightweight quantized LLM from Hugging Face and loads it with `llama_flutter_android` / llama.cpp. When the app opens, a model setup screen checks whether the model is already present; if it is not, it downloads it and stores it locally. After the model is ready, the app opens chat and reuses the local model on later launches.

## Features

- Local-first AI chat experience
- Automatic model download and caching
- Works with GGUF format models
- Runs inference on-device without sending prompts to a remote server
- Speech-to-text support for voice input
- Simple chat UI built in Flutter
- Reuses saved model files across app launches

## How it works

1. The model setup screen checks the application support directory for a saved GGUF model.
2. If the model does not exist, it downloads it from Hugging Face.
3. The model is validated and stored locally.
4. The app loads the model and generates responses directly on the device.

## Requirements

- Flutter SDK 3.10.1 or newer
- Android Studio / Android SDK
- A device or emulator running Android
- Internet connection for the initial model download
- Enough storage for the downloaded model (approximately 350 MB for the current model)

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
├── ios/
├── lib/
│   ├── app.dart
│   ├── features/
│   │   └── chat/
│   │       ├── presentation/
│   │       └── service/
│   └── utils/
├── macos/
├── test/
├── web/
├── windows/
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── .gitignore
```

## Model behavior

The current implementation downloads the Qwen model on first launch and caches it locally. This minimizes repeated network usage while keeping the app usable offline after the model is already available.

## Contributing

Contributions are welcome. If you want to improve the app, please open an issue or submit a pull request with a clear description of the change.

## License

This project is currently unlicensed. If you plan to share or distribute it publicly, consider adding an appropriate license file such as MIT or Apache 2.0.
