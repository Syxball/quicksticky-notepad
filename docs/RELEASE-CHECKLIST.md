# Release Checklist — 1.0.0 (MAJOR)

## 1. New this release

- [x] `quicksticky.notepad` plugin — manual test (no automated QML UI test harness)

## 2. Manual regression tests

- [x] Overlay opens/closes via bar widget click and `omarchy-shell shell toggle quicksticky.notepad '{}'`
- [x] Text/Preview toggle renders markdown live, no split-pane
- [x] Page navigation (‹ › + －) persists text and color correctly across pages
- [x] Color picker updates card background and keeps text readable on every swatch
- [x] Window drag (title bar) and resize (◢ grip) work with the mouse
- [x] `Alt+Arrows` / `Alt+Shift+Arrows` / `Alt+0` hotkeys move, resize, and reset the window
- [x] State survives `omarchy restart shell` (reads back from `~/.local/state/omarchy/notepad.json`)
- [x] `omarchy plugin add https://github.com/Syxball/quicksticky-notepad.git --enable` installs and enables cleanly on a machine with no prior copy
- [ ] `omarchy plugin update quicksticky.notepad` picks up a new commit

## 3. Automated test suite

- [ ] `tests/test.sh` passes
