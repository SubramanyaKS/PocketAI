import 'dart:math' as math;
import 'pocket_tool.dart';

/// Offline calculator tool providing deterministic mathematical evaluation.
///
/// Small on-device LLMs (0.5B - 3B) often hallucinate arithmetic.
/// This tool intercepts mathematical expressions and evaluates them instantly
/// with 100% precision and zero token generation latency.
class CalculatorTool implements PocketTool {
  const CalculatorTool();

  @override
  String get name => 'calculator';

  @override
  Map<String, dynamic> get definition => {
        "name": name,
        "description":
            "Perform exact mathematical calculations, arithmetic, percentages, powers, and square roots offline.",
        "parameters": {
          "type": "object",
          "properties": {
            "expression": {
              "type": "string",
              "description":
                  "The mathematical expression to evaluate, e.g. '25 * 4', '15% of 80', 'sqrt(144)'."
            }
          },
          "required": ["expression"]
        }
      };

  @override
  Future<String?> tryExecute(String prompt) async {
    final result = evaluateQuery(prompt);
    return result;
  }

  /// Evaluates a user prompt and returns a formatted result string, or null if not a calculation.
  static String? evaluateQuery(String query) {
    var text = query.trim().toLowerCase();
    if (text.isEmpty) return null;

    // Strip trailing question marks and punctuation
    text = text.replaceAll(RegExp(r'[?!.]+$'), '').trim();

    // 1. Check direct percentage queries: e.g., "15% of 80" or "15 percent of 80"
    final percentMatch = RegExp(
            r'^(\d+(?:\.\d+)?)\s*(?:%|percent)\s+of\s+(\d+(?:\.\d+)?)$')
        .firstMatch(text);
    if (percentMatch != null) {
      final p = double.parse(percentMatch.group(1)!);
      final val = double.parse(percentMatch.group(2)!);
      final result = (p / 100.0) * val;
      return _formatResult('$p% of $val', result);
    }

    // 2. Strip conversational query prefixes
    final prefixMatch = RegExp(
            r'^(?:what(?: is|\x27s)|calculate|how much is|solve|eval(?:uate)?)\s+(.+)$')
        .firstMatch(text);
    if (prefixMatch != null) {
      text = prefixMatch.group(1)!.trim();
    }

    // Check percentage query again after stripping prefix: e.g. "what is 15% of 80"
    final percentMatch2 = RegExp(
            r'^(\d+(?:\.\d+)?)\s*(?:%|percent)\s+of\s+(\d+(?:\.\d+)?)$')
        .firstMatch(text);
    if (percentMatch2 != null) {
      final p = double.parse(percentMatch2.group(1)!);
      final val = double.parse(percentMatch2.group(2)!);
      final result = (p / 100.0) * val;
      return _formatResult('$p% of $val', result);
    }

    // 3. Normalize natural language math phrases to standard math symbols
    var normalized = text
        .replaceAll(RegExp(r'\bsquare root of\b'), 'sqrt')
        .replaceAll(RegExp(r'\bcube root of\b'), 'cbrt')
        .replaceAll(RegExp(r'\bto the power of\b'), '^')
        .replaceAll(RegExp(r'\braised to\b'), '^')
        .replaceAll(RegExp(r'\bmultiplied by\b'), '*')
        .replaceAll(RegExp(r'\bdivided by\b'), '/')
        .replaceAll(RegExp(r'\btimes\b'), '*')
        .replaceAll(RegExp(r'\binto\b'), '*')
        .replaceAll(RegExp(r'\bplus\b'), '+')
        .replaceAll(RegExp(r'\bminus\b'), '-')
        .replaceAll(RegExp(r'\bover\b'), '/')
        .replaceAll(RegExp(r'\bpower\b'), '^');

    // 4. Must contain at least one digit and at least one math operator or recognized function
    final hasDigit = RegExp(r'\d').hasMatch(normalized);
    final hasOperator =
        RegExp(r'[\+\-\*\/\^\%\÷xX×]|sqrt|cbrt|abs').hasMatch(normalized);

    if (!hasDigit || !hasOperator) return null;

    // 5. Whitelist validation: only allow numbers, operators, parens, whitespace, and functions
    final disallowed = normalized
        .replaceAll(RegExp(r'[0-9\.\+\-\*\/\^\(\)\%\÷xX×\s]'), '')
        .replaceAll('sqrt', '')
        .replaceAll('cbrt', '')
        .replaceAll('abs', '');

    if (disallowed.isNotEmpty) {
      // Contains non-math words (e.g. "what is the capital of France?")
      return null;
    }

    // 6. Parse and evaluate
    try {
      final parser = _MathExpressionParser(normalized);
      final value = parser.parse();
      final displayExpr = query.trim().replaceAll(RegExp(r'[?!.]+$'), '');
      return _formatResult(displayExpr, value);
    } on _DivisionByZeroException {
      return '🧮 Cannot divide by zero.';
    } catch (_) {
      return null;
    }
  }

  static String _formatResult(String expression, double value) {
    if (value.isInfinite) {
      return '🧮 Cannot divide by zero.';
    }
    if (value.isNaN) {
      return '🧮 Invalid mathematical operation.';
    }

    String numStr;
    if (value == value.roundToDouble() && value.abs() < 1e14) {
      numStr = value.toInt().toString();
    } else {
      numStr = value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    }

    return '🧮 $expression = **$numStr**';
  }
}

/// Recursive descent parser for safe mathematical expressions.
class _MathExpressionParser {
  final String src;
  int _pos = 0;

  _MathExpressionParser(this.src);

  double parse() {
    _pos = 0;
    final res = _parseExpression();
    _consumeWhitespace();
    if (_pos < src.length) {
      throw FormatException('Unexpected character: ${src[_pos]} at $_pos');
    }
    return res;
  }

  void _consumeWhitespace() {
    while (_pos < src.length && src[_pos].trim().isEmpty) {
      _pos++;
    }
  }

  double _parseExpression() {
    var val = _parseTerm();
    while (true) {
      _consumeWhitespace();
      if (_pos >= src.length) break;
      final ch = src[_pos];
      if (ch == '+') {
        _pos++;
        val += _parseTerm();
      } else if (ch == '-') {
        _pos++;
        val -= _parseTerm();
      } else {
        break;
      }
    }
    return val;
  }

  double _parseTerm() {
    var val = _parsePower();
    while (true) {
      _consumeWhitespace();
      if (_pos >= src.length) break;
      final ch = src[_pos];
      if (ch == '*' || ch == 'x' || ch == 'X' || ch == '×') {
        _pos++;
        val *= _parsePower();
      } else if (ch == '/' || ch == '÷') {
        _pos++;
        final divisor = _parsePower();
        if (divisor == 0) throw const _DivisionByZeroException();
        val /= divisor;
      } else if (ch == '%') {
        _pos++;
        _consumeWhitespace();
        if (_pos < src.length && (_isDigit(src[_pos]) || src[_pos] == '(')) {
          final mod = _parsePower();
          if (mod == 0) throw const _DivisionByZeroException();
          val = val % mod;
        } else {
          val = val / 100.0;
        }
      } else {
        break;
      }
    }
    return val;
  }

  double _parsePower() {
    var val = _parseFactor();
    _consumeWhitespace();
    if (_pos < src.length && src[_pos] == '^') {
      _pos++;
      final exponent = _parsePower();
      val = math.pow(val, exponent).toDouble();
    }
    return val;
  }

  double _parseFactor() {
    _consumeWhitespace();
    if (_pos >= src.length) {
      throw const FormatException('Unexpected end of input');
    }

    // Unary plus/minus
    if (src[_pos] == '+') {
      _pos++;
      return _parseFactor();
    }
    if (src[_pos] == '-') {
      _pos++;
      return -_parseFactor();
    }

    // Parentheses
    if (src[_pos] == '(') {
      _pos++;
      final val = _parseExpression();
      _consumeWhitespace();
      if (_pos >= src.length || src[_pos] != ')') {
        throw const FormatException('Missing closing parenthesis');
      }
      _pos++;
      return val;
    }

    // Functions: sqrt, cbrt, abs
    if (_pos + 4 <= src.length &&
        src.substring(_pos, _pos + 4).toLowerCase() == 'sqrt') {
      _pos += 4;
      return math.sqrt(_parseFactor());
    }
    if (_pos + 4 <= src.length &&
        src.substring(_pos, _pos + 4).toLowerCase() == 'cbrt') {
      _pos += 4;
      final f = _parseFactor();
      return f < 0
          ? -math.pow(-f, 1 / 3).toDouble()
          : math.pow(f, 1 / 3).toDouble();
    }
    if (_pos + 3 <= src.length &&
        src.substring(_pos, _pos + 3).toLowerCase() == 'abs') {
      _pos += 3;
      return _parseFactor().abs();
    }

    // Numbers
    final start = _pos;
    var hasDot = false;
    while (_pos < src.length && (_isDigit(src[_pos]) || src[_pos] == '.')) {
      if (src[_pos] == '.') {
        if (hasDot) break;
        hasDot = true;
      }
      _pos++;
    }

    if (start == _pos) {
      throw FormatException(
          'Expected number at position $_pos, found: ${src[_pos]}');
    }

    return double.parse(src.substring(start, _pos));
  }

  bool _isDigit(String s) {
    final code = s.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}

class _DivisionByZeroException implements Exception {
  const _DivisionByZeroException();
}
