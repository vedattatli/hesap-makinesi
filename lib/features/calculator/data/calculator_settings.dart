import 'dart:convert';
import 'dart:ui';

import '../../../core/calculator/calculator.dart';

/// Stores calculator preferences that should survive app restarts.
class CalculatorSettings {
  const CalculatorSettings({
    required this.angleMode,
    required this.precision,
    required this.numericMode,
    required this.calculationDomain,
    required this.unitMode,
    required this.themePreference,
    required this.resultFormat,
    this.reduceMotion = false,
    this.highContrast = false,
    this.language = CalculatorAppLanguage.en,
    this.onboardingCompleted = false,
    this.updatedAt,
  }) : assert(precision > 0, 'precision must be positive');

  static const defaults = CalculatorSettings(
    angleMode: AngleMode.degree,
    precision: 10,
    numericMode: NumericMode.approximate,
    calculationDomain: CalculationDomain.real,
    unitMode: UnitMode.disabled,
    themePreference: CalculatorThemePreference.system,
    resultFormat: NumberFormatStyle.auto,
  );

  final AngleMode angleMode;
  final int precision;
  final NumericMode numericMode;
  final CalculationDomain calculationDomain;
  final UnitMode unitMode;
  final CalculatorThemePreference themePreference;
  final NumberFormatStyle resultFormat;
  final bool reduceMotion;
  final bool highContrast;
  final CalculatorAppLanguage language;
  final bool onboardingCompleted;
  final DateTime? updatedAt;

  NumberFormatStyle get defaultResultFormat => resultFormat;

  CalculatorSettings copyWith({
    AngleMode? angleMode,
    int? precision,
    NumericMode? numericMode,
    CalculationDomain? calculationDomain,
    UnitMode? unitMode,
    CalculatorThemePreference? themePreference,
    NumberFormatStyle? resultFormat,
    bool? reduceMotion,
    bool? highContrast,
    CalculatorAppLanguage? language,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return CalculatorSettings(
      angleMode: angleMode ?? this.angleMode,
      precision: precision ?? this.precision,
      numericMode: numericMode ?? this.numericMode,
      calculationDomain: calculationDomain ?? this.calculationDomain,
      unitMode: unitMode ?? this.unitMode,
      themePreference: themePreference ?? this.themePreference,
      resultFormat: resultFormat ?? this.resultFormat,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      language: language ?? this.language,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'angleMode': angleMode.name,
      'precision': precision,
      'numericMode': numericMode.name,
      'calculationDomain': calculationDomain.name,
      'unitMode': unitMode.name,
      'themePreference': themePreference.name,
      'resultFormat': resultFormat.name,
      'reduceMotion': reduceMotion,
      'highContrast': highContrast,
      'language': language.name,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  String toStoredString() => jsonEncode(toJson());

  factory CalculatorSettings.fromJson(Map<String, dynamic> json) {
    return CalculatorSettings(
      angleMode: _parseAngleMode(json['angleMode']) ?? defaults.angleMode,
      precision: _parsePrecision(json['precision']) ?? defaults.precision,
      numericMode:
          _parseNumericMode(json['numericMode']) ?? defaults.numericMode,
      calculationDomain:
          _parseCalculationDomain(json['calculationDomain']) ??
          defaults.calculationDomain,
      unitMode: _parseUnitMode(json['unitMode']) ?? defaults.unitMode,
      themePreference:
          _parseThemePreference(json['themePreference']) ??
          defaults.themePreference,
      resultFormat:
          _parseNumberFormat(
            json['resultFormat'] ?? json['defaultResultFormat'],
          ) ??
          defaults.resultFormat,
      reduceMotion: _parseBool(json['reduceMotion']) ?? defaults.reduceMotion,
      highContrast: _parseBool(json['highContrast']) ?? defaults.highContrast,
      language: _parseLanguage(json['language']) ?? defaults.language,
      onboardingCompleted:
          _parseBool(json['onboardingCompleted']) ??
          defaults.onboardingCompleted,
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static CalculatorSettings fromStoredString(String? source) {
    if (source == null || source.trim().isEmpty) {
      return defaults;
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return defaults;
      }
      return CalculatorSettings.fromJson(decoded);
    } catch (_) {
      return defaults;
    }
  }

  static AngleMode? _parseAngleMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return AngleMode.values.cast<AngleMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static CalculatorThemePreference? _parseThemePreference(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return CalculatorThemePreference.values
        .cast<CalculatorThemePreference?>()
        .firstWhere((value) => value?.name == raw, orElse: () => null);
  }

  static NumberFormatStyle? _parseNumberFormat(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return NumberFormatStyle.values.cast<NumberFormatStyle?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static NumericMode? _parseNumericMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return NumericMode.values.cast<NumericMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static CalculationDomain? _parseCalculationDomain(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return CalculationDomain.values.cast<CalculationDomain?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static UnitMode? _parseUnitMode(Object? raw) {
    if (raw is! String) {
      return null;
    }

    return UnitMode.values.cast<UnitMode?>().firstWhere(
      (value) => value?.name == raw,
      orElse: () => null,
    );
  }

  static int? _parsePrecision(Object? raw) {
    if (raw is int && raw > 0) {
      return raw;
    }

    if (raw is num && raw > 0) {
      return raw.toInt();
    }

    return null;
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw)?.toUtc();
  }

  static bool? _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      return switch (raw.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    }
    return null;
  }

  static CalculatorAppLanguage? _parseLanguage(Object? raw) {
    if (raw is! String) {
      return null;
    }
    return CalculatorAppLanguage.values
        .cast<CalculatorAppLanguage?>()
        .firstWhere((value) => value?.name == raw, orElse: () => null);
  }
}

/// App theme preference stored independently from Flutter theme enums.
enum CalculatorThemePreference { system, light, dark }

enum CalculatorAppLanguage {
  en(Locale('en')),
  tr(Locale('tr'));

  const CalculatorAppLanguage(this.locale);

  final Locale locale;
}
