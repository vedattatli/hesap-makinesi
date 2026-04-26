import 'package:flutter/widgets.dart';

import '../data/calculator_settings.dart';

class CalculatorLocalization extends InheritedWidget {
  const CalculatorLocalization({
    super.key,
    required this.language,
    required super.child,
  });

  final CalculatorAppLanguage language;

  static CalculatorStrings of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<CalculatorLocalization>();
    return CalculatorStrings(inherited?.language ?? CalculatorAppLanguage.en);
  }

  @override
  bool updateShouldNotify(CalculatorLocalization oldWidget) {
    return oldWidget.language != language;
  }
}

class CalculatorStrings {
  const CalculatorStrings(this.language);

  final CalculatorAppLanguage language;

  bool get isTurkish => language == CalculatorAppLanguage.tr;

  String t(String key) {
    final table = isTurkish ? _tr : _en;
    return table[key] ?? _en[key] ?? key;
  }

  String modeLabel(String modeName) {
    final key = 'mode.$modeName';
    return t(key);
  }
}

const Map<String, String> _en = <String, String>{
  'app.title': 'Scientific Calculator',
  'app.subtitle': 'Independent core, controller and persistence architecture',
  'label.expression': 'Expression',
  'hint.expression': 'Type an expression or use the keypad',
  'label.result': 'Result',
  'label.normalized': 'Normalized',
  'label.alternatives': 'Alternatives',
  'action.saveResult': 'Save result',
  'action.copyResult': 'Copy result',
  'snackbar.resultCopied': 'Result copied to clipboard.',
  'snackbar.resultSaved': 'Result saved to worksheet.',
  'snackbar.graphSaved': 'Graph saved to worksheet.',
  'snackbar.historySaved': 'History item saved to worksheet.',
  'settings.title': 'Settings',
  'settings.angleMode': 'Angle mode',
  'settings.numericMode': 'Numeric mode',
  'settings.domain': 'Calculation domain',
  'settings.unitMode': 'Unit mode',
  'settings.precision': 'Precision',
  'settings.resultFormat': 'Result format',
  'settings.theme': 'Theme',
  'settings.accessibility': 'Accessibility',
  'settings.language': 'Language',
  'settings.english': 'English',
  'settings.turkish': 'Turkish',
  'settings.reduceMotion': 'Reduce motion',
  'settings.reduceMotionSubtitle':
      'Shortens premium transitions for motion-sensitive users.',
  'settings.highContrast': 'High contrast',
  'settings.highContrastSubtitle':
      'Increases contrast for badges, controls and focus states.',
  'settings.clearHistory': 'Clear history',
  'settings.themeSystem': 'System',
  'settings.themeLight': 'Light',
  'settings.themeDark': 'Dark',
  'command.title': 'Command Palette',
  'command.shortcuts': 'Keyboard Shortcuts',
  'command.insertSin': 'Insert sin',
  'command.insertSolve': 'Insert solve',
  'command.switchExact': 'Switch to exact',
  'command.switchApprox': 'Switch to approximate',
  'command.openGraph': 'Open graph',
  'command.openWorksheet': 'Open worksheet',
  'command.openHistory': 'Open history',
  'command.saveResult': 'Save result to worksheet',
  'command.copyResult': 'Copy result',
  'mode.calculator': 'CALC',
  'mode.graph': 'GRAPH',
  'mode.worksheet': 'WORKSHEET',
  'mode.cas': 'CAS',
  'mode.stats': 'STATS',
  'mode.matrix': 'MATRIX',
  'mode.units': 'UNITS',
  'mode.history': 'HISTORY',
  'toolbar.precision': 'Precision',
  'toolbar.openCommandPalette': 'Open command palette',
  'toolbar.openSettings': 'Open settings',
  'toolbar.openHistory': 'Open history',
  'semantics.expressionEditor': 'Expression editor',
  'semantics.result': 'Calculation result',
  'semantics.modeNavigation': 'Calculator mode navigation',
  'semantics.error': 'Error',
  'semantics.warning': 'Warning',
};

const Map<String, String> _tr = <String, String>{
  'app.title': 'Bilimsel Hesap Makinesi',
  'app.subtitle': 'Bagimsiz core, controller ve kalici veri mimarisi',
  'label.expression': 'Ifade',
  'hint.expression': 'Bir ifade yazin veya tuslari kullanin',
  'label.result': 'Sonuc',
  'label.normalized': 'Normalize',
  'label.alternatives': 'Alternatifler',
  'action.saveResult': 'Sonucu kaydet',
  'action.copyResult': 'Sonucu kopyala',
  'snackbar.resultCopied': 'Sonuc panoya kopyalandi.',
  'snackbar.resultSaved': 'Sonuc worksheet icine kaydedildi.',
  'snackbar.graphSaved': 'Grafik worksheet icine kaydedildi.',
  'snackbar.historySaved': 'Gecmis kaydi worksheet icine kaydedildi.',
  'settings.title': 'Ayarlar',
  'settings.angleMode': 'Aci modu',
  'settings.numericMode': 'Sayisal mod',
  'settings.domain': 'Hesaplama alani',
  'settings.unitMode': 'Birim modu',
  'settings.precision': 'Hassasiyet',
  'settings.resultFormat': 'Sonuc formati',
  'settings.theme': 'Tema',
  'settings.accessibility': 'Erisilebilirlik',
  'settings.language': 'Dil',
  'settings.english': 'Ingilizce',
  'settings.turkish': 'Turkce',
  'settings.reduceMotion': 'Hareketi azalt',
  'settings.reduceMotionSubtitle':
      'Harekete duyarlilik icin premium gecisleri kisaltir.',
  'settings.highContrast': 'Yuksek kontrast',
  'settings.highContrastSubtitle':
      'Rozetler, kontroller ve fokus durumlari icin kontrasti artirir.',
  'settings.clearHistory': 'Gecmisi temizle',
  'settings.themeSystem': 'Sistem',
  'settings.themeLight': 'Acik',
  'settings.themeDark': 'Koyu',
  'command.title': 'Komut Paleti',
  'command.shortcuts': 'Klavye Kisayollari',
  'command.insertSin': 'sin ekle',
  'command.insertSolve': 'solve ekle',
  'command.switchExact': 'Exact moda gec',
  'command.switchApprox': 'Approx moda gec',
  'command.openGraph': 'Grafik modunu ac',
  'command.openWorksheet': 'Worksheet modunu ac',
  'command.openHistory': 'Gecmisi ac',
  'command.saveResult': 'Sonucu worksheet icine kaydet',
  'command.copyResult': 'Sonucu kopyala',
  'mode.calculator': 'HESAP',
  'mode.graph': 'GRAFIK',
  'mode.worksheet': 'WORKSHEET',
  'mode.cas': 'CAS',
  'mode.stats': 'ISTAT',
  'mode.matrix': 'MATRIX',
  'mode.units': 'BIRIM',
  'mode.history': 'GECMIS',
  'toolbar.precision': 'Hassasiyet',
  'toolbar.openCommandPalette': 'Komut paletini ac',
  'toolbar.openSettings': 'Ayarlari ac',
  'toolbar.openHistory': 'Gecmisi ac',
  'semantics.expressionEditor': 'Ifade editoru',
  'semantics.result': 'Hesaplama sonucu',
  'semantics.modeNavigation': 'Hesap makinesi mod navigasyonu',
  'semantics.error': 'Hata',
  'semantics.warning': 'Uyari',
};
