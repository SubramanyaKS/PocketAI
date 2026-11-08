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

- **Local-first AI Chat**: Real-time streaming token generation with full SQLite conversation history persistence.
- **Voice Assistant & Hands-Free Mode**: Conversational voice pipeline (STT ➔ on-device LLM ➔ low-latency streaming TTS) with an animated glowing orb, rotating ambient rings, live audio waveform equalizer, and auto-continuous hands-free loop with silence detection and tap-to-interrupt.
- **Offline Device Action Tools & Registry**:
  - 🧩 **Central Tool Registry**: Unified, extensible architecture (`PocketTool` contract + `ToolRegistry`) dispatching instant device commands without LLM latency or hallucination.
  - ⏰ **Native Android Clock Alarms & Timers**: Set, stop, or dismiss system alarms and countdown timers in the phone's native Clock app via Android intents (*"Set an alarm for 7:30 AM"*, *"Stop the alarm"*, *"Set a timer for 15 minutes"*, *"Cancel timer"*).
  - 🔋 **Battery Diagnostics**: Check live battery percentage and charging status completely offline (*"What's my battery percentage?"*, *"Check battery status"*).
  - 🔦 **Flashlight / Torch Control**: Turn on, turn off, or toggle the device flashlight completely offline (*"Turn on flashlight"*, *"Flashlight off"*).
  - 📅 **Scheduled Reminders**: Natural language reminder alerts scheduled with `flutter_local_notifications` and persisted to SQLite (*"Remind me to drink water in 10 minutes"*).
  - 🧮 **Deterministic Offline Calculator**: Exact arithmetic evaluation, percentages, powers, and roots evaluated in <1ms without LLM hallucination (*"What is 15% of 80?"*, *"Calculate 1500 / 12"*, *"2 to the power of 8"*).
  - 🚀 **Application Launcher**: Instant app opening via Android intents (*"Open YouTube"*, *"Launch Camera"*, *"Open WhatsApp"*, *"Open Maps"*, *"Open Browser"*, *"Open Spotify"*).
  - ⚙️ **System Settings Shortcuts**: Direct navigation to Android settings panels without searching (*"Open Wi-Fi settings"*, *"Open Bluetooth"*, *"Open Display settings"*, *"Volume settings"*).
- **Multi-Model Manager & Storage Control**: Select, hot-swap, and delete models on-device (SmolLM2-360M, Qwen2.5-0.5B, Qwen3-0.6B, Qwen2.5-1.5B). Inactive models stay on disk for instant offline switching, with one-tap deletion from Settings to reclaim phone storage. Model catalog is decoupled into `assets/models/model_catalog.json` as the single source of truth.
- **Zero-Cloud Privacy & Security**: 100% on-device CPU inference (no prompt or conversation data leaves your phone), enforced on-device speech recognition (`onDevice: true`), sandboxed local SQLite database with `android:allowBackup="false"` (no automated cloud or ADB extraction), zero telemetry or tracking SDKs, and a one-tap permanent "Wipe All Chat History" in Settings.
- **Dynamic Role-Tailored System Prompts**: Specialized persona instructions optimized for text chat (markdown/bullets) vs. voice mode (concise spoken sentences without emojis or asterisks).
- **Rich Markdown & Syntax Highlighting**: Assistant responses render formatted Markdown (headers, bullet lists, blockquotes, tables) with dedicated syntax-highlighted code blocks, language badge tags, horizontal scroll, and an animated "Copy" button.
- **Riverpod Theme Engine**: Complete light and dark mode support with system default following, controllable via dedicated Settings.
- **Speech Input & Synthesis**: Speech recognition and natural speech playback via `speech_to_text` and `flutter_tts`; availability depends on the device's configured speech services.
- **Automatic Model Download & Caching**: The GGUF model is downloaded once, checked for its GGUF header, and reused on subsequent launches.
- **On-Device Inference**: Prompts are processed by the local model. Internet is required to download the model if it is not already cached.
- **Diagnostics & Telemetry**: Logs TTFT (Time-To-First-Token), visible characters/words per second, and inference latency.

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

## Project structure and documentation

```text
lib/       # Flutter app, feature screens, services, and device integrations
test/      # Widget and unit tests
assets/    # App icon and other bundled assets
```

For the full source layout, dependency roles, runtime flows, data storage, and
the architecture diagram, see the [developer documentation](docs/README.md)
and [architecture guide](docs/architecture.md).


## Future Roadmap

Pocket AI is actively evolving towards a full-featured offline assistant:
- [x] **Offline Device Tools & Central Registry**: Flashlight / torch controls, battery diagnostics, scheduled reminders, and native alarms & timers routed through `ToolRegistry`.
- [x] **Offline Alarms & Timers**: Trigger system clock alarms and countdown timers via native Android intents directly from voice or chat commands.
- [x] **Low-Latency Streaming TTS**: Sentence-by-sentence audio playback for instant voice replies.
- [x] **Auto-Continuous Conversation & Barge-in**: Hands-free conversation loop with silence timeout, verbal exit detection, and tap-to-interrupt.
- [x] **Multi-Model Catalog & Storage Manager**: Choose, hot-swap, and delete GGUF models on-device (SmolLM2-360M, Qwen2.5-0.5B, Qwen3-0.6B, Qwen2.5-1.5B) directly in Settings.
- [x] **Live Mic Amplitude Equalizer & Visualizer**: 24-band animated waveform bars and glowing orb dynamically scaled by real-time microphone RMS volume.
- [x] **Zero-Cloud Privacy & Security**: Enforced on-device speech recognition (`onDevice: true`), `android:allowBackup="false"`, zero telemetry, and permanent data wipe in Settings.
- [ ] **Offline Document Chat (RAG)**: Private on-device Q&A for local PDFs and notes.
- [x] **Markdown & Code Highlighting**: Rich formatting, syntax highlighting, language badges, and one-tap copy button in chat.

## Model behavior

The current implementation downloads `Qwen3-0.6B-Q8_0.gguf` on first launch and caches it in the app support directory under `models/`. The service checks the GGUF header and computes a streaming cryptographic SHA-256 digest to verify supply-chain model integrity before loading it into llamadart. Inference uses a 2,048-token context, four generation threads, and configurable max token limits (256 tokens for chat, 120 tokens for voice assistant) with specialized system prompts. Subsequent launches reuse the cached file; model download and initialization timing and file size are written to debug logs.

## Inference package migration

The inference service uses `llamadart` for model loading and streamed generation; `llama_flutter_android` has been removed. The existing Dio-based model download, progress reporting, GGUF validation, and cache location are unchanged. `llamadart` requires Dart 3.10.7 or newer and Flutter 3.38.0 or newer.

## Contributing

Contributions are welcome. If you want to improve the app, please open an issue or submit a pull request with a clear description of the change.

## License

This project is currently unlicensed. If you plan to share or distribute it publicly, consider adding an appropriate license file such as MIT or Apache 2.0.
