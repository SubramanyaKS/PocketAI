# Pocket AI — System Architecture & Technical Specifications

Pocket AI is architected as an offline-first, on-device mobile AI assistant. It integrates native embedded `llama.cpp` machine learning inference via `llamadart`, device-native hardware control, local SQLite data persistence, and an interactive voice pipeline.

---

## 1. High-Level Architecture Overview

```mermaid
flowchart TD
    subgraph UI_Layer ["Presentation & UI Layer"]
        App["PocketAiApp<br/>(Theme & Navigation Root)"]
        SetupScreen["ModelSetupScreen<br/>(Download & Initialization UI)"]
        HomeScreen["HomeScreen<br/>(Tab Shell Navigation)"]
        ChatScreen["ChatScreen<br/>(MarkdownBody, CodeBlockWidget & Prompts)"]
        VoiceScreen["VoiceAssistantScreen<br/>(Orb, Waves & Hands-Free Flow)"]
        SettingsScreen["SettingsScreen<br/>(Theme, Model Storage & Settings)"]
        ManageModelsScreen["ManageModelsScreen<br/>(Model Catalog, Hot-Swap & Delete UI)"]
    end

    subgraph State_Layer ["State Management"]
        RiverpodScope["ProviderScope"]
        ThemeState["themeProvider<br/>(ThemeNotifier: System / Light / Dark)"]
    end

    subgraph Service_Layer ["Core Services & Tool Orchestration"]
        AI["LocalAiService<br/>(Model Manager & Inference Streamer)"]
        Think["ThinkFilter<br/>(CoT / &lt;think&gt; Stream Sanitizer)"]
        ChatUtils["ChatUtils<br/>(Context Pruning & Title Truncation)"]
        VoiceUtils["VoiceUtils<br/>(Spoken Text Sanitizer & State Styling)"]
        Registry["ToolRegistry<br/>(Central Tool Dispatcher & Schema Aggregator)"]
        PocketContract["PocketTool Contract<br/>(Polymorphic Tool Execution)"]
        ReminderHandler["ReminderTool<br/>(Regex / Deterministic Intent Matcher)"]
        Notifier["NotificationService<br/>(Timezone-Aware Scheduled Alarms)"]
        Torch["TorchTool<br/>(Camera Flash Hardware Controller)"]
        Battery["BatteryTool<br/>(Level & Charging Status Reader)"]
        AlarmTimer["AlarmTimerTool<br/>(Native Android Clock & Timer Intent Dispatcher)"]
        Calculator["CalculatorTool<br/>(Deterministic Offline Math & Percentage Parser)"]
        DevSettings["DeviceSettingsTool<br/>(Wi-Fi, Bluetooth, Display, Sound Panels)"]
        AppLauncher["AppLauncherTool<br/>(Camera, YouTube, Maps, WhatsApp Launchers)"]
        DocService["DocumentService<br/>(Text Extraction, Chunking & BM25 Retrieval)"]
        ExportService["ChatExportService<br/>(Markdown Formatter & Share Sheet)"]
    end

    subgraph Native_Layer ["Native Platforms & Device Hardware"]
        LlamaEngine["llamadart / llama.cpp<br/>(C++ Engine: CPU / 4 Threads)"]
        SQLite["SQLite Database<br/>(chat_history.db via sqflite)"]
        LocalFS["Local App Storage<br/>(models/Qwen3-0.6B-Q8_0.gguf)"]
        STT["Device Speech Recognizer<br/>(speech_to_text)"]
        TTS["Device Speech Synthesizer<br/>(flutter_tts)"]
        AlarmMgr["Android AlarmManager & Receivers<br/>(ScheduledNotificationReceiver)"]
        CameraFlash["Hardware Flash LED<br/>(torch_light)"]
        BatteryHW["Battery Hardware & Broadcast<br/>(battery_plus)"]
        ClockApp["Android System Clock App<br/>(ACTION_SET_ALARM / ACTION_SET_TIMER)"]
    end

    subgraph External_Network ["Remote Services (One-Time Only)"]
        HF["Hugging Face Hub<br/>(Initial GGUF Model Download)"]
    end

    App --> RiverpodScope
    RiverpodScope --> ThemeState
    App --> SetupScreen
    SetupScreen -->|On Cache Miss| HF
    HF -->|Stream .part & Validate Header| LocalFS
    LocalFS -->|Load Weights| LlamaEngine
    SetupScreen -->|Model Ready: Pass LocalAiService| HomeScreen
    
    HomeScreen --> ChatScreen
    HomeScreen --> VoiceScreen
    SettingsScreen -.->|Mutates State| ThemeState
    SettingsScreen --> ManageModelsScreen
    ManageModelsScreen -->|Switch / Delete Model| AI
    ThemeState -.->|Rebuilds UI| App

    ChatScreen -->|Context Window| ChatUtils
    ChatScreen -->|Intercept Intent| Registry
    ChatScreen -->|Attach & Grounded RAG| DocService
    ChatScreen -->|Export & Share| ExportService
    ChatScreen -->|Fallback / General Query| AI

    VoiceScreen -->|Voice Input| STT
    VoiceScreen -->|Speech Cleansing| VoiceUtils
    VoiceScreen -->|Intercept Intent| Registry
    VoiceScreen -->|Fallback / General Query| AI
    VoiceScreen -->|Read Aloud| TTS

    Registry --> PocketContract
    PocketContract --> Torch
    PocketContract --> ReminderHandler
    PocketContract --> Battery
    PocketContract --> AlarmTimer
    PocketContract --> Calculator
    PocketContract --> DevSettings
    PocketContract --> AppLauncher

    AI --> Think
    AI --> LlamaEngine
    LlamaEngine -->|Token Chunks| Think
    Think -->|Sanitized Stream| ChatScreen
    Think -->|Sanitized Stream| VoiceScreen

    ReminderHandler -->|Schedule Reminder| Notifier
    Notifier --> AlarmMgr
    Notifier -->|Record Reminder| SQLite
    Torch --> CameraFlash
    Battery --> BatteryHW
    AlarmTimer -->|Launch Intent| ClockApp
    ChatScreen -->|Persist Turn| SQLite
```

---

## 2. Model Preparation & Initialization Flow

When Pocket AI launches, it ensures valid weights are present locally before presenting chat or voice interfaces.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as PocketAiApp
    participant Setup as ModelSetupScreen
    participant Service as LocalAiService
    participant FS as Local FileSystem
    participant HF as Hugging Face CDN
    participant Engine as LlamaEngine (llama.cpp)
    participant Home as HomeScreen

    User->>App: Launch Application
    App->>Setup: Display Model Setup Screen
    Setup->>Service: loadModel(onDownloadProgress)
    Service->>FS: Check models/Qwen3-0.6B-Q8_0.gguf
    
    alt Model Exists & Has GGUF Magic Header
        FS-->>Service: Valid GGUF Header Verified (0x47, 0x47, 0x55, 0x46)
    else Cache Miss or Corrupt Header
        Service->>FS: Remove incomplete artifacts
        Service->>HF: Download GGUF via Dio (Qwen3-0.6B-Q8_0.gguf)
        HF-->>Setup: Emit progress percentage (0-100%)
        HF-->>Service: Complete download to .part file
        Service->>Service: Validate GGUF header on .part
        Service->>Service: Verify SHA-256 cryptographic digest (streaming chunked hash)
        Service->>FS: Atomic rename .part -> final .gguf
    end

    Service->>Engine: setModel(ModelSource.path, contextSize: 2048, threads: 4)
    Engine-->>Service: Native Model Loaded
    Service-->>Setup: _isLoaded = true
    Setup->>Home: Navigate to HomeScreen(aiService: service)
```

---

## 3. End-to-End Chat & Tool Interception Pipeline

User prompts undergo deterministic intent interception via `ToolRegistry` before routing to the LLM. This prevents hallucination for device actions, ensures immediate execution, and conserves mobile battery.

```mermaid
flowchart TD
    Input([User Prompt Submitted]) --> Dispatch[ToolRegistry.dispatch: Iterate Registered PocketTools]
    
    Dispatch --> CheckTorch{Matches TorchTool?<br/>e.g., 'turn on flashlight'}
    CheckTorch -- Yes --> ExecTorch[TorchTool: Hardware Flash LED Toggled]
    ExecTorch --> ReturnTorchReply[Return Flashlight Confirmation]
    ReturnTorchReply --> DisplayBubble[Render UI Message / Read Out Loud]

    CheckTorch -- No --> CheckReminder{Matches ReminderTool?<br/>e.g., 'remind me in 10m'}
    CheckReminder -- Yes --> ExecReminder[ReminderTool: Schedule Local Alarm]
    ExecReminder --> SchedNotif[NotificationService: Schedule Local Notification]
    SchedNotif --> SaveRemindDB[(SQLite: Save to reminders table)]
    SaveRemindDB --> ReturnRemindReply[Return Reminder Confirmation]
    ReturnRemindReply --> DisplayBubble

    CheckReminder -- No --> CheckBattery{Matches BatteryTool?<br/>e.g., 'check battery'}
    CheckBattery -- Yes --> ExecBattery[BatteryTool: Read Battery Level & State]
    ExecBattery --> ReturnBatReply[Return Battery Percentage & State]
    ReturnBatReply --> DisplayBubble

    CheckBattery -- No --> CheckAlarm{Matches AlarmTimerTool?<br/>e.g., 'set alarm 7am', 'timer 10m'}
    CheckAlarm -- Yes --> ExecAlarm[AlarmTimerTool: Fire System Intent]
    ExecAlarm --> ClockAppAction[ACTION_SET_ALARM / ACTION_SET_TIMER]
    ClockAppAction --> ReturnAlarmReply[Return Alarm / Timer Confirmation]
    ReturnAlarmReply --> DisplayBubble

    CheckAlarm -- No --> CheckCalc{Matches CalculatorTool?<br/>e.g., '15% of 80', '25 * 4'}
    CheckCalc -- Yes --> ExecCalc[CalculatorTool: Pure Dart Recursive Descent Parser]
    ExecCalc --> ReturnCalcReply[Return Exact Arithmetic Result]
    ReturnCalcReply --> DisplayBubble

    CheckCalc -- No --> CheckSettings{Matches DeviceSettingsTool?<br/>e.g., 'open wifi', 'bluetooth settings'}
    CheckSettings -- Yes --> ExecSettings[DeviceSettingsTool: Launch android.settings Intent]
    ExecSettings --> ReturnSettingsReply[Return Settings Launch Confirmation]
    ReturnSettingsReply --> DisplayBubble

    CheckSettings -- No --> CheckLauncher{Matches AppLauncherTool?<br/>e.g., 'open youtube', 'open camera'}
    CheckLauncher -- Yes --> ExecLauncher[AppLauncherTool: Launch App Package / Intent]
    ExecLauncher --> ReturnLauncherReply[Return App Launch Confirmation]
    ReturnLauncherReply --> DisplayBubble

    CheckLauncher -- No --> FormatContext[ChatUtils: Prune & Build Context Window]
    FormatContext --> SystemPrompt[Inject Role-Tailored System Prompt]
    SystemPrompt --> StreamGen[LocalAiService.askStream]
    StreamGen --> Filter[ThinkFilter: Strip &lt;think&gt; tags]
    Filter --> RenderChunk[Stream Tokens to Screen / TTS]
    RenderChunk --> SaveChatDB[(SQLite: Save to messages table)]
```

---

## 4. Full-Duplex Voice Assistant Execution Sequence

The voice pipeline connects Speech-to-Text, intent parsing, on-device streaming LLM inference, and Text-to-Speech synthesis.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Mic as STT (speech_to_text)
    participant VoiceUI as VoiceAssistantScreen
    participant Registry as ToolRegistry (PocketTool Dispatcher)
    participant AI as LocalAiService
    participant Engine as llama.cpp Native Core
    participant Speaker as TTS (flutter_tts)

    User->>VoiceUI: Tap Orb (State: Listening)
    VoiceUI->>Mic: speech.listen(onDevice: true, onSoundLevelChange)
    Mic-->>VoiceUI: Live Audio RMS Amplitude Level (EMA smoothed)
    VoiceUI->>VoiceUI: Drive 24-Band Waveform Bars & Orb Bloom
    User->>Mic: Speaks voice command
    Mic-->>VoiceUI: Recognized Words Stream
    User->>VoiceUI: Silence or Tap Stop
    
    VoiceUI->>VoiceUI: Switch State: Thinking
    
    alt Matches Registered PocketTool (Torch / Reminder / Battery / Alarm / Timer / Calculator / Settings / Launcher)
        VoiceUI->>Registry: ToolRegistry.dispatch(prompt)
        Registry-->>VoiceUI: ToolExecutionResult(handled: true, reply)
        VoiceUI->>VoiceUI: Switch State: Speaking
        VoiceUI->>Speaker: flutter_tts.speak(reply)
    else Natural Language Query
        VoiceUI->>AI: askStream(conversation, defaultVoiceSystemPrompt, maxTokens: 120)
        AI->>Engine: Generate token stream (/no_think appended)
        loop Token Stream
            Engine-->>AI: Yield chunk
            AI-->>VoiceUI: Cleaned token chunk
            VoiceUI->>VoiceUI: Update Live Transcript
            opt First Complete Sentence (., ?, !)
                VoiceUI->>VoiceUI: Switch State: Speaking
                VoiceUI->>Speaker: Begin TTS Playback
            end
        end
    end

    Speaker-->>VoiceUI: On Completion Handler
    VoiceUI->>VoiceUI: Switch State: Idle (Ready for next prompt)
```

---

## 5. Local Data Storage & Schema Design

Pocket AI persists all user conversations, messages, and scheduled tasks in a local SQLite database (`chat_history.db`).

```mermaid
erDiagram
    CONVERSATIONS ||--o{ MESSAGES : "contains"
    CONVERSATIONS {
        INTEGER id PK "Auto Increment"
        TEXT title "First prompt summary (max 48 runes)"
        INTEGER created_at "Timestamp in ms"
        INTEGER updated_at "Timestamp in ms"
    }

    MESSAGES {
        INTEGER id PK "Auto Increment"
        INTEGER conversation_id FK "References conversations(id)"
        TEXT role "user | assistant | system"
        TEXT content "Message text content"
        INTEGER created_at "Timestamp in ms"
    }

    REMINDERS {
        INTEGER id PK "Millisecond hash identifier"
        TEXT title "Reminder task description"
        INTEGER scheduled_at "Target alarm timestamp in ms"
        INTEGER created_at "Creation timestamp in ms"
        INTEGER is_completed "0 = Pending, 1 = Completed"
    }
```

---

## 6. Offline Speech & Hardware Permissions Matrix

| Platform Feature | Android Permission | Fallback / Hardware Guard |
|---|---|---|
| **Audio Dictation** | `android.permission.RECORD_AUDIO` | Checks `speech.initialize()` availability |
| **Scheduled Reminders** | `android.permission.POST_NOTIFICATIONS` | `requestNotificationsPermission()` prompt on Android 13+ |
| **Exact Alarms** | `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` | Auto-downgrades from `alarmClock` to `exactAllowWhileIdle` |
| **Reboot Persistence** | `RECEIVE_BOOT_COMPLETED` | Handled by `ScheduledNotificationBootReceiver` |
| **Camera Flashlight** | `android.permission.CAMERA` | `TorchLight.isTorchAvailable()` pre-check |
| **Battery Diagnostics** | None (Standard OS Broadcast) | `BatteryTool.getBatteryInfo()` exception guard |
| **Native Alarms & Timers** | `com.android.alarm.permission.SET_ALARM` | Dispatches `ACTION_SET_ALARM`, `ACTION_SET_TIMER`, `ACTION_DISMISS_ALARM`, `ACTION_DISMISS_TIMER`, `ACTION_SHOW_ALARMS` via `android_intent_plus` (`SKIP_UI: true`) |
| **Deterministic Calculator** | None (Pure Dart Execution) | Evaluates arithmetic, percentages & powers in <1ms; gracefully handles division by zero and delegates non-math to LLM |
| **System Settings Shortcuts** | None (Standard Android Intents) | Dispatches `android.settings.*` intents (WIFI, BLUETOOTH, DISPLAY, SOUND, BATTERY) |
| **Application Launcher** | None (Standard Intent Action / Category) | Dispatches launcher intents for Camera, YouTube, Maps, WhatsApp, Chrome, Gallery, Email, Dialer, Messages, Spotify |
| **Local Document Ingestion & RAG** | None (In-Memory File Bytes) | Pure Dart parsing via `syncfusion_flutter_pdf`, boundary chunking & BM25 retrieval without network access |

---

## 7. Zero-Cloud Privacy & Data Security Architecture

Pocket AI enforces an uncompromising zero-cloud privacy architecture across all layers of the stack:

```mermaid
flowchart TD
    subgraph Device_Enclave ["Hardware & Sandbox Enclave"]
        Input["User Audio & Text"]
        STT["On-Device SpeechRecognizer<br/>(onDevice: true)"]
        RAM["RAM / CPU llama.cpp<br/>(llamadart local execution)"]
        DB[("Internal SQLite<br/>/data/data/.../chat_history.db<br/>allowBackup = false")]
        Wipe["Wipe Action<br/>(ChatDatabase.clearAllChatHistory)"]
    end

    subgraph Blocked_Cloud ["Blocked External Cloud Services"]
        NoCloud["No Telemetry / No Analytics / No Cloud LLMs"]
    end

    Input --> STT
    STT --> RAM
    Input --> RAM
    RAM --> DB
    Wipe -.->|Permanent deletion| DB
    DB x-.-x Blocked_Cloud
    RAM x-.-x Blocked_Cloud
```

### Key Security Safeguards:
1. **100% On-Device CPU Inference**: All prompt evaluations, token generation, and context management occur exclusively in local process memory via C++ `llama.cpp`. Zero prompt or completion data leaves the phone.
2. **Enforced Local Speech Recognition**: Voice recognition is configured with `onDevice: true`, instructing Android to use local speech recognition packages rather than cloud transcription servers.
3. **Internal Sandboxed Storage & No Cloud Backups**: The SQLite database (`chat_history.db`) is stored in Android's private app directory with `android:allowBackup="false"` in `AndroidManifest.xml`, preventing ADB extraction or Google Drive backups from exposing user messages.
4. **Permanent One-Tap Data Wipe**: The Settings screen provides an atomic `ChatDatabase.clearAllChatHistory()` action that permanently deletes all stored messages and conversations with confirmation guards.
5. **Supply Chain Verification**: Model files downloaded from Hugging Face are verified with binary GGUF magic bytes (`0x47, 0x47, 0x55, 0x46`) and SHA-256 cryptographic checksums before memory loading.
6. **Decoupled Model Catalog**: Model configurations are decoupled into [`assets/models/model_catalog.json`](../assets/models/model_catalog.json) as the single source of truth, loaded asynchronously at application boot.

---

## 8. Offline Document Chat & Local RAG Architecture

Pocket AI features a 100% on-device Retrieval-Augmented Generation (RAG) pipeline for document question answering without external vector databases, Python servers, or cloud embedding APIs:

```mermaid
flowchart TD
    DocFile["Local File<br/>(.pdf, .txt, .md)"]
    Picker["DocumentService.pickDocument()<br/>(file_picker)"]
    Extractor["Pure Dart Text Extractor<br/>(syncfusion_flutter_pdf / utf8)"]
    Chunker["Semantic Chunker<br/>(600 chars / 80 char overlap)"]
    MemoryDoc["AttachedDocument Model<br/>(In-Memory Chunks & Metadata)"]
    UserQuery["User Chat Prompt"]
    BM25["BM25 Relevance Scorer<br/>(Dart Term Frequency & Stopwords)"]
    TopChunks["Top Relevant Excerpts<br/>(Ranked 1 to 3)"]
    RAGPrompt["Grounded System Prompt<br/>(Strict Anti-Hallucination Rules)"]
    Llama["llama.cpp Local Inference Engine"]
    Answer["Streaming Grounded Answer"]

    DocFile --> Picker
    Picker --> Extractor
    Extractor --> Chunker
    Chunker --> MemoryDoc
    MemoryDoc --> BM25
    UserQuery --> BM25
    BM25 --> TopChunks
    TopChunks --> RAGPrompt
    RAGPrompt --> Llama
    UserQuery --> Llama
    Llama --> Answer
```

### Key RAG Pipeline Components:
1. **Zero-Cloud Ingestion**: Files (`.pdf`, `.txt`, `.md`) are read locally into process memory. No document content is uploaded or transmitted over the network.
2. **Pure Dart PDF Parsing**: Powered by `syncfusion_flutter_pdf`, which runs entirely in Dart without platform method channel overhead or native OS PDF dependencies.
3. **Paragraph & Sentence Chunking**: Documents are split along natural paragraph (`\n\n`) and sentence boundaries into ~600 character chunks with 80 character overlap to maintain semantic continuity.
4. **Pure Dart BM25 Retrieval**: Fast (<2ms) in-memory ranking with English stopword filtering and term-frequency scoring over candidate chunks, eliminating heavy ONNX runtime or cloud vector database dependencies.
5. **Strict Grounding & Anti-Hallucination Prompting**: Retrieved excerpts are formatted into a constrained system prompt instructing the local LLM to answer strictly from the excerpts and state clearly if information is absent.

---

## 9. Inference Parameters & Hardware Tuning Architecture

Pocket AI allows users to fine-tune CPU generation and sampling parameters directly on-device to balance throughput, battery consumption, and creativity:

```mermaid
flowchart TD
    UI["SettingsScreen (Inference Parameters Card)"]
    Service["LocalAiService"]
    Model["InferenceConfig Model"]
    Disk[("inference_config.json (AppSupportDirectory)")]
    Engine["LlamaEngine (llama.cpp)"]

    UI -->|User Selects Threads / Context / Temp / Tokens| Service
    Service -->|Update State & Notify Listeners| Model
    Service -->|Atomic Disk Persistence| Disk
    Service -->|Dynamic ModelParams Re-initialization| Engine
    Service -->|GenerationParams Temp / MaxTokens| Engine
```

### Configurable Parameters:
1. **CPU Generation Threads**: Selectable between 1, 2, 4, 6, and 8 threads. Dynamic reload updates `ModelParams(numberOfThreads: ...)` on the active engine without app restart. Lower threads conserve battery; higher threads maximize tokens/second on multi-core processors.
2. **Sampling Temperature**: Continuous slider from `0.0` to `1.0` with dynamic semantic labeling:
   - `0.0 - 0.2`: **Strict** (deterministic, factual, code & math)
   - `0.3 - 0.5`: **Balanced** (general conversations & assistance)
   - `0.6 - 1.0`: **Creative** (storytelling, brainstorming, creative writing)
3. **Context Window Size**: Discrete chips for `1024` (Eco / Low RAM), `2048` (Default), and `4096` (Deep / Long Documents). Re-allocates the KV-cache in `LlamaEngine` cleanly on change.
4. **Max Generation Tokens**: Discrete chips for `128`, `256`, `512`, and `1024` tokens per response turn, bounding generation latency.
5. **Reset Defaults Action**: Single tap restores standard configurations (`threads: 4`, `temp: 0.3`, `context: 2048`, `maxTokens: 256`) and persists immediately to disk.


