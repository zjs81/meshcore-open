# Linux CPU performance measurements

## Scope

The working-tree change tested on 2026-10-31 adds a 250 ms
`ScanUpdateThrottle` around BLE scan-result notifications. The reference
commit is `4454033f821851de2b0e5d478edcb7761f41999f`. The connector already
batches `notifyListeners()` calls for 50 ms; the baseline is not an unlimited
UI rebuild per advertisement.

The original scan-throttle patch does not change USB reception, connected
chat, map, or log processing. Later sections record separate measured UI and
USB optimizations. A USB-connected idle measurement is not a test of the BLE
scan throttle's benefit; the connector refuses to start a BLE scan during an
active USB connection.

## Repeatable Scanner Replay

From the repository root:

```bash
nix develop
dart run tools/run_scan_benchmark.dart \
  --pairs=5 --seconds=30 --warmup=5 --rates=0,4,20,100 --devices=12
```

The driver builds a Linux release executable targeting
`tools/benchmark_scan_updates.dart`. Both policies run in the same binary:

- `baseline` updates the replayed results and calls the real connector's
  `notifyListeners()` directly, matching the old scan callback.
- `current` updates the same results and calls the production
  `ScanUpdateThrottle.schedule()`, matching the changed callback.

Both retain the connector's 50 ms batching and render the actual
`ScannerScreen` and device tiles. Twelve synthetic device entries have changing
RSSI values. Every scheduled input is processed; intermediate notifications
are intentionally coalesced. The final input must have been notified after
the fixed 400 ms drain window. Rendering errors or missing frames invalidate
the run.

This isolates the notification policy; it is **not** a pair of full app builds
at different revisions or a native BLE scan. It excludes Bluetooth discovery,
platform-channel delivery, and Linux paired-device merging. Only claim the
measured scanner UI benefit, not a general application or hardware saving.

Each pair alternates baseline/current order. Each process receives a fresh
isolated preferences directory, with the network-backed node banner disabled
identically. The driver saves the reference SHA, tracked diff, relevant source
snapshots, SDK/host/display environment, logs, raw JSONL runs, and a summary.
Results default to a new directory under `/tmp`; use `--output=/new/path` to
keep them elsewhere. An existing output directory is rejected.

Options include `--pairs`, `--seconds`, `--warmup`, `--rates`, `--devices`,
`--output`, and `--skip-build=true`. Only skip the build when the release
bundle was built from the intended benchmark source. Keep the window visible
at the same size, use the same display/power settings, and avoid concurrent
builds, tests, or other app instances during measurement. Lower rates need
longer windows to collect useful latency samples.

CPU is the difference in process user-plus-system CPU ticks from
`/proc/self/stat`, divided by monotonic wall time. It includes all native
threads; 100% means one fully occupied logical core. It does not include GPU
or compositor CPU, child processes, or energy consumption. The fixed drain
window is included in both policies' CPU totals.

The summary reports medians and the range of paired CPU percentage-point
reductions. Mixed-sign paired changes are not evidence of a benefit. The
relative percentage is calculated from the two CPU medians, not from the
median of per-pair relative changes. No statistical confidence interval is
claimed for these short runs.

Frame timing and RSS samples are also recorded. `listener_age_*` measures time
from the **most recent** input to a listener notification, not the wait of the
first suppressed event and not an end-to-end UI visibility deadline. With
continuous traffic this value can be small despite intentional coalescing.
The new policy can add up to roughly 250 ms before notifying the existing
50 ms batcher, plus scheduling/rendering delay. A fixed synthetic rate is not
a realistic model of every advertisement burst.

## Scanner Results: 2026-10-31

Host: AMD Ryzen 9 5950X, 32 logical CPUs, Linux 7.3.0, Wayland session,
approximately 144 Hz display, Flutter 3.47.4 / Dart 3.13.3, release build,
Impeller OpenGL backend. These are local results, not cross-machine targets.

Five pairs per rate, 15 seconds of input per run, five seconds of warm-up,
12 device entries, and a 400 ms drain window:

| Events/s | Baseline CPU | Current CPU | Relative reduction | Paired reduction range |
| --- | --- | --- | --- | --- |
| 0 | 26.10% | 25.90% | No convincing change | -0.97 to +0.52 points |
| 4 | 27.91% | 28.89% | No convincing change | -2.14 to +2.33 points |
| 20 | 27.33% | 25.25% | 7.6% | +1.69 to +3.50 points |
| 100 | 29.15% | 25.37% | 13.0% | +2.79 to +3.85 points |

Every paired run at 20 and 100 events/s used less CPU with the new policy.
At 100 events/s, median notifications fell from 250 to 61 per measured run;
at 20 events/s, from 150 to 61. At 4 events/s both produced 60 notifications.
All 40 runs processed the expected input count, notified the final state,
and recorded zero Flutter errors. At 100 events/s, median RSS was approximately
296 MB baseline versus 295 MB current; do not infer a material memory benefit.

The throttle reduces update-driven UI work but does not stop the scanner's
ongoing animations. The quiet scanner still consumed about 26% of one core
on this host. At 4 events/s, median listener-age p95 increased from 52 ms to
135 ms without reducing notification counts. At 20 and 100 events/s those
median values were about 2/48 ms and 5/10 ms respectively (baseline/current).
Those freshness measurements are not maximum event-to-screen latency.

## UI Optimization: Direct Chat

The next UI change retains the composer outside the transcript's broad
connector `Consumer`. A selector rebuilds it only when the contact name or
either text-encoding mode changes. The composer still observes its own
translation settings, text controller, theme, and focus. Transcript updates
remain broad so same-length replacements, delivery status, and reactions
cannot become stale through list-identity or message-count shortcuts.

No scanner animation was changed. A pulse `RepaintBoundary`
experiment showed no convincing CPU improvement and was removed. Its two
15-second pilot pairs were approximately unchanged or slightly worse; desktop
activity also varied during that pilot. No scanner CPU saving is claimed.

The tools now support two independently built release bundles, keeping the
existing scan throttle identical in both. Preserve the **entire** baseline
bundle before a UI change, not just its executable, and build/copy the
candidate with the same SDK and benchmark target afterward:

```bash
flutter build linux --release --target=tools/benchmark_scan_updates.dart
```

Then compare those saved bundles from the repository root:

```bash
dart run tools/run_scan_benchmark.dart \
  --baseline-binary=/path/to/baseline-bundle/meshcore_open \
  --current-binary=/path/to/current-bundle/meshcore_open \
  --scenario=chat-notify --history=1000 \
  --pairs=5 --seconds=30 --warmup=30 --rates=20
```

In two-bundle mode the runner does not rebuild or overwrite either bundle.
It records executable, AOT library and serial-library SHA-256 fingerprints,
plus any other app processes present at collection start. `variant` identifies
the baseline/current UI bundle; `policy` remains `current` in both. Do not
confuse this comparison with the original same-binary scan-policy experiment.

Available `--scenario` values:

- `scanner`: the existing real scanner screen with synthetic scan results.
- `chat-notify`: the real direct-chat screen receives connector notifications,
  but its message history is unchanged.
- `chat-arrival`: new text messages are appended on each input event.
- `chat-status`: the final message alternates sent/delivered status without
  changing the history length.

`--history` sets the initial chat size (default 1000). Chat fixtures use the
screen's required settings, translation, text-scale and path-history providers,
with no radio connection or translation inference. They do not measure
transport processing. A zero-rate idle chat may legitimately produce no new
frames and remains valid. The driver validates input counts, final history
length, final event notification and zero Flutter errors. These checks do not
replace real-screen correctness tests or prove that every intermediate event
was individually painted.

### UI Results: 2026-10-31

Same host/display/toolchain as the earlier scanner results. Five alternating
pairs per scenario, 30 seconds warm-up, 30 seconds input plus a 400 ms drain,
1000 initially seeded messages:

| Workload | Baseline CPU | Current CPU | Relative reduction | Paired reduction range |
| --- | --- | --- | --- | --- |
| Unrelated notifications, 20 Hz | 8.95% | 7.99% | 10.7% | +0.92 to +1.05 points |
| Incoming text messages, 20 Hz | 17.83% | 16.94% | 5.0% | +0.66 to +2.43 points |
| Unrelated notifications, 1 Hz | 1.35% | 1.25% | No convincing change | -2.70 to +4.60 points |

Every paired 20 Hz run used less process CPU with the composer change. Both
variants processed 600 events and 300 batched notifications per measured
20 Hz run. The arrivals fixture continued appending during warm-up, leaving
2201 messages at the end of each run, including its initial event.

Median per-run build-duration p95 improved from 4.53 to 3.97 ms for unrelated
20 Hz notifications and from 6.96 to 6.40 ms for arrivals. The 1 Hz CPU results
had mixed signs and outliers, so their two medians are not evidence of a
repeatable saving. No material memory reduction is established.

Short paired status-change, arrival-integrity and idle-chat checks also passed.
The five-second idle chat control measured 0.00% CPU in both variants within
counter resolution; this is not a long idle or energy-consumption claim.
Initial pilots ran with another app instance present, which was left untouched;
its PID was absent before the longer measurements. Other desktop activity is
not controlled, particularly in the noisy 1 Hz case. All figures are workload-
specific process CPU results, not a general application speedup.

The real-screen regression tests cover retained composer/draft/focus on
unrelated notifications, same-count message replacements, new arrivals,
contact renaming, both encoding settings, delivery icons and retaining a
scrolled reading position. The test fixture lives in the benchmark target and
is not imported by the production application.

Raw runs, source snapshots, full baseline/candidate bundles and summaries are
retained at `~/.local/state/meshcore-open-benchmarks/ui-2026-10-31/` under
`chat-notify-20hz`, `chat-notify-1hz`, `chat-arrival-20hz`, and the separately
named pilot/smoke directories. Subsequent contacts/map optimizations and
transcript-wide filtering remain profiling-led follow-ups, not part of this
small composer change.

## Additional Runtime Hot Paths

### BLE Debug Log

`BleDebugLogService` continues to capture and retain every frame, with the
existing 500-entry cap. Listener notifications are coalesced to one per 50 ms,
and skipped when there are no listeners. `BleDebugLogScreen` snapshots only
the selected tab and indexes it newest-first instead of copying and reversing
both bounded log lists on every rebuild.

The release replay uses the same binary and same storage/retention code in both
variants; baseline notifications are immediate, current notifications batch
at 50 ms. Five alternating pairs, 30-second warm-up plus 30-second measurement,
100 synthetic frames/s, 3000 frames per run:

| Workload | Baseline CPU | Current CPU | Relative reduction | Paired reduction range |
| --- | --- | --- | --- | --- |
| BLE log screen, 100 frames/s | 46.41% | 14.27% | 69.2% | +30.85 to +35.49 points |
| Raw RX log tab, 100 frames/s | 46.84% | 14.70% | 68.6% | +31.34 to +33.78 points |

All frames were retained. UI notifications fell from 3000 to 500 per run in
both the frame view and raw RX view. The raw replay uses a valid synthetic
packet header and exercises the raw tab's packet decoding.
Notification latency adds up to 50 ms plus scheduling/rendering delay. This is
synthetic replay, not an RF receive benchmark. Raw runs:
`~/.local/state/meshcore-open-benchmarks/ui-2026-10-31/ble-log-100hz-same-binary-v2/`
and `~/.local/state/meshcore-open-benchmarks/ui-2026-10-31/ble-log-raw-100hz/`.
The earlier comparator accidentally combined immediate notifications with the
new timer; those invalid measurements are excluded.

### Message Persistence and Chat List

Message status, translation and reaction updates now use the existing
per-conversation `CoalescedWrites` queue instead of immediately serializing
the full stored conversation on every update. Explicit deletion remains
immediate and cancels any older pending conversation save first. The direct
chat list indexes its source messages in reverse rather than allocating a
reversed copy on each rebuild. Reverse order, day separators, status updates
and scroll position have regression coverage. The composite chat-arrival replay
including these changes measured 17.99% to 16.91% of one core (6.0% relative)
across five pairs, but a large outlier widened paired savings to 0.66–8.58
percentage points. This does not isolate the persistence or reverse-index
contribution; keep that CPU result provisional.

### Raw Channel Packet Lookup

Raw group-text packets now use a lazy index by the protocol's 8-bit channel
hash. All same-hash channels remain candidates for decryption, preserving
collision behavior. The index is invalidated on cached/live channel replacement,
channel responses, timeout restoration and failed-sync restoration. Connector
tests and analysis pass; no isolated CPU A/B is reported yet.

The map snapshot still scans contact/channel metadata on connector changes.
It is unchanged: reducing that work needs a mutation-complete revision contract
and an affected-map CPU benchmark. No map optimization is claimed.

Verification: all 1140 Flutter tests passed, including the direct-chat and BLE
debug-log batching tests. Full analysis and touched-file formatting passed. Normal
Linux profile and release builds passed and were restored to `lib/main.dart`.
The repository-wide formatter check still reports the pre-existing difference
in `test/services/tcp_transport_service_native_test.dart`; that file was not
modified. No physical radio was used for the UI measurements.

## Real USB Control

Use the supplied stable device identity, not an assumed `/dev/ttyUSB` number.
Verify read/write access and that no other process owns the port. The control
uses the real connector, normal handshake/synchronization and battery polling,
but a static window rather than the application's full connected UI. It is
a transport-only control. Normal sync sets device time and fetches queued
messages into the isolated preferences directory; preserve that directory if
the messages matter. The control does not flash firmware, change radio
configuration, or send chat messages.

```bash
nix develop
flutter build linux --release --target=tools/benchmark_scan_updates.dart
CONTROL_DIR=$(mktemp -d "$HOME/meshcore-usb-control.XXXXXX")
env XDG_CONFIG_HOME="$CONTROL_DIR/config" \
  XDG_DATA_HOME="$CONTROL_DIR/data" \
  timeout 600 build/linux/x64/release/bundle/meshcore_open \
  --usb=/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0 \
  --seconds=300 --warmup=60
```

Use `arm64` instead of `x64` on ARM Linux. The control waits for initial
contact/channel/queued-message sync before warm-up. It measures connected CPU
and per-thread CPU, checks connection health, performs three software
disconnect/reconnect cycles, measures twenty sequential read-only device-time
request/response latencies after idle, and samples five seconds after final
disconnect. These are not physical unplug/replug tests or a controlled RF
throughput test.

Read `valid` and the process exit status, not merely whether a log was created.
An initial hardware attempt with scanner navigation was invalidated by a
missing-provider error and continued initial sync. Its CPU result is excluded.

### USB Results: 2026-10-31

The baseline control used the supplied CP2102 bridge at 115200 baud, resolving
to `/dev/ttyUSB0`. With sync complete and 60 seconds of settling, the earlier
300-second baseline consumed 298.48 CPU seconds (**99.49% of one core**), with
four incidental frames and one native thread accounting for 298.44 seconds.
The native function was not verified by sampled stacks.

The desktop-Linux serial worker now sleeps for a bounded 5 ms only after an
iteration completes without RX or TX work. The initial focused result was:

- 15-second final smoke: 0.133% of one core with one incidental RX frame;
  connection healthy, three software reconnects passed, and CPU returned to
  0% after disconnect.
- 30-second idle validation: 0.167% of one core, zero incidental frames,
  stable connection and zero Flutter errors.
- Twenty serialized `CMD_GET_DEVICE_TIME` requests all replied: p50 11 ms,
  p95 12 ms and max 12 ms. These are post-change observations, not a
  before/after latency comparison.
- Three software reconnects passed again; post-disconnect CPU was 0% over five
  seconds.

This is a strong indication the serial worker caused the connected-idle CPU
load, but durations are not matched: rerun a fresh 300-second candidate and
controlled RX load before claiming a stable percentage improvement. Physical
unplug/replug and non-Linux platforms remain untested. No USB messages were
sent; time requests are read-only, while normal connection sync still updates
device time and reads queued messages into the isolated test profile.
No native PTY harness or continuous-RX/TX fairness test was added, so shutdown
under a live burst and write latency during sustained RX still need dedicated
coverage.

Candidate artifacts: `~/.local/state/meshcore-open-benchmarks/2026-10-31/usb-idle-yield-smoke.log`
and `usb-idle-yield-latency.log`. The earlier 300-second value is the baseline
control; it should not be confused with the short post-change samples above.

## Local Artifacts

On the test machine, results and isolated radio data are retained under
`~/.local/state/meshcore-open-benchmarks/2026-10-31/`:

- `meshcore-scan-benchmark-20261031-100hz/`: five high-rate pairs.
- `meshcore-scan-benchmark-20261031-lowrates/`: five pairs each at 20 and 4 Hz.
- `meshcore-scan-benchmark-20261031-quiet/`: five zero-event pairs.
- `usb-control-validated.log`: accepted five-minute hardware run and reconnects.
- `usb-control-validated-smoke.log`: corrected five-second hardware check.
- `usb-control/config/` and `usb-control/data/`: isolated hardware-run data.
- `ui-2026-10-31/ble-log-100hz-same-binary-v2/`: valid frame-log view A/B.
- `ui-2026-10-31/ble-log-raw-100hz/`: valid raw RX log tab A/B.
- `ui-2026-10-31/final-chat-arrival-20hz/`: aggregate chat-arrival A/B.
- `ui-2026-10-31/final-candidate-bundle/`: full release candidate bundle.
- `usb-idle-yield-latency.log`: current 30-second idle, requests and reconnects.
- `meshcore-usb-control-smoke/`: preserved earlier isolated sync data.

The earlier `usb-control.log` is invalid and excluded from the results.
Do not publish the runtime preference directories or raw radio logs: they may
contain contact details, messages, and channel configuration.

## Follow-up Profiling

The counters above do not require kernel perf sampling. For native stack
attribution, use a separate profile build and Sysprof as described in the
[Linux setup](../README.md#linux-with-nix). Verify that actual CPU samples
exist; a `--no-perf` capture cannot attribute CPU stacks. Host sampling access
was not changed for this benchmark. No full sampled-stack attribution is
claimed.

The benchmark replaces the normal release bundle in the generated build
directory. Restore a normal application bundle with:

```bash
flutter build linux --release --target=lib/main.dart
```

No production behavior is changed by the measurement tools. Keep radio data,
preferences, raw logs, and host captures out of source control.