import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/calculator/calculator.dart';
import 'features/calculator/application/calculator_controller.dart';
import 'features/calculator/data/calculator_settings.dart';
import 'features/calculator/data/local_calculator_storage.dart';
import 'features/calculator/presentation/app_localizations.dart';
import 'features/calculator/presentation/calculator_screen.dart';
import 'features/calculator/presentation/design/app_theme.dart';
import 'features/calculator/worksheet/local_worksheet_storage.dart';
import 'features/calculator/worksheet/worksheet_controller.dart';

void main() {
  runApp(const ScientificCalculatorApp());
}

class ScientificCalculatorApp extends StatefulWidget {
  const ScientificCalculatorApp({
    super.key,
    this.controller,
    this.worksheetController,
  });

  final CalculatorController? controller;
  final WorksheetController? worksheetController;

  @override
  State<ScientificCalculatorApp> createState() =>
      _ScientificCalculatorAppState();
}

class _ScientificCalculatorAppState extends State<ScientificCalculatorApp> {
  late final CalculatorController _controller;
  late final WorksheetController _worksheetController;
  late final bool _ownsController;
  late final bool _ownsWorksheetController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsWorksheetController = widget.worksheetController == null;
    _controller =
        widget.controller ??
        CalculatorController(
          storage: LocalCalculatorStorage(),
          engine: const CalculatorEngine(),
        );
    _worksheetController =
        widget.worksheetController ??
        WorksheetController(storage: LocalWorksheetStorage());
    unawaited(_controller.initialize());
    unawaited(_worksheetController.initialize());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsWorksheetController) {
      _worksheetController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final themePreference = _controller.state.settings.themePreference;
        final settings = _controller.state.settings;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: settings.language == CalculatorAppLanguage.tr
              ? 'Bilimsel Hesap Makinesi'
              : 'Scientific Calculator',
          locale: settings.language.locale,
          supportedLocales: CalculatorAppLanguage.values
              .map((language) => language.locale)
              .toList(growable: false),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          themeMode: _themeModeFor(themePreference),
          theme: AppTheme.build(
            Brightness.light,
            highContrast: settings.highContrast,
          ),
          darkTheme: AppTheme.build(
            Brightness.dark,
            highContrast: settings.highContrast,
          ),
          home: CalculatorLocalization(
            language: settings.language,
            child: CalculatorScreen(
              controller: _controller,
              worksheetController: _worksheetController,
            ),
          ),
        );
      },
    );
  }

  ThemeMode _themeModeFor(CalculatorThemePreference preference) {
    return switch (preference) {
      CalculatorThemePreference.system => ThemeMode.system,
      CalculatorThemePreference.light => ThemeMode.light,
      CalculatorThemePreference.dark => ThemeMode.dark,
    };
  }
}
