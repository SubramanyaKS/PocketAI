# Contributing to Arivu AI (ಅರಿವು AI)

Thank you for your interest in contributing to **Arivu AI**! We welcome contributions from developers, researchers, designers, and open-source enthusiasts.

Arivu AI is committed to building an uncompromising, privacy-first, on-device mobile AI assistant that runs entirely on local hardware with zero cloud dependencies.

---

## 🏛️ Core Principles for Contributors

1. **100% On-Device & Zero-Cloud**:
   No user data (prompts, conversations, audio recordings, documents, or metadata) may ever leave the user's phone. Never add remote analytics, telemetry SDKs, or cloud LLM fallbacks.
2. **Sub-Second Offline Performance**:
   Device tools (alarms, timers, torch, calculator, launcher) and voice loops must execute deterministically in `<1ms` without waiting for LLM token generation.
3. **Safety & Grounding**:
   Prompts and tools must prioritize factual truth, anti-hallucination guardrails, and explicit user safety.
4. **Documentation & Tests First**:
   Every new tool, service, or feature must be accompanied by comprehensive unit and widget tests and documented in `docs/architecture.md`.

---

## 🛠️ Development Environment Setup

### Prerequisites
- **Flutter SDK**: `3.38.0` or newer (Dart `3.10.7` or newer).
- **Android Studio / Android SDK**: API Level 34+ (Minimum SDK is 26 / Android 8.0).
- **Android NDK & CMake**: Required by the embedded `llama.cpp` runtime via `llamadart`.
- **Physical Device or Emulator**: An Android phone or emulator with at least 2 GB free RAM (4 GB+ recommended for larger models).

### Getting Started

```bash
# 1. Fork and clone the repository
git clone https://github.com/SubramanyaKS/ArivuAI.git
cd ArivuAI

# 2. Install dependencies
flutter pub get

# 3. Verify static analysis (must report zero warnings/errors)
flutter analyze

# 4. Run the automated test suite
flutter test

# 5. Launch the application
flutter run
```

---

## 🧩 How to Add a New Offline Device Tool

All deterministic device actions in Arivu AI implement the `PocketTool` contract and register with `ToolRegistry`.

### 1. Implement `PocketTool`
Create a new tool class in `lib/tools/<your_tool_name>.dart`:

```dart
import 'package:arivu_ai/llm/tool_definitions.dart';
import 'package:arivu_ai/tools/pocket_tool.dart';

class MyCustomTool implements PocketTool {
  @override
  String get name => 'my_custom_tool';

  @override
  ToolDefinition get definition => ToolDefinition(
    name: name,
    description: 'Describe what the tool does and natural language patterns.',
    parameters: {
      'type': 'object',
      'properties': {
        'parameter_key': {
          'type': 'string',
          'description': 'Description of the parameter.',
        },
      },
    },
  );

  @override
  Future<ToolExecutionResult> tryExecute(String prompt) async {
    final lower = prompt.trim().toLowerCase();

    // Check if the prompt matches your tool's intent
    if (lower.contains('my trigger keyword')) {
      // Execute local platform or hardware action
      final reply = 'Successfully executed custom action!';
      return ToolExecutionResult.handled(reply: reply);
    }

    return ToolExecutionResult.unhandled();
  }
}
```

### 2. Register the Tool
Add your tool instance to the default registry list in `lib/tools/tool_registry.dart`:

```dart
static final List<PocketTool> _defaultTools = [
  AlarmTool(),
  ReminderTool(),
  BatteryTool(),
  CalculatorTool(),
  TorchTool(),
  DeviceSettingsTool(),
  AppLauncherTool(),
  MyCustomTool(), // <-- Register your tool here
];
```

### 3. Write Unit Tests
Create `test/my_custom_tool_test.dart` validating:
- Metadata & schema definitions.
- Accurate keyword matching and argument parsing.
- Dispatch via `ToolRegistry.dispatch()`.
- Rejection of unrelated queries so normal conversation flows to the LLM.

---

## 🧠 How to Add a New Language Model to the Catalog

Model specifications are decoupled into [`assets/models/model_catalog.json`](assets/models/model_catalog.json).

To introduce a new quantized GGUF model:
1. Ensure the model license is open and compatible (e.g. Apache 2.0, MIT, Llama 3 Community).
2. Quantization must be 4-bit (`Q4_K_M`) or 8-bit (`Q8_0`) with file size `< 1.5 GB` for mobile CPU feasibility.
3. Append an entry to `assets/models/model_catalog.json`:

```json
{
  "id": "my-new-model",
  "name": "Model Display Name",
  "description": "Short description of model capabilities and ideal use-case.",
  "category": "Compact & Fast",
  "fileName": "my-model-q4_k_m.gguf",
  "downloadUrl": "https://huggingface.co/<org>/<repo>/resolve/main/my-model-q4_k_m.gguf",
  "sizeBytes": 650000000,
  "sha256": "abcdef1234567890...",
  "recommendedRam": "2GB+ RAM"
}
```

4. Update `test/multi_model_manager_test.dart` to assert catalog count and properties.

---

## 🧪 Quality Standards & Pull Request Process

Before submitting a Pull Request, verify:
- [ ] Code is formatted cleanly: `dart format .`
- [ ] Static analyzer passes without warnings: `flutter analyze`
- [ ] All unit and widget tests pass: `flutter test`
- [ ] No remote network calls or telemetry are introduced.
- [ ] Architecture diagrams or documentation are updated in `docs/` if modifying services.
- [ ] Commit messages are concise, conventional, and descriptive (e.g., `feat(tools): add offline timer support`).

---

## 📜 License

By contributing to **Arivu AI**, you agree that your contributions will be licensed under the project's [Apache 2.0 License](LICENSE).
