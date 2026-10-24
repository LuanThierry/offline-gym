import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstiloDoTema {
  const EstiloDoTema({
    required this.id,
    required this.nome,
    required this.primaria,
    required this.secundaria,
    required this.icone,
  });

  final String id;
  final String nome;
  final Color primaria;
  final Color secundaria;
  final IconData icone;
}

class ProvedorDeTema extends ChangeNotifier {
  static const String _preferenceKey = 'theme_mode';
  static const String _preferenceStyleKey = 'theme_accent_style';
  static const String _preferenceAmoledKey = 'theme_amoled_enabled';
  static const String _preferenceCustomColorKey = 'theme_custom_color_argb';

  static const List<EstiloDoTema> estilosDisponiveis = <EstiloDoTema>[
    EstiloDoTema(
      id: 'roxo',
      nome: 'Roxo Cyber',
      primaria: Color(0xFF7C4DFF),
      secundaria: Color(0xFFB388FF),
      icone: Icons.fitness_center,
    ),
    EstiloDoTema(
      id: 'esmeralda',
      nome: 'Foco Bestial (Verde Neon)',
      primaria: Color(0xFF00E676),
      secundaria: Color(0xFF69F0AE),
      icone: Icons.bolt,
    ),
    EstiloDoTema(
      id: 'ferro',
      nome: 'Sangue & Ferro (Vermelho Neon)',
      primaria: Color(0xFFFF1744),
      secundaria: Color(0xFFFF5252),
      icone: Icons.local_fire_department,
    ),
    EstiloDoTema(
      id: 'ouro',
      nome: 'Ouro Campeão (Dourado Neon)',
      primaria: Color(0xFFFFB300),
      secundaria: Color(0xFFFFD54F),
      icone: Icons.emoji_events,
    ),
    EstiloDoTema(
      id: 'ciano',
      nome: 'Cyber Neon (Ciano)',
      primaria: Color(0xFF00E5FF),
      secundaria: Color(0xFF18FFFF),
      icone: Icons.speed,
    ),
    EstiloDoTema(
      id: 'laranja',
      nome: 'Laranja Hipertrófico',
      primaria: Color(0xFFFF6D00),
      secundaria: Color(0xFFFF9E80),
      icone: Icons.whatshot,
    ),
    EstiloDoTema(
      id: 'magenta',
      nome: 'Synthwave Magenta',
      primaria: Color(0xFFFF007F),
      secundaria: Color(0xFFFF4081),
      icone: Icons.auto_awesome,
    ),
    EstiloDoTema(
      id: 'turquesa',
      nome: 'Aqua Neon',
      primaria: Color(0xFF00BFA5),
      secundaria: Color(0xFF64FFDA),
      icone: Icons.waves,
    ),
    EstiloDoTema(
      id: 'amarelo',
      nome: 'Acid Volt',
      primaria: Color(0xFFCCFF00),
      secundaria: Color(0xFFEEFF41),
      icone: Icons.flash_on,
    ),
    EstiloDoTema(
      id: 'azul',
      nome: 'Azul Elétrico',
      primaria: Color(0xFF2979FF),
      secundaria: Color(0xFF82B1FF),
      icone: Icons.cyclone,
    ),
    EstiloDoTema(
      id: 'obsidiana',
      nome: 'Obsidiana Stealth',
      primaria: Color(0xFF546E7A),
      secundaria: Color(0xFF90A4AE),
      icone: Icons.shield,
    ),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  String _estiloId = 'roxo';
  int? _corCustomizadaARGB;
  bool _modoAmoled = false;
  SharedPreferences? _preferences;

  ThemeMode get modoDoTema => _themeMode;
  String get estiloId => _estiloId;
  int? get corCustomizadaARGB => _corCustomizadaARGB;
  bool get modoAmoled => _modoAmoled;
  bool get isCustomizado => _estiloId == 'customizado';

  EstiloDoTema get estiloAtual {
    if (_estiloId == 'customizado' && _corCustomizadaARGB != null) {
      final cor = Color(_corCustomizadaARGB!);
      return EstiloDoTema(
        id: 'customizado',
        nome: 'Personalizado',
        primaria: cor,
        secundaria: cor.withValues(alpha: 0.8),
        icone: Icons.colorize_rounded,
      );
    }
    return estilosDisponiveis.firstWhere(
      (e) => e.id == _estiloId,
      orElse: () => estilosDisponiveis.first,
    );
  }

  /// Retorna a cor complementar invertida (Hue + 180 graus) no espaço HSL
  /// calibrada com saturação e brilho neon para máxima legibilidade e destaque.
  Color get corInvertidaDestaque {
    final primaria = estiloAtual.primaria;
    final hsl = HSLColor.fromColor(primaria);
    final novaHue = (hsl.hue + 180.0) % 360.0;
    final novaSaturacao = (hsl.saturation * 1.15).clamp(0.85, 1.0);
    final novaLuminosidade = hsl.lightness.clamp(0.50, 0.65);
    return HSLColor.fromAHSL(1.0, novaHue, novaSaturacao, novaLuminosidade)
        .toColor();
  }

  /// Gradiente dual-tone exclusivo entre a cor primária do tema e a cor invertida de destaque
  LinearGradient get gradienteDualToneDestaque {
    return LinearGradient(
      colors: [estiloAtual.primaria, corInvertidaDestaque],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Cores de status fisiológico neon vibrantes
  Color get corSucessoNeon => const Color(0xFF00E676);
  Color get corAlertaNeon => const Color(0xFFFFAB00);
  Color get corPerigoNeon => const Color(0xFFFF1744);

  Future<void> carregarTema() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;

    final savedTheme = preferences.getString(_preferenceKey);
    final savedStyle = preferences.getString(_preferenceStyleKey);
    _modoAmoled = preferences.getBool(_preferenceAmoledKey) ?? false;
    _corCustomizadaARGB = preferences.getInt(_preferenceCustomColorKey);

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    if (savedStyle == 'customizado' && _corCustomizadaARGB != null) {
      _estiloId = 'customizado';
    } else if (savedStyle != null &&
        estilosDisponiveis.any((e) => e.id == savedStyle)) {
      _estiloId = savedStyle;
    }

    notifyListeners();
  }

  Future<void> definirModoAmoled(bool enabled) async {
    if (_modoAmoled == enabled) return;
    _modoAmoled = enabled;
    notifyListeners();

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setBool(_preferenceAmoledKey, enabled);
  }

  Future<void> definirModoDoTema(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await preferences.setString(_preferenceKey, value);
  }

  Future<void> definirEstiloDoTema(String styleId) async {
    if (!estilosDisponiveis.any((e) => e.id == styleId)) return;
    if (_estiloId == styleId) return;
    _estiloId = styleId;
    notifyListeners();

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setString(_preferenceStyleKey, styleId);
  }

  Future<void> definirCorCustomizada(Color cor) async {
    final argb = cor.toARGB32();
    _estiloId = 'customizado';
    _corCustomizadaARGB = argb;
    notifyListeners();

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setString(_preferenceStyleKey, 'customizado');
    await preferences.setInt(_preferenceCustomColorKey, argb);
  }
}
