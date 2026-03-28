import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/linux_ble_pairing_service.dart';

class _FakeProcess implements Process {
  _FakeProcess({this.stdoutText = '', this.autoFinish = true}) {
    _stdin = IOSink(_stdinController.sink);
    _stdinController.stream.listen((chunk) {
      _stdinBuffer.write(utf8.decode(chunk));
    });

    // Use Timer.run (event-loop tick) instead of microtask so that broadcast
    // listeners in _runPairingAttempt are attached before the event fires.
    Timer.run(() {
      if (_closed) {
        return;
      }
      if (stdoutText.isNotEmpty) {
        _stdoutController.add(utf8.encode(stdoutText));
      }
    });

    if (autoFinish) {
      // Scheduled after the Timer.run above (FIFO order), so stdout is
      // emitted before the process exits.
      Timer(Duration.zero, () async {
        await _finish(exitStatus);
      });
    }
  }

  final String stdoutText;
  final bool autoFinish;
  final int exitStatus = 0;
  final StreamController<List<int>> _stdinController =
      StreamController<List<int>>();
  final StreamController<List<int>> _stdoutController =
      StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _stderrController =
      StreamController<List<int>>.broadcast();
  final Completer<int> _exitCodeCompleter = Completer<int>();
  final StringBuffer _stdinBuffer = StringBuffer();
  late final IOSink _stdin;
  bool _closed = false;

  String get stdinText => _stdinBuffer.toString();

  void emitStdout(String text) {
    if (!_closed) {
      _stdoutController.add(utf8.encode(text));
    }
  }

  void finishProcess([int code = 0]) {
    unawaited(_finish(code));
  }

  Future<void> _finish(int code) async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _stdin.close();
    await _stdoutController.close();
    await _stderrController.close();
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(code);
    }
  }

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    unawaited(_finish(exitStatus));
    return true;
  }

  @override
  int get pid => 1;

  @override
  IOSink get stdin => _stdin;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;
}

void main() {
  test(
    'disconnectDevice skips gracefully when bluetoothctl is unavailable',
    () async {
      final logs = <String>[];
      final service = LinuxBlePairingService(
        processStart: (executable, arguments) async {
          throw const ProcessException(
            'bluetoothctl',
            <String>[],
            'not found',
            2,
          );
        },
      );

      await service.disconnectDevice('AA:BB:CC:DD:EE:FF', onLog: logs.add);

      expect(
        logs.any((line) => line.contains('bluetoothctl unavailable')),
        isTrue,
      );
    },
  );

  test(
    'isPairedAndTrusted returns false when bluetoothctl is unavailable',
    () async {
      final service = LinuxBlePairingService(
        processRun: (executable, arguments) async {
          throw const ProcessException(
            'bluetoothctl',
            <String>[],
            'not found',
            2,
          );
        },
      );

      final trusted = await service.isPairedAndTrusted('AA:BB:CC:DD:EE:FF');
      expect(trusted, isFalse);
    },
  );

  test('isBluetoothctlAvailable returns false when unavailable', () async {
    final service = LinuxBlePairingService(
      processRun: (executable, arguments) async {
        throw const ProcessException(
          'bluetoothctl',
          <String>[],
          'not found',
          2,
        );
      },
    );

    final available = await service.isBluetoothctlAvailable();
    expect(available, isFalse);
  });

  test(
    'isBluetoothctlAvailable returns true when version command succeeds',
    () async {
      final service = LinuxBlePairingService(
        processRun: (executable, arguments) async {
          return ProcessResult(1234, 0, '5.72', '');
        },
      );

      final available = await service.isBluetoothctlAvailable();
      expect(available, isTrue);
    },
  );

  test(
    'isPairedAndTrusted returns true when paired and trusted are yes',
    () async {
      final service = LinuxBlePairingService(
        processRun: (executable, arguments) async {
          return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: yes
''', '');
        },
      );

      final trusted = await service.isPairedAndTrusted('AA:BB:CC:DD:EE:FF');
      expect(trusted, isTrue);
    },
  );

  test('pairAndTrust returns false when bluetoothctl is unavailable', () async {
    final service = LinuxBlePairingService(
      processStart: (executable, arguments) async {
        throw const ProcessException(
          'bluetoothctl',
          <String>[],
          'not found',
          2,
        );
      },
    );

    final paired = await service.pairAndTrust(remoteId: 'AA:BB:CC:DD:EE:FF');
    expect(paired, isFalse);
  });

  test('trustDevice verifies trust after trust command succeeds', () async {
    final logs = <String>[];
    final service = LinuxBlePairingService(
      processRun: (executable, arguments) async {
        switch (arguments.first) {
          case 'trust':
            return ProcessResult(1234, 0, 'trust succeeded', '');
          case 'info':
            return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: yes
''', '');
        }
        fail('Unexpected bluetoothctl arguments: $arguments');
      },
    );

    final trusted = await service.trustDevice(
      'AA:BB:CC:DD:EE:FF',
      onLog: logs.add,
    );

    expect(trusted, isTrue);
    expect(logs.any((line) => line.contains('Verified BlueZ trust')), isTrue);
  });

  test(
    'trustDevice returns false when trust verification stays untrusted',
    () async {
      final logs = <String>[];
      final service = LinuxBlePairingService(
        processRun: (executable, arguments) async {
          switch (arguments.first) {
            case 'trust':
              return ProcessResult(1234, 0, 'trust succeeded', '');
            case 'info':
              return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: no
''', '');
          }
          fail('Unexpected bluetoothctl arguments: $arguments');
        },
      );

      final trusted = await service.trustDevice(
        'AA:BB:CC:DD:EE:FF',
        onLog: logs.add,
      );

      expect(trusted, isFalse);
      expect(
        logs.any((line) => line.contains('trust verification failed')),
        isTrue,
      );
    },
  );

  test(
    'pairAndTrust fails when pairing reports success but trust is not restored',
    () async {
      final logs = <String>[];
      final service = LinuxBlePairingService(
        processStart: (executable, arguments) async =>
            _FakeProcess(stdoutText: 'Pairing successful\n'),
        processRun: (executable, arguments) async {
          switch (arguments.first) {
            case 'trust':
              return ProcessResult(1234, 0, 'trust succeeded', '');
            case 'info':
              return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: no
''', '');
          }
          fail('Unexpected bluetoothctl arguments: $arguments');
        },
      );

      final paired = await service.pairAndTrust(
        remoteId: 'AA:BB:CC:DD:EE:FF',
        onLog: logs.add,
      );

      expect(paired, isFalse);
      expect(
        logs.any((line) => line.contains('trust was not restored')),
        isTrue,
      );
    },
  );

  test(
    'pairAndTrust succeeds without requesting proactive PIN after success',
    () async {
      final logs = <String>[];
      var pinRequests = 0;
      final service = LinuxBlePairingService(
        processStart: (executable, arguments) async =>
            _FakeProcess(stdoutText: 'Pairing successful\n'),
        processRun: (executable, arguments) async {
          switch (arguments.first) {
            case 'trust':
              return ProcessResult(1234, 0, 'trust succeeded', '');
            case 'info':
              return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: yes
''', '');
          }
          fail('Unexpected bluetoothctl arguments: $arguments');
        },
      );

      final paired = await service.pairAndTrust(
        remoteId: 'AA:BB:CC:DD:EE:FF',
        onLog: logs.add,
        onRequestPin: () async {
          pinRequests++;
          return '123456';
        },
      );

      expect(paired, isTrue);
      expect(pinRequests, 0);
      expect(
        logs.any((line) => line.contains('did not complete before timeout')),
        isFalse,
      );
    },
  );

  test(
    'pairAndTrust sends empty line when blank PIN is submitted (not cancel)',
    () async {
      final logs = <String>[];
      late final _FakeProcess fakeProc;
      final service = LinuxBlePairingService(
        processStart: (executable, arguments) async {
          fakeProc = _FakeProcess(stdoutText: '', autoFinish: false);
          // Emit PIN prompt after an event-loop tick (not microtask) so
          // broadcast listeners are attached first.
          Timer.run(() {
            fakeProc.emitStdout('Enter PIN code:\n');
            Future<void>.delayed(const Duration(milliseconds: 100), () {
              fakeProc.emitStdout('Pairing successful\n');
              Future<void>.delayed(const Duration(milliseconds: 50), () {
                fakeProc.finishProcess();
              });
            });
          });
          return fakeProc;
        },
        processRun: (executable, arguments) async {
          switch (arguments.first) {
            case 'trust':
              return ProcessResult(1234, 0, 'trust succeeded', '');
            case 'info':
              return ProcessResult(1234, 0, '''
Device AA:BB:CC:DD:EE:FF
  Paired: yes
  Trusted: yes
''', '');
          }
          fail('Unexpected bluetoothctl arguments: $arguments');
        },
      );

      final paired = await service.pairAndTrust(
        remoteId: 'AA:BB:CC:DD:EE:FF',
        timeout: const Duration(seconds: 5),
        onLog: logs.add,
        onRequestPin: () async => '',
      );

      expect(paired, isTrue);
      expect(logs.any((line) => line.contains('Blank PIN submitted')), isTrue);
      expect(logs.any((line) => line.contains('cancelling pairing')), isFalse);
    },
  );

  test('pairAndTrust cancels pairing when PIN dialog returns null', () async {
    final logs = <String>[];
    final service = LinuxBlePairingService(
      processStart: (executable, arguments) async {
        final proc = _FakeProcess(stdoutText: '', autoFinish: false);
        Timer.run(() {
          proc.emitStdout('Enter PIN code:\n');
          // Process will be killed/quit by the pairing service after cancel
          Future<void>.delayed(const Duration(milliseconds: 200), () {
            proc.finishProcess();
          });
        });
        return proc;
      },
      processRun: (executable, arguments) async {
        return ProcessResult(1234, 0, '', '');
      },
    );

    final paired = await service.pairAndTrust(
      remoteId: 'AA:BB:CC:DD:EE:FF',
      timeout: const Duration(seconds: 3),
      onLog: logs.add,
      onRequestPin: () async => null,
    );

    expect(paired, isFalse);
    expect(logs.any((line) => line.contains('cancelled by user')), isTrue);
  });
}
