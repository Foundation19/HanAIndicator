# HanAIndicator

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

- `Keep Badge Visible`: keep the badge visible, Keyla-style
- `Prefer Text Cursor Position`: try the blinking text caret first
- `Open Accessibility Settings`: open the required macOS permission panel
- `Quit HanAIndicator`: quit the app
