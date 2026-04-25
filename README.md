# Scientific Calculator

![Flutter](https://img.shields.io/badge/Flutter-3.41%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Web%20%7C%20Android%20%7C%20Windows-2ea44f)

A responsive scientific calculator built with Flutter.

Repository: [vedattatli/hesap-makinesi](https://github.com/vedattatli/hesap-makinesi)

## Overview

This project is a custom scientific calculator application with a clean dark
interface and a lightweight expression engine written in Dart.

It supports both everyday arithmetic and common scientific operations while
remaining simple to run on multiple Flutter targets.

## Features

- Responsive calculator UI built with Flutter
- Core operators: `+`, `-`, `*`, `/`, `^`
- Scientific functions: `sin`, `cos`, `tan`, `log`, `sqrt`
- Parentheses support for complex expressions
- Degree and radian angle modes
- Backspace and clear actions
- Custom expression parsing and evaluation logic

## Example Expressions

- `7 + 8`
- `sqrt(16)`
- `sin(30)` in degree mode
- `cos(0)`
- `(2+3)^2`
- `log(100)`

## Project Structure

- [`lib/main.dart`](lib/main.dart): UI and input flow
- [`lib/calculator_engine.dart`](lib/calculator_engine.dart): parser and evaluator
- [`test/calculator_engine_test.dart`](test/calculator_engine_test.dart): engine tests
- [`test/widget_test.dart`](test/widget_test.dart): widget test
- [`scripts/build_windows_safe.ps1`](scripts/build_windows_safe.ps1): safe Windows build helper

## Getting Started

### Prerequisites

- Flutter SDK
- A browser, Android device/emulator, or Windows desktop toolchain

### Install Dependencies

```bash
flutter pub get
```

### Run The App

```bash
flutter run -d chrome
```

If Flutter is not available in your PATH on Windows, you can use:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run -d chrome
```

## Validation

The project has been verified with the following commands:

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Windows Build Note

This project may be stored in a folder path containing non-ASCII characters.
On some Windows setups, Flutter desktop builds can fail directly from such
paths.

Use the helper script below for a safe Windows build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_safe.ps1
```

The generated Windows output is copied into:

```text
artifacts/windows
```

## Status

- Code analysis passes
- Tests pass
- Web build passes
- Android debug APK build passes
- Windows build has been verified with the helper script
