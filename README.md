# HanAIndicator

Version: `0.2.4`

Small local macOS menu bar app that shows the current input source as a badge:

- Korean input sources such as `2-Set Korean` -> `한`
- English/ABC/U.S. input sources -> `A`

It tries to place the badge next to the text cursor using macOS Accessibility.
If the current app does not expose a text cursor position, it falls back to the
mouse pointer.

## Build

```bash
/Users/macpro/HanAIndicator/build.sh
```

## Run

```bash
open /Users/macpro/HanAIndicator/build/HanAIndicator.app
```

When macOS asks for permission, allow it in:

```text
System Settings -> Privacy & Security -> Accessibility -> HanAIndicator
```

## Menu

The menu bar item is `한A`.

- `Settings...`: opens the categorized settings window
- `Version 0.2.4`: shows the current app version
- `Open Accessibility Settings`: open the required macOS permission panel
- `Quit HanAIndicator`: quit the app

## Settings

### General

- `Keep badge visible`: keeps the badge on screen while you type. Turn this off
  if you only want a short confirmation after switching input sources.
- `Prefer text cursor position`: tries to attach the badge to the blinking text
  cursor. If the active app does not expose a cursor rectangle through
  Accessibility, HanAIndicator falls back to the mouse pointer.

### Indicator

- `Icon size`: changes the floating badge size from 14 px to 72 px.
- `Cursor position`: places the badge around the cursor using Bottom Right,
  Top Right, Bottom Left, Top Left, or Centered anchoring.
- `Offset X/Y`: fine-tunes the badge distance from the cursor.
- `Korean label`: label shown for Korean input sources, default `한`.
- `English label`: label shown for English/ABC input sources, default `A`.
- `Korean` and `English` color wells: set background and text colors separately
  for each input indicator.
- `Choose Image...`: replaces the badge background image. The label remains on
  top so the current input source is still readable.
- `Clear Image`: removes the custom badge background image.
- The badge fades to a semi-transparent state after the mouse has been still
  for one second, then returns to full opacity when the mouse moves again.

### Advanced

- `Reset Options`: restores defaults.
- `Open Project Folder`: opens the local project folder.

### About

Explains the current options and version inside the app.
