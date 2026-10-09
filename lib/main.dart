import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/workout_provider.dart';
import 'screens/app_shell.dart';

const Color kAppBackground = Color(0xFFF8F9FA);
const Color kAppPrimary = Color(0xFF6C5CE7);
const Color kAppSecondary = Color(0xFF8C7AE6);
const Color kAppText = Color(0xFF2D3436);
const Color kAppMuted = Color(0xFF636E72);
const Color kAppBorder = Color(0xFFE6E7EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  final workoutProvider = WorkoutProvider(DatabaseHelper.instance);
  await workoutProvider.initialize();
  runApp(
    ChangeNotifierProvider<WorkoutProvider>.value(
      value: workoutProvider,
      child: const OfflineGymApp(),
    ),
  );
}

class OfflineGymApp extends StatelessWidget {
  const OfflineGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = kAppPrimary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: kAppSecondary,
      surface: Colors.white,
      onSurface: kAppText,
    );

    return MaterialApp(
      title: 'Offline Gym',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kAppBackground,
        primaryColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppBackground,
          foregroundColor: kAppText,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: kAppBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: kAppBorder,
          thickness: 1,
          space: 1,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: kAppText,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: kAppText,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: kAppText,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: kAppText),
          bodyMedium: TextStyle(color: kAppText),
          bodySmall: TextStyle(color: kAppMuted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAppBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAppBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(0, 46),
            side: const BorderSide(color: kAppBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AppShell(),
    );
  }
}
