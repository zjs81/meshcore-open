# UI Design Reference

How MeshCore Open's interface is built today, and the rules to follow when adding or changing UI. Every value below comes from the code it cites. If you change one of those sources, or settle on a new pattern, update this page in the same change.

The source of truth is `lib/theme/mesh_theme.dart` (theme), `lib/widgets/mesh_ui.dart` (shared widgets), `lib/widgets/settings_reveal.dart` (reveal-on-enable and settings sliders), `lib/widgets/mesh_nav_tile.dart` (settings rows) and `lib/widgets/unsaved_changes_guard.dart` (Save and the leave warning on pages that save to a radio). Where the code disagrees with this page, fix one of them; do not copy the inconsistency.

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
| Floating map chrome (zoom buttons, panels, toggles) | `ColorScheme` roles like a card: `surfaceContainerLow`, `outlineVariant`, `onSurface`. On desktop, overlays at the top of a path map start at `pathMapTopOverlayInset()` (`path_map_scaffold.dart`) so they clear the zoom buttons |
| Coloured text or icon on a tinted background | pass it through `readableAccent(color, background, minContrast:)` (`mesh_ui.dart`), 4.5 for text, 3 for icons |

Rules:

- Do not use `MeshPalette.ink*`, `bg*` or `line*` directly in normal screens. They are the dark-theme values and are wrong in the light theme and in custom themes. Use the matching `ColorScheme` role.
- Do not use raw `Colors.red`, `Colors.grey[600]` and so on for UI chrome.
- Status colours (`error`, `tertiary`, `secondary`) are copied from the stock scheme of the same brightness in `fromCustom`, so they keep their meaning in custom themes.
- A disabled destructive or warning control drops its `error` / `tertiary` colour and shows only the normal disabled look: pass `null` as the colour of `MeshMenuItemRow`, the icon or the `ListTile` text, and leave out `MeshNavTile`'s `titleColor` / `iconColor` while `onTap` is null. Examples: Clear chat and Delete channel while offline, Discovered Contacts Delete all, Reset Learning with nothing learned.
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
| Slider row | `SettingsValueSlider` (`ListTile`), `contentPadding` 16 / 4, `leading` icon size 24, 16 gap | `settings_reveal.dart` |
| Popup menu row | 20px icon, 12 gap | `MeshMenuItemRow` |
| Banner | padding 16 / 12, 24px icon, 12 gap | `RadioDisconnectedBanner` |
| Sheet header | padding 20, 8, 8, 4 (LTRB), 36×4 drag handle | `BottomSheetHeader` |
| Radii | `MeshRadii.xs` 6, `sm` 10, `md` 14 (cards, inputs, menus, snackbars, list tiles), `lg` 18 (sheets, dialogs), `xl` 24, `pill` 999 (buttons, chips, FAB) | `MeshRadii` |
| Default icon size | 22 | `iconTheme` |
| Avatar | 40; initials from letters and digits only (`avatarInitials`), else a person icon. Pass a hop's hex prefix, not a "(AB) Name" label | `AvatarCircle` |
| List bottom padding under a FAB | 88 | `channels_screen.dart` |

Every settings row — including sliders, selectors, child rows revealed inside `SettingsReveal`, and model rows in `ModelDownloadList` — uses a vertically centred 24px leading icon with a 16px gap (`MeshNavTile`, `SwitchListTile.secondary`, or `ListTile.leading`) so titles align vertically across a card.

Icon sizes in use: 24 for tile and banner icons, 20 for menu icons and small action buttons, 18 for inline refresh icons and spinners. Keep tappable icons at 20 or more.

**Tap targets.** Keep Flutter's 48×48 minimum (the default `materialTapTargetSize` and `IconButton` size). Don't shrink with `VisualDensity.compact`, `MaterialTapTargetSize.shrinkWrap` or small `BoxConstraints` unless the control sits inside a larger tappable row.

## 5. Components

| Need | Use | Notes |
|---|---|---|
| Group of related content | `MeshCard` | `onTap`/`onLongPress` give ink feedback; long-press adds a selection haptic |
| Label above a group | `SectionHeader(label, trailing:)` | Upper-cases for you; pass the normal-case l10n string |
| Settings navigation row | `MeshNavTile` | `onTap: null` dims it to 50 % and reports it as disabled; use `subtitle` to say why. `iconSlot` shows a themeable icon (e.g. node types, as in the contact list) |
| Settings switch | `SwitchListTile` inside `MeshSettingsTileTheme` | Wrap the settings screen body once in `MeshSettingsTileTheme` |
| Switch that reveals more controls | `SettingsReveal` | 200ms height ease, `surfaceContainerHighest`, 16px start indent. See [Reveal on enable](#reveal-on-enable) |
| Settings slider | `SettingsValueSlider` | Requires a 24px `icon` (`ListTile.leading`). The title includes the selected number, so it stays visible. The drag bubble repeats it |
| Read-only value in a settings row | 24px `onSurfaceVariant` icon, title (`meshTileTitleStyle`), the value on its own line in `MeshTheme.mono` 15 w500 `onSurface`, subtitle `bodyMedium` `onSurfaceVariant` | Same value style as the Settings device info card; not `StatTile`, which is for status screens (Node Name message length) |
| Settings choice from a long list | `ListTile` with a 24px `leading` icon, title and subtitle, and a `DropdownButtonFormField` under the subtitle | Same row shape as `SettingsValueSlider`; no label or helper inside the field (Hop limit in Contact Settings) |
| Settings saved to a radio | `SaveToRadioPage(title:, hasChanges:, onSave:, children:)` | See [Settings pages](#settings-pages). A custom scaffold uses `UnsavedChangesGuard` + `SaveChangesAction` |
| Section explanation | `SectionHeader(label, description:)` | One or two short sentences in `bodyMedium` `onSurfaceVariant` under the label, for a note that belongs to one section (Node Name, Location) |
| Option that needs a longer explanation | `MeshCard(padding: EdgeInsets.zero)`: explanation text, `Divider(height: 1, indent: 16, endIndent: 16)`, the switch row, divider, optional note | Text in `bodyMedium` `onSurfaceVariant`, padding 16 / 14, so it reads like tile subtitles. The dividers are inset on both sides to match the text (Off-Grid Repeat Mode) |
| Note at the top of a page or section | `MeshInfoCard(text)` | Info icon and `bodyMedium` text in a `MeshCard`; one or two short sentences (Add Contact, Privacy) |
| Text field with a byte limit | `TextField` with `x / max` as `suffixIcon` (Node Name) | Count always visible. Input past the limit is allowed: the count turns `error`, `errorText` says how far over, and Save is disabled. Don't block input silently |
| Choosing a point on a map | `LocationPickerScreen(initial:)` | Page with a fixed centre pin; returns the `LatLng` to the form |
| Radio-style choice in a sheet | `MeshSheetOption` | Used by the language picker, map time filter and compression page. Optional `subtitle` explains the option; `onTap: null` disables it. Selected rows show a filled radio icon **and** a bold title, with `selected` semantics |
| Per-chat setting | Overflow-menu item `[icon] Label: value` that opens a dedicated page (`ChatCompressionScreen` in `screens/chat_compression_screen.dart`) | Same `Label: value` pattern as the channel `Notifications: ...` item. Page: centred `AdaptiveAppBarTitle`, `SectionHeader` with a one-sentence description, a `MeshCard(padding: EdgeInsets.zero)` of `MeshSheetOption` rows split by `Divider(height: 1, indent: 16)`, short notes per option, a `MeshInfoCard` when the choice is locked, an error `MeshCard` when a save fails, and a spinner in the app bar while saving. Shows the saved value only. One shared page for DM and channel chats; parents pass state and async callbacks |
| Choosing between images | Selectable thumbnail tiles in a centred `Wrap` | Image send versions (`_versionTile` in `image_send_preview_sheet.dart`). `InkWell` with `MeshRadii.sm`; selected tile gets a 3px `primary` border **and** a `primary` check badge (never colour alone); caption under the tile in `bodySmall`, w600 when selected; figures such as packet counts in `MeshTheme.mono` 12; wrap the tile in `Semantics(button: true, selected:, label:)` |
| Editing a set of members | Current items first, then a searchable add list | Group editor (`contact_group_editor_dialog.dart`). Wrapping upper-case section label with the count ("Current members (N)"); each member row has a trailing `IconButton` remove (`error` colour, tooltip names the item); the add list excludes current members, and tapping the row or its `primary` add button adds it |
| Popup menu row | **always** `PopupMenuItem(child: MeshMenuItemRow(icon:, label:))` | Relies on `MeshTheme.popupMenuTheme` (`surfaceContainerHigh`, `MeshRadii.md`); `MeshMenuItemRow` gives a 20px icon slot, 12px gap, and 2-line wrap + ellipsis (`leading:` for `ThemedIcon`, no icon keeps the 20px slot). Main views share `mainOverflowTrailingItems` (`widgets/connect_sheet.dart`) |
| Segmented button label | **always** `ButtonSegment(label: MeshSegmentLabel(text))` | Shrinks to 12 (before system scale), then wraps at word boundaries onto 2 centred lines; never breaks a word |
| Alternatives on one page | `TabBar` (icon and label per tab) in `AppBar.bottom` with a `TabBarView` | Connect a radio (`connect_screen.dart`). A tab that needs its own FAB is its own `Scaffold` inside its own `ScaffoldMessenger`, so its snackbars lift its FAB. Labels shrink to fit (`FittedBox`) rather than fade. While an action runs that leaving the tab would cancel, lock the tabs: `ExcludeFocus` and `IgnorePointer` at 50 % opacity, and `NeverScrollableScrollPhysics`. When the keyboard leaves under 400 dp, drop the tab bar and the header so a form keeps room |
| Status | `StatusChip` | Mono label, coloured dot or icon |
| On-device model | `ModelDownloadList` | Name, size, status, selection and one action. See [Model downloads](#model-downloads). |
| Metric | `StatTile` | Label wraps to 2 lines; value wraps |
| Signal | `SignalBars`, `MeshTheme.snrColor` | |
| Route kind | `RouteChip` | Direct / hop count / Flood |
| Count badge | `Badge` on nav icons (`QuickSwitchBar`, caps at 99+), `UnreadBadge` in lists (alert red, mono 12) | |
| Empty list | `EmptyState(icon:, title:, subtitle:, action:)` | Scrolls rather than overflowing at large text |
| Inline error with retry | `ErrorRetryCard(message:, onRetry:, retryLabel:)` | Pass `retryLabel: context.l10n.common_retry` |
| Radio offline on a remote-node screen | `RadioDisconnectedBanner` | Renders nothing while connected |
| Card the user can close | `GetNodeBanner` (bottom of Connect a radio) | Close `IconButton` (`common_close` tooltip) at the end of the title row; closing hides it with `RevealOnEnable` until the page closes. At most 40 % of the screen height, scrolling inside at large text; hidden on screens under 480 dp tall (a landscape phone) |
| Progress bar | `MeshProgressBar`; `MeshProgressAppBarBottom` as an app bar `bottom`; `SyncProgressAppBarBottom` for the app syncs, with `busy: true` while the screen waits for the radio (Settings actions) (`widgets/sync_progress_overlay.dart`) | See [Progress bars](#progress-bars) |
| Toast message | `showDismissibleSnackBar(context, content: Text(...))` | Tap to dismiss, replaces the current snackbar, safe after an async gap. Returns its controller, or null when nothing was shown |
| Undo after a change | `showDismissibleSnackBar` with `action: SnackBarAction(label: l10n.common_undo, ...)` and the default duration | Map marker removal, Discovery add, Message Filter rules (add, edit, delete, bulk delete, bulk turn on/off). Undo reverses the change; deleted rules go back to their places. A switch the user can flip back needs no snackbar. A change no existing call can reverse (deleting messages, Not spam with its learning) is applied only when the snackbar closes without Undo, or when the page closes or the app is hidden, which also close the snackbar; until then its rows leave the list (Filtered Messages). Deleting messages or selected rules still confirms first, as in chats and Bookmarks |
| Selecting several items | App bar `Icons.checklist` button (tooltip names the items) or a long-press starts selection; it stays on at 0 selected | App bar: `Icons.close` leading (`chat_clearSelection`), `chat_selectedCount` title, `Icons.select_all` (`chat_selectAll`, selects the visible rows, so only the matches while searching), then the bulk actions. Rows: 28px `Icons.check_circle` (`primary`) or `Icons.radio_button_unchecked` (`onSurfaceVariant`), a `primary` 16 % tint and `Semantics(selected:)`; a tap toggles the row, and row controls are hidden or disabled. Back leaves selection first (`PopScope`), the FAB hides, and a bulk action ends selection (Filtered Messages, Rules) |
| List item entrance | `ListEntrance(index:)` | Optional. Plays only for rows built while the list is at rest at the top; rows scrolled into view appear at once |

**Buttons.** Theme shapes are all pill-shaped. In use:

- `FilledButton` / `FilledButton.icon`: the primary action of a dialog, sheet, empty state or form (e.g. "Add public channel" in `EmptyState`, Save in the discard dialog in `repeater_settings_screen.dart`). One per view.
- `FilledButton.tonal`: a secondary action that still needs weight (rare).
- `OutlinedButton(.icon)`: secondary actions next to a filled one.
- `TextButton`: Cancel and low-emphasis actions in dialogs; inline actions in cards.
- Destructive confirm: destructive or data-removing actions (such as clearing a chat, deleting a channel or contact, or removing single or bulk bookmarks) always prompt with a confirmation `AlertDialog` pairing a `Cancel` `TextButton` with an error-styled destructive action: `FilledButton` with `backgroundColor: scheme.error`, `foregroundColor: scheme.onError` (`showConfirmClearDialog` in `widgets/confirm_clear_dialog.dart`), or a `TextButton` with `foregroundColor: scheme.error` when it is not the primary action (as in `confirmClearChat` and `confirmRemoveBookmarks`). Use `showConfirmClearDialog(confirmLabel:)` for any confirm dialog; `warning: true` makes the button `scheme.tertiary` for disruptive, non-destructive actions (Reboot in Settings). Removing an app-only item that an Undo snackbar puts back (one Message Filter rule from its row, a map marker) skips the dialog; deleting messages or selected rules still confirms (see Undo after a change).
- Dialog action order: Cancel first, primary last.
- Avoid `ElevatedButton` in new code.

**FAB.** One per screen, for the main "add" action (`contacts_screen.dart`, `channels_screen.dart`) or primary action (`FloatingActionButton.extended` in `themes_screen.dart`, `scanner_screen.dart`). Always give it a `tooltip` or a label.

**IconButton.** Always set `tooltip:` with a localized string. It is the accessible name.

**Chat composer.** Direct and channel chats share `ChatComposer` (`widgets/chat_composer.dart`); change it there, not per screen.

- Panel: no divider; `scheme.surface` without a chat background, transparent over one (the screens pass the composer as `ChatBackdrop.footer`, and `ChatBackdrop.hasBackgroundOf` tells it a background is drawn). Margins 12 on the sides, 8 above and below.
- Bubble: radius `kComposerBubbleRadius` (20), no outline, `surfaceContainerHigh` fill, or the incoming-bubble colour (`MessageBubbleColors`, `surfaceContainerLow`) over a background. One line is 48 tall; the field grows to `kComposerMaxLines` (5), fewer when large text and the keyboard leave little room, then scrolls. Buttons stay bottom-aligned.
- Inside the bubble: a reply quote at the top (`ChatComposerQuote`: 4px leading bar in `primary`, title, one-line content, ✕), the field or the GIF preview, the translate button on the right, and the byte counter bottom-right only past 70 % of the limit (`ByteCountedTextField(counterOnlyNearLimit: true)`).
- One round button beside the bubble, 44 drawn in a 48 touch target: `+` (the action menu) while the field is empty, Send in `primary` once there is text. The swap fades and scales for 150 ms, instantly when `MediaQuery.disableAnimations` is set.
- Offline, `OfflineComposerBar` uses the same panel, bubble and height, with Connect in place of the round button (below the bubble on narrow or large-text layouts).
- Full-width strips that are not part of the draft (image send progress) go in `header`, above the bubble.

### Reveal on enable

A switch that uncovers more controls (such as **Enable image messages** and **Enable translation**) uses `SettingsReveal` (`lib/widgets/settings_reveal.dart`). The block's height eases over 200ms (`RevealOnEnable.duration`, `Curves.easeInOut`, aligned to the top). While the switch is off the extra controls are not in the tree, so they are not announced. The panel uses `surfaceContainerHighest` and a 16px start indent. Because the panel already sits on `surfaceContainerHighest`, controls and inset notices inside it must contrast against `surfaceContainerHighest` as well as `surfaceContainerLow` (`MeshTheme`'s slider inactive track and value indicator step away from `surfaceContainerHighest`, and inset notice boxes inside `SettingsReveal`, such as `ImageCodecModelsSection`'s unavailable-platform notice, use `surfaceContainerLow` with an `outlineVariant` border).

The same animation without the tint is `RevealOnEnable`. Use it when the revealed control is not a settings sub-panel: the Bluetooth-off banner on the scanner, the device-info rows on the Settings screen, and the node banner on Connect a radio.

Do not add a second duration, and do not reveal the controls with a plain `if` that pops them in. A block that swaps between two bodies keeps `AnimatedSize` but uses `RevealOnEnable.duration` and `RevealOnEnable.curve`.

Sliders that belong to a setting use `SettingsValueSlider` with a 24px `icon` (`ListTile.leading`) so the title and slider line up with adjacent rows. Put the selected number in the title (a localized string with the count). The slider's drag label repeats that number; it is not the only place the value appears.

### Model downloads

Image models, translation models, and the restore prompt that fetches missing models all use `ModelDownloadList` (`lib/widgets/model_download_list.dart`). Do not add a second download form (a dropdown of presets, a separate filename row, or a one-off progress bar).

One model is one row inside the existing `MeshCard` (or `SettingsReveal`), rows separated by `Divider(height: 1, indent: 16)`, with leading icon, text column, and trailing action(s) vertically centred (`padding: 16, 12, 4, 12` when an action is present so the icon aligns with `MeshNavTile`'s 16px trailing inset):

| Part | What it shows |
|---|---|
| Leading icon | 24px icon, 16px gap: `Icons.memory_outlined` (`onSurfaceVariant`) when not downloaded, 24px `CircularProgressIndicator` (`primary`) while downloading, `Icons.check_circle` (`primary`) when active, `Icons.check_circle_outline` (`onSurfaceVariant`) when ready, `Icons.error_outline` (`error`) on failure. Never repeat the trailing download icon on the left. |
| Title | Friendly name, `meshTileTitleStyle` (`bodyLarge` w600). It wraps. Never a raw filename or URL. |
| Subtitle | Size via the `mapCache_size*` strings when known, then the status: Not downloaded, Downloading, Ready, or Couldn't download. The model in use also says Active. An install that stopped part-way says Incomplete. The words stay `onSurfaceVariant` (Active is w600). |
| Progress | While downloading, a `LinearProgressIndicator` (indeterminate when the total is unknown, or while chunks are merged or the file is verified) and a mono 12 caption of bytes and percent. |
| Action | One `IconButton` (48×48 touch target) with a localized tooltip: Download, Cancel, or Remove model. An install that already has files but is not ready shows both Download and Remove. Tap a Ready row to select it when more than one model can be active. A row the user cannot use is dimmed to 50 %, same as a disabled `MeshNavTile`. |
| Manual URL | When the feature accepts one (translation), put a single text field under the list. Its download control is the same Download icon. The file joins this list. |

A dialog that offers several missing models (backup restore) uses the same rows for name, size, status and progress, and keeps its own confirm button.

### Chess board

`ChessBoardView` (`lib/games/chess/ui/chess_board.dart`) is board content, not chrome, so its squares keep the same classic colours in every theme (`ChessBoardPalette`). Both have strong contrast with the white and black piece vectors (`chess_vectors_flutter`).

- Last move: both squares get a translucent yellow wash. Check: a red radial glow behind the king. Selected piece: a 3px `primary` border.
- Legal targets: a dark dot on an empty square and a dark ring around a capturable piece, so they differ in shape and not only colour.
- Rank and file labels sit in the corners of the edge squares, in the opposite square colour, at 12–14px.
- The board fills the width (up to 560) and the page scrolls, so it fits a 320dp phone at 2.0× text.

The channel's games list is a `showMeshSheet` with a `DraggableScrollableSheet`, the same layout as the Add channel sheet. Starting a game closes it and opens a second sheet, so sheets are never stacked.

### Progress bars

A thin bar at the top of a screen or list shows that something is running. Bars inside content (model downloads, image send progress) are not covered here.

1. 4px.
2. Theme colours: don't set a colour or track. The theme's `progressIndicatorTheme` (`primary` on `surfaceContainerHigh`) applies, so the bar follows light, dark and custom themes.
3. Use the shared widgets: `MeshProgressAppBarBottom` as an app bar `bottom` for the screen's own task (Refresh all in `repeater_settings_screen.dart`, the chess game), `SyncProgressAppBarBottom` for the app syncs (contacts, channels, queued messages), and `MeshProgressBar` at the top of content (chat search results, the line-of-sight map).
4. Fill (`value`) when the progress is known; move (`value: null`) when it isn't.
5. Keep the height while idle (`active: false`), so the content doesn't jump. A bar laid over content (the line-of-sight map) can be removed instead.
6. One bar at a time: when a screen's own task and an app sync overlap, the same bar shows one of them, never two stacked bars.
7. Waiting for the radio: when the user starts an action and the app waits for the radio, the control shows the 18×18 spinner (see [States](#9-states)) and the screen's top bar moves. Background traffic (polling, message sync, ACKs) doesn't; messages keep their own delivery status.

## 6. Sheets, dialogs and pages

What the code does:

| Container | Call | Used for | Examples |
|---|---|---|---|
| Bottom sheet | `showMeshSheet` + `BottomSheetHeader` (28 calls in 17 files) | Choosing from a list, an item's actions, quick tools tied to the current screen | Language picker, notification mode, add contact/channel options, emoji and GIF pickers, node info, share contact, image actions |
| Draggable sheet | `showModalBottomSheet` + `DraggableScrollableSheet` | Tall, scrollable panels that need a drag size | `ContactRoutingSheet` (`routing_sheet.dart`), image send preview |
| Dialog | `showDialog` + `AlertDialog` | Confirming an action, a short input (one to three fields) outside settings, a short message | Disconnect (`showDisconnectDialog`), clear (`showConfirmClearDialog`), unsaved changes, rename point |
| Page | `Navigator.push(MaterialPageRoute(...))` | Every settings entry, and anything with sections, many fields, its own save, or that the user stays in | App Settings, Node Name, Radio Settings, Location, Contact Settings, Privacy, About, Repeater Settings, Themes, Theme editor, Message Filter, Region management |

Rules for new UI:

1. **Settings → page.** A row in Settings, App Settings or a repeater screen that opens settings opens a page, even for a single field. See [Settings pages](#settings-pages).
2. **Confirmation or a single short input → dialog.** Title, one sentence, Cancel + one action. Destructive or data-removing actions (clearing a chat, deleting a channel/contact, or removing single/bulk bookmarks) always use this `AlertDialog` pattern (`Cancel` + `scheme.error` destructive action button), unless an Undo snackbar puts an app-only item back (one Message Filter rule from its row, a map marker); deleting messages or selected rules still confirms. Inside settings, dialogs only confirm actions (Reboot, Delete all paths, unsaved changes).
3. **Pick one of several options, or act on one item → sheet.** Use `showMeshSheet` and start the content with `BottomSheetHeader(title:, subtitle:)`. It handles the keyboard and navigation-bar insets. Use raw `showModalBottomSheet` only when you need `DraggableScrollableSheet`.
4. **Forms with sections, live remote values, or anything that needs Save/Discard → page.** Guard unsaved changes with `UnsavedChangesGuard` (built into `SaveToRadioPage`).
5. Never stack a dialog on a sheet on a dialog. Close the sheet first, or move the flow to a page.

**Sheet layout.** `showMeshSheet` is the sheet: safe area on the top and sides, and the keyboard or navigation-bar inset on the bottom. Start the content with `BottomSheetHeader`. That widget is the handle and the title row (padding 20, 8, 8, 4 and a 36×4 handle, section 4). Do not add space above it, draw a second handle, or size the sheet with a fraction inside an `Align`; that leaves an empty band over the handle. The status-bar inset stays outside the sheet.

The manual path editor (`path_editor_sheet.dart`) uses that layout. The hop list and the hex path field stay pinned under the header, including while the keyboard is open. When the band under the header is shorter than the search field, as on a landscape phone with the keyboard open, those blocks and the repeater list scroll together instead of overflowing.

### Settings pages

Every settings entry opens its own page, even for one field. On a settings page, dialogs only confirm actions and sheets only pick a value. A visual chooser (**Pick on map** in Location) is its own page that returns a value to the form.

Layout follows App Settings: `SectionHeader` + `MeshCard` groups, an optional `MeshInfoCard` at the top, and `SettingsReveal` for sub-options that only apply while a switch is on. Text fields and dropdowns use the theme's input style; don't set a border per field.

A list that can grow long gets its own page, so it does not push the other settings down: a `MeshNavTile` titled `Label (N)` opens a page with the items in one `MeshCard`, a `FloatingActionButton.extended` to add, and `EmptyState` when there are none (Message Filter → Rules).

| Stored | Saved | Examples |
|---|---|---|
| Only in the app | On each change; no Save button | App Settings, Message Filter, Themes |
| On a radio | Only on Save | Node Name, Radio Settings, Location, Contact Settings, Privacy, Repeater Settings |

Pages that save to a radio use `SaveToRadioPage` (`lib/widgets/unsaved_changes_guard.dart`). It adds `MeshSettingsTileTheme`, `RadioDisconnectedBanner`, the app bar Save, the leave warning, the connection check and the error snackbar.

- Show every setting the page saves, filled with the radio's last reported value.
- Save appears when a field differs from the saved value and hides when it's changed back. It's disabled offline, while saving, or while a field is invalid (`canSave`).
- Leaving with unsaved edits asks Cancel, Discard or Save; Save closes the page only on success.
- After saving, the page stays open and a snackbar confirms. A failed save keeps the edits.
- Validate all fields before sending anything.

## 7. Node search

Contact, repeater, room and user search all use `lib/utils/contact_search.dart`. Sort with `compareContactQueryRank`: names that start with the query, then other substring matches, then a public-key / hop-hash prefix. Use `rankLabeledKeyQuery` for a label that is not itself a contact, such as "my contact" on the share sheet. Do not filter with a separate name `contains`.

That is the Contacts list and its group member picker, Discovery, Map node search, Map "send to contact", Share contact, and the Build Path repeater and room list. Channel names, chat messages, repeater CLI commands and the path-trace hex field are not this search. The map key-prefix setting is a filter, not a ranked search.

## 8. App bars

- Title: a plain localized string, ellipsized on one line.
  - Settings and every page opened from it: a centred plain title, `AdaptiveAppBarTitle` with `centerTitle: true`.
  - Main tabs (Contacts, Channels, Map) and the screens that already use it: `AppBarTitle`, which adds the connected node name as a subtitle and battery/SNR indicators when there is room (dropping them in that order on narrow widths). It fills the bar's width, so it stays left-aligned; keep it that way.
  - Chats keep their own left-aligned title (see below).
- Centre the title (`centerTitle: true`, `AGENTS.md`); 31 screens set it explicitly because the theme default is `false`. Chat screens (`chat_screen.dart`, `channel_chat_screen.dart`) deliberately use `centerTitle: false` for their two-line name + route title.
- Actions: at most two icon buttons plus the overflow (`Icons.more_vert`) menu, for example `RadioStatsIconButton`, search, ⋮ in `chat_screen.dart`. Put everything else in the overflow menu.
- Overflow menus:
  - Order: screen-specific items first, then a `PopupMenuDivider` separating the trailing app-level section — Connect/Disconnect (`connectionMenuItem`) immediately followed by Settings (`settingsMenuItem`) — and destructive items last if a screen has any. Omit the divider when no items precede the app-level section (for example, `MapScreen` while building a path trace). Main views use `mainOverflowTrailingItems(screenContext, menuContext, hasPrecedingItems:)` in `lib/widgets/connect_sheet.dart` so they stay in sync.
  - Visual & interaction rules: rely on `MeshTheme`'s `popupMenuTheme` (`surfaceContainerHigh`, `MeshRadii.md` border radius, and consistent `menuPadding`, margins, item padding, and elevation), separate sections with `PopupMenuDivider`, build every row with `MeshMenuItemRow` (20px icon slot, 12px gap, 2-line wrap + ellipsis), use `context.l10n.contacts_moreOptions` as the button `tooltip` on main views, and capture the screen `context` (not the `itemBuilder`'s `menuContext`) for `onTap` callbacks since menus pop before `onTap` runs. Destructive items use `MeshMenuItemRow(color: scheme.error)` so both icon and label turn red (Clear chat in `chat_screen.dart`; Clear / Delete channel in `channel_chat_screen.dart`).
- Search: tapping search swaps the title for the field and hides all actions (`actions: _searching ? null : [...]`) and the FAB (Rules). The leading back arrow and the system back gesture close the search (`PopScope(canPop: !_searching)`) instead of leaving the screen.
- Long operations: show progress as the app bar `bottom` with the shared bar (see [Progress bars](#progress-bars)).

## 9. States

| State | How to show it |
|---|---|
| Loading, nothing to show yet | `Center(child: CircularProgressIndicator())`, only until the first data arrives; then show partial data (`channels_screen.dart`). |
| Loading in place | Swap the control's icon for an 18×18 `CircularProgressIndicator(strokeWidth: 2)` and disable it (`_buildRefreshButton` in `repeater_settings_screen.dart`). A settings row that runs a radio command keeps its chevron and uses `MeshNavTile(busy: true)` while it waits: the chevron becomes the spinner and taps are ignored, with `SyncProgressAppBarBottom(busy: true)` in the app bar (Settings actions). |
| Background sync | `SyncProgressAppBarBottom`. |
| Waiting for the radio | The control's 18×18 spinner and the screen's top bar, moving. See [Progress bars](#progress-bars). |
| Empty | `EmptyState` with an icon, a short title, and an action when there is an obvious next step. Use a separate "no results" state (`Icons.search_off`) when a search or filter hides everything. |
| Error | A snackbar for a failed action. `ErrorRetryCard` for a failed load the user can retry. Never show raw exception text alone. |
| Companion radio disconnected | Main and chat screens stay open, read-only ([offline mode](offline-mode.md)). Decide with `isRadioReadOnly(connector)` / `context.radioReadOnly` (`lib/utils/radio_guard.dart`): disable menu items (`PopupMenuItem(enabled: false)`, drop destructive colors) and buttons, hide FABs, and call `ensureRadioConnected(context)` as the safety net in handlers. The chat composer shows `OfflineComposerBar` in the same bubble and margins. Repeater screens and the Settings pages that save to the radio stay open with `RadioDisconnectedBanner` at the top and disable radio-dependent actions, including Save. Settings rows that need the radio pass `onTap: null` and show `settings_requiresConnection` as the subtitle (`settings_screen.dart`). |
| Feature unsupported by firmware | Disabled row with a subtitle that says why (`settings_requiresFirmware('v1.10')`). |
| Remote value not fetched yet | See below. |

**Unknown remote values.** A value that lives on a remote node (repeater settings, status) must not look like a real value until it has been fetched or set. `repeater_settings_screen.dart` does this:

- `_known(key)` is true once the value was fetched (`_loadedKeys`) or edited by the user (`_dirtyKeys`).
- Unknown values display as an em dash `—` (sliders' value label, and every `StatTile` value in `repeater_status_screen.dart`); `common_notAvailable` is the localized form.
- `_dimIfUnknown` fades the control to 60 % opacity. It stays usable; changing it makes the value known.
- Unknown switches show off, unknown dropdowns show no selection, and unknown text fields stay empty.
- While nothing is loaded, a card at the top explains this (`repeater_settings_screen.dart`, `repeater_settingsNotLoaded`) with a Refresh all button. Each setting also has its own refresh button.

Follow the same pattern for any new remote-value screen.

## 10. Text and localization

- All user-facing strings go through `context.l10n` (`lib/l10n/l10n.dart`). Add keys to `lib/l10n/app_en.arb` first. No string literals in widgets, including fallbacks.
- Keep strings short: labels are a few words, subtitles one sentence.
- Settings row titles use Title Case in English ("Radio Stats", "About the App"; short words like "the", "and", "of" stay lowercase unless first). Other locales follow their own capitalization. Row descriptions (subtitles) have no trailing full stop in any locale. The main Settings page follows this; apply it to new and changed settings rows.
- Keep established radio terms in English in every locale: Flood, Zero Hop, hop, SNR, RSSI, LoRa, advert, repeater names and CLI commands.
- Never put text in a fixed-width box (`SizedBox(width: 80, child: Text(...))`). Use `Expanded`/`Flexible`, or let a `Row` wrap into a `Column`/`Wrap` when space runs out.
- Labels must wrap or scale, never clip and never break mid-word:
  - Menus: `MeshMenuItemRow` (2 lines, then ellipsis).
  - Segmented buttons: `MeshSegmentLabel`.
  - Tile titles and subtitles: let them wrap. Set `maxLines` only on lists where height matters, and add `overflow: TextOverflow.ellipsis` with it.
  - Do not use `TextOverflow.clip` or `softWrap: false` on translated text.
- Upper-casing is done in code (`SectionHeader`, `StatTile`, `RouteChip`); keep the ARB strings in normal case.
- Test with a long locale (German, Portuguese) and a large system font (at least 1.3×, ideally 2.0×) on a narrow phone (320dp). `test/screens/small_screen_layout_test.dart` checks many screens at 320×568 at 1.0, 1.3 and 2.0× in English; add new screens to it.

## 11. Checklist for a UI change

- [ ] Colours from `colorScheme` or theme extensions; no raw `Colors.*` or `MeshPalette.ink/bg/line` in chrome.
- [ ] Text styles from `textTheme` or `MeshTheme.mono`; nothing below 12.
- [ ] Settings rows use `MeshNavTile` / `SwitchListTile` inside `MeshSettingsTileTheme`; cards are `MeshCard` with a `SectionHeader`.
- [ ] A switch that reveals more controls uses `SettingsReveal`. A settings slider uses `SettingsValueSlider` so the selected value stays in the title.
- [ ] Overflow menus rely on `MeshTheme.popupMenuTheme`, use `MeshMenuItemRow`, have a localized `tooltip`, place screen-specific items above a `PopupMenuDivider` followed by Connect/Disconnect and Settings (omitting any leading divider when empty), and place destructive items last in `scheme.error`; segmented buttons use `MeshSegmentLabel`.
- [ ] Every `IconButton` and FAB has a localized `tooltip`.
- [ ] Tap targets at least 48×48.
- [ ] Right container: page for every settings entry and for forms, dialog for confirm/short input, `showMeshSheet` + `BottomSheetHeader` for choices and item actions. No gap above the sheet handle.
- [ ] Settings stored on a radio use `SaveToRadioPage` and save only on Save; settings stored in the app apply immediately.
- [ ] Contact, repeater, room and user search uses `compareContactQueryRank`: prefix, then substring, then hop hash.
- [ ] Loading, empty, error, offline and unknown-value states handled.
- [ ] Top progress bars use the shared widgets (4px, theme colours); see [Progress bars](#progress-bars).
- [ ] All strings in `app_en.arb`; checked in German or Portuguese at 1.3× and 2.0× on a narrow screen.
- [ ] Settings row titles in Title Case (English); descriptions without a trailing full stop.
- [ ] Light, dark and one custom theme checked.
- [ ] This page updated if you introduced or changed a pattern.

## 12. Known inconsistencies

The current code does not yet follow this page everywhere:

- **App bar centring.** `MeshTheme._build` sets `centerTitle: false`, so screens opt in. One Settings page, `backup_restore_screen.dart`, uses `AppBarTitle(indicators: false, subtitle: false)` for a plain title, which stays left-aligned despite `centerTitle: true`; switch it to `AdaptiveAppBarTitle`. The main tabs and chats are left-aligned on purpose (see [App bars](#8-app-bars)).
- **Disconnect icon-only error tint.** In overflow menus, Disconnect tints only the icon (`iconColor`), while Clear chat / Delete tint icon and label (`color`).
- **Selection in chats and Bookmarks.** Chats and Bookmarks start selection from a message, end it when nothing is selected; the channel chat keeps Select all in its ⋮ menu, and direct chats and Bookmarks have none (see Selecting several items).
- **Reboot keeps its colour when disabled.** In Settings, Reboot stays `tertiary` (dimmed to 50 %) while no radio is connected, instead of dropping the colour ([Colour and theme](#2-colour-and-theme)).
- **Menu rows not using `MeshMenuItemRow`.** `channel_chat_screen.dart` bulk-select menu (Select all / Copy) puts a `ListTile` inside `PopupMenuItem`. `widgets/list_filter_widget.dart` and the group menu in `contacts_screen.dart` use plain `Text` items, which is acceptable for icon-less lists but does not limit wrapping.
- **Tile titles without `MeshSettingsTileTheme`.** Backup & Restore (`CheckboxListTile`) and Themes (`SwitchListTile`) do not wrap their body in it, so those titles are not semibold like the other settings rows.
- **Bars inside content.** The map cache download bar (`map_cache_screen.dart`) uses a fixed `MeshPalette.blue`.
- **Radio waits not shown yet.** `SaveToRadioPage` pages show the Save spinner but no top bar. Other radio actions are not reviewed yet.
- **`ErrorRetryCard` is unused** and its fallback label is the hard-coded English `'Retry'` (`mesh_ui.dart`); screens show load errors in their own ways.
- **Fixed-width label boxes.** `chat_screen.dart` `_buildInfoRow` (80px), `line_of_sight_map_screen.dart` endpoint label (54px, `fontSize: 12`), `channel_message_path_screen.dart` (72px, upper-cased `accentLabel` at its 11px default).
- **11px text.** `MeshTheme.accentLabel()` without `fontSize` gives 11px in `channel_message_path_screen.dart`. The type scale's `labelSmall` (11) is used in `list_filter_widget.dart` section titles.
- **Hard-coded colours.** `AppBarTitle` subtitle uses `Colors.grey[600]` at a literal 14 instead of `onSurfaceVariant`; `telemetry_location_map.dart` uses raw `Colors.*`. `MeshPalette.ink/bg/line` still appear directly in a few screen/widget files: map marker overlays (node name labels and shared-count badges in `path_map_scaffold.dart`, the hop badge on avatars in `channel_message_path_screen.dart`) and the `channels_screen.dart` and `channel_chat_screen.dart` community dots with an 8px icon. The path map chrome (`PathMapBottomPanel`, `PathMapDesktopControls`, `PathViewModeToggle` and the panel contents in `path_map_ui.dart` and both path map screens) uses `ColorScheme` roles: `surfaceContainerLow` background, `outlineVariant` border and dividers, `onSurface`/`onSurfaceVariant` text and icons, `primary` for active toggles and `tertiary` for warnings.
- **Literal sizes instead of the theme.** About 300 literal `fontSize:` values in `lib/screens` and `lib/widgets` (most 12–14), e.g. `EmptyState` subtitle at 13.5; and 36 `BorderRadius.circular(<number>)` calls (8 and 12 most common) instead of `MeshRadii`.
- **Navigation bar theme.** `navigationBarTheme` colours selected labels `onPrimary`, which is white-on-white in light mode; `QuickSwitchBar` overrides it. Any other `NavigationBar` would inherit the problem.
- **Two badge styles.** `QuickSwitchBar` uses Material `Badge` capped at 99+; `UnreadBadge` caps at 9999+.
- **Sheets without `showMeshSheet`.** Besides the draggable sheets, `chat_background.dart`, `map_screen.dart`, `theme_editor_screen.dart`, `repeater_cli_screen.dart`, `message_translation_button.dart` and `path_map_ui.dart` call `showModalBottomSheet` directly, so they skip the shared inset handling and most skip `BottomSheetHeader`.
- **Repeater Settings guard.** `repeater_settings_screen.dart` has its own unsaved-changes dialog instead of `UnsavedChangesGuard`.
- **Settings in dialogs.** App Settings still opens IPFS image links (`_IpfsImageLinksDialog`) and the raster tile source and endpoint as dialogs in `app_settings_screen.dart`, and the per-contact settings in `chat_screen.dart` are a dialog although they behave like a form. The Message Filter rule editor (`widgets/filter_rule_dialog.dart`, shared with channel chats) is a dialog too.
- **Dialog buttons.** `showDisconnectDialog` (`utils/dialog_utils.dart`) uses two `TextButton`s with no emphasis; `showConfirmClearDialog` uses a red `FilledButton`.
- **Snackbars.** A few places still call `ScaffoldMessenger.showSnackBar` directly (`discovery_screen.dart`, `app_settings_screen.dart`, `region_management_screen.dart`, `helpers/image_send_flow.dart`) and so miss tap-to-dismiss and replace-instead-of-queue.
- **Small tap targets.** 40px buttons in `chat_screen.dart`, `channel_chat_screen.dart`, `reaction_chips.dart`, `snr_indicator.dart`, `path_map_ui.dart`; 44px in `routing_sheet.dart`.
- **Unknown placeholders.** Repeater and companion stats screens use `—`; `line_of_sight_map_screen.dart` uses `--`.
- **Missing tooltip.** The Contacts FAB (`contacts_screen.dart`) has no tooltip; about 18 of 111 `IconButton`s have no tooltip nearby.
- **Stale doc comments.** `SectionHeader` is described as "mono" but uses the sans `accentLabel`; the `StatusChip` comment sits above `meshContrastRatio`.
