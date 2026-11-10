# Changelog

All notable changes to the **Arivu AI** (ಅರಿವು AI) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-10

### Added
- **Core On-Device AI Engine**:
  - Embedded `llama.cpp` machine learning runtime via `llamadart` executing quantized GGUF language models directly on mobile CPU with zero cloud dependencies.
  - Decoupled single-source-of-truth model catalog ([`assets/models/model_catalog.json`](assets/models/model_catalog.json)) supporting 5 open-weight models:
    - *SmolLM2 360M Instruct* (386 MB, Ultra-Fast & Voice)
    - *SmolLM2 1.7B Instruct* (1.05 GB, 4-bit Edge Intelligence)
    - *Qwen2.5 0.5B Instruct* (524 MB, Compact & Multilingual)
    - *Qwen3 0.6B Q8_0* (639 MB, Default boot model)
    - *Qwen2.5 1.5B Instruct* (1.03 GB, High Intelligence & Code)
  - Supply-chain security verification with GGUF binary magic header check (`0x47, 0x47, 0x55, 0x46`) and streaming SHA-256 cryptographic digest matching.
  - Multi-model storage manager with on-device hot-swapping and one-tap inactive model deletion in Settings to reclaim phone storage.

- **Inference Parameter Tuning in Settings**:
  - Configurable CPU generation threads (`1`, `2`, `4`, `6`, `8`) with dynamic live reload on active models without app restart.
  - Continuous sampling temperature slider (`0.0`–`1.0`) with real-time semantic badges (*Strict*, *Balanced*, *Creative*).
  - Context window size selection chips (`1K Eco`, `2K Default`, `4K Deep`).
  - Max generation token caps (`128`, `256`, `512`, `1024`).
  - Persistent storage in `inference_config.json` and a one-tap *Reset Defaults* action.

- **Full-Duplex Conversational Voice Assistant**:
  - Sentence-by-sentence streaming audio playback queue with delimiter-based buffering (`.`, `?`, `!`, `\n`) minimizing voice latency to `<1.5s`.
  - Auto-continuous hands-free dialogue loop with automatic microphone reactivation, silence timeout, and voice exit commands (*"stop"*, *"exit"*, *"quit"*).
  - Tap-to-interrupt (barge-in) instantly terminating audio playback and switching back to speech listening.
  - Live audio visualizer featuring 24-band animated waveform bars and responsive glowing orb dynamically scaled by real-time microphone RMS volume via `onSoundLevelChange` with exponential smoothing.
  - Enforced on-device speech recognition (`onDevice: true`).

- **Central Tool Registry & Deterministic Offline Tools**:
  - Central dispatcher `ToolRegistry` and extensible `PocketTool` contract executing device commands in `<1ms` without LLM latency or hallucination.
  - Native Android Clock alarms and countdown timers via `android_intent_plus` intents (`ACTION_SET_ALARM`, `ACTION_SET_TIMER`, `ACTION_DISMISS_ALARM`).
  - Exact scheduled reminders with `flutter_local_notifications` and timezone support, persisted to internal SQLite.
  - Deterministic offline arithmetic calculator with recursive descent parser evaluating PEMDAS operations, floating points, percentages, powers, and roots.
  - Application launcher for common Android apps (Camera, YouTube, Maps, WhatsApp, Chrome, Gallery, Email, Dialer, Messages, Spotify).
  - System settings shortcuts (Wi-Fi, Bluetooth, Display, Sound, Battery, Location, Airplane Mode).
  - Hardware camera flashlight control via `torch_light` and live battery diagnostics via `battery_plus`.

- **Offline Document Chat (Local RAG)**:
  - Local document ingestion supporting `.pdf`, `.txt`, and `.md` attachments directly in chat.
  - Pure Dart PDF text extraction via `syncfusion_flutter_pdf` with zero cloud or OS PDF dependencies.
  - Overlapping semantic boundary chunking (~600 chars with 80-char overlap).
  - Fast in-memory BM25 relevance retrieval (<2ms) with English stopword filtering.
  - Grounded anti-hallucination system prompt injection with interactive attachment chip displaying name, size, and chunk count.

- **Conversation Search & Chat Export**:
  - Full-text keyword search across chat titles and message history in the drawer with live query filtering and matching snippet previews.
  - Formatted Markdown (`.md`) transcript generation via `ChatExportService`.
  - Native Android share sheet integration (`share_plus`) and one-tap clipboard copy.

- **Zero-Cloud Privacy & Security**:
  - Sandboxed local SQLite database (`chat_history.db`) in private internal storage.
  - `android:allowBackup="false"` in `AndroidManifest.xml` preventing automated cloud extraction.
  - One-tap permanent *Wipe All Chat History* in Settings.
  - Zero telemetry, analytics SDKs, or ad tracking.

- **Licensing & Legal**:
  - Apache License, Version 2.0 with a 4-part Supplemental AI & Hardware Safety Addendum covering AI hallucination disclaimers, hardware automation actions, third-party model weights, and air-gapped security.
