# Android Release Readiness

## Android Build Mevcut Durumu

Android projesi Kotlin DSL Gradle yapisini kullaniyor:

- App Gradle: `android/app/build.gradle.kts`
- Root Gradle: `android/build.gradle.kts`
- Settings: `android/settings.gradle.kts`
- Gradle wrapper: `gradle-8.14-all`
- Android Gradle Plugin: `8.11.1`
- Kotlin Android plugin: `2.2.20`
- Java/Kotlin target: 17

Flutter surumu ve SDK yollari `android/local.properties` uzerinden yerel olarak
cozulur. Bu dosya git'e eklenmemelidir.

## ApplicationId / Version

- `namespace`: `com.vedattatli.hesapmakinesi`
- `applicationId`: `com.vedattatli.hesapmakinesi`
- `versionName`: `pubspec.yaml` uzerinden `1.0.0`
- `versionCode`: `pubspec.yaml` uzerinden `1`
- `minSdk`: Flutter SDK default (`flutter.minSdkVersion`)
- `targetSdk`: Flutter SDK konfigrasyonu
- `compileSdk`: Flutter SDK konfigrasyonu

`com.example...` template id kaldirildi.

## Manifest Incelemesi

Ana manifest local-first politika ile sade tutuldu:

- App label: `Hesap Makinesi`
- Main activity: exported `true`, launcher intent-filter ile sinirli
- `launchMode`: `singleTop`
- `windowSoftInputMode`: `adjustResize`
- `hardwareAccelerated`: `true`
- `resizeableActivity`: `true`
- `usesCleartextTraffic`: `false`
- Main manifest icinde `INTERNET` permission yok

Debug/profile manifestlerinde Flutter tooling icin `INTERNET` permission kalir;
release main manifest local-first kalir.

## Icon / Splash Durumu

Template splash yerine Android tarafinda markali launch background kullanilir:

- `drawable/launch_mark.xml`
- `drawable/launch_background.xml`
- `drawable-v21/launch_background.xml`
- `values/colors.xml`
- `values-night/colors.xml`

Android 8+ adaptive icon kaynaklari eklendi:

- `mipmap-anydpi-v26/ic_launcher.xml`
- `mipmap-anydpi-v26/ic_launcher_round.xml`
- `drawable/ic_launcher_foreground.xml`

Mevcut PNG launcher ikonlari eski cihazlar icin korunur. Kullanici ozel marka
logosu vermedigi icin ikon minimal hesap makinesi markasidir; final store asset
icin profesyonel logo/feature graphic ayrica hazirlanmalidir.

## Yapilan Duzeltmeler

- Release build debug signing fallback kaldirildi.
- `key.properties` varsa release signing kullanacak yapi kuruldu.
- `key.properties` yoksa release build unsigned kalir; gizli bilgi repo icine
  girmez.
- `android/key.properties.example` eklendi.
- `.gitignore` signing secret ve keystore patternleriyle netlestirildi.
- `applicationId` ve Kotlin package non-template hale getirildi.
- Main manifest gereksiz permission icermeyecek sekilde kontrol edildi.
- Launch theme, normal theme, status bar ve navigation bar renkleri Android
  light/dark baslangic ekraniyla uyumlu hale getirildi.
- Android release config testleri eklendi.
- Gradle wrapper dosyalari ignore disina alindi; clean checkout Android build
  icin wrapper dosyalarini tasiyabilir.

## Dogrulanan Ciktilar

Bu repo yolu `Masaustu` yerine `Masaüstü` gibi non-ASCII karakter icerdigi icin
Windows release AOT snapshot asamasinda `app.dill` okuma hatasi uretir. Ayni
kaynaklar ASCII bir gecici klasore kopyalanip build dogrulandi:
`C:\hm_release_copy`.

Dogrulanan ve bu repo altindaki `build/` klasorune geri kopyalanan ciktilar:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- APK boyutu: 52.91 MB
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- AAB boyutu: 42.56 MB
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Debug APK boyutu: 140.42 MB

`apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk`
sonucu release APK icin `DOES NOT VERIFY` verdi. Beklenen durumdur, cunku
repoda gercek keystore ve `android/key.properties` yoktur. Signed release icin
kullanici lokal keystore olusturup yeniden build etmelidir.

## Release APK / AAB Uretim Adimlari

Unsigned local build:

```powershell
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Non-ASCII Windows yol sorunu gorulurse repo kopyasi ASCII bir klasorde
calistirilmalidir, ornek:

```powershell
robocopy . C:\hm_release_copy /MIR /XD .git .dart_tool build .gradle .kotlin /XD android\build android\app\build
cd C:\hm_release_copy
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Signed release icin once keystore olusturulmali ve `android/key.properties`
lokalde hazirlanmalidir.

## Signing Adimlari

Windows PowerShell:

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

macOS/Linux:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` ornegi:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:\\Users\\USERNAME\\upload-keystore.jks
```

Windows path icinde backslash karakterleri cift yazilmalidir.

## Bilinen Eksikler

- Gercek release keystore bu repoda yok ve olmamalidir.
- Signed Play upload icin kullanici lokal keystore olusturup yeniden build
  etmelidir.
- Release AOT build Windows'ta non-ASCII proje yolunda kiriliyor; ASCII path
  ile build dogrulandi.
- Store icon, feature graphic ve screenshots icin ozel marka tasarimi ayrica
  hazirlanmalidir.
- Android cihaz/emulator uzerinde manuel gorsel smoke onerilir.

## Kullanicinin APK Cikarma Komutlari

```powershell
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

APK yolu:

```text
build/app/outputs/flutter-apk/app-release.apk
```

AAB yolu:

```text
build/app/outputs/bundle/release/app-release.aab
```

Telefona kurulum:

```powershell
flutter install --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Not: Unsigned release APK normal Android kurulumunda kabul edilmeyebilir.
Signed release icin once keystore adimlari uygulanmalidir. Hemen cihazda smoke
test icin debug APK kurulabilir:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
