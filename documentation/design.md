# UI Design Reference

How MeshCore Open's interface is built today, and the rules to follow when adding or changing UI. Every value below comes from the code it cites. If you change one of those sources, or settle on a new pattern, update this page in the same change.

The source of truth is `lib/theme/mesh_theme.dart` (theme), `lib/widgets/mesh_ui.dart` (shared widgets) and `lib/widgets/mesh_nav_tile.dart` (settings rows). Where the code disagrees with this page, fix one of them; do not copy the inconsistency.

## 1. Principles

- **Readable first.** Many users are older. Use the sizes in [Typography](#3-typography) as minimums, keep text and icons high-contrast, and never use colour as the only signal.
- **Theme and shared widgets, not ad-hoc values.** Take colours from `Theme.of(context).colorScheme` (or the theme extensions), text styles from `Theme.of(context).textTheme`, radii from `MeshRadii`, and build rows, cards, menus and sheets from the shared widgets in section 5.
- **Every label must survive a long translation.** The app ships 19 locales. Text wraps or scales; it never clips or breaks mid-word.
- **Respect the system text size.** The app does not clamp the system text scale (only `ReviewModeBanner` uses `MediaQuery.withClampedTextScaling`). Layouts must grow, wrap or scroll at large scales.
- **Material only.** No Cupertino widgets (`AGENTS.md`).

## 2. Colour and theme

`lib/main.dart` applies `MeshTheme.light()`, `MeshTheme.dark()`, or `MeshTheme.fromCustom(customTheme)` for custom, preset and holiday themes. All three go through `MeshTheme._build`, so component themes are identical; only the `ColorScheme` and three extensions change.

| Need | Use |
|---|---|
| Page background | `scheme.surface` (scaffold default) |
| Card / sheet / dialog / menu surface | `scheme.surfaceContainerLow` (cards, sheets, dialogs), `surfaceContainerHigh` (popup menus, snackbars, input fill) |
| Primary text | `scheme.onSurface` |
| Secondary text, icons, subtitles | `scheme.onSurfaceVariant` (the default `iconTheme` colour) |
| Borders and dividers | `scheme.outlineVariant` (card borders, dividers); `scheme.outline` (stronger: outlined buttons, input border) |
| Accent, selection, primary actions | `scheme.primary` / `onPrimary` |
| Destructive or error | `scheme.error`; banners use `errorContainer` / `onErrorContainer` |
| Warning | `scheme.tertiary` (amber), or `MeshPalette.warn` |
| Good / bad signal | `MeshTheme.snrColor(snr, blocked:)`; `MeshPalette.signal`, `.warn`, `.alert` for status ramps (e.g. battery in `repeater_status_screen.dart`) |
| Own chat bubbles | `MeshBubbleTheme.of(context)` |
| Map overlays and markers | `MapPalette`, `MeshMapTheme.of(context)`; line-of-sight charts use `LosPalette` |
| Coloured text or icon on a tinted background | pass it through `readableAccent(color, background, minContrast:)` (`mesh_ui.dart`), 4.5 for text, 3 for icons |

Rules:

- Do not use `MeshPalette.ink*`, `bg*` or `line*` directly in normal screens. They are the dark-theme values and are wrong in the light theme and in custom themes. Use the matching `ColorScheme` role.
- Do not use raw `Colors.red`, `Colors.grey[600]` and so on for UI chrome.
- Status colours (`error`, `tertiary`, `secondary`) are copied from the stock scheme of the same brightness in `fromCustom`, so they keep their meaning in custom themes.
- `StatusChip` shows how to colour a status: the label keeps `onSurface`, and only the dot or icon carries the colour.

Custom, preset and holiday themes (colours, icons, map markers, chat backgrounds) are described in [themes.md](themes.md). Use `ThemedIcon(ThemeIconSlot.…)` for the icons a theme can replace (tabs, send, settings, node avatars).

## 3. Typography

Fonts (`MeshFonts`): `Inter` (sans, the default), `JetBrains Mono` (mono), each with system fallbacks. `MeshTheme.display()` (serif) exists but is not used.

The text theme is the Material 3 2021 type scale (`Typography.material2021`) with Inter and `onSurface` colour applied in `MeshTheme._build`. Sizes are Flutter's defaults:

| Style | Size / weight | Used for |
|---|---|---|
| `titleLarge` | 22 / 400 | Rare large headings |
| `titleMedium` | 16 / 500 | Sheet titles (`BottomSheetHeader`, w700), empty-state titles (`EmptyState`, w600) |
| `titleSmall` | 14 / 500 | Sub-headings inside cards, banner titles (`RadioDisconnectedBanner`, w700) |
| `bodyLarge` | 16 / 400 | Body text; **settings tile titles at w600** (`meshTileTitleStyle`) |
| `bodyMedium` | 14 / 400 | Default `Text`; tile subtitles in `onSurfaceVariant` |
| `bodySmall` | 12 / 400 | Sheet subtitles, captions |
| `labelMedium` | 12 / 500 | Bottom navigation labels (`QuickSwitchBar`) |
| `labelSmall` | 11 / 500 | Avoid for anything the user must read |

Component text set explicitly in `MeshTheme._build`:

| Component | Style |
|---|---|
| App bar title | 20, w600, letter-spacing -0.2 |
| Filled / elevated button | 14, w600 |
| Segmented button | 13, w600 |
| Tab bar | 13.5, w700 selected, w500 unselected |
| Chip label | 12.5, w600 |
| Snackbar content | 16 |
| Tooltip | 12 |
| Slider value label | mono 12 |

Which style to use:

| Text | Style |
|---|---|
| Screen title | App bar default (20/w600); don't override |
| Section header above a card | `SectionHeader` (upper-cased `MeshTheme.accentLabel`, 13, w700, letter-spacing 0.6, `onSurfaceVariant`) |
| Settings / list row title | `meshTileTitleStyle(theme)` = `bodyLarge` w600. Inside `MeshSettingsTileTheme`, stock `ListTile`/`SwitchListTile`/`CheckboxListTile` titles get it automatically |
| Row subtitle | `bodyMedium`, `onSurfaceVariant` (stock `ListTile` default; `MeshNavTile` sets it) |
| Body copy, dialog content | `bodyMedium` / `bodyLarge` |
| Numbers, units, keys, hashes, CLI output, counts | `MeshTheme.mono(...)` (tabular figures). `StatTile` values are mono 20/w600 with a mono 12 unit |
| Timestamps, meta text | 12 minimum (`bodySmall` or `fontSize: 12`) |
| Chat message body | 14 × chat text scale (`chat_screen.dart` `bodyFontSize`) |

Minimum sizes: no hard-coded `fontSize` below 12 exists in `lib/screens` or `lib/widgets`; keep it that way. `MeshTheme.accentLabel()` defaults to 11, so always pass `fontSize:` (12 or more). Prefer a `textTheme` style over a literal `fontSize`.

**Chat text scale.** `ChatTextScaleService` (0.8–1.8, pinch in `chat_zoom_wrapper.dart`) multiplies chat text only. It stacks with the system scale. Read it with `context.select<ChatTextScaleService, double>((s) => s.scale)`.

## 4. Spacing, shape and sizing

| Thing | Value | Source |
|---|---|---|
| Screen side padding | 16 | `MeshCard.margin`, `SectionHeader.padding`, `MeshNavTile.padding` |
| Card | margin 16 horizontal / 4 vertical, padding 14, radius `MeshRadii.md` (14), 1px `outlineVariant` border, `surfaceContainerLow` fill, no elevation | `MeshCard` |
| Card holding tiles | `MeshCard(padding: EdgeInsets.zero)`, rows separated by `Divider(height: 1, indent: 16)` | `app_settings_screen.dart`, `settings_screen.dart` |
| Section header | padding 16, 20, 16, 8 (LTRB) | `SectionHeader` |
| Settings row | padding 16 / 12, 24px icon, 16 gap, chevron 24 | `MeshNavTile` |
| Switch row | `SwitchListTile`, `contentPadding` 16 / 4, `secondary` icon size 24 | `app_settings_screen.dart` |
| Popup menu row | 20px icon, 12 gap | `MeshMenuItemRow` |
| Banner | padding 16 / 12, 24px icon, 12 gap | `RadioDisconnectedBanner` |
| Sheet header | padding 20, 8, 8, 4 (LTRB), 36×4 drag handle | `BottomSheetHeader` |
| Radii | `MeshRadii.xs` 6, `sm` 10, `md` 14 (cards, inputs, menus, snackbars, list tiles), `lg` 18 (sheets, dialogs), `xl` 24, `pill` 999 (buttons, chips, FAB) | `MeshRadii` |
| Default icon size | 22 | `iconTheme` |
| Avatar | 40 | `AvatarCircle` |
| List bottom padding under a FAB | 88 | `channels_screen.dart` |

Icon sizes in use: 24 for tile and banner icons, 20 for menu icons and small action buttons, 18 for inline refresh icons and spinners. Keep tappable icons at 20 or more.

**Tap targets.** Keep Flutter's 48×48 minimum (the default `materialTapTargetSize` and `IconButton` size). Don't shrink with `VisualDensity.compact`, `MaterialTapTargetSize.shrinkWrap` or small `BoxConstraints` unless the control sits inside a larger tappable row.

## 5. Components

| Need | Use | Notes |
|---|---|---|
| Group of related content | `MeshCard` | `onTap`/`onLongPress` give ink feedback; long-press adds a selection haptic |
| Label above a group | `SectionHeader(label, trailing:)` | Upper-cases for you; pass the normal-case l10n string |
| Settings navigation row | `MeshNavTile` | `onTap: null` dims it to 50 % and reports it as disabled; use `subtitle` to say why |
| Settings switch | `SwitchListTile` inside `MeshSettingsTileTheme` | Wrap the settings screen body once in `MeshSettingsTileTheme` |
| Radio-style choice in a sheet | `MeshSheetOption` | Used by the language picker and map time filter |
| Popup menu row | **always** `PopupMenuItem(child: MeshMenuItemRow(icon:, label:))` | Label wraps to 2 lines then ellipsizes; `leading:` for `ThemedIcon`; no icon keeps the 20px slot |
| Segmented button label | **always** `ButtonSegment(label: MeshSegmentLabel(text))` | Shrinks to 12 (before system scale), then wraps at word boundaries onto 2 centred lines; never breaks a word |
| Status | `StatusChip` | Mono label, coloured dot or icon |
| Metric | `StatTile` | Label wraps to 2 lines; value wraps |
| Signal | `SignalBars`, `MeshTheme.snrColor` | |
| Route kind | `RouteChip` | Direct / hop count / Flood |
| Count badge | `Badge` on nav icons (`QuickSwitchBar`, caps at 99+), `UnreadBadge` in lists (alert red, mono 12) | |
| Empty list | `EmptyState(icon:, title:, subtitle:, action:)` | Scrolls rather than overflowing at large text |
| Inline error with retry | `ErrorRetryCard(message:, onRetry:, retryLabel:)` | Pass `retryLabel: context.l10n.common_retry` |
| Radio offline on a remote-node screen | `RadioDisconnectedBanner` | Renders nothing while connected |
| Sync progress | `SyncProgressAppBarBottom` as the app bar `bottom` | 3px bar |
| Toast message | `showDismissibleSnackBar(context, content: Text(...))` | Tap to dismiss, replaces the current snackbar, safe after an async gap |
| List item entrance | `ListEntrance(index:)` | Optional |

**Buttons.** Theme shapes are all pill-shaped. In use:

- `FilledButton` / `FilledButton.icon`: the primary action of a dialog, sheet, empty state or form (e.g. "Add public channel" in `EmptyState`, Save in the discard dialog in `repeater_settings_screen.dart`). One per view.
- `FilledButton.tonal`: a secondary action that still needs weight (rare).
- `OutlinedButton(.icon)`: secondary actions next to a filled one.
- `TextButton`: Cancel and low-emphasis actions in dialogs; inline actions in cards.
- Destructive confirm: `FilledButton` with `backgroundColor: scheme.error`, `foregroundColor: scheme.onError` (`showConfirmClearDialog` in `widgets/confirm_clear_dialog.dart`), or a `TextButton` with `foregroundColor: scheme.error` when it is not the primary action.
- Dialog action order: Cancel first, primary last.
- Avoid `ElevatedButton` in new code.

**FAB.** One per screen, for the main "add" action (`contacts_screen.dart`, `channels_screen.dart`) or primary action (`FloatingActionButton.extended` in `themes_screen.dart`, `scanner_screen.dart`). Always give it a `tooltip` or a label.

**IconButton.** Always set `tooltip:` with a localized string. It is the accessible name.

## 6. Sheets, dialogs and pages

What the code does:

| Container | Call | Used for | Examples |
|---|---|---|---|
| Bottom sheet | `showMeshSheet` + `BottomSheetHeader` (28 calls in 17 files) | Choosing from a list, an item's actions, quick tools tied to the current screen | Language picker, notification mode, add contact/channel options, emoji and GIF pickers, node info, share contact, image actions |
| Draggable sheet | `showModalBottomSheet` + `DraggableScrollableSheet` | Tall, scrollable panels that need a drag size | `ContactRoutingSheet` (`routing_sheet.dart`), path editor, image send preview |
| Dialog | `showDialog` + `AlertDialog` (72 calls in 35 files) | Confirming an action, a short input (one to three fields), a short message | Disconnect (`showDisconnectDialog`), clear (`showConfirmClearDialog`), unsaved changes, edit node name, rename point |
| Page | `Navigator.push(MaterialPageRoute(...))` | Anything with sections, many fields, its own save, or that the user stays in | App Settings, Repeater Settings, Themes, Theme editor, Message filter, Region management |

Rules for new UI:

1. **Confirmation or a single short input → dialog.** Title, one sentence, Cancel + one action.
2. **Pick one of several options, or act on one item → sheet.** Use `showMeshSheet` and start the content with `BottomSheetHeader(title:, subtitle:)`. It handles the keyboard and navigation-bar insets. Use raw `showModalBottomSheet` only when you need `DraggableScrollableSheet`.
3. **Forms with sections, live remote values, or anything that needs Save/Discard → page.** Guard unsaved changes with `PopScope` and a discard dialog, as `repeater_settings_screen.dart` does.
4. Never stack a dialog on a sheet on a dialog. Close the sheet first, or move the flow to a page.

## 7. App bars

- Title: a plain localized string, ellipsized on one line. Use `AppBarTitle` on top-level and settings screens; it adds the connected node name as a subtitle and battery/SNR indicators when there is room, dropping them in that order on narrow widths. Use `AdaptiveAppBarTitle` for a plain one-line title.
- Centre the title (`centerTitle: true`, `AGENTS.md`); 31 screens set it explicitly because the theme default is `false`. Chat screens (`chat_screen.dart`, `channel_chat_screen.dart`) deliberately use `centerTitle: false` for their two-line name + route title.
- Actions: at most two icon buttons plus the overflow (`Icons.more_vert`) menu, for example `RadioStatsIconButton`, search, ⋮ in `chat_screen.dart`. Put everything else in the overflow menu.
- Overflow menu order: things about this screen first, then app-level items (Disconnect, Settings), with destructive items last. Destructive items use `MeshMenuItemRow(color: scheme.error)` so both icon and label turn red (Clear chat in `chat_screen.dart`; Clear / Delete channel in `channel_chat_screen.dart`). Use `PopupMenuDivider` between groups.
- Search: tapping search swaps the title for the field and hides all actions (`actions: _searching ? null : [...]`). The leading back arrow and the system back gesture close the search (`PopScope(canPop: !_searching)`) instead of leaving the screen.
- Long operations: show progress as the app bar `bottom` (`SyncProgressAppBarBottom`, or a 4px `LinearProgressIndicator` for Refresh all in `repeater_settings_screen.dart`).

## 8. States

| State | How to show it |
|---|---|
| Loading, nothing to show yet | `Center(child: CircularProgressIndicator())`, only until the first data arrives; then show partial data (`channels_screen.dart`). |
| Loading in place | Swap the control's icon for an 18×18 `CircularProgressIndicator(strokeWidth: 2)` and disable it (`_buildRefreshButton` in `repeater_settings_screen.dart`). |
| Background sync | `SyncProgressAppBarBottom`. |
| Empty | `EmptyState` with an icon, a short title, and an action when there is an obvious next step. Use a separate "no results" state (`Icons.search_off`) when a search or filter hides everything. |
| Error | A snackbar for a failed action. `ErrorRetryCard` for a failed load the user can retry. Never show raw exception text alone. |
| Companion radio disconnected | Main and chat screens stay open, read-only ([offline mode](offline-mode.md)). Decide with `isRadioReadOnly(connector)` / `context.radioReadOnly` (`lib/utils/radio_guard.dart`): disable menu items (`PopupMenuItem(enabled: false)`, drop destructive colors) and buttons, hide FABs, and call `ensureRadioConnected(context)` as the safety net in handlers. The chat composer shows `OfflineComposerBar`. Repeater screens stay open with `RadioDisconnectedBanner` at the top and disable radio-dependent actions. Settings rows that need the radio pass `onTap: null` and show `settings_requiresConnection` as the subtitle (`settings_screen.dart`). |
| Feature unsupported by firmware | Disabled row with a subtitle that says why (`settings_requiresFirmware('v1.10')`). |
| Remote value not fetched yet | See below. |

**Unknown remote values.** A value that lives on a remote node (repeater settings, status) must not look like a real value until it has been fetched or set. `repeater_settings_screen.dart` does this:

- `_known(key)` is true once the value was fetched (`_loadedKeys`) or edited by the user (`_dirtyKeys`).
- Unknown values display as an em dash `—` (sliders' value label, and every `StatTile` value in `repeater_status_screen.dart`); `common_notAvailable` is the localized form.
- `_dimIfUnknown` fades the control to 60 % opacity. It stays usable; changing it makes the value known.
- Unknown switches show off, unknown dropdowns show no selection, and unknown text fields stay empty.
- While nothing is loaded, a card at the top explains this (`repeater_settings_screen.dart`, `repeater_settingsNotLoaded`) with a Refresh all button. Each setting also has its own refresh button.

Follow the same pattern for any new remote-value screen.

## 9. Text and localization

- All user-facing strings go through `context.l10n` (`lib/l10n/l10n.dart`). Add keys to `lib/l10n/app_en.arb` first. No string literals in widgets, including fallbacks.
- Keep strings short: labels are a few words, subtitles one sentence.
- Keep established radio terms in English in every locale: Flood, Zero Hop, hop, SNR, RSSI, LoRa, advert, repeater names and CLI commands.
- Never put text in a fixed-width box (`SizedBox(width: 80, child: Text(...))`). Use `Expanded`/`Flexible`, or let a `Row` wrap into a `Column`/`Wrap` when space runs out.
- Labels must wrap or scale, never clip and never break mid-word:
  - Menus: `MeshMenuItemRow` (2 lines, then ellipsis).
  - Segmented buttons: `MeshSegmentLabel`.
  - Tile titles and subtitles: let them wrap. Set `maxLines` only on lists where height matters, and add `overflow: TextOverflow.ellipsis` with it.
  - Do not use `TextOverflow.clip` or `softWrap: false` on translated text.
- Upper-casing is done in code (`SectionHeader`, `StatTile`, `RouteChip`); keep the ARB strings in normal case.
- Test with a long locale (German, Portuguese) and a large system font (at least 1.3×, ideally 2.0×) on a narrow phone (320dp). `test/screens/small_screen_layout_test.dart` checks many screens at 320×568 at 1.0, 1.3 and 2.0× in English; add new screens to it.

## 10. Checklist for a UI change

- [ ] Colours from `colorScheme` or theme extensions; no raw `Colors.*` or `MeshPalette.ink/bg/line` in chrome.
- [ ] Text styles from `textTheme` or `MeshTheme.mono`; nothing below 12.
- [ ] Settings rows use `MeshNavTile` / `SwitchListTile` inside `MeshSettingsTileTheme`; cards are `MeshCard` with a `SectionHeader`.
- [ ] Popup menu rows use `MeshMenuItemRow`; segmented buttons use `MeshSegmentLabel`; destructive menu items last, in `scheme.error`.
- [ ] Every `IconButton` and FAB has a localized `tooltip`.
- [ ] Tap targets at least 48×48.
- [ ] Right container: dialog for confirm/short input, `showMeshSheet` + `BottomSheetHeader` for choices and item actions, page for forms.
- [ ] Loading, empty, error, offline and unknown-value states handled.
- [ ] All strings in `app_en.arb`; checked in German or Portuguese at 1.3× and 2.0× on a narrow screen.
- [ ] Light, dark and one custom theme checked.
- [ ] This page updated if you introduced or changed a pattern.

## 11. Known inconsistencies

The current code does not yet follow this page everywhere:

- **App bar centring.** `MeshTheme._build` sets `centerTitle: false`, but `AGENTS.md` asks for centred titles and 31 screens override it. `contacts_screen.dart` does not, so its title is left-aligned while Channels and Settings are centred.
- **Disconnect placement in overflow menus.** It is the first item in `channels_screen.dart`, but just above Settings in `contacts_screen.dart` and `map_screen.dart`. It tints only the icon (`iconColor`), while Clear chat / Delete tint icon and label (`color`).
- **Menu rows not using `MeshMenuItemRow`.** `channel_chat_screen.dart` bulk-select menu (Select all / Copy) puts a `ListTile` inside `PopupMenuItem`. `widgets/list_filter_widget.dart` and the group menu in `contacts_screen.dart` use plain `Text` items, which is acceptable for icon-less lists but does not limit wrapping.
- **Settings toggles in two sizes.** `FeatureToggleRow` (`widgets/elements_ui.dart`, used in `settings_screen.dart` dialogs) uses a `bodyMedium` w600 title and `bodySmall` subtitle with a 32px refresh button. `MeshNavTile` and themed `SwitchListTile`s use `bodyLarge` w600 / `bodyMedium`. Only App Settings, Message Filter and Repeater Settings wrap their body in `MeshSettingsTileTheme`.
- **`ErrorRetryCard` is unused** and its fallback label is the hard-coded English `'Retry'` (`mesh_ui.dart`); screens show load errors in their own ways.
- **Fixed-width label boxes.** `chat_screen.dart` `_buildInfoRow` (80px), `line_of_sight_map_screen.dart` endpoint label (54px, `fontSize: 12`), `channel_message_path_screen.dart` (72px, upper-cased `accentLabel` at its 11px default).
- **11px text.** `MeshTheme.accentLabel()` without `fontSize` gives 11px in `channel_message_path_screen.dart` and `widgets/path_map_ui.dart` (which also uses dark-only `MeshPalette.ink3`). The type scale's `labelSmall` (11) is used in `list_filter_widget.dart` section titles.
- **Hard-coded colours.** `SyncProgressAppBarBottom` uses `Colors.red`, `Colors.blue` and `Colors.green`; `AppBarTitle` subtitle uses `Colors.grey[600]` at a literal 14 instead of `onSurfaceVariant`; `telemetry_location_map.dart` uses raw `Colors.*`. `MeshPalette.ink/bg/line` appear directly in eight screen/widget files (mostly map panels, where they are intentional; also `channels_screen.dart` and `channel_chat_screen.dart` community dots with an 8px icon).
- **Literal sizes instead of the theme.** About 300 literal `fontSize:` values in `lib/screens` and `lib/widgets` (most 12–14), e.g. `EmptyState` subtitle at 13.5; and 36 `BorderRadius.circular(<number>)` calls (8 and 12 most common) instead of `MeshRadii`.
- **Navigation bar theme.** `navigationBarTheme` colours selected labels `onPrimary`, which is white-on-white in light mode; `QuickSwitchBar` overrides it. Any other `NavigationBar` would inherit the problem.
- **Two badge styles.** `QuickSwitchBar` uses Material `Badge` capped at 99+; `UnreadBadge` caps at 9999+.
- **Sheets without `showMeshSheet`.** Besides the draggable sheets, `chat_background.dart`, `map_screen.dart`, `theme_editor_screen.dart`, `repeater_cli_screen.dart`, `message_translation_button.dart` and `path_map_ui.dart` call `showModalBottomSheet` directly, so they skip the shared inset handling and most skip `BottomSheetHeader`.
- **Large forms in dialogs.** `RadioSettingsDialog` (`widgets/radio_settings_dialog.dart`, nine inputs) and the contact settings dialog in `chat_screen.dart` are dialogs although they behave like forms.
- **Dialog buttons.** `showDisconnectDialog` (`utils/dialog_utils.dart`) uses two `TextButton`s with no emphasis; `showConfirmClearDialog` uses a red `FilledButton`.
- **Snackbars.** A few places still call `ScaffoldMessenger.showSnackBar` directly (`discovery_screen.dart`, `app_settings_screen.dart`, `message_filter_settings_screen.dart`, `region_management_screen.dart`, `helpers/image_send_flow.dart`) and so miss tap-to-dismiss and replace-instead-of-queue.
- **Small tap targets.** `FeatureToggleRow` refresh (32px) and 40px buttons in `chat_screen.dart`, `channel_chat_screen.dart`, `reaction_chips.dart`, `snr_indicator.dart`, `path_map_ui.dart`; 44px in `routing_sheet.dart`, `path_editor_sheet.dart`.
- **Unknown placeholders.** Repeater and companion stats screens use `—`; `line_of_sight_map_screen.dart` uses `--`.
- **Missing tooltip.** The Contacts FAB (`contacts_screen.dart`) has no tooltip; about 18 of 111 `IconButton`s have no tooltip nearby.
- **Stale doc comments.** `SectionHeader` is described as "mono" but uses the sans `accentLabel`; the `StatusChip` comment sits above `meshContrastRatio`.
