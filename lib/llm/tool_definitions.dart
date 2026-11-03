import '../tools/tool_registry.dart';

/// Central LLM tool definitions aggregated dynamically from the ToolRegistry.
List<Map<String, dynamic>> get toolDefinitions => ToolRegistry.definitions;
