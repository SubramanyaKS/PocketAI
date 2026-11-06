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
        ChatScreen["ChatScreen<br/>(Markdown, Prompts & History)"]
        VoiceScreen["VoiceAssistantScreen<br/>(Orb, Waves & Hands-Free Flow)"]
        SettingsScreen["SettingsScreen<br/>(Theme & System Preferences)"]
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
    ThemeState -.->|Rebuilds UI| App

    ChatScreen -->|Context Window| ChatUtils
    ChatScreen -->|Intercept Intent| Registry
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

    CheckAlarm -- No --> FormatContext[ChatUtils: Prune & Build Context Window]
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
    VoiceUI->>Mic: speech.listen(partialResults: true)
    User->>Mic: Speaks voice command
    Mic-->>VoiceUI: Recognized Words Stream
    User->>VoiceUI: Silence or Tap Stop
    
    VoiceUI->>VoiceUI: Switch State: Thinking
    
    alt Matches Registered PocketTool (Torch / Reminder / Battery / Alarm / Timer)
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
