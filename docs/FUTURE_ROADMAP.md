# Pocket AI — Future Roadmap & Architecture Plan

Here is the updated roadmap and milestone status for taking **Pocket AI** from a prototype to a full-featured, high-performance offline AI assistant.

---

## Completed Milestones & Implemented Features

### 1. Offline LLM Inference & Multi-Model Engine
- [x] **Local GGUF Inference**: On-device 4-thread CPU execution via `llamadart` (`llama.cpp`) with 2,048-token context window.
- [x] **Supply-Chain Integrity**: GGUF binary magic header validation (`0x47, 0x47, 0x55, 0x46`) and streaming SHA-256 cryptographic verification.
- [x] **Multi-Model Catalog**: Curated model specs (SmolLM2-360M, Qwen2.5-0.5B, Qwen3-0.6B, Qwen2.5-1.5B) decoupled into [`assets/models/model_catalog.json`](../assets/models/model_catalog.json) as the single source of truth.
- [x] **RAM Hot-Swapping & Disk Management**: Switch active model dynamically in RAM with safe cleanup, and delete inactive models from disk in Settings to reclaim phone storage.

### 2. Full-Duplex Voice Assistant
- [x] **Streaming Sentence-by-Sentence Audio Playback**: Delimiter token buffer (`.`, `?`, `!`, `\n`) sequentially queues sentences to `flutter_tts` for instant sub-second spoken replies.
- [x] **Auto-Continuous Hands-Free Dialogue Loop**: Automatic microphone reactivation with silence timeout and verbal exit commands (*"stop"*, *"exit"*, *"quit"*).
- [x] **Tap-to-Interrupt / Barge-In**: Tapping the glowing orb cuts off TTS playback immediately and switches to listening.
- [x] **Live Mic Amplitude Equalizer**: 24-band center-weighted Gaussian wave bars and glowing orb bloom dynamically scaled by real-time microphone RMS volume via `onSoundLevelChange` with exponential smoothing.
- [x] **Enforced On-Device Speech Recognition**: `onDevice: true` in `SpeechListenOptions` guarantees voice audio stays strictly offline on the user's phone.

### 3. Central Tool Registry & Offline Device Actions
- [x] **Polymorphic Tool Contract**: Extensible `PocketTool` interface with central `ToolRegistry` dispatching commands in <1ms without LLM latency or hallucination.
- [x] **Native Android Alarms & Timers**: Set, stop, or dismiss system clock alarms and timers via `android_intent_plus` intents (`AlarmClock.ACTION_SET_ALARM`, `ACTION_SET_TIMER`, `ACTION_DISMISS_ALARM`).
- [x] **Scheduled Reminders**: Exact device reminders with `flutter_local_notifications` and timezone support, persisted to SQLite.
- [x] **Deterministic Offline Calculator**: Recursive descent parser for exact arithmetic, order of operations (PEMDAS), powers, square roots, and natural language percentage queries.
- [x] **Application Launcher**: Intent dispatcher for Camera, YouTube, Maps, WhatsApp, Chrome, Gallery, Email, Dialer, Messages, and Spotify.
- [x] **System Settings Shortcuts**: Direct navigation to Android settings panels (Wi-Fi, Bluetooth, Display, Sound, Battery, Location, Airplane Mode).
- [x] **Hardware Flashlight & Battery**: Camera torch control via `torch_light` and battery diagnostics via `battery_plus`.

### 4. Chat Presentation & Theming
- [x] **Rich Markdown & Syntax Highlighting**: Formatted markdown (headers, tables, blockquotes) with syntax-highlighted code blocks, language badges, and one-tap copy button (`flutter_markdown_plus` + `flutter_highlighter`).
- [x] **Global Riverpod Theming**: System default, Light mode, and OLED Dark mode themes.
- [x] **Dynamic Role-Tailored System Prompts**: Specialized persona instructions for text chat (markdown/bullets) vs. voice mode (concise spoken sentences without emojis or asterisks).

### 5. Zero-Cloud Privacy & Security
- [x] **Sandboxed Local Storage**: All messages, conversations, and reminders stored in private internal SQLite (`chat_history.db`).
- [x] **Cloud Backup Guard**: `android:allowBackup="false"` in `AndroidManifest.xml` prevents automated Google cloud backups or ADB data extraction.
- [x] **One-Tap Permanent Data Wipe**: "Wipe All Chat History" in Settings permanently erases the SQLite database with confirmation guard.
- [x] **Zero Telemetry**: No tracking SDKs, no analytics, no ad networks.

### 6. Offline Document Chat (Local RAG)
- [x] **Local Document Ingestion**: Attach local `.pdf`, `.txt`, and `.md` files via `file_picker` directly in chat.
- [x] **Pure Dart PDF Parsing**: Instant on-device text extraction via `syncfusion_flutter_pdf` with zero cloud or native OS PDF dependencies.
- [x] **Semantic Chunking & Overlap**: Splits documents into ~600-character chunks with 80-character boundary overlap respecting paragraph and sentence boundaries.
- [x] **In-Memory BM25 Relevance Search**: Pure Dart keyword matching with English stopword filtering evaluates chunk rankings in <2ms.
- [x] **Strict Context Grounding**: Injects top retrieved excerpts with anti-hallucination guardrails into the LLM system prompt (`buildRagSystemPrompt`).
- [x] **Interactive Document Chip**: Shows document name, formatted size, chunk count, and one-tap detachment button above the chat input box.

---

## Upcoming Phases & Planned Features

### Phase 7: Hardware Acceleration & Performance Tuning
- **Inference Performance Controls in Settings**: User-configurable CPU generation threads (`2`, `4`, `6`, `8`) and context window size (`1K`, `2K`, `4K`).
- **Hardware Acceleration**: Enable OpenCL / Vulkan / NPU backends on supported Android chipsets (Snapdragon / MediaTek) via `llama.cpp` compilation flags for 2x-4x tokens/second.
- **Background Keep-Alive**: Lifecycle management so switching apps during long generations doesn't abort inference.

### Phase 8: Conversation Management
- **Conversation Search**: Search past chat sessions by keyword in the history drawer.
- **Export & Share**: One-tap export of conversation transcripts as Markdown (`.md`) or plain text.

---

## Roadmap Milestone Tracker

| Phase | Milestone | Focus Area | Status |
|---|---|---|---|
| **Phase 1** | **Streaming TTS & Hands-Free Loop** | Voice Assistant | **Completed** |
| **Phase 2** | **Offline Alarms, Timers, Tools & Device Controls** | Device Tasks | **Completed** |
| **Phase 3** | **Markdown & Code Syntax Highlighting** | Chat Screen | **Completed** |
| **Phase 4** | **Multi-Model Manager & Decoupled JSON Catalog** | Core AI | **Completed** |
| **Phase 5** | **Live Mic Amplitude Equalizer & Security Enhancements** | Voice & Privacy | **Completed** |
| **Phase 6** | **Offline Document Chat (Local RAG)** | Local Knowledge | **Completed** |
| **Phase 7** | **Inference Controls & Hardware Acceleration** | Performance | **Next Priority** |
| **Phase 8** | **Conversation Search & Export** | Productivity | Planned |
