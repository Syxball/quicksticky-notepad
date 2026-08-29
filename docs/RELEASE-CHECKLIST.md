# Release Checklist — 1.0.0 (MAJOR)

## 1. New this release

- [x] `quicksticky.notepad` plugin — manual test (no automated QML UI test harness)

## 2. Manual regression tests

- [ ] Overlay opens/closes via bar widget click and `omarchy-shell shell toggle quicksticky.notepad '{}'`
- [ ] Text/Preview toggle renders markdown live, no split-pane
- [ ] Page navigation (‹ › + －) persists text and color correctly across pages
- [ ] Color picker updates card background and keeps text readable on every swatch
- [ ] Window drag (title bar) and resize (◢ grip) work with the mouse
- [ ] `Alt+Arrows` / `Alt+Shift+Arrows` / `Alt+0` hotkeys move, resize, and reset the window
- [ ] State survives `omarchy restart shell` (reads back from `~/.local/state/omarchy/notepad.json`)
- [ ] `omarchy plugin add https://github.com/Syxball/quicksticky-notepad.git --enable` installs and enables cleanly on a machine with no prior copy
- [ ] `omarchy plugin update quicksticky.notepad` picks up a new commit

## 3. Automated test suite

- [ ] `tests/test.sh` passes
