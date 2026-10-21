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

  static const List<EstiloDoTema> estilosDisponiveis = <EstiloDoTema>[
    EstiloDoTema(
      id: 'roxo',
      nome: 'Roxo Clássico',
      primaria: Color(0xFF6C5CE7),
      secundaria: Color(0xFF8C7AE6),
      icone: Icons.fitness_center,
    ),
    EstiloDoTema(
      id: 'esmeralda',
      nome: 'Foco Bestial',
      primaria: Color(0xFF00B894),
      secundaria: Color(0xFF00E676),
      icone: Icons.bolt,
    ),
    EstiloDoTema(
      id: 'ferro',
      nome: 'Sangue & Ferro',
      primaria: Color(0xFFD63031),
      secundaria: Color(0xFFFF7675),
      icone: Icons.local_fire_department,
    ),
    EstiloDoTema(
      id: 'ouro',
      nome: 'Ouro Campeão',
      primaria: Color(0xFFE67E22),
      secundaria: Color(0xFFF1C40F),
      icone: Icons.emoji_events,
    ),
    EstiloDoTema(
      id: 'ciano',
      nome: 'Cyber Neon',
      primaria: Color(0xFF0984E3),
      secundaria: Color(0xFF00CEC9),
      icone: Icons.speed,
    ),
    EstiloDoTema(
      id: 'obsidiana',
      nome: 'Obsidiana Stealth',
      primaria: Color(0xFF2D3436),
      secundaria: Color(0xFF636E72),
      icone: Icons.shield,
    ),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  String _estiloId = 'roxo';
  bool _modoAmoled = false;
  SharedPreferences? _preferences;

  ThemeMode get modoDoTema => _themeMode;
  String get estiloId => _estiloId;
  bool get modoAmoled => _modoAmoled;

  EstiloDoTema get estiloAtual => estilosDisponiveis.firstWhere(
        (e) => e.id == _estiloId,
        orElse: () => estilosDisponiveis.first,
      );

  Future<void> carregarTema() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;

    final savedTheme = preferences.getString(_preferenceKey);
    final savedStyle = preferences.getString(_preferenceStyleKey);
    _modoAmoled = preferences.getBool(_preferenceAmoledKey) ?? false;

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

    if (savedStyle != null &&
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
}
