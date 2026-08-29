# Release Checklist — 1.0.1 (PATCH)

## 1. New this release

- [x] Renamed displayed app title from "Notepad" to "Quick Sticky" — manually verified in the running overlay after `omarchy restart shell`

## 2. Manual regression tests

~~- [ ] Overlay opens/closes via bar widget click and `omarchy-shell shell toggle quicksticky.notepad '{}'`~~
~~- [ ] Text/Preview toggle renders markdown live, no split-pane~~
~~- [ ] Page navigation (‹ › + －) persists text and color correctly across pages~~
~~- [ ] Color picker updates card background and keeps text readable on every swatch~~
~~- [ ] Window drag (title bar) and resize (◢ grip) work with the mouse~~
~~- [ ] `Alt+Arrows` / `Alt+Shift+Arrows` / `Alt+0` hotkeys move, resize, and reset the window~~
~~- [ ] State survives `omarchy restart shell` (reads back from `~/.local/state/omarchy/notepad.json`)~~
~~- [ ] `omarchy plugin update quicksticky.notepad` picks up a new commit~~

## 3. Automated test suite

- [ ] `tests/test.sh` passes
