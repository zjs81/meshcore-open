import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef ProcessStartFn =
    Future<Process> Function(String executable, List<String> arguments);
typedef ProcessRunFn =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// Best-effort Linux BLE pairing helper using bluetoothctl.
///
/// This is used only as a fallback when BlueZ pairing via flutter_blue_plus
/// fails to surface agent prompts in-app.
class LinuxBlePairingService {
  /// Maximum number of pairing attempts (initial + retries).
  /// Covers one remove-and-retry plus one proactive-PIN retry.
  static const int _maxAttempts = 3;

  static const Duration _processExitTimeout = Duration(seconds: 6);
  static const Duration _pairingCleanupTimeout = Duration(seconds: 5);
  static const Duration _defaultPairingTimeout = Duration(seconds: 45);
  LinuxBlePairingService({
    ProcessStartFn? processStart,
    ProcessRunFn? processRun,
  }) : _processStart = processStart ?? Process.start,
       _processRun = processRun ?? Process.run;

  final ProcessStartFn _processStart;
  final ProcessRunFn _processRun;

  Future<bool> isBluetoothctlAvailable() async {
    try {
      final result = await _processRun('bluetoothctl', <String>['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  Future<void> disconnectDevice(
    String remoteId, {
    void Function(String message)? onLog,
  }) async {
    onLog?.call('Requesting BlueZ disconnect for $remoteId');
    Process process;
    try {
      process = await _processStart('bluetoothctl', <String>[]);
    } on ProcessException catch (error) {
      onLog?.call(
        'bluetoothctl unavailable, skipping BlueZ disconnect: $error',
      );
      return;
    }
    process.stdin.writeln('disconnect $remoteId');
    process.stdin.writeln('quit');
    try {
      await process.exitCode.timeout(_processExitTimeout);
    } catch (_) {
      process.kill();
    }
    onLog?.call('Issued bluetoothctl disconnect for $remoteId');
  }

  Future<bool> isPairedAndTrusted(String remoteId) async {
    ProcessResult result;
    try {
      result = await _processRun('bluetoothctl', <String>['info', remoteId]);
    } on ProcessException {
      return false;
    }
    if (result.exitCode != 0) {
      return false;
    }
    final output = (result.stdout as String).toLowerCase();
    return output.contains('paired: yes') && output.contains('trusted: yes');
  }

  Future<bool> trustDevice(
    String remoteId, {
    void Function(String message)? onLog,
  }) async {
    onLog?.call('Requesting BlueZ trust for $remoteId');
    ProcessResult result;
    try {
      result = await _processRun('bluetoothctl', <String>['trust', remoteId]);
    } on ProcessException catch (error) {
      onLog?.call('bluetoothctl unavailable, cannot trust $remoteId: $error');
      return false;
    }
    if (result.exitCode != 0) {
      onLog?.call('bluetoothctl trust failed for $remoteId: ${result.stderr}');
      return false;
    }
    final trusted = await isPairedAndTrusted(remoteId);
    onLog?.call(
      trusted
          ? 'Verified BlueZ trust for $remoteId'
          : 'BlueZ trust verification failed for $remoteId',
    );
    return trusted;
  }

  Future<bool> pairAndTrust({
    required String remoteId,
    Duration timeout = _defaultPairingTimeout,
    void Function(String message)? onLog,
    Future<String?> Function()? onRequestPin,
  }) async {
    var removeRetryUsed = false;
    var proactivePinRetryUsed = false;
    Future<String?> Function()? currentPinProvider = onRequestPin;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final result = await _runPairingAttempt(
        remoteId: remoteId,
        timeout: timeout,
        onLog: onLog,
        onRequestPin: currentPinProvider,
      );

      if (result.success) return true;
      if (result.userCancelled) {
        onLog?.call('Pairing cancelled by user; skipping retry/remove flow');
        return false;
      }

      if (result.pairFailed) {
        if (!removeRetryUsed) {
          removeRetryUsed = true;
          onLog?.call(
            'Pairing failed; removing cached bond and retrying '
            '(attempt ${attempt + 1}/$_maxAttempts)',
          );
          await _removeDevice(remoteId, onLog: onLog);
          continue;
        }
        if (!result.pinSent &&
            !proactivePinRetryUsed &&
            currentPinProvider != null) {
          proactivePinRetryUsed = true;
          onLog?.call(
            'Pairing failed before PIN challenge; requesting PIN for '
            'proactive retry (attempt ${attempt + 1}/$_maxAttempts)',
          );
          final pin = await currentPinProvider();
          if (pin == null) {
            onLog?.call('PIN entry cancelled for proactive retry');
            return false;
          }
          final capturedPin = pin.trim();
          currentPinProvider = () async => capturedPin;
          continue;
        }
        return false;
      }

      // Timeout path — pairing neither succeeded nor failed.
      onLog?.call('Pairing did not complete before timeout');
      if (!result.pinSent &&
          !proactivePinRetryUsed &&
          currentPinProvider != null) {
        proactivePinRetryUsed = true;
        onLog?.call(
          'No PIN challenge observed before timeout; requesting PIN for '
          'proactive retry (attempt ${attempt + 1}/$_maxAttempts)',
        );
        final pin = await currentPinProvider();
        if (pin == null) {
          onLog?.call('PIN entry cancelled for proactive retry after timeout');
          return false;
        }
        final capturedPin = pin.trim();
        currentPinProvider = () async => capturedPin;
        continue;
      }
      return false;
    }
    return false;
  }

  /// Runs a single bluetoothctl pairing attempt.
  ///
  /// Uses a [Completer] to wake as soon as pairing succeeds or fails,
  /// instead of polling.
  Future<_PairingResult> _runPairingAttempt({
    required String remoteId,
    required Duration timeout,
    void Function(String message)? onLog,
    Future<String?> Function()? onRequestPin,
  }) async {
    onLog?.call('Starting bluetoothctl pairing flow for $remoteId');
    Process process;
    try {
      process = await _processStart('bluetoothctl', <String>[]);
    } on ProcessException catch (error) {
      onLog?.call('bluetoothctl unavailable, cannot run pairing flow: $error');
      return const _PairingResult();
    }
    final output = StringBuffer();
    var pinSent = false;
    var sessionClosed = false;
    var userCancelledPinEntry = false;
    var confirmationHandled = false;
    var successHandled = false;
    var failureHandled = false;
    var detectorBuffer = '';
    final pairingDone = Completer<void>();
    var pairSucceeded = false;
    var pairFailed = false;

    void writeCmd(String cmd) {
      if (sessionClosed) return;
      try {
        process.stdin.writeln(cmd);
      } on StateError {
        sessionClosed = true;
        onLog?.call('bluetoothctl stdin already closed; ignoring "$cmd"');
      }
    }

    unawaited(
      process.exitCode.then((_) {
        sessionClosed = true;
        if (!pairingDone.isCompleted) pairingDone.complete();
      }),
    );

    void handleChunk(String chunk) {
      output.write(chunk);
      detectorBuffer += chunk.toLowerCase();
      if (detectorBuffer.length > 4096) {
        detectorBuffer = detectorBuffer.substring(detectorBuffer.length - 4096);
      }
      final lower = detectorBuffer;

      if (!pinSent &&
          !sessionClosed &&
          (lower.contains('enter pin code') ||
              lower.contains('requestpin') ||
              lower.contains('input pin code') ||
              lower.contains('request passkey') ||
              lower.contains('requestpasskey') ||
              lower.contains('enter passkey'))) {
        pinSent = true;
        if (onRequestPin == null) {
          onLog?.call(
            'PIN/passkey requested but no onRequestPin callback; '
            'sending empty line to accept default pairing',
          );
          writeCmd('');
        } else {
          onLog?.call('Pairing agent is ready for PIN/passkey input');
          unawaited(
            Future<void>(() async {
              String? pin;
              try {
                pin = await onRequestPin();
              } catch (e) {
                onLog?.call('onRequestPin callback threw: $e');
                pairFailed = true;
                writeCmd('cancel');
                if (!pairingDone.isCompleted) pairingDone.complete();
                return;
              }
              if (pin == null) {
                if (sessionClosed) {
                  onLog?.call(
                    'PIN prompt resolved after pairing session closed',
                  );
                  return;
                }
                onLog?.call('PIN entry cancelled by user; cancelling pairing');
                userCancelledPinEntry = true;
                pairFailed = true;
                writeCmd('cancel');
                if (!pairingDone.isCompleted) pairingDone.complete();
                return;
              }
              if (sessionClosed) {
                onLog?.call(
                  'PIN provided after pairing session closed; ignoring',
                );
                return;
              }
              if (pin.trim().isEmpty) {
                onLog?.call(
                  'Blank PIN submitted; sending empty line to accept default pairing',
                );
                writeCmd('');
              } else {
                onLog?.call('Submitting PIN/passkey to pairing agent');
                writeCmd(pin.trim());
              }
            }),
          );
        }
      }

      if (!confirmationHandled &&
          (lower.contains('confirm passkey') ||
              lower.contains('requestconfirmation') ||
              lower.contains('[agent] confirm'))) {
        confirmationHandled = true;
        onLog?.call(
          'Pairing agent requested passkey confirmation; answering yes',
        );
        writeCmd('yes');
      }

      if (!successHandled &&
          (lower.contains('pairing successful') ||
              lower.contains('already paired'))) {
        successHandled = true;
        onLog?.call('Pairing reported success');
        pairSucceeded = true;
        if (!pairingDone.isCompleted) pairingDone.complete();
      }

      if (!failureHandled &&
          (lower.contains('failed to pair') ||
              lower.contains('authenticationfailed') ||
              lower.contains('authentication failed'))) {
        failureHandled = true;
        onLog?.call('Pairing reported authentication failure');
        pairFailed = true;
        if (!pairingDone.isCompleted) pairingDone.complete();
      }
    }

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen(handleChunk);
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(handleChunk);

    writeCmd('power on');
    writeCmd('agent KeyboardDisplay');
    writeCmd('default-agent');
    onLog?.call('Waiting for pairing challenge from bluetoothctl agent');
    writeCmd('pair $remoteId');

    // Wait for the Completer to fire (success/failure/process exit) or timeout.
    await pairingDone.future.timeout(timeout, onTimeout: () {});

    if (!pairFailed && pairSucceeded) {
      onLog?.call('Pair succeeded; trusting and connecting device');
      writeCmd('trust $remoteId');
      writeCmd('connect $remoteId');
    }
    writeCmd('quit');
    sessionClosed = true;

    try {
      await process.exitCode.timeout(_pairingCleanupTimeout);
    } catch (_) {
      process.kill();
    }
    await stdoutSub.cancel();
    await stderrSub.cancel();

    if (pairFailed) {
      return _PairingResult(
        pairFailed: true,
        pinSent: pinSent,
        userCancelled: userCancelledPinEntry,
      );
    }

    final allOutput = output.toString().toLowerCase();
    final reportedSuccess =
        pairSucceeded ||
        allOutput.contains('pairing successful') ||
        allOutput.contains('already paired');
    if (reportedSuccess) {
      final trusted = await trustDevice(remoteId, onLog: onLog);
      if (!trusted) {
        onLog?.call('Pairing completed but BlueZ trust was not restored');
      }
      return _PairingResult(success: trusted, pinSent: pinSent);
    }

    return _PairingResult(pinSent: pinSent);
  }

  Future<void> _removeDevice(
    String remoteId, {
    void Function(String message)? onLog,
  }) async {
    Process process;
    try {
      process = await _processStart('bluetoothctl', <String>[]);
    } on ProcessException catch (error) {
      onLog?.call(
        'bluetoothctl unavailable, skipping remove for $remoteId: $error',
      );
      return;
    }
    process.stdin.writeln('remove $remoteId');
    process.stdin.writeln('quit');
    try {
      await process.exitCode.timeout(_processExitTimeout);
    } catch (_) {
      process.kill();
    }
    onLog?.call('Issued bluetoothctl remove for $remoteId');
  }
}

/// Outcome of a single bluetoothctl pairing attempt.
class _PairingResult {
  final bool success;
  final bool pairFailed;
  final bool pinSent;
  final bool userCancelled;

  const _PairingResult({
    this.success = false,
    this.pairFailed = false,
    this.pinSent = false,
    this.userCancelled = false,
  });
}
