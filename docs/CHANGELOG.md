# Changelog

All notable changes to this repository will be documented here.

Version format: `MAJOR.MINOR.PATCH`
- **PATCH** — bug fixes and small improvements
- **MINOR** — new features, backwards compatible
- **MAJOR** — significant redesigns or breaking changes

---

## 1.1.0 (2026-08-30)

- Added an in-overlay settings menu: a gear icon expands a collapsible drawer inside the same card, no new manifest entry point
- Added a default note color setting — new pages/notes start with the picked swatch instead of always the default
- Added a hotkeys reference to the settings drawer, so the move/resize/reset shortcuts are discoverable in-app
- Added a default startup window position setting (center + 4 corners); manual drag/resize still overrides it for the rest of the session, and `Alt+0` now resets back to the configured position rather than a hardcoded center

## 1.0.1 (2026-08-30)

- Renamed the displayed app title from "Notepad" to "Quick Sticky" (overlay title bar, bar-widget tooltip, manifest name)
- Added a README overlay screenshot and an animated GIF demo (typing, markdown preview, color picker, window drag/resize)
- README now tracks every version, including patches, instead of minor/major only
- Stopped tracking `docs/RELEASE-CHECKLIST.md` and `docs/TODO.md` — kept locally for personal use, no longer part of the repo

## 1.0.0 (2026-08-29)

- Added `quicksticky.notepad` plugin: persistent multi-page notepad overlay with a markdown Text/Preview toggle, per-note color picker (7 swatches, contrast-aware text), a draggable and resizable window (mouse + Alt-based hotkeys), and a bar-widget launcher
