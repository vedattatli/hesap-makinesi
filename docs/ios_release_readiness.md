# iOS Release Readiness

## iOS Build Mevcut Durumu

iOS projesi standart Flutter Runner yapisini kullaniyor:

- Workspace: `ios/Runner.xcworkspace`
- Xcode project: `ios/Runner.xcodeproj`
- App plist: `ios/Runner/Info.plist`
- Launch screen: `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- App icons: `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- Podfile: `ios/Podfile`

Bu calisma Windows ortaminda yapildi. iOS build, archive ve IPA uretimi icin
macOS + Xcode + CocoaPods gerekir. Windows ortaminda proje ayarlari ve testler
dogrulanabilir, fakat `flutter build ios` veya `flutter build ipa` calismaz.

## Bundle ID / Version

- Bundle ID: `com.vedattatli.hesapmakinesi`
- Test bundle ID: `com.vedattatli.hesapmakinesi.RunnerTests`
- Display name: `Hesap Makinesi`
- `CFBundleShortVersionString`: `$(FLUTTER_BUILD_NAME)`
- `CFBundleVersion`: `$(FLUTTER_BUILD_NUMBER)`
- `pubspec.yaml`: `1.0.0+1`
- Deployment target: iOS `13.0`
- Device family: iPhone + iPad (`1,2`)

`com.example...` template bundle id kaldirildi.

## Xcode / Podfile Durumu

`ios/Podfile` eklendi ve Flutter pod helper akisi ile uyumlu hale getirildi.
Deployment target `13.0` olarak sabitlendi. Pod install icin once
`flutter pub get`, sonra macOS uzerinde `cd ios && pod install && cd ..`
calistirilmalidir.

Runner target icin automatic signing hazir tutuldu. Team ID hardcoded degildir;
kullanici Xcode icinde kendi Apple Developer Team bilgisini sececektir.

## Info.plist / Permissions

`Info.plist` local-first calculator politikasina uygun tutuldu:

- Gereksiz camera/microphone/location usage description yok.
- Launch storyboard `LaunchScreen`.
- iPhone portrait + landscape desteklenir.
- iPad portrait, upside-down ve landscape desteklenir.
- `UIApplicationSupportsIndirectInputEvents` aktif.
- `UIRequiresFullScreen` false; iPad multitasking/split view icin daha uygundur.
- `ITSAppUsesNonExemptEncryption` false olarak belirtildi.

## Icon / Launch Screen

AppIcon seti iPhone, iPad ve marketing 1024x1024 slotlarini icerir. Launch
screen beyaz template yerine markali, sade ve premium bir ekran olacak sekilde
yenilendi. Launch screen named color assets kullanir:

- `LaunchBackground`
- `LaunchAccent`
- `LaunchCard`
- `LaunchText`
- `LaunchMutedText`

Kullanici ozel marka logosu vermedigi icin mevcut ikonlar final store gorseli
icin placeholder kabul edilmelidir. App Store icin profesyonel icon, feature
graphic ve screenshots ayrica hazirlanmalidir.

## Signing Hazirligi

Gercek signing certificate, provisioning profile, Team ID veya Apple account
bilgisi repoya yazilmadi. `ios/ExportOptions.example.plist` sadece non-secret
ornek export ayaridir. Gercek `ios/ExportOptions.plist`, `.p12`, `.cer`,
`.mobileprovision` ve provisioning dosyalari git tarafindan ignore edilir.

Xcode icinde:

1. `ios/Runner.xcworkspace` acilir.
2. Runner target secilir.
3. Signing & Capabilities bolumunde Team secilir.
4. Bundle ID `com.vedattatli.hesapmakinesi` dogrulanir.
5. Product > Archive ile archive alinabilir.

## IPA Uretim Adimlari

Mac uzerinde on hazirlik:

```bash
flutter doctor -v
flutter pub get
cd ios && pod install && cd ..
```

No-codesign dogrulama:

```bash
flutter build ios --debug --no-codesign
flutter build ios --release --no-codesign
```

Signed IPA:

```bash
flutter build ipa --release
```

Export method ornekleri:

```bash
flutter build ipa --release --export-method app-store
flutter build ipa --release --export-method ad-hoc
flutter build ipa --release --export-method development
```

Beklenen ciktilar:

- Archive: `build/ios/archive/Runner.xcarchive`
- IPA: `build/ios/ipa/*.ipa`

## App Store / TestFlight Notlari

App Store Connect/TestFlight upload bu fazda yapilmadi. Upload icin Apple
Developer Program uyeligi, valid signing certificate/provisioning profile ve
App Store Connect app kaydi gerekir. `version/build` degerleri `pubspec.yaml`
uzerinden `1.0.0+1`; sonraki yuklemelerde build number artirilmalidir.

## Bilinen Eksikler

- Bu Windows ortaminda macOS/Xcode olmadigi icin IPA uretilemez.
- CocoaPods `pod install` komutu macOS ortaminda calistirilmalidir.
- Apple Developer Team ID ve signing secret kullanici tarafindan lokal
  ayarlanmalidir.
- Store icon ve screenshot seti final marka calismasi gerektirir.
- Fiziksel iPhone/iPad uzerinde manuel safe-area, keyboard ve graph gesture
  smoke onerilir.
