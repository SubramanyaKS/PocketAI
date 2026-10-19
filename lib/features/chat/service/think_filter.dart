class ThinkFilter {
  static const _startTag = '<think>';
  static const _endTag = '</think>';

  bool _insideThink = false;
  bool _hasEmittedText = false;
  String _buffer = '';

  String process(String chunk) {
    _buffer += chunk;
    final output = StringBuffer();

    while (_buffer.isNotEmpty) {
      if (_insideThink) {
        final end = _buffer.indexOf(_endTag);

        if (end == -1) {
          // Keep enough characters to detect a split </think> tag.
          final keep = _endTag.length - 1;

          if (_buffer.length > keep) {
            _buffer = _buffer.substring(_buffer.length - keep);
          }
          break;
        }

        _buffer = _buffer.substring(end + _endTag.length);
        _insideThink = false;
      } else {
        final start = _buffer.indexOf(_startTag);

        if (start == -1) {
          // Avoid emitting a partial <think> tag.
          final keep = _startTag.length - 1;

          if (_buffer.length > keep) {
            output.write(
              _visibleText(_buffer.substring(0, _buffer.length - keep)),
            );
            _buffer = _buffer.substring(_buffer.length - keep);
          }
          break;
        }

        output.write(_visibleText(_buffer.substring(0, start)));
        _buffer = _buffer.substring(start + _startTag.length);
        _insideThink = true;
      }
    }

    return output.toString();
  }

  String finish() {
    if (_insideThink) {
      _buffer = '';
      return '';
    }

    final result = _visibleText(_buffer);
    _buffer = '';
    return result;
  }

  String _visibleText(String text) {
    if (_hasEmittedText) return text;

    final trimmed = text.trimLeft();
    if (trimmed.isNotEmpty) {
      _hasEmittedText = true;
    }
    return trimmed;
  }
}