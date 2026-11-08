# Pocket AI Developer Documentation

Welcome to the Pocket AI developer documentation. Pocket AI is an offline-first mobile AI assistant built with Flutter and embedded `llama.cpp` (`llamadart`).

---

## 📚 Documentation Index

1. **[Architecture & Technical Specifications](architecture.md)**
   - High-Level Multi-Tier Component Diagram
   - Model Preparation, Validation, and Lifecycle Flow
   - Tool Interception & Deterministic Execution Pipeline
   - Full-Duplex Voice Assistant Sequence Diagram
   - SQLite Schema & Entity-Relationship Diagram (ERD)
   - Android Permissions & Hardware Guard Matrix

2. **[Project Overview & Quickstart](../README.md)**
   - Prerequisites & Setup Guide
   - Feature Highlights
   - Build & Run Instructions

3. **[Future Project Roadmap](FUTURE_ROADMAP.md)**
   - Completed Milestones
   - Upcoming Engineering Phases (RAG, Streaming Audio Queue, Multi-Model Manager)

---

## 🗂️ Clean Source Directory Structure

```text
lib/
├── main.dart                           # Flutter bindings & notification initialization
├── app.dart                            # MaterialApp root, route setup & theme definitions
│
├── provider/
│   └── theme_provider.dart             # Riverpod ThemeNotifier (System / Light / Dark)
│
├── llm/
│   └── tool_definitions.dart           # Offline function schemas for reminder & torch
│
├── tools/
│   ├── pocket_tool.dart                # Abstract PocketTool contract (name, definition, tryExecute)
│   ├── tool_registry.dart              # Central tool dispatcher & schema aggregation hub
│   ├── alarm_tool.dart                 # Native Android Clock alarms & timers via Intent Plus
│   ├── app_launcher_tool.dart          # Launch Camera, YouTube, Maps, WhatsApp, etc.
│   ├── battery_tool.dart               # Battery level & charging status diagnostics
│   ├── calculator_tool.dart            # Exact offline arithmetic, percentage & power evaluator
│   ├── device_settings_tool.dart       # Wi-Fi, Bluetooth, Display, Sound settings shortcuts
│   ├── remainder_tools.dart            # Local notification & alarm scheduling service
│   ├── reminder_parser.dart            # Offline natural language regex intent extractor
│   └── torch_tool.dart                 # Device camera flashlight hardware controller
│
├── features/
│   ├── model/
│   │   ├── models/
│   │   │   ├── model_spec.dart         # Model entity (id, size, url, RAM reqs)
│   │   │   └── model_catalog.dart      # Curated catalog (SmolLM2, Qwen2.5, Qwen3)
│   │   └── presentation/
│   │       └── model_setup_screen.dart # Download progress & model preparation screen
│   │
│   ├── home/presentation/
│   │   ├── home_screen.dart            # Tab scaffold & bottom navigation bar
│   │   └── welcome_screen.dart         # Initial onboard welcome widget
│   │
│   ├── chat/
│   │   ├── models/
│   │   │   ├── chat_message.dart       # Message entity (role, content, timestamp)
│   │   │   └── performance_metrics.dart# Diagnostics (TTFT, tokens/sec, throughput)
│   │   ├── presentation/
│   │   │   └── chat_screen.dart        # Chat UI, history drawer & message dispatcher
│   │   ├── service/
│   │   │   ├── chat_database.dart      # SQLite database (conversations, messages, reminders)
│   │   │   ├── chat_utils.dart         # Context pruning & title truncation utilities
│   │   │   ├── local_ai_service.dart   # LlamaEngine wrapper, streaming & prompt manager
│   │   │   └── think_filter.dart       # DeepSeek/Qwen <think> tag stream sanitizer
│   │   └── widgets/
│   │       ├── chat_empty_widget.dart  # Empty state with ready-to-test starter prompts
│   │       └── prompt_suggestion.dart  # Interactive suggestion chip component
│   │
│   ├── assistant/presentation/
│   │   ├── voice_assistant_screen.dart # Interactive voice UI with animated orb & wave bars
│   │   └── voice_utils.dart            # Spoken text sanitization & visual state styling
│   │
│   └── settings/presentation/
│       ├── settings_screen.dart        # Appearance & model storage settings
│       └── manage_models_screen.dart   # Model catalog, hot-swap & delete manager
│
└── utils/
    ├── constant.dart                   # GGUF download URL, filename & storage constants
    └── theme.dart                      # Core color palettes & text styling rules
```

---

## ⚙️ Core Technology Stack

| Domain | Technology / Package | Role & Responsibility |
|---|---|---|
| **Language & Framework** | Dart 3.10+ / Flutter 3.38+ | Cross-platform core framework |
| **Local Model Engine** | `llamadart` (`llama.cpp`) | On-device 4-thread CPU GGUF inference |
| **Model Download & Cache** | `dio` + `path_provider` | Download with progress & local file storage |
| **State Management** | `flutter_riverpod` | Unified theme state management |
| **Persistence** | `sqflite` + `path` | Local SQLite database (`chat_history.db`) |
| **Speech-to-Text** | `speech_to_text` | Real-time speech dictation and transcription |
| **Text-to-Speech** | `flutter_tts` | Offline voice audio synthesis |
| **Notifications & Alarms** | `flutter_local_notifications` + `timezone` | Exact alarms, device reboots & reminder alerts |
| **Device Battery & Power** | `battery_plus` | Hardware battery level & charging state |
| **Hardware Flashlight** | `torch_light` | Device camera LED control |
| **System Alarms & Timers** | `android_intent_plus` | Android native Clock app intent dispatching |
| **Integrity & Security** | `crypto` | Streaming SHA-256 model supply-chain verification |
| **Markdown Rendering** | `flutter_markdown_plus` + `markdown` | Markdown parsing for assistant replies |
| **Code Syntax Highlighting** | `flutter_highlighter` | Language syntax highlighter & themes |

---

## 🧪 Local Quality & Testing

To ensure stability across the pipeline, run the project analysis and test suite:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (enforces lint rules and type safety)
flutter analyze

# 3. Execute unit and widget tests
flutter test
```
