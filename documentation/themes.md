# Themes, Chat Backgrounds & Holiday Themes

Themes change the app's colors, icons, map markers, and (optionally) chat backgrounds. Everything here is stored on this device only; nothing is sent to the radio or the mesh.

## How to Access

**Settings → App Settings → Appearance → Color theme** opens the Themes screen. The tile's subtitle shows the theme in use ("MeshCore" for the standard theme), with a color swatch when a custom or preset theme is active.

## Light / Dark and Color Theme

Appearance has two related controls:

- **Theme** (System / Light / Dark): the brightness of the standard MeshCore theme.
- **Color theme**: the standard MeshCore theme, a built-in preset, a holiday theme, or one of your own.

A custom or preset theme sets its own brightness (a dark background makes a dark theme), so while one is active, none of the System / Light / Dark buttons is selected. Tapping one of them goes back to the standard MeshCore theme in that mode.

## Themes Screen

The screen has three sections. Tap a theme to use it right away; the active theme is marked as selected.

### My themes

Themes you created or imported. Each has a menu with **Edit**, **Copy theme code**, **Export to file**, and **Delete**. Deleting the active theme returns to the standard theme.

### Built-in

- **MeshCore**: the standard colors, following the Light / Dark setting.
- Presets: Forest, Ocean, Ember, Grape, High Contrast, Paper, Mint, and Sky.

Preset menus offer **Customize a copy** (opens the editor on a copy under "My themes") and **Copy theme code**. Presets themselves can't be edited.

### Holidays

Halloween, Thanksgiving, Christmas, and New Year's themes, each with its own colors, chat background picture, tab and send icons, and map markers. You can pick one at any time, like any other theme. This section also holds the **Switch automatically** toggle; see [Automatic holiday themes](#automatic-holiday-themes).

## Automatic Holiday Themes

**Switch automatically** is **on by default**, including for people who already chose a theme before updating. While it is on, each holiday's theme is shown in place of your own theme from **17 days before the holiday until the end of the holiday itself**:

| Holiday | Date | Automatic theme starts |
|---|---|---|
| Halloween | October 31 | October 14 |
| Thanksgiving | Fourth Thursday of November (US) | 17 days before (Nov 5–11, depending on the year) |
| Christmas | December 25 | December 8 |
| New Year's | January 1 | December 15 |

When windows overlap, the nearest upcoming holiday wins. A holiday keeps its theme through its own day, and the next holiday takes over the day after (for example, Christmas runs through December 25 and New Year's from December 26). Dates use the device's local calendar, and the app checks for a date change at midnight (and at least hourly), so the theme switches without restarting.

Your own choice is never changed: the holiday theme only covers it. When the window ends, your theme comes back by itself. While a holiday theme is on automatically, the Themes screen shows a note ("… theme is on automatically. Your own theme comes back after the holiday.") and tags that holiday's tile **On automatically**.

### Keeping your own theme

- **For the current holiday only**: pick any theme, or tap System / Light / Dark in App Settings. Your choice sticks for the rest of that holiday; the next holiday switches automatically again.
- **For all holidays**: turn off **Switch automatically** on the Themes screen. Your own theme returns immediately.

Turning **Switch automatically** back on also forgets an earlier "for this holiday only" choice, so the current holiday's theme shows again. Picking the holiday theme that is already on automatically doesn't change your saved theme, so your own theme still comes back after the holiday.

## Creating and Editing a Theme

Tap **Create theme** (or **Edit** / **Customize a copy**) to open the editor. A live preview shows chat bubbles and a switch in the new colors.

- **Name** (required)
- **Background**: the main background color. A dark background makes a dark theme. Surfaces, text, and bubbles are derived from it.
- **Accent**: buttons, highlights, and your own chat bubbles. A warning appears when the accent is hard to see on the background.
- Colors can be chosen from swatches or entered as a hex color.
- **Chat background**: none, a color, or a picture, with a fade slider. It is shown in chats that have no background of their own. Turn on **Use in every chat** to also replace backgrounds set on individual chats.
- **Icons**: swap the Contacts, Channels, and Map tab icons, the send button, the Settings icon, and the Repeater, Room, and Sensor avatars. Tap an icon to choose another named icon or **Use a picture** from your gallery; **Use the default icon** resets it. Pictures are stored as lossless JPEG XL.
- **Map markers**: swap the map markers for chat nodes, repeaters, rooms, sensors, and your own position the same way.

**Save and use** saves the theme and makes it active.

## Sharing Themes

- **Copy theme code** copies a single theme as text. Share it any way you like; the recipient uses **Paste theme code** (Themes screen ⋮ menu) to add it.
- **Export to file** (one theme) and **Export my themes** (all of yours, ⋮ menu) write a `.jsonl` file, one theme per line. On Android and iOS it opens the share sheet, on desktop a save dialog, and on web the file downloads.
- **Import from file** (⋮ menu) accepts `.jsonl`, `.json`, or `.txt`. Invalid lines are skipped, and themes identical to one you already have aren't added twice.

Imported themes appear under "My themes"; importing doesn't switch to them.

## Map

The map follows the active theme: panels, accent color, a tint over the map tiles, and the theme's map markers. See [Map & Location](map-and-location.md).

## Chat Backgrounds

Each direct chat and channel can have its own background. Open the chat, then **⋮ → Chat background**:

- **None**, one of 12 colors, or **Picture** (**Choose a picture** from your gallery).
- **Fade** (10–90%) blends the background toward the theme's surface color so messages stay readable.

Changes apply live behind the sheet and affect only that chat. If the active theme has **Use in every chat** on, the sheet says so, and the theme's background is shown until you turn that option off in the theme. Holiday themes include a background picture that appears in chats without their own background.

Backgrounds are tied to the channel or contact, not the radio, so they follow the chat if you connect a different radio. Pictures are re-encoded as JPEG XL; on web they are kept in browser storage.

## Holiday Message Animations

When a new message containing a holiday greeting arrives in, or is sent from, the chat you have open, a short full-screen animation plays: bats for "Happy Halloween", a turkey for "Happy Thanksgiving", Santa for "Merry Christmas", and fireworks for "Happy New Year". Greetings are recognized in all of the app's languages, whatever your own language setting, and case and punctuation are ignored. Hashtags like `#HappyNewYear` also count.

- Only new messages play; messages already in the chat when you open it, and synced messages more than 2 minutes old, stay quiet.
- Animations play any day of the year, not only during the holiday windows.
- Touches pass through the animation.
- Turn them off with **App Settings → Appearance → Holiday message animations**. They are also skipped when the system's reduce-motion / remove-animations setting is on.
