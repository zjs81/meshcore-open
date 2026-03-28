const String linuxConnectStageFailureMarker = 'linux connect stage failure';

bool isLinuxBleConnectFailureText(String errorText) {
  final lowerErrorText = errorText.toLowerCase();
  if (isLinuxBlePairingFailureText(errorText)) {
    return false;
  }
  return lowerErrorText.contains(linuxConnectStageFailureMarker) ||
      lowerErrorText.contains('| connect |') ||
      lowerErrorText.contains('linux connect hard-timeout') ||
      lowerErrorText.contains('org.bluez.error.failed') ||
      lowerErrorText.contains('org.bluez.error.inprogress') ||
      lowerErrorText.contains('le-connection-abort-by-local');
}

bool isLinuxBlePairingFailureText(String errorText) {
  final lowerErrorText = errorText.toLowerCase();
  final isPairingSpecificStateError =
      lowerErrorText.contains('bad state: no element') &&
      (lowerErrorText.contains('pair') ||
          lowerErrorText.contains('bond') ||
          lowerErrorText.contains('trust'));
  return lowerErrorText.contains('authenticationfailed') ||
      lowerErrorText.contains('authentication failed') ||
      lowerErrorText.contains('notpermitted: not paired') ||
      lowerErrorText.contains('pairing fallback failed') ||
      lowerErrorText.contains('linux ble pairing did not complete') ||
      lowerErrorText.contains('linux ble trust repair did not complete') ||
      isPairingSpecificStateError ||
      isLikelyLinuxBlePairingTimeoutText(errorText);
}

bool isLikelyLinuxBlePairingTimeoutText(String errorText) {
  final lowerErrorText = errorText.toLowerCase();
  return lowerErrorText.contains('timed out') &&
      (lowerErrorText.contains('pair') || lowerErrorText.contains('bond'));
}
