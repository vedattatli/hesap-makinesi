# Scientific Calculator

A responsive scientific calculator built with Flutter.

## Features

- Clean scientific calculator layout
- Core math operators: `+`, `-`, `*`, `/`, `^`
- Scientific functions: `sin`, `cos`, `tan`, `log`, `sqrt`
- Parentheses support
- Degree and radian angle modes
- Responsive Flutter UI for web and desktop

## Run

```bash
flutter pub get
flutter run
```

## Validation

```bash
flutter analyze
flutter test
flutter build web
```

## Windows note

This project lives in a folder path with non-ASCII characters. Flutter Windows
builds may fail directly from this location on some Windows setups.

Use the helper script below for a safe Windows build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_safe.ps1
```
