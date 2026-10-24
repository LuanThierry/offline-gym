import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'banco_dados/banco_de_dados.dart';
import 'provedores/estado_treino.dart';
import 'telas/estrutura_aplicativo.dart';

import 'provedores/estado_tema.dart';

import 'servicos/som_do_alarme.dart';

const Color kAppPrimary = Color(0xFF6C5CE7);
const Color kAppSecondary = Color(0xFF8C7AE6);

// Tema Claro refinado: não é tão claro/pálido, fundo suave lilás-ardósia e cartões com contraste
const Color kAppLightBackground = Color(0xFFE8E6F2);
const Color kAppLightSurface = Color(0xFFFFFFFF);
const Color kAppLightSurfaceVariant = Color(0xFFF3F1FA);
const Color kAppLightBorder = Color(0xFFD6D1EB);
const Color kAppLightText = Color(0xFF1E1834);
const Color kAppLightMuted = Color(0xFF5E5978);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  final workoutProvider = ProvedorDeTreino(BancoDeDados.instance);
  final provedorDoTema = ProvedorDeTema();
  await Future.wait(<Future<void>>[
    workoutProvider.inicializar(),
    provedorDoTema.carregarTema(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProvedorDeTreino>.value(value: workoutProvider),
        ChangeNotifierProvider<ProvedorDeTema>.value(value: provedorDoTema),
      ],
      child: const AplicativoOfflineGym(),
    ),
  );
}

class AplicativoOfflineGym extends StatefulWidget {
  const AplicativoOfflineGym({super.key});

  @override
  State<AplicativoOfflineGym> createState() => _EstadoDoAplicativoOfflineGym();
}

class _EstadoDoAplicativoOfflineGym extends State<AplicativoOfflineGym>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ServicoDeSomDoAlarme.instance.pararAudio();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ServicoDeSomDoAlarme.instance.pararAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provedorDoTema = context.watch<ProvedorDeTema>();
    final themeMode = provedorDoTema.modoDoTema;
    final primary = provedorDoTema.estiloAtual.primaria;
    final secondary = provedorDoTema.estiloAtual.secundaria;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: kAppLightSurface,
      surfaceContainerHighest: kAppLightSurfaceVariant,
      onSurface: kAppLightText,
      onSurfaceVariant: kAppLightMuted,
      outline: kAppLightBorder,
      outlineVariant: kAppLightBorder,
      primaryContainer: primary.withValues(alpha: 0.15),
      onPrimaryContainer: primary,
    );

    final modoAmoled = provedorDoTema.modoAmoled;
    final darkBackground =
        modoAmoled ? const Color(0xFF000000) : const Color(0xFF121218);
    final darkSurface =
        modoAmoled ? const Color(0xFF0A0A0C) : const Color(0xFF1E1E2A);
    final darkCardColor =
        modoAmoled ? const Color(0xFF0D0D10) : const Color(0xFF1E1E2A);
    final darkBorder =
        modoAmoled ? const Color(0xFF1E1E28) : const Color(0xFF353545);
    final darkInputFill =
        modoAmoled ? const Color(0xFF0E0E12) : const Color(0xFF252532);

    return MaterialApp(
      title: 'Offline Gym',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kAppLightBackground,
        primaryColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppLightBackground,
          foregroundColor: kAppLightText,
          toolbarHeight: 64,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: kAppLightText,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
          iconTheme: IconThemeData(size: 22, color: kAppLightText),
        ),
        cardTheme: CardThemeData(
          color: kAppLightSurface,
          elevation: 1.5,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shadowColor: primary.withValues(alpha: 0.08),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: kAppLightBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: kAppLightBorder,
          thickness: 1,
          space: 1,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kAppLightSurface,
          indicatorColor: primary.withValues(alpha: 0.14),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primary);
            }
            return const IconThemeData(color: kAppLightMuted);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: kAppLightMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: kAppLightSurface,
          modalBackgroundColor: kAppLightSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: kAppLightSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: kAppLightBorder),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: kAppLightText,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          titleLarge:
              TextStyle(color: kAppLightText, fontWeight: FontWeight.w700),
          titleMedium:
              TextStyle(color: kAppLightText, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: kAppLightText),
          bodyMedium: TextStyle(color: kAppLightText),
          bodySmall: TextStyle(color: kAppLightMuted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kAppLightSurfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAppLightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAppLightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.6),
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
            side: const BorderSide(color: kAppLightBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          surface: darkSurface,
          surfaceContainerHighest: darkInputFill,
          onSurface: const Color(0xFFF1F1F5),
          onSurfaceVariant: const Color(0xFFA0A0B2),
          outline: darkBorder,
          outlineVariant: darkBorder,
          primaryContainer: primary.withValues(alpha: 0.22),
          onPrimaryContainer: Colors.white,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: darkBackground,
          foregroundColor: const Color(0xFFF1F1F5),
          toolbarHeight: 64,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            color: Color(0xFFF1F1F5),
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
          iconTheme: const IconThemeData(size: 22),
        ),
        cardTheme: CardThemeData(
          color: darkCardColor,
          elevation: modoAmoled ? 0 : 1,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: darkBorder),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: darkBorder,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkInputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 2,
            shadowColor: primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          focusElevation: 6,
          hoverElevation: 6,
          highlightElevation: 8,
          splashColor: Colors.white24,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkBackground,
          indicatorColor: primary.withValues(alpha: 0.20),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primary);
            }
            return const IconThemeData(color: Color(0xFFA0A0B2));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: Color(0xFFA0A0B2),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: darkSurface,
          modalBackgroundColor: darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: darkBorder),
          ),
        ),
      ),
      themeMode: themeMode,
      home: const _AberturaAnimada(child: EstruturaDoAplicativo()),
    );
  }
}

class _AberturaAnimada extends StatefulWidget {
  const _AberturaAnimada({required this.child});

  final Widget child;

  @override
  State<_AberturaAnimada> createState() => _EstadoDaAberturaAnimada();
}

class _EstadoDaAberturaAnimada extends State<_AberturaAnimada> {
  Timer? _timer;
  bool _showSplash = true;
  bool _splashVisible = true;
  bool _timerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timerStarted) return;
    _timerStarted = true;
    final reduzirAnimacoes = MediaQuery.of(context).disableAnimations;
    _timer = Timer(
      reduzirAnimacoes ? Duration.zero : const Duration(milliseconds: 700),
      () {
        if (!mounted) return;
        setState(() => _showSplash = false);
        Timer(
          reduzirAnimacoes ? Duration.zero : const Duration(milliseconds: 260),
          () {
            if (mounted) setState(() => _splashVisible = false);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzirAnimacoes = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_splashVisible)
          IgnorePointer(
            ignoring: !_showSplash,
            child: AnimatedOpacity(
              duration: reduzirAnimacoes
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              opacity: _showSplash ? 1.0 : 0.0,
              child: const _TelaInicialDoAplicativo(
                key: ValueKey<String>('app-launch-splash'),
              ),
            ),
          ),
      ],
    );
  }
}

class _TelaInicialDoAplicativo extends StatelessWidget {
  const _TelaInicialDoAplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    final provedor = Provider.of<ProvedorDeTema>(context, listen: false);
    final primary = provedor.estiloAtual.primaria;
    final secondary = provedor.estiloAtual.secundaria;
    final amoled = provedor.modoAmoled;
    final darkTarget =
        amoled ? const Color(0xFF000000) : const Color(0xFF101018);
    final reduzirAnimacoes = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration:
          reduzirAnimacoes ? Duration.zero : const Duration(milliseconds: 680),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, _) {
        final background = Color.lerp(
          primary,
          darkTarget,
          progress,
        )!;
        return Scaffold(
          key: const ValueKey<String>('launch-splash-scaffold'),
          backgroundColor: background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: reduzirAnimacoes ? 1 : 0.86 + (0.14 * progress),
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withValues(
                              alpha: 0.32 * (1 - progress)),
                          blurRadius: 42,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: progress,
                  child: const Text(
                    'OFFLINE GYM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
