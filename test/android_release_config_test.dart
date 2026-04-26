import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android release configuration', () {
    test('uses non-template application id and optional release signing', () {
      final buildGradle = File(
        'android/app/build.gradle.kts',
      ).readAsStringSync();

      expect(buildGradle, contains('com.vedattatli.hesapmakinesi'));
      expect(buildGradle, isNot(contains('com.example.hesap_makinesi')));
      expect(buildGradle, contains('key.properties'));
      expect(buildGradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(buildGradle, contains('isMinifyEnabled = false'));
      expect(buildGradle, contains('isShrinkResources = false'));
    });

    test('manifest is local-first and launcher metadata is release-ready', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:label="Hesap Makinesi"'));
      expect(manifest, contains('android:exported="true"'));
      expect(
        manifest,
        contains('android:roundIcon="@mipmap/ic_launcher_round"'),
      );
      expect(manifest, contains('android:usesCleartextTraffic="false"'));
      expect(manifest, isNot(contains('android.permission.INTERNET')));
    });

    test('signing secrets are ignored and example file is safe', () {
      final rootIgnore = File('.gitignore').readAsStringSync();
      final example = File('android/key.properties.example').readAsStringSync();

      expect(rootIgnore, contains('/android/key.properties'));
      expect(rootIgnore, contains('**/*.jks'));
      expect(rootIgnore, contains('**/*.keystore'));
      expect(example, contains('CHANGE_ME'));
      expect(example, contains('storeFile='));
    });

    test('adaptive icon and branded splash resources exist', () {
      expect(
        File(
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/drawable/launch_mark.xml').existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/values/colors.xml').existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/values-night/colors.xml').existsSync(),
        isTrue,
      );
    });
  });
}
