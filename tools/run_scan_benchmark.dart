import 'dart:convert';
import 'dart:io';

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

Future<void> main(List<String> arguments) async {
  final options = <String, String>{};
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (!argument.startsWith('--') || separator < 0) {
      throw ArgumentError('Expected --name=value, got $argument');
    }
    options[argument.substring(2, separator)] = argument.substring(
      separator + 1,
    );
  }
  const allowed = {
    'pairs',
    'seconds',
    'warmup',
    'rates',
    'devices',
    'output',
    'skip-build',
    'baseline-binary',
    'current-binary',
    'scenario',
    'history',
  };
  if (options.keys.any((key) => !allowed.contains(key))) {
    throw ArgumentError('Unknown option: $options');
  }
  final pairs = int.parse(options['pairs'] ?? '5');
  final seconds = int.parse(options['seconds'] ?? '30');
  final warmup = int.parse(options['warmup'] ?? '5');
  final devices = int.parse(options['devices'] ?? '12');
  final scenario = options['scenario'] ?? 'scanner';
  final history = int.parse(options['history'] ?? '1000');
  final compareBinaries = options.containsKey('baseline-binary');
  if (compareBinaries != options.containsKey('current-binary')) {
    throw ArgumentError('Provide both --baseline-binary and --current-binary');
  }
  final binaries = {
    if (compareBinaries)
      for (final variant in ['baseline', 'current'])
        variant: File(options['$variant-binary']!).absolute,
  };
  for (final binary in binaries.values) {
    if (!binary.existsSync()) {
      throw ArgumentError('Missing benchmark executable: ${binary.path}');
    }
  }
  final rates = (options['rates'] ?? '0,4,20,100')
      .split(',')
      .map(int.parse)
      .toSet()
      .toList();
  if (pairs < 1 ||
      seconds < 1 ||
      warmup < 1 ||
      devices < 1 ||
      devices > 255 ||
      history < 1 ||
      history > 10000 ||
      !{
        'scanner',
        'chat-notify',
        'chat-arrival',
        'chat-status',
        'ble-log',
        'ble-log-raw',
      }.contains(scenario) ||
      rates.isEmpty ||
      rates.any((rate) => rate < 0 || rate > 1000) ||
      !{'true', 'false'}.contains(options['skip-build'] ?? 'false')) {
    throw ArgumentError('Invalid benchmark options: $options');
  }
  final output = Directory(
    options['output'] ??
        '${Directory.systemTemp.path}/meshcore-scan-${DateTime.now().millisecondsSinceEpoch}',
  ).absolute;
  if (output.existsSync()) {
    throw ArgumentError(
      'Output directory must not already exist: ${output.path}',
    );
  }
  output.createSync(recursive: true);
  stdout.writeln('Results: ${output.path}');
  final manifest = <String, Object?>{
    'started_at': DateTime.now().toUtc().toIso8601String(),
    'os': Platform.operatingSystemVersion,
    'logical_cpus': Platform.numberOfProcessors,
    'cpu_model': File('/proc/cpuinfo').readAsLinesSync().firstWhere(
      (line) => line.startsWith('model name'),
      orElse: () => '',
    ),
    'environment': {
      for (final key in [
        'DISPLAY',
        'WAYLAND_DISPLAY',
        'XDG_SESSION_TYPE',
        'GDK_BACKEND',
      ])
        key: Platform.environment[key],
    },
    'options': {
      'pairs': pairs,
      'seconds': seconds,
      'warmup': warmup,
      'devices': devices,
      'rates': rates,
      'scenario': scenario,
      'history': history,
    },
    'comparison': compareBinaries
        ? 'Two release bundles, both using current scan throttling. UI-only synthetic replay, no BLE or USB.'
        : scenario.startsWith('ble-log')
        ? 'Same release binary; benchmark baseline immediately notifies the BLE log screen, current batches notifications every 50ms. Frame capture and retention are identical; no radio transport.'
        : 'Same release binary; baseline immediate notifyListeners versus current ScanUpdateThrottle.schedule; both retain connector 50ms batching. Synthetic results, no real BLE reception or USB.',
    'binaries': {
      for (final entry in binaries.entries) entry.key: entry.value.path,
    },
  };
  for (final command in [
    ['git', 'rev-parse', 'HEAD'],
    ['git', 'status', '--short'],
    ['flutter', '--version'],
  ]) {
    final result = await Process.run(command.first, command.sublist(1));
    if (result.exitCode != 0) {
      throw StateError('${command.join(' ')} failed: ${result.stderr}');
    }
    manifest[command.join(' ')] = (result.stdout as String).trim();
  }
  final diff = await Process.run('git', ['diff', 'HEAD']);
  if (diff.exitCode != 0) throw StateError('Cannot capture baseline diff');
  File('${output.path}/tracked.diff').writeAsStringSync(diff.stdout as String);
  for (final source in [
    'tools/benchmark_scan_updates.dart',
    'tools/run_scan_benchmark.dart',
    'lib/utils/scan_update_throttle.dart',
    'lib/connector/meshcore_connector.dart',
    'lib/widgets/mesh_ui.dart',
    'lib/screens/scanner_screen.dart',
    'lib/screens/chat_screen.dart',
  ]) {
    final destination = File('${output.path}/sources/$source');
    destination.parent.createSync(recursive: true);
    File(source).copySync(destination.path);
  }
  File(
    '${output.path}/manifest.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

  if (!compareBinaries && options['skip-build'] != 'true') {
    final build = await Process.start('flutter', [
      'build',
      'linux',
      '--release',
      '--target=tools/benchmark_scan_updates.dart',
    ], mode: ProcessStartMode.inheritStdio);
    if (await build.exitCode != 0) throw StateError('Release build failed');
  }
  final arch = Platform.version.contains('arm64') ? 'arm64' : 'x64';
  final binary = File(
    'build/linux/$arch/release/bundle/meshcore_open',
  ).absolute;
  if (!compareBinaries && !binary.existsSync()) {
    throw StateError('Missing bundle: ${binary.path}');
  }
  final bundleHashes = <String, String>{};
  for (final entry
      in (compareBinaries ? binaries : {'shared': binary}).entries) {
    final result = await Process.run('sha256sum', [
      entry.value.path,
      '${entry.value.parent.path}/lib/libapp.so',
      '${entry.value.parent.path}/lib/libflserial.so',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Cannot fingerprint ${entry.key} bundle: ${result.stderr}',
      );
    }
    bundleHashes[entry.key] = (result.stdout as String).trim();
  }
  manifest['bundle_sha256'] = bundleHashes;
  final existingApps = await Process.run('ps', [
    '-C',
    'meshcore_open',
    '-o',
    'pid=,pcpu=,args=',
  ]);
  manifest['existing_app_processes'] = (existingApps.stdout as String).trim();
  File(
    '${output.path}/manifest.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  final runs = <Map<String, dynamic>>[];
  for (final rate in rates) {
    for (var pair = 0; pair < pairs; pair++) {
      final order = pair.isEven
          ? ['baseline', 'current']
          : ['current', 'baseline'];
      for (final policy in order) {
        final notificationPolicy = compareBinaries ? 'current' : policy;
        final name = 'rate-$rate-pair-${pair + 1}-$policy';
        stdout.writeln('Running $name');
        final runtime = Directory('${output.path}/runtime/$name')
          ..createSync(recursive: true);
        final process = await Process.start(
          (binaries[policy] ?? binary).path,
          [
            '--policy=$notificationPolicy',
            '--rate=$rate',
            '--seconds=$seconds',
            '--warmup=$warmup',
            '--devices=$devices',
            '--scenario=$scenario',
            '--history=$history',
          ],
          environment: {
            'XDG_CONFIG_HOME': '${runtime.path}/config',
            'XDG_DATA_HOME': '${runtime.path}/data',
          },
        );
        final outputText = process.stdout.transform(utf8.decoder).join();
        final errorText = process.stderr.transform(utf8.decoder).join();
        final code = await process.exitCode.timeout(
          Duration(seconds: 3 * (seconds + warmup) + 60),
          onTimeout: () {
            process.kill(ProcessSignal.sigkill);
            throw StateError('Benchmark timed out: $name');
          },
        );
        final text = await outputText;
        final errors = await errorText;
        File('${output.path}/$name.log').writeAsStringSync('$text\n$errors');
        if (code != 0) {
          throw StateError('$name exited $code; see ${output.path}/$name.log');
        }
        final record = text
            .split('\n')
            .singleWhere((line) => line.startsWith('SCAN_BENCHMARK '));
        final result =
            jsonDecode(record.substring('SCAN_BENCHMARK '.length))
                as Map<String, dynamic>;
        if (result['valid'] != true ||
            result['policy'] != notificationPolicy ||
            result['rate_hz'] != rate ||
            result['requested_seconds'] != seconds ||
            result['devices'] != devices) {
          throw StateError('Invalid or mismatched run: $record');
        }
        if (result['scenario'] != scenario || result['history'] != history) {
          throw StateError('Mismatched UI workload: $record');
        }
        final expectedMessages = scenario.startsWith('chat-')
            ? history +
                  (scenario == 'chat-arrival'
                      ? 1 + rate * (warmup + seconds)
                      : 0)
            : 0;
        if (result['events'] != rate * seconds ||
            result['final_message_count'] != expectedMessages ||
            result['final_event_notified'] != true ||
            result['flutter_errors'] != 0) {
          throw StateError('Incomplete UI workload: $record');
        }
        result['pair'] = pair + 1;
        result['variant'] = policy;
        result['run_order'] = runs.length + 1;
        runs.add(result);
        File(
          '${output.path}/runs.jsonl',
        ).writeAsStringSync('${jsonEncode(result)}\n', mode: FileMode.append);
        stdout.writeln(
          '  CPU ${(result['cpu_percent'] as num).toStringAsFixed(2)}%, '
          '${result['events']} events, ${result['notifications']} notifications',
        );
      }
    }
  }

  final summary = <Map<String, Object?>>[];
  for (final rate in rates) {
    final matching = runs.where((run) => run['rate_hz'] == rate).toList();
    double medianFor(String policy, String field) => _median(
      matching
          .where((run) => run['variant'] == policy)
          .map((run) => (run[field] as num).toDouble())
          .toList(),
    );
    final baseline = medianFor('baseline', 'cpu_percent');
    final current = medianFor('current', 'cpu_percent');
    final pairedDrops = <double>[];
    for (var pair = 1; pair <= pairs; pair++) {
      final paired = matching.where((run) => run['pair'] == pair);
      pairedDrops.add(
        (paired.singleWhere(
                      (run) => run['variant'] == 'baseline',
                    )['cpu_percent']
                    as num)
                .toDouble() -
            (paired.singleWhere(
                      (run) => run['variant'] == 'current',
                    )['cpu_percent']
                    as num)
                .toDouble(),
      );
    }
    pairedDrops.sort();
    summary.add({
      'rate_hz': rate,
      'pairs': pairs,
      'baseline_median_cpu_percent': baseline,
      'current_median_cpu_percent': current,
      'median_relative_reduction_percent': baseline == 0
          ? null
          : 100 * (baseline - current) / baseline,
      'paired_drop_median_percentage_points': _median(pairedDrops),
      'paired_drop_min_percentage_points': pairedDrops.first,
      'paired_drop_max_percentage_points': pairedDrops.last,
      'baseline_median_notifications': medianFor('baseline', 'notifications'),
      'current_median_notifications': medianFor('current', 'notifications'),
      'baseline_median_rss_bytes': medianFor('baseline', 'rss_bytes'),
      'current_median_rss_bytes': medianFor('current', 'rss_bytes'),
      'baseline_median_build_p95_ms': medianFor('baseline', 'build_p95_ms'),
      'current_median_build_p95_ms': medianFor('current', 'build_p95_ms'),
      'baseline_median_listener_age_p95_ms': medianFor(
        'baseline',
        'listener_age_p95_ms',
      ),
      'current_median_listener_age_p95_ms': medianFor(
        'current',
        'listener_age_p95_ms',
      ),
    });
  }
  final formatted = const JsonEncoder.withIndent('  ').convert(summary);
  File('${output.path}/summary.json').writeAsStringSync(formatted);
  stdout.writeln(formatted);
  stdout.writeln(
    'Raw runs, logs, source snapshot and manifest: ${output.path}',
  );
}
