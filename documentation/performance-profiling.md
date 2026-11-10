# Performance and memory profiling

Use `flutter run --profile` to measure frame times and memory after repeating
the same actions. Debug builds also retain Dart source, JIT code and debugger
objects, so their process memory is not a release-build baseline.

## HTTP recording retains response bodies

Dart's HTTP timeline logging defaults to off. The app does not enable it.
Developer tools can enable it through the VM service, independently of the
app's debug-log settings. When enabled, Dart retains HTTP request records and
response bodies until those captures are cleared. Map browsing and downloads
can therefore increase profiling memory even after the app stops displaying
the downloaded images. Stopping recording does not clear earlier captures.

For a memory baseline, stop HTTP recording and clear its captures in DevTools'
Network view. Close or disconnect tools that turn recording back on. If the
Network controls are unavailable, run this command from the repository root
with the Dart VM service URI printed by `flutter run`:

```sh
dart run scripts/reset_http_profile.dart http://127.0.0.1:PORT/TOKEN=/
```

This explicitly stops HTTP recording and clears the retained Dart HTTP profile
in the running app's main isolate. Save any captures you need first. It does
not delete downloaded map tiles, change app settings, stop network requests or
change CPU/timeline profiling. You can enable HTTP recording again in DevTools
when investigating network requests. Other HTTP profiling providers may keep
their own records; the command reports any requests that remain.

After clearing, use DevTools' memory view to collect garbage and compare live
heap snapshots at the same point in the workflow. Process RSS can remain high
because the runtime and native libraries can keep reusable allocations; a
larger RSS alone does not establish a leak. Keep frame measurements collected
before heap inspection separate from collection pauses caused by diagnostics.

## Local history storage

Native apps store direct messages, channel messages, and route histories in
`history_v1.db` in the application support directory. Small preferences remain
in SharedPreferences. Web builds continue to use browser preferences.

The first launch after upgrading imports existing histories. The database has a
schema version and a separate import version, so a completed import is skipped
on later launches. Source preferences are removed only after their database
writes commit; an interrupted import retries safely. Unreadable history values
remain in preferences for recovery instead of being discarded; new messages for
that conversation are saved to the database beside them. A failed import step
does not stop the app: the database is used and the step repeats on the next
launch. If the database cannot be opened at all, that run keeps histories in
preferences, and the next launch that opens the database merges them in.

Chat history is indexed by entry, allowing older pages to be read without loading
the whole conversation. Backups include native database histories and restore
them into the selected radio's scope. Review-mode cleanup also covers the database.
For a manual full application-data copy, keep the history database alongside the
application's other support files; copying the preferences file alone no longer
includes native message or route histories.
