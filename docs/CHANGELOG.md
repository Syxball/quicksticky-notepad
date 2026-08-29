# Changelog

All notable changes to this repository will be documented here.

Version format: `MAJOR.MINOR.PATCH`
- **PATCH** — bug fixes and small improvements
- **MINOR** — new features, backwards compatible
- **MAJOR** — significant redesigns or breaking changes

---

## 1.0.1 (2026-08-30)

- Renamed the displayed app title from "Notepad" to "Quick Sticky" (overlay title bar, bar-widget tooltip, manifest name)
- Added a README overlay screenshot and an animated GIF demo (typing, markdown preview, color picker, window drag/resize)
- README now tracks every version, including patches, instead of minor/major only
- Stopped tracking `docs/RELEASE-CHECKLIST.md` and `docs/TODO.md` — kept locally for personal use, no longer part of the repo

## 1.0.0 (2026-08-29)

- Added `quicksticky.notepad` plugin: persistent multi-page notepad overlay with a markdown Text/Preview toggle, per-note color picker (7 swatches, contrast-aware text), a draggable and resizable window (mouse + Alt-based hotkeys), and a bar-widget launcher
