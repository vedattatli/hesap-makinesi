import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS release configuration', () {
    test('uses production bundle identifiers instead of template ids', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.vedattatli.hesapmakinesi;'),
      );
      expect(
        project,
        contains(
          'PRODUCT_BUNDLE_IDENTIFIER = com.vedattatli.hesapmakinesi.RunnerTests;',
        ),
      );
      expect(project, isNot(contains('com.example')));
      expect(project, contains('CODE_SIGN_STYLE = Automatic;'));
      expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;'));
      expect(project, contains('TARGETED_DEVICE_FAMILY = "1,2";'));
    });

    test('Info.plist keeps local-first release metadata', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, contains('<string>Hesap Makinesi</string>'));
      expect(plist, contains('<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>'));
      expect(plist, contains('<key>UILaunchStoryboardName</key>'));
      expect(plist, contains('<string>LaunchScreen</string>'));
      expect(plist, contains('<key>UIRequiresFullScreen</key>'));
      expect(plist, contains('<false/>'));
      expect(plist, isNot(contains('NSCameraUsageDescription')));
      expect(plist, isNot(contains('NSMicrophoneUsageDescription')));
      expect(plist, isNot(contains('NSLocationWhenInUseUsageDescription')));
    });

    test('Podfile and signing export template are safe for release prep', () {
      final podfile = File('ios/Podfile').readAsStringSync();
      final exportOptions = File(
        'ios/ExportOptions.example.plist',
      ).readAsStringSync();
      final iosGitignore = File('ios/.gitignore').readAsStringSync();
      final rootGitignore = File('.gitignore').readAsStringSync();

      expect(podfile, contains("platform :ios, '13.0'"));
      expect(podfile, contains('flutter_ios_podfile_setup'));
      expect(podfile, contains('flutter_install_all_ios_pods'));
      expect(exportOptions, contains('<string>app-store</string>'));
      expect(exportOptions, contains('<string>automatic</string>'));
      expect(exportOptions, isNot(contains('teamID')));
      expect(iosGitignore, contains('ExportOptions.plist'));
      expect(iosGitignore, contains('*.mobileprovision'));
      expect(rootGitignore, contains('/ios/ExportOptions.plist'));
      expect(rootGitignore, contains('*.p12'));
    });

    test('launch screen and app icon assets are present', () {
      final launch = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();
      final appIcon = File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).readAsStringSync();

      expect(launch, contains('LaunchBackground'));
      expect(launch, contains('LaunchAccent'));
      expect(launch, contains('Hesap Makinesi'));
      expect(launch, isNot(contains('LaunchImage')));
      expect(appIcon, contains('ios-marketing'));
      expect(
        Directory(
          'ios/Runner/Assets.xcassets/LaunchBackground.colorset',
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          'ios/Runner/Assets.xcassets/LaunchAccent.colorset',
        ).existsSync(),
        isTrue,
      );
    });
  });
}
