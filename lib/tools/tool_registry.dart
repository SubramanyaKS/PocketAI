import 'pocket_tool.dart';
import 'battery_tool.dart';
import 'torch_tool.dart';
import 'reminder_parser.dart';
import 'alarm_tool.dart';
import 'calculator_tool.dart';
import 'device_settings_tool.dart';
import 'app_launcher_tool.dart';

class ToolExecutionResult {
  final bool handled;
  final String? reply;
  final String? toolName;

  const ToolExecutionResult({
    required this.handled,
    this.reply,
    this.toolName,
  });

  const ToolExecutionResult.unhandled()
      : handled = false,
        reply = null,
        toolName = null;
}

/// Central Tool Registry managing discovery, schema definition,
/// and deterministic execution of all offline device tools.
class ToolRegistry {
  ToolRegistry._();

  static final List<PocketTool> _tools = [
    const TorchTool(),
    const ReminderTool(),
    const BatteryTool(),
    const AlarmTimerTool(),
    const CalculatorTool(),
    const DeviceSettingsTool(),
    const AppLauncherTool(),
  ];

  /// Returns immutable list of registered tools.
  static List<PocketTool> get tools => List.unmodifiable(_tools);

  /// Aggregates LLM tool definitions from all registered tools dynamically.
  static List<Map<String, dynamic>> get definitions =>
      _tools.map((t) => t.definition).toList();

  /// Attempts to match and execute user input against registered tools.
  /// If any tool handles the input, returns a [ToolExecutionResult] with `handled: true`.
  /// Otherwise returns [ToolExecutionResult.unhandled()].
  static Future<ToolExecutionResult> dispatch(String prompt) async {
    final cleaned = prompt.trim();
    if (cleaned.isEmpty) return const ToolExecutionResult.unhandled();

    for (final tool in _tools) {
      try {
        final reply = await tool.tryExecute(cleaned);
        if (reply != null) {
          return ToolExecutionResult(
            handled: true,
            reply: reply,
            toolName: tool.name,
          );
        }
      } catch (e) {
        // Individual tool failure does not halt pipeline
        continue;
      }
    }

    return const ToolExecutionResult.unhandled();
  }
}
