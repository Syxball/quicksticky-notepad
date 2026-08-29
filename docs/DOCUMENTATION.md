# Documentation

## Overview

A single Omarchy shell plugin (Quickshell/QML): a persistent scratch notepad,
distributed as its own git repo so `omarchy plugin add` / `omarchy plugin
update` can install and update it directly.

## Architecture

| File | Responsibility |
|------|-----------------|
| `manifest.json` | Plugin metadata: id, kinds (`overlay`, `bar-widget`), entry points |
| `BarWidget.qml` | Bar icon widget; toggles the overlay via `omarchy-shell shell toggle <id>` |
| `Notepad.qml` | Overlay UI (Quickshell/QML, built on the shell's `qs.Commons` / `qs.Ui` component kit) |
| `NotepadModel.js` | Plain JS helpers (parsing, serialization, color contrast) imported into QML |

## Installing / running

1. Install and enable:
   ```bash
   omarchy plugin add https://github.com/Syxball/quicksticky-notepad.git --enable
   ```
2. Update later:
   ```bash
   omarchy plugin update quicksticky.notepad
   ```
3. Validate the manifest any time (e.g. after local edits):
   ```bash
   omarchy plugin validate .
   ```

## Hot-reload is unreliable

Saving a file is supposed to hot-reload it in the running shell. In practice
this has proven flaky for QML changes — the shell logs "Local plugin
changed, reloading" but keeps rendering stale UI. If a change doesn't
visibly take effect:

```bash
omarchy-shell shell rescanPlugins   # try first
omarchy restart shell               # reliable fallback — always picks up changes
```

Check for QML errors after either with:

```bash
journalctl --user -t omarchy-shell -n 40 --no-pager
```

## Testing changes safely

The overlay window uses `WlrKeyboardFocus.Exclusive`, which grabs *all*
keyboard input while open — including keys meant for whatever you're typing
elsewhere. Before summoning it to test (e.g. via `omarchy-shell shell summon
quicksticky.notepad '{}'`), make sure you're not mid-typing somewhere else,
or your keystrokes will land in the overlay instead.

## Plugin behavior

Persistent scratch notepad, multiple pages, live markdown preview, per-note
colors, and a draggable/resizable window.

- **State**: `~/.local/state/omarchy/notepad.json` — `{ pages: [{text, color}], currentPage }`
- **Modes**: `Text` (raw markdown editor) / `Preview` (rendered via Qt's
  built-in `Text.MarkdownText`) — toggled by the buttons at the top, always
  live (no separate render step)
- **Colors**: 7 swatches (Default + 6 pastels); text/icon color is computed
  from the chosen background's luminance for contrast
- **Window controls**: drag the title bar to move, drag the `◢` grip
  (bottom-right) to resize; `Alt+Arrows` moves, `Alt+Shift+Arrows` resizes,
  `Alt+0` resets to the default centered size
- **Pages**: `‹ › + －` navigate/add/delete pages independently of color/mode
