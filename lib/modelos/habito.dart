import 'dart:convert';
import 'package:flutter/material.dart';

/// Representa um hábito diário ou recorrente (inspirado no Habit Now, 100% offline).
class Habito {
  const Habito({
    this.id,
    required this.titulo,
    this.descricao = '',
    this.categoria = 'Geral',
    this.iconeCodePoint = 0xe28c, // Icons.fitness_center_rounded
    this.corValor = 0xFF6C5CE7,
    this.diasSemana = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.metaValor = 1,
    this.metaUnidade = 'vez',
    this.ordem = 0,
    this.ativo = true,
    required this.dataCriacaoISO,
    this.concluidoHoje = false,
    this.progressoHoje = 0,
    this.ofensivaAtual = 0,
    this.totalConclusoes = 0,
  });

  final int? id;
  final String titulo;
  final String descricao;
  final String categoria;
  final int iconeCodePoint;
  final int corValor;
  final List<int> diasSemana;
  final int metaValor;
  final String metaUnidade;
  final int ordem;
  final bool ativo;
  final String dataCriacaoISO;
  final bool concluidoHoje;
  final int progressoHoje;
  final int ofensivaAtual;
  final int totalConclusoes;

  IconData get icone => CatalogoIconesHabito.obterIcone(iconeCodePoint);
  Color get cor => Color(corValor);

  double get percentualHoje => metaValor <= 0
      ? (concluidoHoje ? 1.0 : 0.0)
      : (progressoHoje / metaValor).clamp(0.0, 1.0);

  int get passoIncremento {
    final u = metaUnidade.toLowerCase().trim();
    if (u == 'ml') return 250;
    if (u == 'minutos' && metaValor >= 15) return 5;
    return 1;
  }

  bool seAplicaAoDia(int diaSemana) => diasSemana.contains(diaSemana);

  Habito copiarCom({
    int? id,
    String? titulo,
    String? descricao,
    String? categoria,
    int? iconeCodePoint,
    int? corValor,
    List<int>? diasSemana,
    int? metaValor,
    String? metaUnidade,
    int? ordem,
    bool? ativo,
    String? dataCriacaoISO,
    bool? concluidoHoje,
    int? progressoHoje,
    int? ofensivaAtual,
    int? totalConclusoes,
  }) {
    return Habito(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      iconeCodePoint: iconeCodePoint ?? this.iconeCodePoint,
      corValor: corValor ?? this.corValor,
      diasSemana: diasSemana ?? this.diasSemana,
      metaValor: metaValor ?? this.metaValor,
      metaUnidade: metaUnidade ?? this.metaUnidade,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      dataCriacaoISO: dataCriacaoISO ?? this.dataCriacaoISO,
      concluidoHoje: concluidoHoje ?? this.concluidoHoje,
      progressoHoje: progressoHoje ?? this.progressoHoje,
      ofensivaAtual: ofensivaAtual ?? this.ofensivaAtual,
      totalConclusoes: totalConclusoes ?? this.totalConclusoes,
    );
  }

  factory Habito.deMapa(Map<String, Object?> map) {
    List<int> parsedDias;
    try {
      final rawDias = map['diasSemana'];
      if (rawDias is String) {
        parsedDias = (jsonDecode(rawDias) as List)
            .map((e) => (e as num).toInt())
            .toList();
      } else if (rawDias is List) {
        parsedDias = rawDias.map((e) => (e as num).toInt()).toList();
      } else {
        parsedDias = const <int>[1, 2, 3, 4, 5, 6, 7];
      }
    } catch (_) {
      parsedDias = const <int>[1, 2, 3, 4, 5, 6, 7];
    }

    return Habito(
      id: (map['id'] as num?)?.toInt(),
      titulo: (map['titulo'] as String?) ?? '',
      descricao: (map['descricao'] as String?) ?? '',
      categoria: (map['categoria'] as String?) ?? 'Geral',
      iconeCodePoint: (map['iconeCodePoint'] as num?)?.toInt() ?? 0xe28c,
      corValor: (map['corValor'] as num?)?.toInt() ?? 0xFF6C5CE7,
      diasSemana: parsedDias,
      metaValor: (map['metaValor'] as num?)?.toInt() ?? 1,
      metaUnidade: (map['metaUnidade'] as String?) ?? 'vez',
      ordem: (map['ordem'] as num?)?.toInt() ?? 0,
      ativo: ((map['ativo'] as num?)?.toInt() ?? 1) == 1,
      dataCriacaoISO: (map['dataCriacaoISO'] as String?) ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, Object?> paraMapa({bool incluirId = true}) => <String, Object?>{
        if (incluirId && id != null) 'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria,
        'iconeCodePoint': iconeCodePoint,
        'corValor': corValor,
        'diasSemana': jsonEncode(diasSemana),
        'metaValor': metaValor,
        'metaUnidade': metaUnidade,
        'ordem': ordem,
        'ativo': ativo ? 1 : 0,
        'dataCriacaoISO': dataCriacaoISO,
      };
}

/// Registro de conclusão diária de um hábito.
class ConclusaoHabito {
  const ConclusaoHabito({
    this.id,
    required this.idHabito,
    required this.dataISO,
    this.valor = 1.0,
  });

  final int? id;
  final int idHabito;
  final String dataISO;
  final double valor;

  factory ConclusaoHabito.deMapa(Map<String, Object?> map) => ConclusaoHabito(
        id: (map['id'] as num?)?.toInt(),
        idHabito: (map['idHabito'] as num).toInt(),
        dataISO: (map['dataISO'] as String?) ?? '',
        valor: (map['valor'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, Object?> paraMapa({bool incluirId = true}) => <String, Object?>{
        if (incluirId && id != null) 'id': id,
        'idHabito': idHabito,
        'dataISO': dataISO,
        'valor': valor,
      };
}

/// Tarefa to-do offline com prioridade e data limite opcional.
class TarefaToDo {
  const TarefaToDo({
    this.id,
    required this.titulo,
    this.dataLimiteISO,
    this.concluida = false,
    this.prioridade = 'media',
    this.categoria = 'Geral',
    this.ordem = 0,
    required this.dataCriacaoISO,
  });

  final int? id;
  final String titulo;
  final String? dataLimiteISO;
  final bool concluida;
  final String prioridade; // 'alta', 'media', 'baixa'
  final String categoria;
  final int ordem;
  final String dataCriacaoISO;

  Color get corPrioridade {
    switch (prioridade.toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF5252);
      case 'baixa':
        return const Color(0xFF4CAF50);
      case 'media':
      default:
        return const Color(0xFFFF9800);
    }
  }

  String get labelPrioridade {
    switch (prioridade.toLowerCase()) {
      case 'alta':
        return 'Alta';
      case 'baixa':
        return 'Baixa';
      case 'media':
      default:
        return 'Média';
    }
  }

  TarefaToDo copiarCom({
    int? id,
    String? titulo,
    String? dataLimiteISO,
    bool limparDataLimite = false,
    bool? concluida,
    String? prioridade,
    String? categoria,
    int? ordem,
    String? dataCriacaoISO,
  }) {
    return TarefaToDo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      dataLimiteISO:
          limparDataLimite ? null : (dataLimiteISO ?? this.dataLimiteISO),
      concluida: concluida ?? this.concluida,
      prioridade: prioridade ?? this.prioridade,
      categoria: categoria ?? this.categoria,
      ordem: ordem ?? this.ordem,
      dataCriacaoISO: dataCriacaoISO ?? this.dataCriacaoISO,
    );
  }

  factory TarefaToDo.deMapa(Map<String, Object?> map) => TarefaToDo(
        id: (map['id'] as num?)?.toInt(),
        titulo: (map['titulo'] as String?) ?? '',
        dataLimiteISO: map['dataLimiteISO'] as String?,
        concluida: ((map['concluida'] as num?)?.toInt() ?? 0) == 1,
        prioridade: (map['prioridade'] as String?) ?? 'media',
        categoria: (map['categoria'] as String?) ?? 'Geral',
        ordem: (map['ordem'] as num?)?.toInt() ?? 0,
        dataCriacaoISO: (map['dataCriacaoISO'] as String?) ??
            DateTime.now().toIso8601String(),
      );

  Map<String, Object?> paraMapa({bool incluirId = true}) => <String, Object?>{
        if (incluirId && id != null) 'id': id,
        'titulo': titulo,
        'dataLimiteISO': dataLimiteISO,
        'concluida': concluida ? 1 : 0,
        'prioridade': prioridade,
        'categoria': categoria,
        'ordem': ordem,
        'dataCriacaoISO': dataCriacaoISO,
      };
}

/// Figurinha ou emoji arrastável no diário com coordenadas relativas (0.0 a 1.0).
class FigurinhaDiario {
  const FigurinhaDiario({
    required this.id,
    required this.emoji,
    required this.x,
    required this.y,
    this.tamanho = 32.0,
  });

  final String id;
  final String emoji;
  final double x; // Fração horizontal (0.0 até 1.0)
  final double y; // Fração vertical (0.0 até 1.0)
  final double tamanho;

  FigurinhaDiario copiarCom({
    String? id,
    String? emoji,
    double? x,
    double? y,
    double? tamanho,
  }) {
    return FigurinhaDiario(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      x: x ?? this.x,
      y: y ?? this.y,
      tamanho: tamanho ?? this.tamanho,
    );
  }

  factory FigurinhaDiario.deMapa(Map<String, Object?> map) => FigurinhaDiario(
        id: (map['id'] ?? '').toString(),
        emoji: (map['emoji'] ?? '🔥').toString(),
        x: ((map['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        y: ((map['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        tamanho:
            ((map['tamanho'] as num?)?.toDouble() ?? 32.0).clamp(16.0, 80.0),
      );

  Map<String, Object?> paraMapa() => <String, Object?>{
        'id': id,
        'emoji': emoji,
        'x': x,
        'y': y,
        'tamanho': tamanho,
      };
}

/// Catálogo de ícones disponíveis para hábitos (com Icons constantes para evitar lints).
class CatalogoIconesHabito {
  const CatalogoIconesHabito._();

  static const List<IconData> iconesDisponiveis = <IconData>[
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.directions_walk_rounded,
    Icons.sports_gymnastics_rounded,
    Icons.pedal_bike_rounded,
    Icons.pool_rounded,
    Icons.sports_martial_arts_rounded,
    Icons.sports_soccer_rounded,
    Icons.sports_tennis_rounded,
    Icons.water_drop_rounded,
    Icons.local_drink_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.apple_rounded,
    Icons.medication_rounded,
    Icons.bedtime_rounded,
    Icons.nightlight_round,
    Icons.wb_sunny_rounded,
    Icons.self_improvement_rounded,
    Icons.spa_rounded,
    Icons.menu_book_rounded,
    Icons.edit_note_rounded,
    Icons.psychology_rounded,
    Icons.school_rounded,
    Icons.language_rounded,
    Icons.code_rounded,
    Icons.laptop_rounded,
    Icons.alarm_rounded,
    Icons.timer_rounded,
    Icons.check_circle_rounded,
    Icons.star_rounded,
    Icons.bolt_rounded,
    Icons.local_fire_department_rounded,
    Icons.emoji_events_rounded,
    Icons.favorite_rounded,
    Icons.sentiment_satisfied_alt_rounded,
    Icons.music_note_rounded,
    Icons.headphones_rounded,
    Icons.brush_rounded,
    Icons.cleaning_services_rounded,
    Icons.savings_rounded,
    Icons.eco_rounded,
    Icons.smoke_free_rounded,
    Icons.no_drinks_rounded,
    Icons.shield_rounded,
    Icons.lightbulb_rounded,
  ];

  static IconData obterIcone(int codePoint) {
    for (final icon in iconesDisponiveis) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.fitness_center_rounded;
  }
}

/// Paleta de cores vibrantes e elegantes para categorizar hábitos.
class PaletaCoresHabito {
  const PaletaCoresHabito._();

  static const List<Color> cores = <Color>[
    Color(0xFF6C5CE7), // Roxo Primário
    Color(0xFF7C4DFF), // Violeta
    Color(0xFF3F51B5), // Índigo
    Color(0xFF00BFA5), // Turquesa
    Color(0xFF00C853), // Verde Esmeralda
    Color(0xFFFFB300), // Âmbar Dourado
    Color(0xFFFF6D00), // Laranja Intenso
    Color(0xFFFF1744), // Carmim / Vermelho
    Color(0xFF00B0FF), // Azul Claro
    Color(0xFFE91E63), // Rosa Choque
    Color(0xFF795548), // Marrom
    Color(0xFF607D8B), // Ardósia
  ];

  static const List<String> categoriasPadrao = <String>[
    'Treino & Físico',
    'Saúde & Corpo',
    'Hidratação',
    'Nutrição',
    'Mente & Foco',
    'Sono & Descanso',
    'Produtividade',
    'Desenvolvimento',
  ];
}
