/// Base interface that every offline tool in Arivu AI must implement.
abstract class PocketTool {
  /// Unique identifier of the tool.
  String get name;

  /// Schema definition conforming to OpenAI / LLM function calling standards.
  Map<String, dynamic> get definition;

  /// Attempts to parse and execute the user's prompt deterministically.
  /// Returns a user-facing reply if handled, or `null` if the prompt does not match this tool.
  Future<String?> tryExecute(String prompt);
}
