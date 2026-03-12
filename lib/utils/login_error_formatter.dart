String formatLoginError(Object error, {required String fallbackMessage}) {
  if (error is FormatException || error is ArgumentError) {
    return error.toString();
  }

  final message = error.toString().trim();
  if (message.startsWith('Exception:')) {
    final detail = message.substring('Exception:'.length).trim();
    if (detail.isNotEmpty) {
      return detail;
    }
  }

  return fallbackMessage;
}
