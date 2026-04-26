# Hesap Makinesi

![Flutter](https://img.shields.io/badge/Flutter-3.41%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-444%20passing-2ea44f)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-334155)
![Local First](https://img.shields.io/badge/local--first-no%20cloud-0f766e)

Modern Flutter ile gelistirilmis, local-first calisan kapsamli bir bilimsel
hesap makinesi ve matematik calisma alani.

Repository: [vedattatli/hesap-makinesi](https://github.com/vedattatli/hesap-makinesi)

## Nedir?

Bu proje basit bir calculator UI'inin cok otesine gecen, Flutter'dan bagimsiz
bir Dart matematik cekirdegi uzerine kurulu bilimsel hesap makinesi
uygulamasidir. Core katman guvenli lexer/parser/evaluator mimarisiyle calisir;
Flutter UI ise calculator, graph, worksheet, CAS-lite, export, ayarlar,
accessibility ve productization katmanlarini kullaniciya sunar.

Uygulama cloud, account veya external API gerektirmez. History, settings,
worksheet ve export akislari local-first tasarlanmistir.

## One Cikan Ozellikler

- Typed calculator core: exact/approx numeric mode, rational values, typed errors
  and structured result metadata.
- Symbolic-lite math: radicals, symbolic constants, exact trig table, limited
  expression transforms.
- Complex domain: `i`, complex arithmetic, helper functions and formatted
  complex results.
- Vector and matrix support: literals, constructors, determinant, inverse,
  transpose and arithmetic.
- Units: dimension vectors, unit-aware arithmetic, conversion and temperature
  handling.
- Statistics: datasets, descriptive stats, quantiles, weighted mean,
  distributions, combinatorics, regression and correlation.
- Graphing: `fn`, `plot`, adaptive sampling, discontinuity breaks, roots,
  intersections, slope, area and a Flutter graph panel.
- Worksheet/notebook: calculation, text, graph, variable, function, solve and
  CAS blocks with dependency graph execution.
- Worksheet-scoped symbols: variables and user-defined functions without
  enabling unsafe global resolver behavior.
- CAS-lite: equation parsing, solve/nsolve, polynomial detection, exact
  linear/quadratic solving, rational-root cases, derivative/integral helpers,
  simplify/expand/factor and small linear systems.
- Premium UI: responsive shell, mode navigation, result cards, graph/worksheet
  panels, command palette, input editors, autocomplete and palettes.
- Accessibility/i18n: Turkish/English localization, high contrast groundwork,
  reduced motion, keyboard shortcuts and semantic labels.
- Productization: onboarding, examples library, help/reference panel,
  backup/restore, export previews and release documentation.

## Ornek Ifadeler

```text
1/3 + 1/6
sqrt(2)
sqrt(-1)              // complex mode
det(mat(2,2,1,2,3,4))
to(1 m + 20 cm, cm)
mean(data(1,2,3,4))
linreg(data(1,2,3), data(2,4,6))
plot(sin(x), -pi, pi)
roots(x^2 - 4, -5, 5)
solve(x^2 - 4 = 0, x)
diff(3*x^2 + 2*x + 1, x)
factor(x^3 - 6*x^2 + 11*x - 6)
```

## Uygulama Modlari

| Mode | Kisa aciklama |
| --- | --- |
| Calc | Scientific/exact/symbolic/complex hesaplama. |
| Graph | Fonksiyon cizimi, viewport, pan/zoom, roots/intersections helpers. |
| Worksheet | Notebook bloklari, scoped variables/functions, run all, export. |
| CAS | Solve, simplify, expand, factor, derivative/integral helpers. |
| Stats | Dataset, probability, combinatorics, regression/correlation. |
| Matrix | Vector/matrix girisleri ve linear algebra islemleri. |
| Units | Unit-aware arithmetic and conversion. |
| History | Structured history, recall, export and worksheet save flows. |

## Mimari

Matematik cekirdegi Flutter'dan bagimsiz tutulur:

- [`lib/core/calculator/`](lib/core/calculator): lexer, parser, evaluator,
  typed values, formatter, graph, statistics, units, solve and CAS-lite.
- [`lib/features/calculator/application/`](lib/features/calculator/application):
  calculator controller/state.
- [`lib/features/calculator/data/`](lib/features/calculator/data): settings,
  history and storage.
- [`lib/features/calculator/worksheet/`](lib/features/calculator/worksheet):
  worksheet documents, blocks, scoped symbol table, dependency graph,
  execution and export.
- [`lib/features/calculator/presentation/`](lib/features/calculator/presentation):
  Flutter UI, design system, localization, panels, graph painter and input
  editors.
- [`lib/features/calculator/productization/`](lib/features/calculator/productization):
  examples, sample worksheets and local backup helpers.

Detayli mimari ve faz dokumanlari icin:

- [Documentation Index](docs/README.md)
- [User Guide](docs/user_guide.md)
- [Developer Guide](docs/developer_guide.md)
- [Final Regression Matrix](docs/final_regression_matrix.md)
- [Known Limitations](docs/known_limitations.md)

## Baslamak

### Gereksinimler

- Flutter SDK `3.41+`
- Dart `3.11+`
- Android Studio / Android SDK for Android builds
- macOS + Xcode + CocoaPods for iOS archive/IPA builds

### Kurulum

```bash
flutter pub get
```

Windows'ta Flutter PATH'te degilse:

```powershell
C:\src\flutter\bin\flutter.bat pub get
```

### Calistirma

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## Dogrulama

Guncel kalite komutlari:

```bash
flutter analyze
flutter test
git diff --check
```

Bu makinede explicit Flutter path:

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
git diff --check
```

Son dogrulanan test sayisi: `444`.

## Android Release

Android tarafinda release config, adaptive icon/splash, manifest and signing
hazirligi yapildi. Gercek keystore ve `android/key.properties` repo icine
girmemelidir.

Keystore olusturulduysa ignored local `android/key.properties` dosyasini
guvenli sekilde yazmak icin:

```powershell
powershell -ExecutionPolicy Bypass -File tools\create_android_key_properties.ps1
```

Ardindan:

```powershell
flutter clean
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Beklenen ciktilar:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

Not: Windows'ta proje yolu non-ASCII karakter iceriyorsa release AOT build
kirabilir. Boyle bir durumda projeyi `C:\hm_release_copy` gibi ASCII bir klasore
kopyalayip build alin.

Detay: [Android Release Readiness](docs/android_release_readiness.md)

## iOS Release

iOS project release-ready ayarlara yaklastirildi: bundle id, Podfile,
Info.plist, launch screen and export/signing template hazir. IPA uretimi icin
macOS + Xcode + CocoaPods gerekir.

Mac uzerinde:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
flutter build ipa --release
```

Detay: [iOS Release Readiness](docs/ios_release_readiness.md)

## Export / Backup

Worksheet, graph and history data local-first calisir. Desteklenen export
yuzeyleri:

- Worksheet Markdown
- Worksheet calculation CSV
- Graph SVG
- Graph sampled data CSV
- History Markdown/CSV
- Local backup JSON

Dosya secici veya cloud sync eklenmedi; kullanici kontrollu preview/copy akisi
tercih edildi.

## Guvenlik ve Gizli Dosyalar

Asagidaki dosyalar local-only kalmalidir:

- `android/key.properties`
- `*.jks`
- `*.keystore`
- `ios/ExportOptions.plist`
- `*.mobileprovision`
- `*.p12`
- `*.cer`

Bu repo secret icermemelidir. Release signing bilgileri sadece local makinede
tutulur.

## Bilinen Limitler

- Bu bir full CAS degildir; CAS-lite kapsamli ve guard'li calisir.
- Global user-defined variables/functions acik degildir; symbols worksheet scope
  icindedir.
- Graph roots/numeric solvers approximate olabilir.
- 3D/parametric/polar graph yoktur.
- Cloud sync, account system and external API yoktur.
- iOS IPA build Windows'ta yapilamaz; Mac/Xcode gerekir.

Daha fazla detay: [Known Limitations](docs/known_limitations.md)

## Release Durumu

- `flutter analyze`: passing
- `flutter test`: passing
- Android project: release signing hazir, local `key.properties` gerektirir
- iOS project: macOS/Xcode signing sonrasi archive/IPA hazirligi mevcut
- GitHub docs: architecture, user guide, developer guide, QA matrix and release
  notes included
