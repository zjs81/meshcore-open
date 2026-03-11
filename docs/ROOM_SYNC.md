# Room Sync Feature Guide

This document describes the room server auto-sync feature and the minimum validation expected before opening a pull request.

## Scope

Room sync adds app-side reliability for room server catch-up:

- Optional auto-login to room servers with saved passwords
- Push-priority queued message sync with timeout and exponential backoff fallback
- Per-room auto-sync control (rooms are opt-in by default)
- Room sync status indicators in contacts and room chat header
- Global room sync tuning in app settings

## User Controls

### Global controls

App settings include:

- Enable room auto-sync
- Auto-login saved room sessions
- Base sync interval (seconds)
- Max backoff interval (seconds)
- Sync timeout (seconds)
- Stale threshold (minutes)

Default tuning is conservative for low traffic:

- Base interval: `300s`
- Max backoff: `3600s`
- Sync timeout: `20s`
- Stale threshold: `45m`

When firmware emits `PUSH_CODE_MSG_WAITING`, room sync schedules an immediate catch-up (throttled) for enabled active rooms.

### Per-room control

From Contacts, long-press a room server and use:

- `Auto-sync this room` switch

Auto-sync is disabled by default for newly discovered rooms. When disabled, that room is excluded from auto-login and periodic sync.

Saving and using a successful manual room login will automatically opt that room into auto-sync unless it was explicitly disabled.

## Status Meanings

- `Connected, synced`: active room session with recent successful sync
- `Syncing...`: sync cycle currently in progress
- `Connected, stale`: room session active but last successful sync is older than stale threshold
- `Not logged in`: sync is enabled but no active room session
- `Sync disabled`: per-room auto-sync is turned off
- `Room sync off`: global room sync feature is disabled

## PR Validation Checklist

Run this checklist on a real Android device and at least one room server.

1. Enable global room sync and auto-login, keep one room enabled.
2. Save room password, disconnect BLE, reconnect BLE.
3. Confirm room reaches `Connected, synced` without manual login.
4. Set very short timeout and confirm status transitions during intermittent RF.
5. Disable auto-sync for one room and verify it shows `Sync disabled`.
6. Confirm enabled room still syncs while disabled room does not.
7. Re-enable disabled room and verify login/sync resumes.
8. Confirm app restart preserves per-room toggle state and room statuses.
9. Run `flutter analyze` with no new issues.

## Notes

- Feature is app-side and protocol-compatible with current room server firmware.
- Per-room selection is the intended way to avoid syncing every room in large node lists.
