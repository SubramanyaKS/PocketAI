# Pocket AI - Future Roadmap & Architecture Plan

Here is the updated roadmap and milestone status for taking **Pocket AI** from a prototype to a full-featured, high-performance offline AI application.

---

## Completed Milestones & Recent Improvements

- [x] **Offline LLM Integration**: GGUF inference via llamadart (llama.cpp) with caching and header validation.
- [x] **Full-Duplex Offline Voice Assistant**: Interactive pipeline (speech_to_text -> LocalAiService -> flutter_tts).
- [x] **Futuristic Voice UI**: Glowing animated orb, rotating ambient rings, dynamic multi-state gradient colors (Idle, Listening, Thinking, Speaking), and live audio equalizer wave bars.
- [x] **Dynamic Role-Tailored System Prompts**: Decoupled system prompts for Chat (defaultChatSystemPrompt) vs. Voice (defaultVoiceSystemPrompt), ensuring clean text formatting in chat and spoken, markdown-free responses in voice mode.
- [x] **Global Riverpod Theming & Settings**: Unified light & dark mode themes across Chat, Voice Assistant, and Bottom Navigation, switchable in SettingsScreen.
- [x] **Enhanced Prompt Suggestions**: Real-world starter ideas in the empty chat state.

---

## Next Phases & Planned Features

### 1. Voice Assistant Enhancements (Real-time Audio)

#### A. Sentence-by-Sentence Streaming Audio Playback
- **Current state**: Live streaming tokens display on screen, but audio playback waits for complete sentences or final generation.
- **Goal**: Token buffer splits on delimiters (., ?, !, \n) and queues each sentence into flutter_tts sequentially.
- **Benefit**: Slashes perceived voice latency from ~5 seconds down to ~1-2 seconds.

#### B. Auto-Continuous Conversation (Hands-Free Loop)
- Automatically trigger speech recognition after TTS audio completes, with a 3-5s silence timeout.
- Enables natural back-and-forth dialogue without pressing buttons repeatedly.

#### C. Voice Interrupt / Barge-In
- If the user starts speaking while the AI is talking, immediately cancel TTS playback and switch back to listening state.

---

### 2. Offline Device Tasks & Action Execution (Alarms, Timers, Reminders)

Elevate Pocket AI into an **offline device assistant** (private Siri / Google Assistant alternative).

#### A. Alarms & Timers (Native Android System Intents)
- **Commands**: 'Set an alarm for 7:30 AM', 'Set a 15-minute pasta timer', 'Wake me up at 6:00'.
- **Implementation**:
  - Regex / pattern intent detector with local LLM fallback.
  - Launch Android AlarmClock.ACTION_SET_ALARM and AlarmClock.ACTION_SET_TIMER via android_intent_plus. Runs natively in the phone's clock app even if Pocket AI is closed.

#### B. Offline Reminders & Task Lists
- **Commands**: 'Remind me to call John in 2 hours', 'Add to my to-do list: buy groceries'.
- **Implementation**:
  - Store scheduled reminders in local SQLite database.
  - Trigger device notifications via flutter_local_notifications.

#### C. System Toggles & Utilities
- Offline shortcuts: 'Turn on flashlight' (torch_light), 'Open Wi-Fi settings', 'Battery status'.

---

### 3. Multi-Model Support & Model Management Screen

Allow users to download and switch between models based on their device specifications:

#### Model Catalog
- **Ultra-lightweight / Fast (Voice & Quick replies)**:
  - SmolLM2-360M-Instruct (~250 MB)
  - Qwen2.5-0.5B-Instruct (~400 MB)
- **Balanced (Default)**:
  - Qwen3-0.6B-Q8_0 (Current)
  - Qwen2.5-1.5B-Instruct-Q4_K_M (~1.0 GB)
- **High Intelligence / Coding / Complex Reasoning**:
  - Llama-3.2-1B-Instruct or Llama-3.2-3B-Instruct
  - Phi-3.5-mini-instruct (devices with 8GB+ RAM)

#### Management UI
- Download, pause, resume, and delete models from local storage.
- Switch active model dynamically with memory cleanup (LlamaEngine.dispose() / reload).

---

### 4. Offline RAG (Retrieval-Augmented Generation) & Document Chat

Enable users to chat with their private files completely offline:
1. **Local Document Ingestion**: Pick PDF, TXT, EPUB, or Markdown files via file_picker.
2. **Text Chunking**: Split text into paragraphs (200-500 words).
3. **Local Embedding & Vector Search**: Lightweight local embeddings (all-MiniLM-L6-v2 via ONNX or SQLite cosine similarity).
4. **Context Injection**: Retrieve relevant chunks and inject them into the system prompt for grounded, private answers.

---

### 5. Chat UI/UX & Performance Optimization

- **Rich Markdown & Code Highlighting**: Add flutter_markdown with code syntax highlighting, copy-code buttons, and tables.
- **Hardware Acceleration**: Enable OpenCL / Vulkan / NPU backends on supported Android chipsets (Snapdragon / MediaTek) via llama.cpp compilation flags for 2x-4x tokens/second.
- **Background Keep-Alive**: Lifecycle management so switching apps during long generations doesn't abort inference.

---

## Roadmap Priority Order

| Phase | Milestone | Focus Area | Expected Impact |
|---|---|---|---|
| **Phase 1** | **Streaming TTS & Hands-Free Loop** | Voice Assistant | ~1s instant audio response, conversational flow |
| **Phase 2** | **Offline Alarms, Timers & Reminders** | Device Tasks | Everyday utility without internet |
| **Phase 3** | **Markdown & Code Syntax Highlighting** | Chat Screen | Clean readable output for code, lists & tables |
| **Phase 4** | **Multi-Model Manager** | Core AI | Flexibility for budget vs flagship devices |
| **Phase 5** | **Offline Document Chat (RAG)** | Local Knowledge | Private study & document search on-device |
