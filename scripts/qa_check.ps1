$ErrorActionPreference = 'Stop'

flutter analyze
flutter test
git diff --check
dart format --set-exit-if-changed lib test
