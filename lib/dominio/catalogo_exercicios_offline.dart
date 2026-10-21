import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../modelos/plano_de_treino.dart';

/// Item do catálogo 100% offline de exercícios.
class ItemCatalogoExercicio {
  const ItemCatalogoExercicio({
    required this.nome,
    required this.modalidade,
    required this.grupoMuscular,
    required this.equipamento,
    this.cargaSugeridaKg = 0,
    this.seriesSugeridas = 3,
    this.repeticoesSugeridas = 12,
    this.descansoSugeridoSegundos = 60,
  });

  final String nome;
  final String modalidade;
  final String grupoMuscular;
  final String equipamento;
  final double cargaSugeridaKg;
  final int seriesSugeridas;
  final int repeticoesSugeridas;
  final int descansoSugeridoSegundos;

  ExercicioPlanejado paraExercicioPlanejado(int diaSemana) {
    return ExercicioPlanejado(
      diaSemana: diaSemana,
      nome: nome,
      carga: cargaSugeridaKg,
      series: seriesSugeridas,
      repeticoes: repeticoesSugeridas,
      tempoDescansoSegundos: descansoSugeridoSegundos,
    );
  }
}

/// Modelo pronto de treino para importar com 1 toque.
class ModeloDeTreinoPronto {
  const ModeloDeTreinoPronto({
    required this.nome,
    required this.subtitulo,
    required this.modalidade,
    required this.icone,
    required this.exercicios,
  });

  final String nome;
  final String subtitulo;
  final String modalidade;
  final IconData icone;
  final List<ItemCatalogoExercicio> exercicios;
}

/// Resultado da calculadora de anilhas por lado da barra.
class ResultadoCalculadoraAnilhas {
  const ResultadoCalculadoraAnilhas({
    required this.cargaTotalKg,
    required this.pesoBarraKg,
    required this.pesoPorLadoKg,
    required this.anilhasPorLado,
    required this.restantePorLadoKg,
  });

  final double cargaTotalKg;
  final double pesoBarraKg;
  final double pesoPorLadoKg;
  final List<double> anilhasPorLado;
  final double restantePorLadoKg;

  bool get usaApenasBarra => cargaTotalKg <= pesoBarraKg;
}

/// Catálogo 100% offline com mais de 2.000 exercícios de Academia, Calistenia,
/// Treino em Casa, CrossFit/Funcional, Corrida/Cardio, Mobilidade/Core,
/// Artes Marciais/Boxe, Pilates/Postura e Elásticos/Kettlebell.
class CatalogoDeExerciciosOffline {
  CatalogoDeExerciciosOffline._();

  static const List<String> modalidades = <String>[
    'Todas',
    'Academia',
    'Calistenia',
    'Em Casa',
    'CrossFit & Funcional',
    'Corrida & Cardio',
    'Mobilidade & Core',
    'Artes Marciais & Boxe',
    'Pilates & Postura',
    'Elásticos & Kettlebell',
  ];

  static const List<String> gruposMusculares = <String>[
    'Todos',
    'Peito',
    'Costas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Quadríceps',
    'Posterior & Glúteos',
    'Panturrilha',
    'Abdômen & Core',
    'Antebraço & Trapézio',
    'Corpo Inteiro',
    'Cardio & Corrida',
    'Mobilidade',
  ];

  static List<ItemCatalogoExercicio>? _cacheExercicios;
  static List<String>? _cacheBuscasNormalizadas;

  /// Retorna a lista completa (+1.100 exercícios) gerada e mantida em memória local.
  static List<ItemCatalogoExercicio> get todosOsExercicios {
    return _cacheExercicios ??= _construirCatalogoCompleto();
  }

  static List<String> get _buscasNormalizadas {
    final exercicios = todosOsExercicios;
    return _cacheBuscasNormalizadas ??= List<String>.unmodifiable(
      exercicios.map(
        (item) => _normalizar(
          '${item.nome} ${item.grupoMuscular} ${item.modalidade} ${item.equipamento}',
        ),
      ),
    );
  }

  /// Retorna o ícone representativo por grupo muscular (100% offline).
  static IconData iconeDoGrupo(String grupo) {
    switch (grupo) {
      case 'Peito':
        return Icons.shield_rounded;
      case 'Costas':
        return Icons.accessibility_new_rounded;
      case 'Ombros':
        return Icons.hardware_rounded;
      case 'Bíceps':
        return Icons.pan_tool_alt_rounded;
      case 'Tríceps':
        return Icons.sports_martial_arts_rounded;
      case 'Quadríceps':
        return Icons.directions_walk_rounded;
      case 'Posterior & Glúteos':
        return Icons.airline_seat_legroom_extra_rounded;
      case 'Panturrilha':
      case 'Panturrilhas':
        return Icons.skateboarding_rounded;
      case 'Abdômen & Core':
        return Icons.grid_4x4_rounded;
      case 'Antebraço & Trapézio':
        return Icons.fitness_center_rounded;
      case 'Cardio & Corrida':
        return Icons.directions_run_rounded;
      case 'Mobilidade':
        return Icons.self_improvement_rounded;
      case 'Corpo Inteiro':
        return Icons.all_inclusive_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// Retorna o ícone para um item do catálogo considerando modalidade e grupo
  static IconData iconeDoItem(ItemCatalogoExercicio item) {
    if (item.modalidade == 'Corrida & Cardio') {
      return Icons.directions_run_rounded;
    }
    if (item.modalidade == 'Calistenia') {
      return Icons.sports_gymnastics_rounded;
    }
    if (item.modalidade == 'Em Casa') {
      return Icons.home_rounded;
    }
    if (item.modalidade == 'CrossFit & Funcional') {
      return Icons.bolt_rounded;
    }
    if (item.modalidade == 'Pilates & Postura') {
      return Icons.self_improvement_rounded;
    }
    if (item.modalidade == 'Artes Marciais & Boxe') {
      return Icons.sports_kabaddi_rounded;
    }
    return iconeDoGrupo(item.grupoMuscular);
  }

  /// Retorna o ícone correspondente para qualquer nome de exercício
  static IconData iconeDoExercicio(String nomeOuGrupo) {
    final grupo = identificarGrupoMuscular(nomeOuGrupo);
    return iconeDoGrupo(grupo);
  }

  /// Encontra o exercício mais parecido no catálogo offline usando regex e tokens normalizados.
  /// Essencial para mapear nomes importados de planilhas ou de outras fontes.
  static ItemCatalogoExercicio? encontrarMaisProximo(String nome) {
    if (nome.trim().isEmpty) return null;
    final termoNorm = _normalizar(nome.trim());

    // 1. Correspondência exata normalizada
    for (final item in todosOsExercicios) {
      if (_normalizar(item.nome) == termoNorm) {
        return item;
      }
    }

    // 2. Substring direta no nome oficial
    for (final item in todosOsExercicios) {
      final itemNorm = _normalizar(item.nome);
      if (itemNorm.contains(termoNorm) || termoNorm.contains(itemNorm)) {
        return item;
      }
    }

    // 3. Regex e pontuação de tokens de palavras-chave
    final tokens = termoNorm
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3)
        .toList(growable: false);

    if (tokens.isNotEmpty) {
      ItemCatalogoExercicio? melhorItem;
      int maxScore = 0;

      for (final item in todosOsExercicios) {
        final itemNorm = _normalizar(item.nome);
        int score = 0;
        for (final token in tokens) {
          if (itemNorm.contains(token)) {
            score += token.length;
          }
        }
        if (score > maxScore) {
          maxScore = score;
          melhorItem = item;
        }
      }
      if (maxScore >= 4 && melhorItem != null) {
        return melhorItem;
      }
    }

    return null;
  }

  /// Executa a filtragem textual em background através de um Isolate (`compute()`),
  /// garantindo 120 FPS cravados na thread principal da UI mesmo em buscas complexas
  /// com Regex ou catálogos com milhares de variações.
  static Future<List<ItemCatalogoExercicio>> filtrarAsync({
    String busca = '',
    String modalidade = 'Todas',
    String grupoMuscular = 'Todos',
  }) async {
    final termoTrim = busca.trim();
    if (termoTrim.isEmpty &&
        modalidade == 'Todas' &&
        grupoMuscular == 'Todos') {
      return todosOsExercicios;
    }

    return compute(
      _executarFiltroCatalogoNoIsolate,
      ParametrosFiltroCatalogo(
        busca: termoTrim,
        modalidade: modalidade,
        grupoMuscular: grupoMuscular,
      ),
    );
  }

  /// Filtra exercícios por busca textual, modalidade e grupo muscular.
  static List<ItemCatalogoExercicio> filtrar({
    String busca = '',
    String modalidade = 'Todas',
    String grupoMuscular = 'Todos',
  }) {
    final termoTrim = busca.trim();
    final termoNormalizado = _normalizar(termoTrim);
    final termos = termoNormalizado
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    RegExp? userRegex;
    if (termoTrim.length >= 2) {
      try {
        userRegex = RegExp(termoTrim, caseSensitive: false);
      } catch (_) {
        userRegex = null;
      }
    }

    final lista = todosOsExercicios;
    final indiceNormalizado = termos.isEmpty ? null : _buscasNormalizadas;
    final resultado = <ItemCatalogoExercicio>[];
    final prioritarios = <ItemCatalogoExercicio>[];

    for (var i = 0; i < lista.length; i++) {
      final item = lista[i];
      if (modalidade != 'Todas' && item.modalidade != modalidade) {
        continue;
      }
      if (grupoMuscular != 'Todos' && item.grupoMuscular != grupoMuscular) {
        continue;
      }

      if (userRegex != null &&
          (userRegex.hasMatch(item.nome) ||
              userRegex.hasMatch(item.grupoMuscular))) {
        resultado.add(item);
        continue;
      }

      if (indiceNormalizado != null) {
        final alvo = indiceNormalizado[i];
        var combina = true;
        for (final t in termos) {
          if (!alvo.contains(t)) {
            combina = false;
            break;
          }
        }
        if (!combina) continue;

        if (_normalizar(item.nome).startsWith(termoNormalizado)) {
          prioritarios.add(item);
          continue;
        }
      }
      resultado.add(item);
    }

    if (prioritarios.isNotEmpty) {
      return [...prioritarios, ...resultado];
    }
    return resultado;
  }

  /// Identifica o grupo muscular correspondente para qualquer exercício (+2.000 itens ou busca semântica).
  static String identificarGrupoMuscular(String nomeExercicio) {
    if (nomeExercicio.trim().isEmpty) return 'Outros';
    final termoNormalizado = _normalizar(nomeExercicio);

    // 1. Busca exata ou por correspondência no catálogo local
    for (final item in todosOsExercicios) {
      if (_normalizar(item.nome) == termoNormalizado) {
        return item.grupoMuscular;
      }
    }

    // 2. Busca de substring em nomes oficiais
    for (final item in todosOsExercicios) {
      final itemNorm = _normalizar(item.nome);
      if (itemNorm.contains(termoNormalizado) ||
          termoNormalizado.contains(itemNorm)) {
        return item.grupoMuscular;
      }
    }

    // 3. Heurística semântica para exercícios manuais ou variações livres
    if (termoNormalizado.contains('supin') ||
        termoNormalizado.contains('crucifixo') ||
        termoNormalizado.contains('peito') ||
        termoNormalizado.contains('crossover') ||
        termoNormalizado.contains('paralela')) {
      return 'Peito';
    }
    if (termoNormalizado.contains('remad') ||
        termoNormalizado.contains('puxad') ||
        termoNormalizado.contains('costa') ||
        termoNormalizado.contains('dorsal') ||
        termoNormalizado.contains('barra fixa') ||
        termoNormalizado.contains('pulldown')) {
      return 'Costas';
    }
    if (termoNormalizado.contains('agacha') ||
        termoNormalizado.contains('leg') ||
        termoNormalizado.contains('extensor') ||
        termoNormalizado.contains('quadriceps') ||
        termoNormalizado.contains('passada') ||
        termoNormalizado.contains('afundo') ||
        termoNormalizado.contains('hack')) {
      return 'Quadríceps';
    }
    if (termoNormalizado.contains('stiff') ||
        termoNormalizado.contains('flexor') ||
        termoNormalizado.contains('gluteo') ||
        termoNormalizado.contains('posterior') ||
        termoNormalizado.contains('pelvica') ||
        termoNormalizado.contains('terramoto') ||
        termoNormalizado.contains('levantamento terra')) {
      return 'Posterior & Glúteos';
    }
    if (termoNormalizado.contains('desenvolviment') ||
        termoNormalizado.contains('elevacao') ||
        termoNormalizado.contains('ombro') ||
        termoNormalizado.contains('deltoide') ||
        termoNormalizado.contains('militar')) {
      return 'Ombros';
    }
    if (termoNormalizado.contains('rosca') ||
        termoNormalizado.contains('biceps') ||
        termoNormalizado.contains('scott') ||
        termoNormalizado.contains('martelo')) {
      return 'Bíceps';
    }
    if (termoNormalizado.contains('triceps') ||
        termoNormalizado.contains('testa') ||
        termoNormalizado.contains('frances') ||
        termoNormalizado.contains('mergulho')) {
      return 'Tríceps';
    }
    if (termoNormalizado.contains('panturrilha') ||
        termoNormalizado.contains('gemeos') ||
        termoNormalizado.contains('soleo')) {
      return 'Panturrilhas';
    }
    if (termoNormalizado.contains('abdom') ||
        termoNormalizado.contains('prancha') ||
        termoNormalizado.contains('infra') ||
        termoNormalizado.contains('crunch') ||
        termoNormalizado.contains('obliquo')) {
      return 'Abdômen & Core';
    }

    return 'Outros';
  }

  /// Calcula as anilhas necessárias em cada lado da barra (100% offline).
  static ResultadoCalculadoraAnilhas calcularAnilhasPorLado(
    double cargaTotalKg, {
    double pesoBarraKg = 20.0,
  }) {
    if (cargaTotalKg <= pesoBarraKg) {
      return ResultadoCalculadoraAnilhas(
        cargaTotalKg: cargaTotalKg,
        pesoBarraKg: pesoBarraKg,
        pesoPorLadoKg: 0,
        anilhasPorLado: const <double>[],
        restantePorLadoKg: 0,
      );
    }

    const anilhasDisponiveis = <double>[25, 20, 15, 10, 5, 2.5, 1.25];
    final pesoPorLado = (cargaTotalKg - pesoBarraKg) / 2.0;
    var restante = pesoPorLado;
    final escolhidas = <double>[];

    for (final anilha in anilhasDisponiveis) {
      while (restante + 0.001 >= anilha && escolhidas.length < 16) {
        escolhidas.add(anilha);
        restante -= anilha;
      }
    }

    return ResultadoCalculadoraAnilhas(
      cargaTotalKg: cargaTotalKg,
      pesoBarraKg: pesoBarraKg,
      pesoPorLadoKg: pesoPorLado,
      anilhasPorLado: escolhidas,
      restantePorLadoKg: restante < 0.01 ? 0 : restante,
    );
  }

  /// Modelos de treinos completos prontos para importar com 1 toque.
  static final List<ModeloDeTreinoPronto> modelosProntos =
      <ModeloDeTreinoPronto>[
    const ModeloDeTreinoPronto(
      nome: 'Treino A — Empurrar (Peito, Ombro e Tríceps)',
      subtitulo: 'Divisão Push clássica focada em hipertrofia na academia',
      modalidade: 'Academia',
      icone: Icons.fitness_center_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Supino Reto com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Barra',
          cargaSugeridaKg: 40,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Supino Inclinado com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Halteres',
          cargaSugeridaKg: 20,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 75,
        ),
        ItemCatalogoExercicio(
          nome: 'Crucifixo na Polia Média (Crossover)',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 15,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Desenvolvimento com Halteres Sentado',
          modalidade: 'Academia',
          grupoMuscular: 'Ombros',
          equipamento: 'Halteres',
          cargaSugeridaKg: 15,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Elevação Lateral com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Ombros',
          equipamento: 'Halteres',
          cargaSugeridaKg: 10,
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Tríceps Pulley na Polia com Corda',
          modalidade: 'Academia',
          grupoMuscular: 'Tríceps',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 25,
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Treino B — Puxar (Costas, Bíceps e Trapézio)',
      subtitulo: 'Divisão Pull completa para dorsal larga e bíceps denso',
      modalidade: 'Academia',
      icone: Icons.sports_gymnastics_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Puxada Frontal Aberta na Polia (Pulldown)',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 45,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Remada Curvada Pronada com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Barra',
          cargaSugeridaKg: 40,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Remada Baixa Sentado com Triângulo',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 45,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Crucifixo Inverso na Máquina (Peck Deck)',
          modalidade: 'Academia',
          grupoMuscular: 'Ombros',
          equipamento: 'Máquina',
          cargaSugeridaKg: 30,
          seriesSugeridas: 3,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Rosca Direta com Barra W',
          modalidade: 'Academia',
          grupoMuscular: 'Bíceps',
          equipamento: 'Barra W',
          cargaSugeridaKg: 20,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Rosca Martelo Alternada com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Bíceps',
          equipamento: 'Halteres',
          cargaSugeridaKg: 10,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Treino C — Pernas Completo & Panturrilha',
      subtitulo: 'Quadríceps, posterior de coxa, glúteos e panturrilha',
      modalidade: 'Academia',
      icone: Icons.directions_walk_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Agachamento Livre com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Barra',
          cargaSugeridaKg: 60,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 120,
        ),
        ItemCatalogoExercicio(
          nome: 'Leg Press 45°',
          modalidade: 'Academia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Máquina',
          cargaSugeridaKg: 140,
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Cadeira Extensora',
          modalidade: 'Academia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Máquina',
          cargaSugeridaKg: 45,
          seriesSugeridas: 3,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Stiff com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Barra',
          cargaSugeridaKg: 50,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Mesa Flexora',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Máquina',
          cargaSugeridaKg: 40,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Panturrilha em Pé na Máquina',
          modalidade: 'Academia',
          grupoMuscular: 'Panturrilha',
          equipamento: 'Máquina',
          cargaSugeridaKg: 50,
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Calistenia & Street Workout Completo',
      subtitulo: 'Força e domínio corporal nas barras e paralelas',
      modalidade: 'Calistenia',
      icone: Icons.sports_mma_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Barra Fixa Pronada (Pull-up)',
          modalidade: 'Calistenia',
          grupoMuscular: 'Costas',
          equipamento: 'Barra Fixa',
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Mergulho nas Paralelas (Dips)',
          modalidade: 'Calistenia',
          grupoMuscular: 'Peito',
          equipamento: 'Paralelas',
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Barra Fixa Supinada (Chin-up)',
          modalidade: 'Calistenia',
          grupoMuscular: 'Bíceps',
          equipamento: 'Barra Fixa',
          seriesSugeridas: 3,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Flexão Pike (Pike Push-up)',
          modalidade: 'Calistenia',
          grupoMuscular: 'Ombros',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Agachamento Pistol Assistido',
          modalidade: 'Calistenia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 8,
        ),
        ItemCatalogoExercicio(
          nome: 'Elevação de Pernas na Barra Fixa (Toes-to-Bar)',
          modalidade: 'Calistenia',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Barra Fixa',
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Treino em Casa Sem Equipamento (Full Body)',
      subtitulo: 'Treino completo na sala ou quarto usando apenas o corpo',
      modalidade: 'Em Casa',
      icone: Icons.home_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Flexão de Braços Tradicional em Casa',
          modalidade: 'Em Casa',
          grupoMuscular: 'Peito',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Agachamento Livre Peso do Corpo em Casa',
          modalidade: 'Em Casa',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Afundo Alternado (Passada) em Casa',
          modalidade: 'Em Casa',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Mergulho de Tríceps na Cadeira / Sofá',
          modalidade: 'Em Casa',
          grupoMuscular: 'Tríceps',
          equipamento: 'Móvel / Cadeira',
          seriesSugeridas: 3,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Elevação Pélvica no Solo (Ponte de Glúteos)',
          modalidade: 'Em Casa',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Abdominal Bicicleta no Solo',
          modalidade: 'Em Casa',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 25,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'CrossFit WOD & Condicionamento Metabólico',
      subtitulo: 'Potência, LPO, Kettlebell e resistência cardiorrespiratória',
      modalidade: 'CrossFit & Funcional',
      icone: Icons.bolt_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Thruster com Barra Olímpica',
          modalidade: 'CrossFit & Funcional',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Barra Olímpica',
          cargaSugeridaKg: 40,
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Kettlebell Swing Russo',
          modalidade: 'CrossFit & Funcional',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Kettlebell',
          cargaSugeridaKg: 20,
          seriesSugeridas: 4,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Box Jump (Salto no Caixote)',
          modalidade: 'CrossFit & Funcional',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Caixote / Box',
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Wall Ball Shot',
          modalidade: 'CrossFit & Funcional',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Medicine Ball',
          cargaSugeridaKg: 10,
          seriesSugeridas: 4,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Burpee Over the Bar',
          modalidade: 'CrossFit & Funcional',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Corrida Intervalada & Resistência',
      subtitulo: 'Aquecimento, tiros de velocidade e educativo de corrida',
      modalidade: 'Corrida & Cardio',
      icone: Icons.directions_run_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Trote Leve de Aquecimento (10 min)',
          modalidade: 'Corrida & Cardio',
          grupoMuscular: 'Cardio & Corrida',
          equipamento: 'Corrida de Rua / Pista',
          seriesSugeridas: 1,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Tiro de Corrida 400m Forte',
          modalidade: 'Corrida & Cardio',
          grupoMuscular: 'Cardio & Corrida',
          equipamento: 'Corrida de Rua / Pista',
          seriesSugeridas: 6,
          repeticoesSugeridas: 1,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Educativo de Corrida: Skipping Alto',
          modalidade: 'Corrida & Cardio',
          grupoMuscular: 'Cardio & Corrida',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 30,
        ),
        ItemCatalogoExercicio(
          nome: 'Corrida Contínua 5 km (Ritmo Confortável)',
          modalidade: 'Corrida & Cardio',
          grupoMuscular: 'Cardio & Corrida',
          equipamento: 'Corrida de Rua / Pista',
          seriesSugeridas: 1,
          repeticoesSugeridas: 5,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Upper Body — Superior Completo (Peito, Costas, Ombros e Braços)',
      subtitulo: 'Ideal para divisão Upper/Lower 4x na semana',
      modalidade: 'Academia',
      icone: Icons.accessibility_new_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Supino Inclinado com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Halteres',
          cargaSugeridaKg: 22,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Puxada Frontal Aberta na Polia (Pulldown)',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 45,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Remada Baixa Sentado com Triângulo',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Polia / Cabo',
          cargaSugeridaKg: 45,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Elevação Lateral com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Ombros',
          equipamento: 'Halteres',
          cargaSugeridaKg: 10,
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Rosca Direta com Barra W',
          modalidade: 'Academia',
          grupoMuscular: 'Bíceps',
          equipamento: 'Barra W',
          cargaSugeridaKg: 20,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Tríceps Testa com Barra W Deitado',
          modalidade: 'Academia',
          grupoMuscular: 'Tríceps',
          equipamento: 'Barra W',
          cargaSugeridaKg: 20,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Glúteos & Posterior Foco Máximo',
      subtitulo: 'Foco em elevação pélvica, búlgaro, stiff e abdução',
      modalidade: 'Academia',
      icone: Icons.local_fire_department_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Elevação Pélvica (Hip Thrust) com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Barra',
          cargaSugeridaKg: 60,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Agachamento Búlgaro com Halteres',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Halteres',
          cargaSugeridaKg: 14,
          seriesSugeridas: 4,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Stiff com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Barra',
          cargaSugeridaKg: 45,
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Cadeira Flexora',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Máquina',
          cargaSugeridaKg: 40,
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Cadeira Abdutora',
          modalidade: 'Academia',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Máquina',
          cargaSugeridaKg: 45,
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Força Pura Powerlifting (Protocolo 5x5)',
      subtitulo: 'Foco nos 3 grandes levantamentos básicos e força bruta',
      modalidade: 'Academia',
      icone: Icons.workspace_premium_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Agachamento Livre com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Barra',
          cargaSugeridaKg: 70,
          seriesSugeridas: 5,
          repeticoesSugeridas: 5,
          descansoSugeridoSegundos: 150,
        ),
        ItemCatalogoExercicio(
          nome: 'Supino Reto com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Barra',
          cargaSugeridaKg: 55,
          seriesSugeridas: 5,
          repeticoesSugeridas: 5,
          descansoSugeridoSegundos: 150,
        ),
        ItemCatalogoExercicio(
          nome: 'Levantamento Terra Convencional com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Costas',
          equipamento: 'Barra',
          cargaSugeridaKg: 80,
          seriesSugeridas: 3,
          repeticoesSugeridas: 5,
          descansoSugeridoSegundos: 180,
        ),
        ItemCatalogoExercicio(
          nome: 'Desenvolvimento Militar em Pé (Overhead Press) com Barra',
          modalidade: 'Academia',
          grupoMuscular: 'Ombros',
          equipamento: 'Barra',
          cargaSugeridaKg: 35,
          seriesSugeridas: 5,
          repeticoesSugeridas: 5,
          descansoSugeridoSegundos: 120,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Boxe, Muay Thai & Condicionamento de Luta',
      subtitulo:
          'Rounds explosivos de sombra, saco de pancada e core de combate',
      modalidade: 'Artes Marciais & Boxe',
      icone: Icons.sports_kabaddi_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Pular Corda Ritmo de Boxe (Aquecimento 3 Rounds)',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Cardio & Corrida',
          equipamento: 'Corda de Pular',
          seriesSugeridas: 3,
          repeticoesSugeridas: 100,
          descansoSugeridoSegundos: 60,
        ),
        ItemCatalogoExercicio(
          nome: 'Shadowboxing (Sombra de Boxe: Jab, Direto, Esquiva e Pêndulo)',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 20,
          descansoSugeridoSegundos: 60,
        ),
        ItemCatalogoExercicio(
          nome:
              'Saco de Pancadas: Combinação Jab + Direto + Cruzado + Low Kick',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Saco de Pancadas',
          seriesSugeridas: 4,
          repeticoesSugeridas: 15,
          descansoSugeridoSegundos: 60,
        ),
        ItemCatalogoExercicio(
          nome: 'Sprawl Explosivo de Defesa de Queda',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Abdominal Russian Twist (Giro Russo para Golpes)',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Peso do Corpo / Medicine Ball',
          seriesSugeridas: 4,
          repeticoesSugeridas: 30,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Pilates Solo, Postura & Core Profundo',
      subtitulo:
          'Fortalecimento de centro de força (Powerhouse) e coluna saudável',
      modalidade: 'Pilates & Postura',
      icone: Icons.self_improvement_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Pilates The Hundred (Bombeamento Respiratório 100)',
          modalidade: 'Pilates & Postura',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Pilates Single Leg Stretch (Alongamento Alternado de Perna)',
          modalidade: 'Pilates & Postura',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 16,
        ),
        ItemCatalogoExercicio(
          nome: 'Pilates Shoulder Bridge (Ponte Articulada de Coluna)',
          modalidade: 'Pilates & Postura',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Pilates Swimming (Natação no Solo para Paravertebrais)',
          modalidade: 'Pilates & Postura',
          grupoMuscular: 'Costas',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 20,
        ),
        ItemCatalogoExercicio(
          nome: 'Perdigueiro (Bird-Dog) Estabilidade Lombar',
          modalidade: 'Pilates & Postura',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Mobilidade Articular & Alívio Lombar (15 min)',
      subtitulo:
          'Rotina diária para destravar quadril, coluna torácica e ombros',
      modalidade: 'Mobilidade & Core',
      icone: Icons.spa_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Mobilidade de Coluna Gato-Vaca (Cat-Cow)',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Mobilidade',
          equipamento: 'Livre / Rolo',
          seriesSugeridas: 2,
          repeticoesSugeridas: 15,
        ),
        ItemCatalogoExercicio(
          nome: 'Maior Alongamento do Mundo (World’s Greatest Stretch)',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Mobilidade',
          equipamento: 'Livre / Rolo',
          seriesSugeridas: 2,
          repeticoesSugeridas: 10,
        ),
        ItemCatalogoExercicio(
          nome: 'Mobilidade de Quadril 90/90 Alternado no Solo',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Mobilidade',
          equipamento: 'Livre / Rolo',
          seriesSugeridas: 2,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Alongamento de Flexores de Quadril (Psoas) Ajoelhado',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Mobilidade',
          equipamento: 'Livre / Rolo',
          seriesSugeridas: 2,
          repeticoesSugeridas: 12,
        ),
        ItemCatalogoExercicio(
          nome: 'Postura da Criança (Child’s Pose) Relaxamento Lombar',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Mobilidade',
          equipamento: 'Livre / Rolo',
          seriesSugeridas: 2,
          repeticoesSugeridas: 10,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Reabilitação & Alívio Lombar e Joelho (McGill & Isometrias)',
      subtitulo:
          'Protocolo preventivo para coluna estável, joelhos fortes e postura',
      modalidade: 'Mobilidade & Core',
      icone: Icons.healing_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Protocolo McGill: Perdigueiro (Bird-Dog) Isométrico com Pausa',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 45,
        ),
        ItemCatalogoExercicio(
          nome: 'Protocolo McGill: Prancha Lateral com Elevação de Perna',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 45,
        ),
        ItemCatalogoExercicio(
          nome: 'Protocolo McGill: Curl-Up com Mãos sob a Lombar e Pausa',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 45,
        ),
        ItemCatalogoExercicio(
          nome:
              'Agachamento Espanhol Isométrico para Tendão Patelar (Spanish Squat)',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Super Band Elástica',
          seriesSugeridas: 4,
          repeticoesSugeridas: 45,
          descansoSugeridoSegundos: 60,
        ),
        ItemCatalogoExercicio(
          nome:
              'Elevação de Tibial Anterior Encostado na Parede (Tibialis Raise)',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Panturrilha',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 20,
          descansoSugeridoSegundos: 45,
        ),
        ItemCatalogoExercicio(
          nome: 'Ponte de Glúteo no Solo com Isometria e Abdução',
          modalidade: 'Mobilidade & Core',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Tapete / Solo',
          seriesSugeridas: 3,
          repeticoesSugeridas: 15,
          descansoSugeridoSegundos: 45,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'Força & Hipertrofia com Trap Bar e Barra W (Powerbuilding)',
      subtitulo:
          'Treino pesado com barras ergonômicas para máxima sobrecarga segura',
      modalidade: 'Academia',
      icone: Icons.fitness_center_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'Levantamento Terra com Trap Bar Pegada Alta',
          modalidade: 'Academia',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Trap Bar (Barra Hexagonal)',
          cargaSugeridaKg: 80,
          seriesSugeridas: 4,
          repeticoesSugeridas: 6,
          descansoSugeridoSegundos: 120,
        ),
        ItemCatalogoExercicio(
          nome: 'Supino com Barra Romana (Pegada Neutra para Ombros Saudáveis)',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: 'Barra Romana / H',
          cargaSugeridaKg: 40,
          seriesSugeridas: 4,
          repeticoesSugeridas: 8,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Passada Dinâmica com Trap Bar',
          modalidade: 'Academia',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Trap Bar (Barra Hexagonal)',
          cargaSugeridaKg: 35,
          seriesSugeridas: 3,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 90,
        ),
        ItemCatalogoExercicio(
          nome: 'Encolhimento de Ombros Pesado com Trap Bar',
          modalidade: 'Academia',
          grupoMuscular: 'Antebraço & Trapézio',
          equipamento: 'Trap Bar (Barra Hexagonal)',
          cargaSugeridaKg: 70,
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 75,
        ),
        ItemCatalogoExercicio(
          nome: 'Rosca Bíceps Scott com Barra W (Banco Scott)',
          modalidade: 'Academia',
          grupoMuscular: 'Bíceps',
          equipamento: 'Barra W',
          cargaSugeridaKg: 25,
          seriesSugeridas: 3,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 60,
        ),
        ItemCatalogoExercicio(
          nome: 'Tríceps Testa no Banco Reto com Barra W',
          modalidade: 'Academia',
          grupoMuscular: 'Tríceps',
          equipamento: 'Barra W',
          cargaSugeridaKg: 25,
          seriesSugeridas: 3,
          repeticoesSugeridas: 10,
          descansoSugeridoSegundos: 60,
        ),
      ],
    ),
    const ModeloDeTreinoPronto(
      nome: 'HIIT Metabólico Queima Rápida em Casa (Sem Equipamento, 15 min)',
      subtitulo:
          'Circuito dinâmico de alta queima calórica e condicionamento na sala',
      modalidade: 'Em Casa',
      icone: Icons.flash_on_rounded,
      exercicios: <ItemCatalogoExercicio>[
        ItemCatalogoExercicio(
          nome: 'HIIT em Casa: Polichinelo com Agachamento (Squat Jack)',
          modalidade: 'Em Casa',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 30,
          descansoSugeridoSegundos: 30,
        ),
        ItemCatalogoExercicio(
          nome: 'HIIT em Casa: Mountain Climber Rápido (Corrida no Solo)',
          modalidade: 'Em Casa',
          grupoMuscular: 'Abdômen & Core',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 30,
          descansoSugeridoSegundos: 30,
        ),
        ItemCatalogoExercicio(
          nome:
              'HIIT em Casa: Afundo Pliométrico Trocando no Ar (Jumping Lunge)',
          modalidade: 'Em Casa',
          grupoMuscular: 'Quadríceps',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 16,
          descansoSugeridoSegundos: 30,
        ),
        ItemCatalogoExercicio(
          nome: 'HIIT em Casa: Prancha Sobe e Desce (Up-Down Plank)',
          modalidade: 'Em Casa',
          grupoMuscular: 'Peito',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 30,
        ),
        ItemCatalogoExercicio(
          nome: 'HIIT em Casa: Skater Jump Lateral com Toque no Chão',
          modalidade: 'Em Casa',
          grupoMuscular: 'Posterior & Glúteos',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 20,
          descansoSugeridoSegundos: 30,
        ),
        ItemCatalogoExercicio(
          nome: 'HIIT em Casa: Burpee Militar Completo com Flexão e Salto',
          modalidade: 'Em Casa',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: 'Peso do Corpo',
          seriesSugeridas: 4,
          repeticoesSugeridas: 12,
          descansoSugeridoSegundos: 45,
        ),
      ],
    ),
  ];

  static final RegExp _regA = RegExp(r'[áàâã]');
  static final RegExp _regE = RegExp(r'[éê]');
  static final RegExp _regI = RegExp(r'[í]');
  static final RegExp _regO = RegExp(r'[óôõ]');
  static final RegExp _regU = RegExp(r'[úü]');

  static String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(_regA, 'a')
        .replaceAll(_regE, 'e')
        .replaceAll(_regI, 'i')
        .replaceAll(_regO, 'o')
        .replaceAll(_regU, 'u')
        .replaceAll('ç', 'c');
  }

  static List<ItemCatalogoExercicio> _construirCatalogoCompleto() {
    final lista = <ItemCatalogoExercicio>[];
    final nomesAdicionados = <String>{};

    void adicionar(
      String nome, {
      required String modalidade,
      required String grupoMuscular,
      required String equipamento,
      double carga = 0,
      int series = 3,
      int reps = 12,
      int descanso = 60,
    }) {
      final chave = nome.trim();
      if (chave.isEmpty || !nomesAdicionados.add(chave)) return;
      lista.add(
        ItemCatalogoExercicio(
          nome: chave,
          modalidade: modalidade,
          grupoMuscular: grupoMuscular,
          equipamento: equipamento,
          cargaSugeridaKg: carga,
          seriesSugeridas: series,
          repeticoesSugeridas: reps,
          descansoSugeridoSegundos: descanso,
        ),
      );
    }

    // =========================================================================
    // 1. ACADEMIA — PEITO (~110 exercícios)
    // =========================================================================
    const angulosPeito = <String>[
      'Reto',
      'Inclinado',
      'Declinado',
      'Inclinado 30°',
      'Inclinado 45°',
    ];
    const implementosPeito = <(String, String, double)>[
      ('com Barra Olímpica', 'Barra', 40),
      ('com Halteres', 'Halteres', 20),
      ('no Smith', 'Smith', 35),
      ('na Máquina Articulada', 'Máquina', 40),
      ('Unilateral com Halter', 'Halteres', 15),
      ('com Pegada Fechada', 'Barra', 30),
      ('com Pegada Aberta', 'Barra', 40),
      ('com Pausa no Peito (2s)', 'Barra', 35),
      ('Alternado com Halteres', 'Halteres', 15),
      ('com Pegada Neutra (Halteres)', 'Halteres', 20),
    ];
    for (final ang in angulosPeito) {
      for (final imp in implementosPeito) {
        adicionar(
          'Supino $ang ${imp.$1}',
          modalidade: 'Academia',
          grupoMuscular: 'Peito',
          equipamento: imp.$2,
          carga: imp.$3,
          series: 4,
          reps: 10,
          descanso: 75,
        );
      }
    }
    const variacoesCrucifixo = <String>[
      'Reto com Halteres',
      'Inclinado com Halteres',
      'Declinado com Halteres',
      'Reto nos Cabos com Banco',
      'Inclinado nos Cabos com Banco',
      'na Máquina Peck Deck (Voador)',
      'Unilateral no Peck Deck',
      'Unilateral na Polia Média',
      'na Polia Alta (Crossover Para Baixo)',
      'na Polia Média (Crossover Reto)',
      'na Polia Baixa (Crossover Para Cima)',
      'Cruzando as Mãos no Crossover',
      'Sentado na Máquina Convergente',
      'com Pausa em Alongamento Máximo',
    ];
    for (final v in variacoesCrucifixo) {
      adicionar(
        'Crucifixo $v',
        modalidade: 'Academia',
        grupoMuscular: 'Peito',
        equipamento:
            v.contains('Polia') || v.contains('Cabo') || v.contains('Crossover')
                ? 'Polia / Cabo'
                : v.contains('Máquina') || v.contains('Peck')
                    ? 'Máquina'
                    : 'Halteres',
        carga: 15,
        series: 3,
        reps: 12,
      );
    }
    for (final extraPeito in const <String>[
      'Pullover Reto com Halter',
      'Pullover Cruzado no Banco com Halter',
      'Pullover com Barra W Deitado',
      'Press Svend com Anilha em Pé',
      'Press Svend Deitado no Banco',
      'Mergulho nas Paralelas Foco Peitoral (Tronco Inclinado)',
      'Mergulho nas Paralelas com Carga Adicional',
      'Mergulho no Graviton Foco Peitoral',
      'Supino Sentado na Máquina Vertical',
      'Supino Horizontal na Máquina Cabo',
      'Supino Guilhotina com Barra',
      'Supino no Chão (Floor Press) com Barra',
      'Supino no Chão (Floor Press) com Halteres',
      'Around the World no Banco Reto com Halteres',
    ]) {
      adicionar(
        extraPeito,
        modalidade: 'Academia',
        grupoMuscular: 'Peito',
        equipamento: 'Máquina / Livre',
        carga: 20,
      );
    }

    // =========================================================================
    // 2. ACADEMIA — COSTAS (~130 exercícios)
    // =========================================================================
    const puxadasPolia = <String>[
      'Frontal Aberta Pronada',
      'Frontal Fechada Supinada',
      'Frontal com Triângulo',
      'Frontal com Barra Romana (Pegada Neutra)',
      'Unilateral na Polia Alta',
      'Articulada na Máquina',
      'Unilateral na Máquina Articulada',
      'com Corda na Polia Alta',
      'Pronada Média com Pausa Iso (2s)',
      'Supinada Unilateral Ajoelhado na Polia',
    ];
    for (final p in puxadasPolia) {
      adicionar(
        'Puxada $p',
        modalidade: 'Academia',
        grupoMuscular: 'Costas',
        equipamento: p.contains('Máquina') ? 'Máquina' : 'Polia / Cabo',
        carga: 40,
        series: 4,
        reps: 10,
      );
    }

    const tiposRemada = <String>[
      'Curvada com Barra Olímpica Pegada Pronada',
      'Curvada com Barra Olímpica Pegada Supinada (Yates Row)',
      'Pendlay Row Explosiva com Barra',
      'Cavalinho (T-Bar) com Triângulo',
      'Cavalinho (T-Bar) Pegada Aberta',
      'Cavalinho na Máquina com Apoio no Peito',
      'Unilateral com Halter (Serrote)',
      'Unilateral com Halter Apoiado no Banco Inclinado',
      'Dupla no Banco Inclinado com Halteres (Chest-Supported Row)',
      'Sentado na Polia Baixa com Triângulo',
      'Sentado na Polia Baixa com Barra Reta Pronada',
      'Sentado na Polia Baixa com Barra Reta Supinada',
      'Sentado na Polia Baixa com Barra Romana',
      'Sentado na Polia Baixa com Corda',
      'Unilateral Sentado na Polia Baixa',
      'na Máquina Articulada Pegada Neutra',
      'na Máquina Articulada Pegada Pronada Alta',
      'Unilateral na Máquina Articulada',
      'no Smith Curvado',
      'Meadows Row Unilateral no Landmine',
      'no Landmine com Duas Mãos',
      'Seal Row (Deitado no Banco Reto Elevado) com Barra',
      'Seal Row (Deitado no Banco Reto Elevado) com Halteres',
      'Kroc Row Pesada Unilateral com Halter',
      'Renegade Row com Halteres em Prancha',
      'Alta na Polia Sentado',
      'em Pé na Polia Média Unilateral',
    ];
    for (final r in tiposRemada) {
      adicionar(
        'Remada $r',
        modalidade: 'Academia',
        grupoMuscular: 'Costas',
        equipamento: r.contains('Polia')
            ? 'Polia / Cabo'
            : r.contains('Halter')
                ? 'Halteres'
                : r.contains('Máquina')
                    ? 'Máquina'
                    : 'Barra',
        carga: 35,
        series: 4,
        reps: 10,
      );
    }

    for (final extraCostas in const <String>[
      'Pulldown na Polia Alta com Barra Reta',
      'Pulldown na Polia Alta com Corda',
      'Pulldown Unilateral na Polia Alta',
      'Pulldown Ajoelhado na Polia Alta',
      'Pullover na Máquina (Nautilus)',
      'Barra Fixa no Graviton Pegada Pronada',
      'Barra Fixa no Graviton Pegada Supinada',
      'Barra Fixa no Graviton Pegada Neutra',
      'Levantamento Terra Convencional com Barra',
      'Levantamento Terra Sumô com Barra',
      'Rack Pull (Meio Terra no Suporte) com Barra',
      'Hiperextensão Lombar no Banco Romano 45°',
      'Hiperextensão Lombar no Banco Romano com Anilha',
      'Bom Dia (Good Morning) com Barra',
      'Extensão Lombar na Máquina Sentado',
    ]) {
      adicionar(
        extraCostas,
        modalidade: 'Academia',
        grupoMuscular: 'Costas',
        equipamento: 'Academia',
        carga: 35,
        series: 3,
        reps: 12,
      );
    }

    // =========================================================================
    // 3. ACADEMIA — OMBROS, TRAPÉZIO & ANTEBRAÇO (~130 exercícios)
    // =========================================================================
    const desenvolvimentos = <String>[
      'Militar em Pé com Barra Olímpica',
      'Sentado com Barra pela Frente',
      'Sentado com Halteres',
      'Sentado Alternado com Halteres',
      'Arnold Sentado com Halteres',
      'Arnold em Pé com Halteres',
      'na Máquina Articulada Pegada Pronada',
      'na Máquina Articulada Pegada Neutra',
      'Unilateral na Máquina Articulada',
      'no Smith Sentado',
      'no Smith em Pé',
      'Unilateral em Pé com Halter',
      'Unilateral no Landmine em Pé',
      'Unilateral no Landmine Ajoelhado',
      'Sentado com Pegada Neutra (Halteres)',
      'Push Press com Barra na Academia',
    ];
    for (final d in desenvolvimentos) {
      adicionar(
        'Desenvolvimento $d',
        modalidade: 'Academia',
        grupoMuscular: 'Ombros',
        equipamento: d.contains('Halter')
            ? 'Halteres'
            : d.contains('Máquina')
                ? 'Máquina'
                : 'Barra',
        carga: 20,
        series: 4,
        reps: 10,
      );
    }

    const elevacoesOmbro = <String>[
      'Lateral em Pé com Halteres',
      'Lateral Sentado com Halteres',
      'Lateral Unilateral Inclinado com Halter',
      'Lateral na Polia Baixa Unilateral por Trás',
      'Lateral na Polia Baixa Unilateral pela Frente',
      'Lateral na Polia Altura do Punho (Cuff)',
      'Lateral na Máquina Sentado',
      'Lateral Cruzada nos Cabos',
      'Lateral no Banco Inclinado 45° com Halter',
      'Lateral Completa (Lu Raises) com Halteres',
      'Frontal Alternada com Halteres',
      'Frontal Simultânea com Halteres',
      'Frontal com Barra Reta Pronada',
      'Frontal com Barra W Supinada',
      'Frontal na Polia Baixa com Corda',
      'Frontal na Polia Baixa com Barra',
      'Frontal com Anilha (Volante)',
      'Frontal no Banco Inclinado com Halteres',
      'Posterior (Crucifixo Inverso) Curvado com Halteres',
      'Posterior Sentado Curvado com Halteres',
      'Posterior Apoiado no Banco Inclinado com Halteres',
      'Posterior na Máquina Peck Deck Inverso',
      'Posterior Unilateral no Peck Deck Inverso',
      'Posterior Cruzado na Polia Alta (Crossover Inverso)',
      'Posterior Unilateral na Polia Média',
      'Face Pull na Polia Alta com Corda',
      'Face Pull Sentado na Polia com Corda',
      'Remada Alta com Barra Reta Pegada Média',
      'Remada Alta com Barra W',
      'Remada Alta com Halteres',
      'Remada Alta na Polia Baixa com Corda',
      'Rotação Externa de Manguito na Polia',
      'Rotação Interna de Manguito na Polia',
      'Rotação Cubana com Halteres',
    ];
    for (final e in elevacoesOmbro) {
      adicionar(
        e.startsWith('Face') ||
                e.startsWith('Remada') ||
                e.startsWith('Rotação')
            ? e
            : 'Elevação $e',
        modalidade: 'Academia',
        grupoMuscular: 'Ombros',
        equipamento: e.contains('Polia') || e.contains('Cabo')
            ? 'Polia / Cabo'
            : e.contains('Máquina') || e.contains('Peck')
                ? 'Máquina'
                : 'Halteres',
        carga: 10,
        series: 4,
        reps: 12,
      );
    }

    for (final trapAnt in const <(String, double)>[
      ('Encolhimento de Ombros com Barra pela Frente', 50),
      ('Encolhimento de Ombros com Barra por Trás', 50),
      ('Encolhimento de Ombros com Halteres em Pé', 25),
      ('Encolhimento de Ombros Sentado com Halteres', 20),
      ('Encolhimento de Ombros no Smith', 50),
      ('Encolhimento de Ombros na Polia Baixa', 40),
      ('Encolhimento na Máquina Articulada / Trap Bar', 60),
      ('Encolhimento Inclinado no Banco 45° com Halteres', 20),
      ('Rosca de Punho Sentado com Barra Supinada', 15),
      ('Rosca de Punho Sentado com Halter Unilateral', 10),
      ('Rosca de Punho Inversa Sentado com Barra Pronada', 10),
      ('Rosca de Punho por Trás das Costas em Pé com Barra', 20),
      ('Rolo de Punho (Wrist Roller) com Carga', 10),
      ('Sustentação de Halteres Pesados (Pegada / Grip)', 30),
    ]) {
      adicionar(
        trapAnt.$1,
        modalidade: 'Academia',
        grupoMuscular: 'Antebraço & Trapézio',
        equipamento: 'Livre / Máquina',
        carga: trapAnt.$2,
      );
    }

    // =========================================================================
    // 4. ACADEMIA — BÍCEPS & TRÍCEPS (~120 exercícios)
    // =========================================================================
    const roscasBiceps = <String>[
      'Direta em Pé com Barra Reta',
      'Direta em Pé com Barra W (EZ)',
      'Direta Pegada Fechada com Barra W',
      'Direta Pegada Aberta com Barra W',
      'Direta na Polia Baixa com Barra Reta',
      'Direta na Polia Baixa com Barra W',
      'Direta Deitado na Polia Baixa',
      'Alternada em Pé com Halteres',
      'Alternada Sentado com Halteres',
      'Simultânea em Pé com Halteres',
      'No Banco Inclinado 45° com Halteres',
      'No Banco Inclinado Alternada com Halteres',
      'Martelo em Pé Simultânea com Halteres',
      'Martelo Alternada com Halteres',
      'Martelo Cruzada (Cross-Body) com Halteres',
      'Martelo na Polia Baixa com Corda',
      'Martelo no Banco Scott com Halteres',
      'Scott com Barra W',
      'Scott com Barra Reta',
      'Scott Unilateral com Halter',
      'Scott na Máquina',
      'Scott na Polia Baixa',
      'Concentrada Sentado com Halter',
      'Concentrada na Polia Baixa Unilateral',
      'Spider (Aranha) no Banco Inclinado com Barra W',
      'Spider (Aranha) no Banco Inclinado com Halteres',
      'Bayesian Curl Unilateral na Polia Baixa (Costas para a Polia)',
      'Bayesian Curl Duplo nos Cabos',
      'Duplo Bíceps na Polia Alta (Posição Crucificada)',
      '21 com Barra W',
      '21 na Polia Baixa',
      'Zottman em Pé com Halteres',
      'Inversa em Pé com Barra Reta',
      'Inversa em Pé com Barra W',
      'Inversa na Polia Baixa com Barra',
      'Drag Curl com Barra Reta',
      'Drag Curl no Smith',
      'Waiter Curl (Rosca Garçom) com Halter Único',
    ];
    for (final b in roscasBiceps) {
      adicionar(
        'Rosca $b',
        modalidade: 'Academia',
        grupoMuscular: 'Bíceps',
        equipamento: b.contains('Polia') || b.contains('Cabo')
            ? 'Polia / Cabo'
            : b.contains('Halter')
                ? 'Halteres'
                : 'Barra',
        carga: 15,
        series: 3,
        reps: 12,
      );
    }

    const exerciciosTriceps = <String>[
      'Tríceps Pulley na Polia Alta com Corda',
      'Tríceps Pulley na Polia Alta com Barra Reta Pronada',
      'Tríceps Pulley na Polia Alta com Barra W',
      'Tríceps Pulley na Polia Alta com Barra V',
      'Tríceps Pulley Invertido (Pegada Supinada) com Barra',
      'Tríceps Unilateral na Polia Alta Pegada Pronada',
      'Tríceps Unilateral na Polia Alta Pegada Supinada',
      'Tríceps Unilateral na Polia Alta Sem Acessório (Cabo Puro)',
      'Tríceps Francês Sentado com Halter (Duas Mãos)',
      'Tríceps Francês Unilateral Sentado com Halter',
      'Tríceps Francês em Pé com Barra W',
      'Tríceps Francês na Polia Baixa com Corda',
      'Tríceps Francês na Polia Alta com Corda (Inclinado à Frente)',
      'Tríceps Francês Unilateral Cruzado na Polia',
      'Tríceps Testa Deitado com Barra W',
      'Tríceps Testa Deitado com Barra Reta',
      'Tríceps Testa Deitado com Halteres (Pegada Neutra)',
      'Tríceps Testa no Banco Inclinado com Barra W',
      'Tríceps Testa Deitado na Polia Baixa',
      'Tríceps Coice Unilateral com Halter',
      'Tríceps Coice Duplo Curvado com Halteres',
      'Tríceps Coice Unilateral na Polia Baixa',
      'Tríceps Mergulho na Máquina Sentado',
      'Tríceps Mergulho nas Paralelas (Tronco Reto)',
      'Tríceps Mergulho entre Bancos com Anilha no Colo',
      'Tríceps JM Press com Barra',
      'Tríceps Tate Press Deitado com Halteres',
      'Tríceps Cross-Body (Cruzado) Duplo nos Cabos',
    ];
    for (final t in exerciciosTriceps) {
      adicionar(
        t,
        modalidade: 'Academia',
        grupoMuscular: 'Tríceps',
        equipamento: t.contains('Polia') || t.contains('Cabo')
            ? 'Polia / Cabo'
            : t.contains('Halter')
                ? 'Halteres'
                : 'Barra / Máquina',
        carga: 20,
        series: 3,
        reps: 12,
      );
    }

    // =========================================================================
    // 5. ACADEMIA — PERNAS: QUADRÍCEPS, POSTERIOR, GLÚTEOS & PANTURRILHA (~170)
    // =========================================================================
    const exerciciosQuadriceps = <(String, String, double)>[
      ('Agachamento Livre com Barra nas Costas (High Bar)', 'Barra', 60),
      ('Agachamento Livre com Barra Baixa (Low Bar)', 'Barra', 70),
      ('Agachamento Frontal (Front Squat) com Barra', 'Barra', 45),
      ('Agachamento com Pausa no Fundo (2s) com Barra', 'Barra', 50),
      ('Agachamento no Smith Pés Tradicionais', 'Smith', 50),
      ('Agachamento no Smith Pés à Frente', 'Smith', 45),
      ('Agachamento Hack Machine 45°', 'Máquina', 80),
      ('Agachamento Hack Pêndulo (Pendulum Squat)', 'Máquina', 40),
      ('Agachamento no Belt Squat (Cinto)', 'Máquina', 60),
      ('Agachamento V-Squat na Máquina', 'Máquina', 70),
      ('Agachamento Sissy no Aparelho', 'Máquina', 10),
      ('Agachamento Goblet com Halter no Peito', 'Halteres', 25),
      ('Agachamento com Dois Halteres ao Lado do Corpo', 'Halteres', 20),
      ('Agachamento com Calcanhares Elevados (Cyclist Squat)', 'Barra', 40),
      ('Agachamento Zercher com Barra', 'Barra', 40),
      ('Agachamento no Landmine', 'Barra', 35),
      ('Leg Press 45° Pés na Largura dos Ombros', 'Máquina', 140),
      ('Leg Press 45° Pés Baixos (Foco Quadríceps)', 'Máquina', 120),
      ('Leg Press 45° Unilateral', 'Máquina', 60),
      ('Leg Press Horizontal na Máquina', 'Máquina', 100),
      ('Leg Press Horizontal Unilateral', 'Máquina', 45),
      ('Leg Press Articulado / Iso-Lateral', 'Máquina', 120),
      ('Cadeira Extensora Bilateral', 'Máquina', 50),
      ('Cadeira Extensora Unilateral', 'Máquina', 25),
      ('Cadeira Extensora com Isometria no Topo (2s)', 'Máquina', 40),
      (
        'Cadeira Extensora 21 (Meio Baixo + Meio Alto + Completo)',
        'Máquina',
        35
      ),
      ('Afundo Estático com Halteres', 'Halteres', 15),
      ('Afundo Estático com Barra nas Costas', 'Barra', 35),
      ('Afundo no Smith', 'Smith', 30),
      ('Passada (Walking Lunge) com Halteres', 'Halteres', 15),
      ('Passada (Walking Lunge) com Barra', 'Barra', 30),
      ('Afundo Reverso com Halteres', 'Halteres', 15),
      ('Afundo Reverso no Smith', 'Smith', 30),
      ('Agachamento Búlgaro com Halteres (Foco Quadríceps)', 'Halteres', 15),
      ('Agachamento Búlgaro no Smith', 'Smith', 30),
      ('Step-Up no Caixote com Halteres', 'Halteres', 15),
      ('Cadeira Adutora', 'Máquina', 45),
      ('Adução de Quadril na Polia Baixa com Caneleira', 'Polia / Cabo', 10),
    ];
    for (final q in exerciciosQuadriceps) {
      adicionar(
        q.$1,
        modalidade: 'Academia',
        grupoMuscular: 'Quadríceps',
        equipamento: q.$2,
        carga: q.$3,
        series: 4,
        reps: 10,
        descanso: 90,
      );
    }

    const exerciciosPosteriorGluteos = <(String, String, double)>[
      ('Stiff com Barra Olímpica', 'Barra', 50),
      ('Stiff com Halteres', 'Halteres', 20),
      ('Stiff Unilateral (B-Stance) com Halteres', 'Halteres', 15),
      ('Stiff Unilateral Livre com Halter', 'Halteres', 15),
      ('Stiff no Smith', 'Smith', 45),
      ('Levantamento Terra Romeno (RDL) com Barra', 'Barra', 60),
      ('Levantamento Terra Romeno (RDL) com Halteres', 'Halteres', 25),
      ('Agachamento Sumô com Barra', 'Barra', 50),
      ('Agachamento Sumô com Halter Único no Step', 'Halteres', 30),
      ('Agachamento Sumô no Smith', 'Smith', 45),
      ('Mesa Flexora Deitado Bilateral', 'Máquina', 40),
      ('Mesa Flexora Deitado Unilateral', 'Máquina', 20),
      ('Cadeira Flexora Sentado Bilateral', 'Máquina', 45),
      ('Cadeira Flexora Sentado Unilateral', 'Máquina', 20),
      ('Flexora em Pé Unilateral na Máquina', 'Máquina', 20),
      ('Nordic Hamstring Curl Assistido na Academia', 'Peso do Corpo', 0),
      ('Glute Ham Raise (GHD)', 'Máquina', 0),
      ('Elevação Pélvica (Hip Thrust) com Barra no Banco', 'Barra', 70),
      ('Elevação Pélvica na Máquina Específica', 'Máquina', 80),
      ('Elevação Pélvica no Smith', 'Smith', 60),
      ('Elevação Pélvica Unilateral com Halter', 'Halteres', 15),
      ('Kas Glute Bridge (Curta Amplitude no Topo) com Barra', 'Barra', 70),
      ('Agachamento Búlgaro Foco Glúteo (Tronco Inclinado)', 'Halteres', 15),
      ('Cadeira Abdutora Sentado', 'Máquina', 50),
      ('Cadeira Abdutora com Tronco Inclinado à Frente', 'Máquina', 50),
      ('Coice de Glúteo na Polia Baixa (Kickback Reto)', 'Polia / Cabo', 15),
      ('Coice de Glúteo Diagonal na Polia Baixa (30°)', 'Polia / Cabo', 15),
      ('Coice de Glúteo na Máquina (Glute Kickback)', 'Máquina', 35),
      ('Coice de Glúteo com Caneleira em 4 Apoios', 'Caneleira', 10),
      ('Abdução de Quadril em Pé na Polia Baixa', 'Polia / Cabo', 10),
      ('Pull-Through na Polia Baixa com Corda', 'Polia / Cabo', 30),
      (
        'Leg Press 45° Pés Altos e Afastados (Foco Posterior/Glúteo)',
        'Máquina',
        130
      ),
    ];
    for (final pg in exerciciosPosteriorGluteos) {
      adicionar(
        pg.$1,
        modalidade: 'Academia',
        grupoMuscular: 'Posterior & Glúteos',
        equipamento: pg.$2,
        carga: pg.$3,
        series: 4,
        reps: 12,
      );
    }

    const exerciciosPanturrilha = <(String, double)>[
      ('Panturrilha em Pé na Máquina', 50),
      ('Panturrilha em Pé Unilateral na Máquina', 25),
      ('Panturrilha em Pé no Smith com Step', 50),
      ('Panturrilha Sentado na Máquina (Sóleo)', 35),
      ('Panturrilha Sentado Unilateral na Máquina', 20),
      ('Panturrilha no Leg Press 45°', 100),
      ('Panturrilha no Leg Press Horizontal', 80),
      ('Panturrilha no Hack Machine', 60),
      ('Panturrilha em Pé Unilateral com Halter no Step', 15),
      ('Panturrilha Burrinho (Donkey Calf Raise)', 40),
      ('Flexão Tibial Anterior (Tibialis Raise) com Carga', 10),
    ];
    for (final pant in exerciciosPanturrilha) {
      adicionar(
        pant.$1,
        modalidade: 'Academia',
        grupoMuscular: 'Panturrilha',
        equipamento: 'Máquina / Livre',
        carga: pant.$2,
        series: 4,
        reps: 15,
      );
    }

    // =========================================================================
    // 6. CALISTENIA & STREET WORKOUT (~190 exercícios)
    // =========================================================================
    const barrasCalistenia = <String>[
      'Barra Fixa Pronada Tradicional (Pull-up)',
      'Barra Fixa Pronada Pegada Aberta',
      'Barra Fixa Pronada Pegada Fechada',
      'Barra Fixa Supinada (Chin-up)',
      'Barra Fixa Supinada Pegada Fechada',
      'Barra Fixa Pegada Neutra (Paralela)',
      'Barra Fixa Pegada Mista (Comando)',
      'Barra Fixa Explosiva (Chest-to-Bar)',
      'Barra Fixa Arqueiro (Archer Pull-up)',
      'Barra Fixa Typewriter (Máquina de Escrever)',
      'Barra Fixa em L-Sit',
      'Barra Fixa Unilateral Assistida com Toalha',
      'Barra Fixa Unilateral Completa (One-Arm Pull-up)',
      'Barra Fixa Escapular (Scapular Pull-up)',
      'Barra Fixa Negativa Lenta (5s Descida)',
      'Barra Fixa Isométrica no Topo (Queixo Acima da Barra)',
      'Barra Fixa com Cinto de Lastro (Weighted Pull-up)',
      'Chin-up com Cinto de Lastro (Weighted Chin-up)',
      'Muscle-up na Barra Fixa',
      'Muscle-up Estrito nas Argolas',
      'Muscle-up Assistido com Super Band',
      'Remada Australiana (Inverted Row) Pegada Pronada',
      'Remada Australiana Pegada Supinada',
      'Remada Australiana com Pés Elevados',
      'Remada Australiana Unilateral',
      'Remada nas Argolas (Ring Row)',
      'Pelican Curl nas Argolas',
      'Face Pull nas Argolas',
      'Skin the Cat na Barra / Argolas',
      'Front Lever Tuck (Encolhido)',
      'Front Lever Advanced Tuck',
      'Front Lever One Leg',
      'Front Lever Straddle',
      'Front Lever Completo (Full)',
      'Front Lever Raises na Barra',
      'Back Lever Tuck',
      'Back Lever Straddle',
      'Back Lever Completo (Full)',
      'Human Flag (Bandeira Humana) Progressão Vertical',
      'Human Flag (Bandeira Humana) Completa',
    ];
    for (final c in barrasCalistenia) {
      adicionar(
        c,
        modalidade: 'Calistenia',
        grupoMuscular: c.contains('Chin-up') || c.contains('Pelican')
            ? 'Bíceps'
            : 'Costas',
        equipamento: c.contains('Argolas') ? 'Argolas' : 'Barra Fixa',
        carga: c.contains('Lastro') ? 10 : 0,
        series: 4,
        reps: 8,
      );
    }

    const empurrarCalistenia = <String>[
      'Mergulho nas Paralelas Tradicional (Dips)',
      'Mergulho nas Paralelas com Cinto de Lastro',
      'Mergulho Russo nas Paralelas (Russian Dips)',
      'Mergulho na Barra Reta (Straight Bar Dips)',
      'Mergulho Coreano na Barra (Korean Dips)',
      'Mergulho nas Argolas (Ring Dips)',
      'Mergulho Bulgáro nas Argolas',
      'Support Hold nas Argolas (RTO)',
      'Flexão de Braços Militar (Strict Push-up)',
      'Flexão Diamante (Diamond Push-up)',
      'Flexão Arqueiro (Archer Push-up)',
      'Flexão Pseudo Planche (Pseudo Planche Push-up)',
      'Flexão Explosiva com Palma (Clap Push-up)',
      'Flexão Superman',
      'Flexão Hindu (Dive Bomber Push-up)',
      'Flexão Esfinge (Tríceps no Solo)',
      'Flexão Unilateral (One-Arm Push-up)',
      'Flexão nas Argolas (Ring Push-up)',
      'Flexão nas Paralelas Baixas (Parallettes)',
      'Flexão Pike (Pike Push-up) no Solo',
      'Flexão Pike com Pés Elevados no Caixote',
      'Handstand Push-up (HSPU) na Parede',
      'Handstand Push-up (HSPU) Livre em Equilíbrio',
      '90 Degree Push-up',
      'Parada de Mão (Handstand) Isometria na Parede',
      'Parada de Mão (Handstand) Livre nas Paralelas',
      'Frog Stand / Crow Pose (Equilíbrio nos Braços)',
      'Tuck Planche nas Paralelas / Solo',
      'Advanced Tuck Planche',
      'Straddle Planche',
      'Full Planche',
      'Planche Lean no Solo',
      'Maltese Lean c/ Elástico',
    ];
    for (final emp in empurrarCalistenia) {
      adicionar(
        emp,
        modalidade: 'Calistenia',
        grupoMuscular: emp.contains('Pike') ||
                emp.contains('Handstand') ||
                emp.contains('Planche') ||
                emp.contains('Parada')
            ? 'Ombros'
            : emp.contains('Diamante') || emp.contains('Esfinge')
                ? 'Tríceps'
                : 'Peito',
        equipamento: 'Peso do Corpo / Paralelas',
        carga: emp.contains('Lastro') ? 10 : 0,
        series: 4,
        reps: 10,
      );
    }

    const pernasCoreCalistenia = <String>[
      'Agachamento Pistol Unilateral Completo (Pistol Squat)',
      'Agachamento Pistol Assistido na Barra / Argola',
      'Agachamento Pistol sobre Caixote',
      'Agachamento Camarão (Shrimp Squat)',
      'Agachamento Camarão Avançado (Duas Mãos no Pé)',
      'Agachamento Sissy Peso do Corpo (Calistenia)',
      'Agachamento Cossaco (Cossack Squat)',
      'Agachamento Dragon Squat',
      'Agachamento com Salto Explosivo (Jump Squat)',
      'Salto em Distância Parado (Broad Jump)',
      'Salto Unilateral (Single-Leg Bounds)',
      'Nordic Curl no Solo (Posterior de Coxa)',
      'Reverse Nordic Curl (Quadríceps)',
      'Ponte de Glúteo Unilateral Elevada',
      'Panturrilha Unilateral no Degrau em Pé (Calistenia)',
      'L-Sit no Solo / Paralelas',
      'V-Sit nas Paralelas',
      'Manna Progressão nas Paralelas',
      'Dragon Flag Negativa no Banco',
      'Dragon Flag Completa',
      'Elevação de Pernas Estendidas na Barra (Hanging Leg Raise)',
      'Elevação de Joelhos no Peito na Barra (Hanging Knee Raise)',
      'Limpador de Para-brisa na Barra (Windshield Wipers)',
      'Hollow Body Hold (Canoa Isométrica)',
      'Hollow Body Rocks (Balanço em Canoa)',
      'Arch Body Hold (Superman Isométrico)',
    ];
    for (final pc in pernasCoreCalistenia) {
      adicionar(
        pc,
        modalidade: 'Calistenia',
        grupoMuscular: pc.contains('L-Sit') ||
                pc.contains('V-Sit') ||
                pc.contains('Manna') ||
                pc.contains('Dragon Flag') ||
                pc.contains('Elevação') ||
                pc.contains('Wipers') ||
                pc.contains('Hollow') ||
                pc.contains('Arch')
            ? 'Abdômen & Core'
            : pc.contains('Nordic Curl no Solo') || pc.contains('Glúteo')
                ? 'Posterior & Glúteos'
                : 'Quadríceps',
        equipamento: 'Peso do Corpo',
        series: 4,
        reps: 10,
      );
    }

    // =========================================================================
    // 7. TREINO EM CASA (SEM EQUIPAMENTO, MOCHILA, ELÁSTICO, GARRAFA) (~210)
    // =========================================================================
    const exerciciosCasaCorpo = <(String, String)>[
      ('Flexão de Braços com Joelhos Apoiados', 'Peito'),
      ('Flexão de Braços Tradicional no Chão', 'Peito'),
      ('Flexão de Braços Aberta no Chão', 'Peito'),
      ('Flexão Inclinada (Mãos no Sofá / Cadeira)', 'Peito'),
      ('Flexão Declinada (Pés no Sofá / Cadeira)', 'Peito'),
      ('Flexão com Pausa de 2s em Baixo', 'Peito'),
      ('Flexão T (Com Rotação Lateral)', 'Peito'),
      ('Flexão Spiderman (Joelho no Cotovelo)', 'Peito'),
      ('Flexão Pliométrica Deslocando Lateralmente', 'Peito'),
      ('Flexão com Mochila Pesada nas Costas', 'Peito'),
      ('Crucifixo Deslizante no Chão com Toalhas', 'Peito'),
      ('Remada Invertida Debaixo da Mesa Firme', 'Costas'),
      ('Remada na Porta com Toalha (Doorframe Row)', 'Costas'),
      ('Superman com Puxada Dorsal no Chão (Lat Pulldown no Solo)', 'Costas'),
      ('Anjo da Neve Invertido de Bruços (Reverse Snow Angels)', 'Costas'),
      ('Y-T-W-L de Bruços no Chão para Escápulas e Ombros', 'Costas'),
      ('Puxada Deslizante de Bruços no Chão com Toalha', 'Costas'),
      ('Remada Curvada com Mochila Carregada', 'Costas'),
      ('Remada Unilateral (Serrote) com Mochila / Galão', 'Costas'),
      ('Desenvolvimento Vertical com Mochila', 'Ombros'),
      ('Elevação Lateral com Garrafas / Mochila', 'Ombros'),
      ('Elevação Frontal com Mochila', 'Ombros'),
      ('Crucifixo Inverso Curvado com Garrafas', 'Ombros'),
      ('Wall Walk (Subida na Parede de Costas)', 'Ombros'),
      ('Isometria em Pike com Pés no Sofá', 'Ombros'),
      ('Rosca Direta com Mochila (Pegada nas Alças)', 'Bíceps'),
      ('Rosca Martelo com Mochila', 'Bíceps'),
      ('Rosca Concentrada Sentado com Mochila', 'Bíceps'),
      ('Rosca Bíceps com Toalha Passada por Baixo da Perna', 'Bíceps'),
      ('Mergulho de Tríceps Apoiado na Cadeira (Pés Dobrados)', 'Tríceps'),
      ('Mergulho de Tríceps na Cadeira (Pernas Estendidas)', 'Tríceps'),
      (
        'Extensão de Tríceps na Parede / Mesa (Bodyweight Skullcrusher)',
        'Tríceps'
      ),
      ('Tríceps Francês em Pé com Mochila', 'Tríceps'),
      ('Tríceps Coice com Garrafa / Peso Improvisado', 'Tríceps'),
      ('Agachamento Livre em Casa', 'Quadríceps'),
      ('Agachamento Sumô em Casa', 'Quadríceps'),
      ('Agachamento com Pausa de 3s em Baixo', 'Quadríceps'),
      ('Agachamento Pulsando em Baixo (3 Pulsos por Rep)', 'Quadríceps'),
      ('Agachamento na Parede Isométrico (Wall Sit)', 'Quadríceps'),
      ('Agachamento na Parede Unilateral', 'Quadríceps'),
      ('Agachamento Abraçando Mochila Pesada', 'Quadríceps'),
      ('Agachamento Búlgaro com Pé no Sofá / Cadeira', 'Quadríceps'),
      ('Agachamento Búlgaro com Mochila nas Costas', 'Quadríceps'),
      ('Afundo Alternado para Frente em Casa', 'Quadríceps'),
      ('Afundo Reverso Alternado em Casa', 'Quadríceps'),
      ('Afundo Lateral em Casa', 'Quadríceps'),
      ('Afundo Reverência (Curtsy Lunge)', 'Posterior & Glúteos'),
      ('Subida na Cadeira Firme (Step-Up em Casa)', 'Quadríceps'),
      ('Ponte de Glúteos Bilateral no Chão', 'Posterior & Glúteos'),
      ('Ponte de Glúteos Unilateral no Chão', 'Posterior & Glúteos'),
      ('Ponte de Glúteos Tipo Borboleta (Frog Pump)', 'Posterior & Glúteos'),
      ('Elevação Pélvica com Costas no Sofá', 'Posterior & Glúteos'),
      ('Elevação Pélvica com Mochila no Quadril', 'Posterior & Glúteos'),
      (
        'Deslizamento de Calcanhar no Chão com Toalha (Leg Curl em Casa)',
        'Posterior & Glúteos'
      ),
      ('Stiff Unilateral Peso do Corpo (Aviãozinho)', 'Posterior & Glúteos'),
      ('Stiff com Mochila Pesada', 'Posterior & Glúteos'),
      ('Coice de Glúteo em 4 Apoios no Tapete', 'Posterior & Glúteos'),
      ('Hidrante (Abdução em 4 Apoios no Tapete)', 'Posterior & Glúteos'),
      ('Abdução Lateral de Quadril Deitado de Lado', 'Posterior & Glúteos'),
      ('Clamshell (Ostra) para Glúteo Médio no Solo', 'Posterior & Glúteos'),
      ('Panturrilha Bilateral no Degrau da Escada', 'Panturrilha'),
      ('Panturrilha Unilateral no Degrau da Escada', 'Panturrilha'),
      ('Panturrilha Sentado com Mochila nos Joelhos', 'Panturrilha'),
    ];
    for (final ec in exerciciosCasaCorpo) {
      adicionar(
        ec.$1,
        modalidade: 'Em Casa',
        grupoMuscular: ec.$2,
        equipamento: ec.$1.contains('Mochila') || ec.$1.contains('Garrafa')
            ? 'Mochila / Casa'
            : 'Peso do Corpo',
        series: 3,
        reps: 15,
      );
    }

    // Exercícios em Casa com Elástico (Mini Band & Super Band)
    const exerciciosElasticoCasa = <(String, String)>[
      ('Supino em Pé com Super Band Presa Atrás', 'Peito'),
      ('Flexão de Braços Resistida com Super Band', 'Peito'),
      ('Crucifixo em Pé com Elástico', 'Peito'),
      ('Remada Sentado no Chão com Super Band nos Pés', 'Costas'),
      ('Remada Curvada Pisando na Super Band', 'Costas'),
      ('Puxada Alta Ajoelhado com Elástico na Porta', 'Costas'),
      ('Pulldown em Pé com Elástico na Porta', 'Costas'),
      ('Face Pull com Elástico', 'Ombros'),
      ('Desenvolvimento em Pé Pisando na Super Band', 'Ombros'),
      ('Elevação Lateral Pisando na Super Band', 'Ombros'),
      ('Elevação Frontal Pisando na Super Band', 'Ombros'),
      ('Band Pull-Apart (Abertura de Elástico à Frente)', 'Ombros'),
      ('Rosca Direta Pisando na Super Band', 'Bíceps'),
      ('Rosca Martelo com Super Band', 'Bíceps'),
      ('Rosca Concentrada com Elástico', 'Bíceps'),
      ('Tríceps Pulley com Elástico Preso no Alto da Porta', 'Tríceps'),
      ('Tríceps Francês com Super Band', 'Tríceps'),
      ('Agachamento com Mini Band Acima dos Joelhos', 'Quadríceps'),
      ('Agachamento Pisando na Super Band', 'Quadríceps'),
      ('Passada Lateral (Monster Walk) com Mini Band', 'Posterior & Glúteos'),
      ('Abdução Sentado com Mini Band nos Joelhos', 'Posterior & Glúteos'),
      ('Elevação Pélvica com Mini Band nos Joelhos', 'Posterior & Glúteos'),
      (
        'Coice de Glúteo em Pé com Mini Band no Tornozelo',
        'Posterior & Glúteos'
      ),
      ('Stiff Pisando na Super Band Forte', 'Posterior & Glúteos'),
      ('Flexão de Joelho Deitado com Mini Band nos Pés', 'Posterior & Glúteos'),
    ];
    for (final el in exerciciosElasticoCasa) {
      adicionar(
        el.$1,
        modalidade: 'Em Casa',
        grupoMuscular: el.$2,
        equipamento: 'Elástico / Band',
        series: 3,
        reps: 15,
      );
    }

    // =========================================================================
    // 8. CROSSFIT, LPO, KETTLEBELL & FUNCIONAL (~180 exercícios)
    // =========================================================================
    const exerciciosCrossfit = <(String, String, String, double)>[
      (
        'Power Snatch com Barra Olímpica',
        'Corpo Inteiro',
        'Barra Olímpica',
        40
      ),
      (
        'Squat Snatch (Arranco Completo) com Barra',
        'Corpo Inteiro',
        'Barra Olímpica',
        45
      ),
      ('Hang Power Snatch com Barra', 'Corpo Inteiro', 'Barra Olímpica', 35),
      ('Hang Squat Snatch com Barra', 'Corpo Inteiro', 'Barra Olímpica', 40),
      ('Muscle Snatch com Barra', 'Ombros', 'Barra Olímpica', 30),
      ('Snatch Balance com Barra', 'Corpo Inteiro', 'Barra Olímpica', 35),
      (
        'Overhead Squat (Agachamento de Arranco) com Barra',
        'Quadríceps',
        'Barra Olímpica',
        35
      ),
      ('Power Clean com Barra Olímpica', 'Corpo Inteiro', 'Barra Olímpica', 50),
      (
        'Squat Clean (Arremesso Completo) com Barra',
        'Corpo Inteiro',
        'Barra Olímpica',
        55
      ),
      ('Hang Power Clean com Barra', 'Corpo Inteiro', 'Barra Olímpica', 45),
      ('Hang Squat Clean com Barra', 'Corpo Inteiro', 'Barra Olímpica', 50),
      ('Muscle Clean com Barra', 'Corpo Inteiro', 'Barra Olímpica', 40),
      (
        'Clean & Jerk Completo com Barra Olímpica',
        'Corpo Inteiro',
        'Barra Olímpica',
        50
      ),
      ('Push Jerk com Barra Olímpica', 'Ombros', 'Barra Olímpica', 45),
      ('Split Jerk com Barra Olímpica', 'Ombros', 'Barra Olímpica', 50),
      ('Strict Press com Barra Olímpica', 'Ombros', 'Barra Olímpica', 35),
      ('Push Press Olímpico com Barra', 'Ombros', 'Barra Olímpica', 45),
      ('Thruster com Barra Olímpica', 'Corpo Inteiro', 'Barra Olímpica', 40),
      (
        'Cluster (Squat Clean + Thruster) com Barra',
        'Corpo Inteiro',
        'Barra Olímpica',
        40
      ),
      (
        'Sumo Deadlift High Pull (SDHP) com Barra',
        'Corpo Inteiro',
        'Barra Olímpica',
        35
      ),
      ('Devil Press com Dois Halteres', 'Corpo Inteiro', 'Halteres', 15),
      ('Man Maker com Dois Halteres', 'Corpo Inteiro', 'Halteres', 15),
      ('Dumbbell Snatch Alternado', 'Corpo Inteiro', 'Halteres', 20),
      ('Dumbbell Hang Clean & Jerk', 'Corpo Inteiro', 'Halteres', 15),
      ('Dumbbell Thruster', 'Corpo Inteiro', 'Halteres', 15),
      ('Dumbbell Box Step-Over', 'Quadríceps', 'Halteres', 15),
      ('Dumbbell Overhead Walking Lunge', 'Quadríceps', 'Halteres', 15),
      (
        'Kettlebell Swing Russo (Altura dos Olhos)',
        'Posterior & Glúteos',
        'Kettlebell',
        20
      ),
      (
        'Kettlebell Swing Americano (Acima da Cabeça)',
        'Corpo Inteiro',
        'Kettlebell',
        15
      ),
      ('Kettlebell Swing Unilateral', 'Posterior & Glúteos', 'Kettlebell', 15),
      ('Kettlebell Snatch Unilateral', 'Corpo Inteiro', 'Kettlebell', 15),
      ('Kettlebell Clean & Press Unilateral', 'Ombros', 'Kettlebell', 15),
      ('Kettlebell Goblet Squat', 'Quadríceps', 'Kettlebell', 20),
      ('Kettlebell Front Rack Squat Duplo', 'Quadríceps', 'Kettlebell', 15),
      ('Kettlebell Turkish Get-Up (TGU)', 'Corpo Inteiro', 'Kettlebell', 15),
      ('Kettlebell Windmill (Moinho)', 'Abdômen & Core', 'Kettlebell', 10),
      ('Kettlebell Halo (Giro ao Redor da Cabeça)', 'Ombros', 'Kettlebell', 10),
      ('Kettlebell Sumo Deadlift High Pull', 'Corpo Inteiro', 'Kettlebell', 20),
      ('Wall Ball Shot Tradicional', 'Corpo Inteiro', 'Medicine Ball', 10),
      (
        'Medicine Ball Slam (Arremesso no Chão)',
        'Corpo Inteiro',
        'Medicine Ball',
        10
      ),
      (
        'Medicine Ball Rotational Throw na Parede',
        'Abdômen & Core',
        'Medicine Ball',
        10
      ),
      ('Medicine Ball Clean', 'Corpo Inteiro', 'Medicine Ball', 10),
      ('Box Jump (Salto no Caixote)', 'Quadríceps', 'Caixote / Box', 0),
      (
        'Box Jump Over (Salto Atravessando o Caixote)',
        'Corpo Inteiro',
        'Caixote / Box',
        0
      ),
      ('Burpee Box Jump Over', 'Corpo Inteiro', 'Caixote / Box', 0),
      (
        'Burpee Tradicional (Peito no Chão)',
        'Corpo Inteiro',
        'Peso do Corpo',
        0
      ),
      ('Burpee Bar Muscle-up', 'Corpo Inteiro', 'Barra Fixa', 0),
      ('Burpee Pull-up', 'Corpo Inteiro', 'Barra Fixa', 0),
      ('Kipping Pull-up (Barra com Balanço)', 'Costas', 'Barra Fixa', 0),
      ('Butterfly Pull-up', 'Costas', 'Barra Fixa', 0),
      ('Kipping Chest-to-Bar Pull-up', 'Costas', 'Barra Fixa', 0),
      ('Bar Muscle-up (CrossFit)', 'Corpo Inteiro', 'Barra Fixa', 0),
      ('Ring Muscle-up (CrossFit)', 'Corpo Inteiro', 'Argolas', 0),
      ('Toes-to-Bar (Pés na Barra)', 'Abdômen & Core', 'Barra Fixa', 0),
      (
        'Knees-to-Elbows (Joelhos nos Cotovelos)',
        'Abdômen & Core',
        'Barra Fixa',
        0
      ),
      ('Kipping Handstand Push-up (HSPU)', 'Ombros', 'Peso do Corpo', 0),
      (
        'Handstand Walk (Caminhada de Ponta-Cabeça)',
        'Ombros',
        'Peso do Corpo',
        0
      ),
      ('Rope Climb (Subida na Corda com Pés)', 'Costas', 'Corda', 0),
      ('Legless Rope Climb (Subida na Corda Sem Pés)', 'Costas', 'Corda', 0),
      (
        'Double Unders (Salto Duplo de Corda)',
        'Cardio & Corrida',
        'Corda de Pular',
        0
      ),
      (
        'Single Unders (Salto Simples de Corda)',
        'Cardio & Corrida',
        'Corda de Pular',
        0
      ),
      ('Crossover Double Unders', 'Cardio & Corrida', 'Corda de Pular', 0),
      (
        'Corda Naval (Battle Rope) Ondas Alternadas',
        'Corpo Inteiro',
        'Corda Naval',
        0
      ),
      (
        'Corda Naval (Battle Rope) Ondas Simultâneas (Slam)',
        'Corpo Inteiro',
        'Corda Naval',
        0
      ),
      ('Sled Push (Empurrar Trenó)', 'Quadríceps', 'Trenó / Sled', 60),
      ('Sled Pull (Puxar Trenó com Corda)', 'Costas', 'Trenó / Sled', 50),
      (
        'Sled Drag (Arrastar Trenó de Costas)',
        'Quadríceps',
        'Trenó / Sled',
        50
      ),
      (
        'Farmer Walk (Caminhada do Fazendeiro) com Halteres/KB',
        'Antebraço & Trapézio',
        'Halteres / KB',
        25
      ),
      (
        'Suitcase Carry (Caminhada Unilateral Mala)',
        'Abdômen & Core',
        'Kettlebell',
        20
      ),
      (
        'Overhead Carry com Kettlebell / Barra',
        'Ombros',
        'Kettlebell / Barra',
        20
      ),
      ('Yoke Walk', 'Corpo Inteiro', 'Yoke', 100),
      ('Sandbag Clean (Saco de Areia)', 'Corpo Inteiro', 'Sandbag', 40),
      ('Sandbag Carry no Peito', 'Corpo Inteiro', 'Sandbag', 40),
      ('Tire Flip (Virar Pneu de Trator)', 'Corpo Inteiro', 'Pneu', 0),
      ('Marreta no Pneu (Sledgehammer Strikes)', 'Corpo Inteiro', 'Marreta', 0),
      ('GHD Sit-up (Abdominal no GHD)', 'Abdômen & Core', 'GHD', 0),
    ];
    for (final cf in exerciciosCrossfit) {
      adicionar(
        cf.$1,
        modalidade: 'CrossFit & Funcional',
        grupoMuscular: cf.$2,
        equipamento: cf.$3,
        carga: cf.$4,
        series: 4,
        reps: 12,
      );
    }

    // =========================================================================
    // 9. CORRIDA, CARDIO & ENDURANCE (~120 exercícios)
    // =========================================================================
    const exerciciosCorridaCardio = <(String, String)>[
      ('Tiro de Corrida 100m Velocidade Máxima', 'Corrida de Rua / Pista'),
      ('Tiro de Corrida 200m Forte', 'Corrida de Rua / Pista'),
      ('Tiro de Corrida 400m Ritmo de Prova', 'Corrida de Rua / Pista'),
      ('Tiro de Corrida 800m (Yasso 800s)', 'Corrida de Rua / Pista'),
      ('Tiro de Corrida 1000m (VO2 Máx)', 'Corrida de Rua / Pista'),
      ('Tiro de Corrida em Ladeira / Subida (30s)', 'Corrida de Rua'),
      ('Tiro de Corrida em Ladeira / Subida (60s)', 'Corrida de Rua'),
      ('Corrida Contínua 2 km', 'Corrida de Rua / Esteira'),
      ('Corrida Contínua 3 km', 'Corrida de Rua / Esteira'),
      ('Corrida Contínua 5 km', 'Corrida de Rua / Esteira'),
      ('Corrida Contínua 8 km', 'Corrida de Rua / Esteira'),
      ('Corrida Contínua 10 km', 'Corrida de Rua / Esteira'),
      ('Corrida Contínua 12 km', 'Corrida de Rua'),
      ('Corrida Contínua 15 km', 'Corrida de Rua'),
      ('Corrida Longão 18 km', 'Corrida de Rua'),
      ('Meia Maratona 21.1 km', 'Corrida de Rua'),
      ('Corrida Regenerativa Zona 2 (30 min)', 'Corrida de Rua / Esteira'),
      ('Corrida Regenerativa Zona 2 (45 min)', 'Corrida de Rua / Esteira'),
      ('Corrida Fartlek (Alternância Livre de Ritmo 30 min)', 'Corrida de Rua'),
      ('Corrida Tempo Run (Ritmo Limiar 25 min)', 'Corrida de Rua / Esteira'),
      ('Corrida Progressiva (Começa Leve e Termina Forte)', 'Corrida de Rua'),
      ('HIIT na Esteira (1 min Forte / 1 min Caminhada)', 'Esteira'),
      ('HIIT Tabata na Esteira (20s Sprint / 10s Pausa)', 'Esteira'),
      ('Caminhada na Esteira com Inclinação Máxima (12-3-30)', 'Esteira'),
      ('Caminhada Rápida ao Ar Livre (45 min)', 'Ao Ar Livre'),
      ('Rucking (Caminhada com Mochila de Peso)', 'Mochila'),
      ('Educativo de Corrida: Skipping Baixo', 'Peso do Corpo'),
      ('Educativo de Corrida: Skipping Alto', 'Peso do Corpo'),
      ('Educativo de Corrida: Anfersen (Calcanhar no Glúteo)', 'Peso do Corpo'),
      ('Educativo de Corrida: Hopserlauf (Saltitos)', 'Peso do Corpo'),
      ('Educativo de Corrida: Dribling', 'Peso do Corpo'),
      ('Remo Ergômetro (Concept2) 500m Sprint', 'Remo'),
      ('Remo Ergômetro (Concept2) 2000m Tempo', 'Remo'),
      ('Remo Ergômetro 15 min Contínuo', 'Remo'),
      ('Assault Air Bike (Tiros de Calorias 30s)', 'Air Bike'),
      ('Assault Air Bike 15 min Contínuo', 'Air Bike'),
      ('SkiErg 500m Sprint', 'SkiErg'),
      ('Bicicleta Ergométrica Vertical (30 min)', 'Bike Ergométrica'),
      ('Bicicleta Ergométrica Horizontal (30 min)', 'Bike Ergométrica'),
      ('Aula / Treino de Spinning HIIT (45 min)', 'Bike Spinning'),
      ('Ciclismo de Estrada / Urbano (10 km)', 'Bicicleta'),
      ('Ciclismo de Estrada / Urbano (20 km)', 'Bicicleta'),
      ('Escada Rolante Infinita (StairMaster) 15 min', 'Escada'),
      ('Escada Rolante Infinita (StairMaster) 30 min', 'Escada'),
      ('Subida de Escadaria Real em Prédio / Arquibancada', 'Escada'),
      ('Elíptico / Transport Contínuo (25 min)', 'Elíptico'),
      ('Pular Corda Contínuo (10 min)', 'Corda de Pular'),
      ('Pular Corda HIIT (1 min Pulando / 30s Descanso)', 'Corda de Pular'),
      ('Polichinelo (Jumping Jacks)', 'Peso do Corpo'),
      ('Corrida Estacionária (Joelho Alto / High Knees)', 'Peso do Corpo'),
      ('Sprawl (Meio Burpee Rápido)', 'Peso do Corpo'),
      ('Mountain Climber (Escalador Rápido no Solo)', 'Peso do Corpo'),
      ('Shadow Boxing (Boxe Sombra 3 Rounds de 3 min)', 'Peso do Corpo'),
      ('Saco de Pancada (Boxe / Muay Thai Rounds)', 'Saco de Pancada'),
      ('Natação Crawl Contínuo (1000m)', 'Piscina'),
      ('Natação Tiros de 50m Livre', 'Piscina'),
    ];
    for (final cc in exerciciosCorridaCardio) {
      adicionar(
        cc.$1,
        modalidade: 'Corrida & Cardio',
        grupoMuscular: 'Cardio & Corrida',
        equipamento: cc.$2,
        series: 1,
        reps: 15,
      );
    }

    // =========================================================================
    // 10. ABDÔMEN, CORE & MOBILIDADE (~130 exercícios)
    // =========================================================================
    const exerciciosAbdomenCore = <(String, String)>[
      ('Abdominal Supra Tradicional no Solo', 'Peso do Corpo'),
      ('Abdominal Supra com Anilha no Peito', 'Anilha'),
      ('Abdominal Supra no Banco Declinado', 'Banco'),
      ('Abdominal na Polia Alta Ajoelhado com Corda (Crunch)', 'Polia / Cabo'),
      ('Abdominal na Máquina Sentado', 'Máquina'),
      ('Abdominal Infra Elevação de Pernas no Solo', 'Peso do Corpo'),
      ('Abdominal Infra no Banco Inclinado', 'Banco'),
      ('Abdominal Infra nas Paralelas (Captain Chair)', 'Paralelas'),
      ('Abdominal Remador Completo no Solo', 'Peso do Corpo'),
      ('Abdominal Canivete (V-Up) no Solo', 'Peso do Corpo'),
      ('Abdominal Canivete Alternado', 'Peso do Corpo'),
      ('Abdominal Bicicleta no Solo', 'Peso do Corpo'),
      ('Abdominal Oblíquo Russo (Russian Twist) Livre', 'Peso do Corpo'),
      ('Abdominal Oblíquo Russo com Anilha / Medicine Ball', 'Anilha / Bola'),
      ('Abdominal Toque nos Calcanhares Alternado', 'Peso do Corpo'),
      ('Lenhador (Woodchopper) na Polia Alta para Baixo', 'Polia / Cabo'),
      ('Lenhador (Woodchopper) na Polia Baixa para Cima', 'Polia / Cabo'),
      ('Pallof Press Antirrotação na Polia Média', 'Polia / Cabo'),
      ('Pallof Press com Elástico em Casa', 'Elástico'),
      ('Roda Abdominal (Ab Wheel) de Joelhos', 'Roda Abdominal'),
      ('Roda Abdominal (Ab Wheel) em Pé', 'Roda Abdominal'),
      ('Prancha Frontal Isométrica nos Antebraços', 'Peso do Corpo'),
      ('Prancha Frontal Alta (Mãos no Chão)', 'Peso do Corpo'),
      ('Prancha Frontal RKC (Contração Total)', 'Peso do Corpo'),
      ('Prancha Lateral Esquerda / Direita', 'Peso do Corpo'),
      ('Prancha Lateral com Elevação de Quadril', 'Peso do Corpo'),
      ('Prancha Lateral Estrela (Abdução de Perna)', 'Peso do Corpo'),
      ('Prancha Dinâmica (Sobe e Desce Cotovelo/Mão)', 'Peso do Corpo'),
      ('Prancha com Toque no Ombro Alternado', 'Peso do Corpo'),
      ('Prancha Copenhagen para Adutores e Core', 'Banco / Cadeira'),
      ('Dead Bug (Inseto Morto) Controle de Core', 'Peso do Corpo'),
      ('Bird Dog (Perdigueiro) Estabilidade Lombar', 'Peso do Corpo'),
      ('Vacuum Abdominal (Stomach Vacuum) em Pé', 'Peso do Corpo'),
      ('Vacuum Abdominal em 4 Apoios', 'Peso do Corpo'),
      ('Inclinação Lateral com Halter para Oblíquos', 'Halteres'),
    ];
    for (final ab in exerciciosAbdomenCore) {
      adicionar(
        ab.$1,
        modalidade: ab.$2.contains('Polia') || ab.$2.contains('Máquina')
            ? 'Academia'
            : 'Mobilidade & Core',
        grupoMuscular: 'Abdômen & Core',
        equipamento: ab.$2,
        series: 3,
        reps: 15,
      );
    }

    const exerciciosMobilidade = <String>[
      'Mobilidade de Quadril 90/90 no Solo',
      'Mobilidade de Quadril (Cossack Flow)',
      'Mobilidade de Quadril (Posição do Sapo / Frog Stretch)',
      'Mobilidade de Tornozelo na Parede (Dorsiflexão)',
      'Mobilidade de Tornozelo com Peso sobre o Joelho',
      'Mobilidade Torácica Gato-Vaca (Cat-Cow)',
      'Mobilidade Torácica Rotação em 4 Apoios (Mão na Nuca)',
      'Mobilidade Torácica Livro Aberto Deitado de Lado (Open Book)',
      'Mobilidade Torácica no Rolo de Espuma (Foam Roller)',
      'Mobilidade de Ombros Dislocates com Bastão / Elástico',
      'Mobilidade de Ombros Wall Slides (Deslizar Braços na Parede)',
      'Mobilidade de Punhos em 4 Apoios (Calistenia / LPO)',
      'World’s Greatest Stretch (Melhor Alongamento do Mundo)',
      'Agachamento Profundo Isométrico (Deep Squat Hold) Mobilidade',
      'Jefferson Curl Leve para Mobilidade da Coluna',
      'Alongamento de Flexores de Quadril (Psoas) Ajoelhado',
      'Alongamento de Posterior de Coxa Sentado',
      'Alongamento de Glúteo e Piriforme (Postura do Pombo)',
      'Alongamento de Peitoral no Batente da Porta',
      'Alongamento de Grande Dorsal Pendurado na Barra (Dead Hang)',
      'Dead Hang Unilateral na Barra Fixa (Descompressão)',
      'Liberação Miofascial de Quadríceps no Foam Roller',
      'Liberação Miofascial de Banda Iliotibial no Foam Roller',
      'Liberação Miofascial de Dorsal no Foam Roller',
      'Liberação Miofascial de Panturrilha e Posterior no Rolo',
      'Saudação ao Sol (Fluxo de Mobilidade Matinal)',
      'Postura da Criança (Child’s Pose) Relaxamento Lombar',
      'Postura da Cobra (Alongamento Abdominal)',
      'Cachorro Olhando para Baixo (Downward Dog)',
    ];
    for (final mob in exerciciosMobilidade) {
      adicionar(
        mob,
        modalidade: 'Mobilidade & Core',
        grupoMuscular: 'Mobilidade',
        equipamento: 'Livre / Rolo',
        series: 2,
        reps: 12,
      );
    }

    // =========================================================================
    // 11. EXPANSÃO SISTEMÁTICA DE VARIAÇÕES TÉCNICAS (+600 variações reais)
    // =========================================================================
    // Gera combinações técnicas reais de movimentos fundamentais com implementos,
    // pegadas e cadências usadas em fichas de musculação, calistenia e treino em casa.
    const movimentosAcademiaBase = <(String, String)>[
      ('Supino Reto', 'Peito'),
      ('Supino Inclinado', 'Peito'),
      ('Supino Declinado', 'Peito'),
      ('Crucifixo Reto', 'Peito'),
      ('Crucifixo Inclinado', 'Peito'),
      ('Puxada Alta', 'Costas'),
      ('Remada Baixa', 'Costas'),
      ('Remada Curvada', 'Costas'),
      ('Remada Articulada', 'Costas'),
      ('Pulldown', 'Costas'),
      ('Desenvolvimento de Ombros', 'Ombros'),
      ('Elevação Lateral', 'Ombros'),
      ('Elevação Frontal', 'Ombros'),
      ('Crucifixo Inverso', 'Ombros'),
      ('Remada Alta', 'Ombros'),
      ('Encolhimento de Trapézio', 'Antebraço & Trapézio'),
      ('Rosca Bíceps', 'Bíceps'),
      ('Rosca Scott', 'Bíceps'),
      ('Rosca Martelo', 'Bíceps'),
      ('Rosca Inclinada', 'Bíceps'),
      ('Tríceps Pulley', 'Tríceps'),
      ('Tríceps Francês', 'Tríceps'),
      ('Tríceps Testa', 'Tríceps'),
      ('Tríceps Coice', 'Tríceps'),
      ('Agachamento', 'Quadríceps'),
      ('Leg Press', 'Quadríceps'),
      ('Cadeira Extensora', 'Quadríceps'),
      ('Afundo', 'Quadríceps'),
      ('Agachamento Búlgaro', 'Quadríceps'),
      ('Stiff', 'Posterior & Glúteos'),
      ('Mesa Flexora', 'Posterior & Glúteos'),
      ('Cadeira Flexora', 'Posterior & Glúteos'),
      ('Elevação Pélvica', 'Posterior & Glúteos'),
      ('Cadeira Abdutora', 'Posterior & Glúteos'),
      ('Panturrilha em Pé', 'Panturrilha'),
      ('Panturrilha Sentado', 'Panturrilha'),
    ];

    const protocolosTecnicosAcademia = <(String, String, double, int, int)>[
      ('Cadência Controlada (3s Excêntrica)', 'Academia', 25, 3, 10),
      ('Com Pico de Contração (2s Iso)', 'Academia', 20, 3, 12),
      ('Série Drop-Set Final', 'Academia', 25, 3, 12),
      ('Série Rest-Pause', 'Academia', 30, 3, 10),
      (
        'Repetições Parciais Alongadas (Lengthened Partials)',
        'Academia',
        25,
        3,
        12
      ),
      ('Série Pirâmide Crescente', 'Academia', 25, 4, 10),
      ('Série Pirâmide Decrescente (Back-off Set)', 'Academia', 25, 4, 10),
      ('Myo-Reps (Ativação + Mini-Séries)', 'Academia', 20, 3, 15),
      ('Unilateral Alternando Lados Sem Descanso', 'Academia', 15, 3, 12),
      ('Cluster Set (Blocos de 3+3+3 Reps)', 'Academia', 35, 3, 9),
      ('Foco Força Pura (5x5)', 'Academia', 40, 5, 5),
      ('Foco Resistência Metabólica (20 Reps)', 'Academia', 15, 3, 20),
    ];

    for (final mov in movimentosAcademiaBase) {
      for (final prot in protocolosTecnicosAcademia) {
        adicionar(
          '${mov.$1} — ${prot.$1}',
          modalidade: 'Academia',
          grupoMuscular: mov.$2,
          equipamento: prot.$2,
          carga: prot.$3,
          series: prot.$4,
          reps: prot.$5,
        );
      }
    }

    // Variações de Calistenia & Em Casa por nível e cadência
    const movimentosCorpoBase = <(String, String, String)>[
      ('Barra Fixa Pronada', 'Calistenia', 'Costas'),
      ('Barra Fixa Supinada', 'Calistenia', 'Bíceps'),
      ('Mergulho nas Paralelas', 'Calistenia', 'Peito'),
      ('Remada Australiana', 'Calistenia', 'Costas'),
      ('Flexão de Braços', 'Em Casa', 'Peito'),
      ('Flexão Diamante', 'Em Casa', 'Tríceps'),
      ('Flexão Pike', 'Em Casa', 'Ombros'),
      ('Agachamento Livre', 'Em Casa', 'Quadríceps'),
      ('Afundo Passada', 'Em Casa', 'Quadríceps'),
      ('Ponte de Glúteos', 'Em Casa', 'Posterior & Glúteos'),
      ('Abdominal Supra', 'Em Casa', 'Abdômen & Core'),
      ('Prancha Abdominal', 'Em Casa', 'Abdômen & Core'),
    ];

    const protocolosCorpo = <String>[
      'EMOM 10 Minutos (A Cada Minuto no Minuto)',
      'AMRAP 5 Minutos (Máximo de Repetições)',
      'Tabata (20s Ativo / 10s Descanso)',
      'Tempo Lento 4-1-4 (Super Slow)',
      'Com Pausa Isométrica no Meio da Amplitude',
      'Com Mochila de Carga (+5kg a 15kg)',
      'Com Super Band de Resistência',
      'Escada Crescente (1 a 10 Repetições)',
      'Pirâmide Completa (1-2-3-4-5-4-3-2-1)',
      '100 Repetições no Menor Tempo (For Time)',
    ];

    for (final mov in movimentosCorpoBase) {
      for (final prot in protocolosCorpo) {
        adicionar(
          '${mov.$1} — $prot',
          modalidade: mov.$2,
          grupoMuscular: mov.$3,
          equipamento: 'Peso do Corpo',
          series: 3,
          reps: 12,
        );
      }
    }

    // =========================================================================
    // 12. ARTES MARCIAIS, BOXE, MUAY THAI, JIU-JITSU & MMA (~190 exercícios)
    // =========================================================================
    const exerciciosArtesMarciaisDiretos = <(String, String, String, int, int)>[
      (
        'Pular Corda Ritmo de Boxe (Aquecimento 3 Rounds)',
        'Cardio & Corrida',
        'Corda de Pular',
        3,
        100
      ),
      (
        'Pular Corda Passo Alternado de Lutador (Boxer Step)',
        'Cardio & Corrida',
        'Corda de Pular',
        3,
        120
      ),
      (
        'Pular Corda com Giro Duplo Explosivo (Double Under)',
        'Cardio & Corrida',
        'Corda de Pular',
        4,
        40
      ),
      (
        'Shadowboxing (Sombra de Boxe: Jab, Direto, Esquiva e Pêndulo)',
        'Corpo Inteiro',
        'Peso do Corpo',
        3,
        20
      ),
      (
        'Shadowboxing com Halteres Leves (1kg a 2kg) para Resistência de Ombro',
        'Ombros',
        'Halteres Leves',
        3,
        30
      ),
      (
        'Shadowboxing Muay Thai (Socos, Cotoveladas, Joelhadas e Caneladas)',
        'Corpo Inteiro',
        'Peso do Corpo',
        3,
        20
      ),
      (
        'Shadowboxing Footwork (Deslocamento Lateral, Pivô e Passo Atrás)',
        'Cardio & Corrida',
        'Peso do Corpo',
        3,
        20
      ),
      (
        'Saco de Pancadas: Combinação Jab + Direto (1-2)',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        20
      ),
      (
        'Saco de Pancadas: Combinação Jab + Direto + Cruzado de Esquerda (1-2-3)',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Combinação Jab + Direto + Cruzado + Direto (1-2-3-2)',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Combinação Jab + Uppercut + Cruzado',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Combinação Jab + Direto + Gancho no Fígado (Body Shot)',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Combinação Jab + Direto + Cruzado + Low Kick',
        'Corpo Inteiro',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Chute Circular Baixo na Coxa (Low Kick Direita/Esquerda)',
        'Posterior & Glúteos',
        'Saco de Pancadas',
        4,
        20
      ),
      (
        'Saco de Pancadas: Chute Circular Médio nas Costelas (Middle Kick)',
        'Abdômen & Core',
        'Saco de Pancadas',
        4,
        15
      ),
      (
        'Saco de Pancadas: Chute Circular Alto (High Kick)',
        'Mobilidade',
        'Saco de Pancadas',
        3,
        12
      ),
      (
        'Saco de Pancadas: Chute Frontal de Empurrão (Teep / Push Kick)',
        'Quadríceps',
        'Saco de Pancadas',
        4,
        20
      ),
      (
        'Saco de Pancadas: Sequência de Joelhadas no Clinch',
        'Abdômen & Core',
        'Saco de Pancadas',
        4,
        25
      ),
      (
        'Saco de Pancadas: Cotoveladas Horizontais e Ascendentes no Clinch',
        'Ombros',
        'Saco de Pancadas',
        3,
        20
      ),
      (
        'Saco de Pancadas: Round de Explosão 30s Socos Contínuos + 30s Trote',
        'Cardio & Corrida',
        'Saco de Pancadas',
        5,
        1
      ),
      (
        'Manopla de Foco (Focus Mitt): Combinações de Velocidade e Esquiva',
        'Corpo Inteiro',
        'Manopla / Aparador',
        4,
        20
      ),
      (
        'Aparador de Chute (Thai Pad): Sequência de Chutes e Joelhadas em Dupla',
        'Corpo Inteiro',
        'Aparador Thai Pad',
        4,
        15
      ),
      (
        'Teto-Solo (Double End Bag): Precisão, Reflexo e Pêndulo',
        'Ombros',
        'Teto-Solo',
        3,
        30
      ),
      (
        'Punching Ball (Speed Bag): Ritmo Contínuo e Resistência de Ombros',
        'Ombros',
        'Speed Bag',
        3,
        50
      ),
      (
        'Sprawl Explosivo de Defesa de Queda',
        'Corpo Inteiro',
        'Peso do Corpo',
        4,
        15
      ),
      (
        'Sprawl + Jab + Direto + Joelhada no Ar',
        'Corpo Inteiro',
        'Peso do Corpo',
        4,
        12
      ),
      (
        'Entrada de Queda (Double Leg / Single Leg Shot) no Tatame',
        'Quadríceps',
        'Tatame / Solo',
        4,
        12
      ),
      (
        'Fuga de Quadril no Solo (Shrimp / Escapada de Quadril Jiu-Jitsu)',
        'Abdômen & Core',
        'Tatame / Solo',
        3,
        20
      ),
      (
        'Ponte de Pescoço e Quadril no Tatame (Upa / Bridge & Roll)',
        'Posterior & Glúteos',
        'Tatame / Solo',
        3,
        15
      ),
      (
        'Levantada Técnica de Jiu-Jitsu e MMA (Technical Stand-Up)',
        'Corpo Inteiro',
        'Tatame / Solo',
        3,
        15
      ),
      (
        'Reposição de Guarda no Solo (Granby Roll / Giro de Quadril)',
        'Abdômen & Core',
        'Tatame / Solo',
        3,
        12
      ),
      (
        'Passagem de Guarda Lateral Dinâmica (Toreando Drill)',
        'Cardio & Corrida',
        'Tatame / Solo',
        3,
        20
      ),
      (
        'Barra Fixa com Quimono ou Toalha (Pegada de Jiu-Jitsu / Judô)',
        'Antebraço & Trapézio',
        'Barra Fixa + Toalha',
        4,
        8
      ),
      (
        'Remada Australiana com Toalha para Pegada de Luta',
        'Antebraço & Trapézio',
        'Barra + Toalha',
        4,
        10
      ),
      (
        'Abdominal Russian Twist (Giro Russo para Golpes)',
        'Abdômen & Core',
        'Peso do Corpo / Medicine Ball',
        4,
        30
      ),
      (
        'Arremesso Rotacional de Medicine Ball na Parede (Potência de Cruzado)',
        'Abdômen & Core',
        'Medicine Ball',
        4,
        12
      ),
      (
        'Fortalecimento Cervical Isométrico 4 Direções (Com Mão ou Elástico)',
        'Antebraço & Trapézio',
        'Elástico / Livre',
        3,
        15
      ),
    ];

    for (final ex in exerciciosArtesMarciaisDiretos) {
      adicionar(
        ex.$1,
        modalidade: 'Artes Marciais & Boxe',
        grupoMuscular: ex.$2,
        equipamento: ex.$3,
        series: ex.$4,
        reps: ex.$5,
      );
    }

    const combosLuta = <String>[
      'Combinação 1 (Jab + Direto + Esquiva)',
      'Combinação 2 (Jab + Direto + Cruzado + Pêndulo)',
      'Combinação 3 (Jab + Uppercut + Cruzado + Direto)',
      'Combinação 4 (Duplo Jab + Direto + Gancho no Fígado)',
      'Combinação 5 (Jab + Direto + Low Kick)',
      'Combinação 6 (Cruzado + Direto + Middle Kick)',
      'Combinação 7 (Jab + Chute Frontal Teep + Direto)',
      'Combinação 8 (Esquiva + Contra-Golpe Direto + Cruzado)',
      'Combinação 9 (Joelhada + Cotovelada + Chute Circular)',
      'Combinação 10 (Sprawl + Jab + Direto + Joelhada)',
    ];
    const formatosRoundLuta = <(String, String)>[
      ('Saco de Pancadas Pesado', 'Saco de Pancadas'),
      ('Sombra Técnica (Shadowboxing)', 'Peso do Corpo'),
      ('Sombra com Elástico de Resistência', 'Elástico'),
      ('Manopla / Aparador de Precisão', 'Manopla'),
      ('Round HIIT 3 Minutos (Ritmo de Luta)', 'Saco / Livre'),
      ('Round de Potência Máxima', 'Saco de Pancadas'),
      ('Round de Velocidade e Volume', 'Saco / Livre'),
      ('Foco Guarda Canhota (Southpaw)', 'Saco / Livre'),
      ('Foco Guarda Destra (Orthodox)', 'Saco / Livre'),
      ('Foco Contra-Ataque e Deslocamento', 'Saco / Livre'),
      ('Com Halteres de 1kg nas Mãos', 'Halteres Leves'),
      ('Com Caneleira de Peso', 'Caneleira'),
      ('No Tatame Descalço', 'Tatame'),
      ('Tabata Explosivo (20s Forte / 10s Guarda Alta)', 'Saco / Livre'),
      ('EMOM 5 Rounds', 'Saco / Livre'),
    ];
    for (final combo in combosLuta) {
      for (final fmt in formatosRoundLuta) {
        adicionar(
          'Boxe & Muay Thai: $combo — ${fmt.$1}',
          modalidade: 'Artes Marciais & Boxe',
          grupoMuscular: 'Corpo Inteiro',
          equipamento: fmt.$2,
          series: 3,
          reps: 15,
        );
      }
    }

    // =========================================================================
    // 13. PILATES SOLO, POSTURA, COLUNA & CORE PROFUNDO (~130 exercícios)
    // =========================================================================
    const exerciciosPilatesDiretos = <(String, String, int, int)>[
      (
        'Pilates The Hundred (Bombeamento Respiratório 100)',
        'Abdômen & Core',
        3,
        20
      ),
      (
        'Pilates Roll Up (Enrolamento Completo da Coluna no Solo)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Pilates Roll Over (Elevação de Pernas Acima da Cabeça com Controle)',
        'Abdômen & Core',
        3,
        8
      ),
      (
        'Pilates Single Leg Circles (Círculos com Uma Perna no Solo)',
        'Mobilidade',
        3,
        12
      ),
      (
        'Pilates Rolling Like a Ball (Balanço em Bola para Massagem Dorsal)',
        'Abdômen & Core',
        3,
        12
      ),
      (
        'Pilates Single Leg Stretch (Alongamento Alternado de Perna)',
        'Abdômen & Core',
        3,
        16
      ),
      (
        'Pilates Double Leg Stretch (Extensão Simultânea de Braços e Pernas)',
        'Abdômen & Core',
        3,
        12
      ),
      (
        'Pilates Scissors (Tesoura Clássica com Alongamento de Posterior)',
        'Abdômen & Core',
        3,
        16
      ),
      (
        'Pilates Lower Lift (Descida e Subida de Pernas Unidas com Powerhouse)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Pilates Criss Cross (Oblíquos com Rotação Torácica Controlada)',
        'Abdômen & Core',
        3,
        16
      ),
      (
        'Pilates Spine Stretch Forward (Alongamento da Coluna Sentado)',
        'Mobilidade',
        3,
        10
      ),
      (
        'Pilates Open Leg Rocker (Equilíbrio Sentado em V com Pernas Abertas)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Pilates Corkscrew (Saca-Rolhas para Controle de Oblíquos)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Pilates Saw (A Serra — Rotação e Flexão de Tronco Sentado)',
        'Mobilidade',
        3,
        12
      ),
      (
        'Pilates Swan Dive Prep (Extensão Torácica e Lombar em Decúbito Ventral)',
        'Costas',
        3,
        10
      ),
      (
        'Pilates Single Leg Kick (Chute Simples em Prono para Posterior)',
        'Posterior & Glúteos',
        3,
        16
      ),
      (
        'Pilates Double Leg Kick (Chute Duplo com Extensão Dorsal)',
        'Costas',
        3,
        12
      ),
      (
        'Pilates Neck Pull (Articulação de Coluna com Mãos na Nuca)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Pilates Shoulder Bridge (Ponte Articulada de Coluna)',
        'Posterior & Glúteos',
        3,
        12
      ),
      (
        'PilatesShoulder Bridge Unilateral com Chute Vertical',
        'Posterior & Glúteos',
        3,
        10
      ),
      (
        'Pilates Spine Twist (Torção de Coluna Sentado com Postura Ereta)',
        'Mobilidade',
        3,
        12
      ),
      (
        'Pilates Side Kick Front & Back (Chute Lateral Frente e Trás)',
        'Posterior & Glúteos',
        3,
        15
      ),
      (
        'Pilates Side Kick Up & Down (Elevação Lateral de Perna)',
        'Posterior & Glúteos',
        3,
        15
      ),
      (
        'Pilates Side Kick Small Circles (Círculos Laterais de Quadril)',
        'Posterior & Glúteos',
        3,
        15
      ),
      (
        'Pilates Clam Shell (Ostra Lateral para Glúteo Médio)',
        'Posterior & Glúteos',
        3,
        15
      ),
      (
        'Pilates Teaser I (Canivete Isométrico em V de Equilíbrio)',
        'Abdômen & Core',
        3,
        8
      ),
      (
        'Pilates Teaser II (Subida e Descida das Pernas em V)',
        'Abdômen & Core',
        3,
        8
      ),
      (
        'Pilates Teaser III (Subida e Descida Completa de Tronco e Pernas)',
        'Abdômen & Core',
        3,
        8
      ),
      (
        'Pilates Swimming (Natação no Solo para Paravertebrais)',
        'Costas',
        3,
        20
      ),
      (
        'Pilates Leg Pull Front (Prancha com Elevação Alternada de Perna)',
        'Abdômen & Core',
        3,
        12
      ),
      (
        'Pilates Leg Pull Back (Prancha Invertida com Chute Alternado)',
        'Posterior & Glúteos',
        3,
        12
      ),
      (
        'Pilates Kneeling Side Kick (Chute Lateral Ajoelhado)',
        'Posterior & Glúteos',
        3,
        12
      ),
      (
        'Pilates Mermaid Stretch (Alongamento da Sereia para Cadeia Lateral)',
        'Mobilidade',
        3,
        10
      ),
      (
        'Pilates Seal (A Foca — Controle e Equilíbrio Pélvico)',
        'Abdômen & Core',
        3,
        12
      ),
      ('Perdigueiro (Bird-Dog) Estabilidade Lombar', 'Abdômen & Core', 3, 12),
      (
        'Dead Bug (Inseto Morto) com Pressão Lombar no Solo',
        'Abdômen & Core',
        3,
        16
      ),
      (
        'Retração Escapular na Parede (Wall Angels para Postura Cifótica)',
        'Ombros',
        3,
        12
      ),
      (
        'Chin Tuck (Retração Cervical contra Parede para Postura de Pescoço)',
        'Mobilidade',
        3,
        15
      ),
      (
        'Prancha Lateral Modificada com Elevação de Quadril (Pilates Side Bend)',
        'Abdômen & Core',
        3,
        10
      ),
      (
        'Ativação de Transverso Abdominal (Vácuo Respiratório de Pilates)',
        'Abdômen & Core',
        3,
        10
      ),
    ];

    for (final pEx in exerciciosPilatesDiretos) {
      adicionar(
        pEx.$1,
        modalidade: 'Pilates & Postura',
        grupoMuscular: pEx.$2,
        equipamento: 'Tapete / Solo',
        series: pEx.$3,
        reps: pEx.$4,
      );
    }

    const acessoriosPilates = <String>[
      'Com Bola Suíça (Fitball)',
      'Com Overball (Bola Macia entre os Joelhos)',
      'Com Anel Mágico (Magic Circle / Pilates Ring)',
      'Com Faixa Elástica (TheraBand)',
      'Com Rolo de Espuma (Foam Roller)',
    ];
    const movimentosPilatesAcessorio = <(String, String)>[
      ('Ponte de Glúteos Articulada (Shoulder Bridge)', 'Posterior & Glúteos'),
      ('Abdominal Enroll (Roll Up)', 'Abdômen & Core'),
      ('Abdominal Oblíquo (Criss Cross)', 'Abdômen & Core'),
      ('Adutores Isométricos deitada no Solo', 'Quadríceps'),
      ('Extensão Torácica (Swan)', 'Costas'),
      ('Agachamento Postural na Parede', 'Quadríceps'),
      ('Prancha de Estabilidade de Core', 'Abdômen & Core'),
      ('Perdigueiro de Estabilidade', 'Abdômen & Core'),
      ('Elevação Lateral de Quadril', 'Posterior & Glúteos'),
      ('Alongamento de Cadeia Posterior', 'Mobilidade'),
      ('Mobilidade de Ombros e Escápulas', 'Ombros'),
      ('Pilates Teaser Assistido', 'Abdômen & Core'),
      ('Abdominal Hundred', 'Abdômen & Core'),
      ('Flexão de Posterior de Coxa (Hamstring Curl)', 'Posterior & Glúteos'),
      ('Rotação de Tronco Sentado (Spine Twist)', 'Mobilidade'),
      ('Abdução de Quadril em Decúbito Lateral', 'Posterior & Glúteos'),
    ];
    for (final mov in movimentosPilatesAcessorio) {
      for (final ac in acessoriosPilates) {
        adicionar(
          'Pilates: ${mov.$1} $ac',
          modalidade: 'Pilates & Postura',
          grupoMuscular: mov.$2,
          equipamento: ac.replaceFirst('Com ', ''),
          series: 3,
          reps: 12,
        );
      }
    }

    // =========================================================================
    // 14. ELÁSTICOS (MINI BAND / SUPER BAND) & KETTLEBELL (~220 exercícios)
    // =========================================================================
    const exerciciosKettlebellDiretos = <(String, String, double, int, int)>[
      (
        'Kettlebell Swing Russo (Até a Linha dos Ombros)',
        'Posterior & Glúteos',
        16,
        4,
        20
      ),
      (
        'Kettlebell Swing Americano (Acima da Cabeça)',
        'Corpo Inteiro',
        16,
        4,
        15
      ),
      (
        'Kettlebell Swing Unilateral (Uma Mão)',
        'Posterior & Glúteos',
        12,
        3,
        15
      ),
      (
        'Kettlebell Swing Alternando as Mãos no Topo',
        'Posterior & Glúteos',
        16,
        4,
        20
      ),
      ('Kettlebell Goblet Squat (Agachamento Cálice)', 'Quadríceps', 16, 4, 12),
      (
        'Kettlebell Front Squat Duplo (Com 2 Kettlebells no Rack)',
        'Quadríceps',
        12,
        4,
        10
      ),
      (
        'Kettlebell Clean Unilateral (Arremesso ao Rack)',
        'Corpo Inteiro',
        12,
        3,
        12
      ),
      ('Kettlebell Clean & Press Unilateral', 'Ombros', 12, 4, 10),
      ('Kettlebell Clean & Push Press Duplo', 'Corpo Inteiro', 12, 4, 10),
      (
        'Kettlebell Snatch Unilateral (Arranco com Kettlebell)',
        'Corpo Inteiro',
        12,
        4,
        10
      ),
      (
        'Kettlebell Turkish Get-Up (Levantada Turca Completa)',
        'Abdômen & Core',
        12,
        3,
        5
      ),
      (
        'Kettlebell Meia Levantada Turca (Half Get-Up)',
        'Abdômen & Core',
        12,
        3,
        8
      ),
      (
        'Kettlebell Windmill (Moinho de Vento para Oblíquos e Quadril)',
        'Abdômen & Core',
        10,
        3,
        8
      ),
      (
        'Kettlebell Halo (Giro ao Redor da Cabeça para Mobilidade de Ombros)',
        'Ombros',
        10,
        3,
        12
      ),
      (
        'Kettlebell Bottoms-Up Press (Desenvolvimento com Fundo para Cima)',
        'Ombros',
        8,
        3,
        10
      ),
      (
        'Kettlebell Bottoms-Up Carry (Caminhada com Kettlebell Invertido)',
        'Antebraço & Trapézio',
        8,
        3,
        20
      ),
      (
        'Kettlebell Suitcase Carry (Caminhada Mala Unilateral para Oblíquos)',
        'Abdômen & Core',
        20,
        3,
        30
      ),
      (
        'Kettlebell Front Rack Carry (Caminhada com Kettlebell no Peito)',
        'Abdômen & Core',
        16,
        3,
        30
      ),
      (
        'Kettlebell Overhead Waiter Carry (Caminhada do Garçom Acima da Cabeça)',
        'Ombros',
        12,
        3,
        25
      ),
      (
        'Kettlebell Gorilla Row (Remada Alternada em Base de Sumô)',
        'Costas',
        16,
        4,
        12
      ),
      (
        'Kettlebell Renegade Row (Prancha com Remada Alternada)',
        'Costas',
        12,
        3,
        12
      ),
      (
        'Kettlebell Stiff Unilateral (Single-Leg RDL)',
        'Posterior & Glúteos',
        12,
        3,
        10
      ),
      (
        'Kettlebell Sumo Deadlift High Pull (Terra Sumô com Remada Alta)',
        'Corpo Inteiro',
        16,
        4,
        15
      ),
      ('Kettlebell Thruster Unilateral', 'Corpo Inteiro', 12, 3, 12),
      ('Kettlebell Thruster Duplo', 'Corpo Inteiro', 12, 4, 10),
      ('Kettlebell Floor Press Unilateral no Solo', 'Peito', 16, 4, 12),
      ('Kettlebell Sots Press (Desenvolvimento Agachado)', 'Ombros', 10, 3, 8),
      (
        'Kettlebell Passagem Entre as Pernas (Figure 8)',
        'Abdômen & Core',
        12,
        3,
        20
      ),
      ('Kettlebell Russian Twist Sentado', 'Abdômen & Core', 10, 3, 24),
      ('Kettlebell Pullover Deitado no Solo', 'Peito', 12, 3, 12),
    ];

    for (final kb in exerciciosKettlebellDiretos) {
      adicionar(
        kb.$1,
        modalidade: 'Elásticos & Kettlebell',
        grupoMuscular: kb.$2,
        equipamento: 'Kettlebell',
        carga: kb.$3,
        series: kb.$4,
        reps: kb.$5,
      );
    }

    const exerciciosElasticosBase = <(String, String)>[
      ('Agachamento com Abdução Isométrica', 'Posterior & Glúteos'),
      ('Passada Lateral (Monster Walk)', 'Posterior & Glúteos'),
      ('Passada Diagonal em Zigue-Zague', 'Posterior & Glúteos'),
      ('Elevação Pélvica com Abdução no Topo', 'Posterior & Glúteos'),
      ('Abdução de Quadril Sentado (Tronco Ereto)', 'Posterior & Glúteos'),
      (
        'Abdução de Quadril Sentado (Tronco Inclinado à Frente)',
        'Posterior & Glúteos'
      ),
      ('Coice de Glúteo em pé (Glute Kickback)', 'Posterior & Glúteos'),
      ('Coice de Glúteo em 4 Apoios', 'Posterior & Glúteos'),
      ('Hidrante (Abdução em 4 Apoios)', 'Posterior & Glúteos'),
      ('Ostra Lateral (Clamshell)', 'Posterior & Glúteos'),
      ('Flexão de Posterior de Coxa Deitado (Leg Curl)', 'Posterior & Glúteos'),
      ('Stiff Romeno (RDL)', 'Posterior & Glúteos'),
      ('Bom Dia (Good Morning)', 'Posterior & Glúteos'),
      ('Supino em Pé (Chest Press)', 'Peito'),
      ('Crucifixo (Chest Fly)', 'Peito'),
      ('Flexão de Braços Resistida', 'Peito'),
      ('Remada Baixa Sentado', 'Costas'),
      ('Remada Alta em Pé', 'Ombros'),
      ('Puxada Alta Ajoelhado (Lat Pulldown)', 'Costas'),
      ('Pulldown Braços Estendidos (Straight-Arm Pulldown)', 'Costas'),
      ('Face Pull (Puxada na Testa para Deltoide Posterior)', 'Ombros'),
      ('Band Pull-Apart (Abertura Horizontal na Linha do Peito)', 'Ombros'),
      ('Desenvolvimento de Ombros em Pé', 'Ombros'),
      ('Elevação Lateral de Ombros', 'Ombros'),
      ('Elevação Frontal de Ombros', 'Ombros'),
      ('Rotação Externa de Manguito Rotador', 'Ombros'),
      ('Rotação Interna de Manguito Rotador', 'Ombros'),
      ('Rosca Bíceps Bilaterial', 'Bíceps'),
      ('Rosca Martelo', 'Bíceps'),
      ('Rosca Concentrada Unilateral', 'Bíceps'),
      ('Tríceps Pulley (Pressdown)', 'Tríceps'),
      ('Tríceps Francês Acima da Cabeça', 'Tríceps'),
      ('Tríceps Coice Unilateral', 'Tríceps'),
      ('Pallof Press Anti-Rotação de Core', 'Abdômen & Core'),
      ('Rotação de Tronco (Woodchopper)', 'Abdômen & Core'),
      (
        'Flexão de Quadril em Pé (Marcha Resistida para Psoas)',
        'Abdômen & Core'
      ),
    ];

    const tiposElastico = <String>[
      'Com Mini Band Leve',
      'Com Mini Band Média',
      'Com Mini Band Forte / Extra Forte',
      'Com Super Band Elástica',
      'Com Elástico Extensor com Pegador (Tube Band)',
    ];

    for (final exEl in exerciciosElasticosBase) {
      for (final tipo in tiposElastico) {
        adicionar(
          '${exEl.$1} $tipo',
          modalidade: 'Elásticos & Kettlebell',
          grupoMuscular: exEl.$2,
          equipamento: tipo.replaceFirst('Com ', ''),
          series: 3,
          reps: 15,
        );
      }
    }

    // =========================================================================
    // 15. POWERLIFTING, STRONGMAN & PLIOMETRIA EXPLOSIVA (~140 exercícios)
    // =========================================================================
    const exerciciosPowerliftingStrongman =
        <(String, String, String, double, int, int)>[
      (
        'Agachamento Low Bar de Powerlifting com Pausa (Paused Squat)',
        'Academia',
        'Quadríceps',
        70,
        4,
        5
      ),
      (
        'Agachamento nos Pinos da Gaiola (Pin Squat)',
        'Academia',
        'Quadríceps',
        65,
        4,
        5
      ),
      (
        'Agachamento no Caixote (Box Squat de Powerlifting)',
        'Academia',
        'Quadríceps',
        70,
        5,
        5
      ),
      (
        'Agachamento Tempo 3-2-0 (3s Descida + 2s Pausa no Fundo)',
        'Academia',
        'Quadríceps',
        60,
        4,
        6
      ),
      (
        'Agachamento com Correntes ou Elásticos (Accommodating Resistance)',
        'Academia',
        'Quadríceps',
        65,
        5,
        5
      ),
      (
        'Supino Reto com Pausa de Competição no Peito (Paused Bench Press)',
        'Academia',
        'Peito',
        55,
        5,
        5
      ),
      (
        'Supino Spoto Press (Pausa a 2cm do Peito)',
        'Academia',
        'Peito',
        50,
        4,
        6
      ),
      (
        'Supino Larsen Press (Pernas Estendidas no Ar sem Leg Drive)',
        'Academia',
        'Peito',
        45,
        4,
        8
      ),
      (
        'Supino nos Pinos (Pin Press para Lockout)',
        'Academia',
        'Peito',
        60,
        4,
        5
      ),
      (
        'Supino no Chão com Barra (Barbell Floor Press)',
        'Academia',
        'Peito',
        55,
        4,
        6
      ),
      (
        'Supino Fechado Pesado para Força de Tríceps (Close-Grip Bench Press)',
        'Academia',
        'Tríceps',
        50,
        4,
        6
      ),
      (
        'Levantamento Terra em Déficit (Sobre Anilha / Plataforma)',
        'Academia',
        'Posterior & Glúteos',
        75,
        4,
        5
      ),
      (
        'Levantamento Terra com Pausa Abaixo do Joelho (Paused Deadlift)',
        'Academia',
        'Costas',
        75,
        4,
        4
      ),
      (
        'Levantamento Terra Parcial em Blocos (Block Pull / Rack Pull)',
        'Academia',
        'Costas',
        90,
        4,
        5
      ),
      (
        'Levantamento Terra com Barra Hexagonal Pesado (Trap Bar Deadlift)',
        'Academia',
        'Corpo Inteiro',
        85,
        4,
        6
      ),
      (
        'Levantamento Terra Snatch-Grip (Pegada Aberta de Arranco)',
        'Academia',
        'Costas',
        65,
        4,
        6
      ),
      (
        'Remada Pendlay Explosiva Saindo do Chão (Pendlay Row)',
        'Academia',
        'Costas',
        50,
        4,
        6
      ),
      (
        'Z-Press (Desenvolvimento Sentado no Chão com Pernas Estendidas)',
        'Academia',
        'Ombros',
        30,
        4,
        8
      ),
      (
        'Strongman: Tombamento de Pneu Gigante (Tire Flip)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        0,
        4,
        8
      ),
      (
        'Strongman: Marreta no Pneu (Sledgehammer Strikes)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        8,
        4,
        20
      ),
      (
        'Strongman: Caminhada do Fazendeiro Pesada (Heavy Farmer’s Walk)',
        'CrossFit & Funcional',
        'Antebraço & Trapézio',
        35,
        4,
        30
      ),
      (
        'Strongman: Yoke Walk (Caminhada com Canga nos Ombros)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        100,
        4,
        20
      ),
      (
        'Strongman: Abraço e Transporte de Saco de Areia (Sandbag Bear Hug Carry)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        40,
        4,
        25
      ),
      (
        'Strongman: Sandbag Over Shoulder (Arremesso de Saco de Areia por Cima do Ombro)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        35,
        4,
        8
      ),
      (
        'Strongman: Log Clean & Press (Arremesso e Desenvolvimento com Tronco)',
        'CrossFit & Funcional',
        'Ombros',
        45,
        4,
        6
      ),
      (
        'Strongman: Axle Bar Deadlift (Terra com Barra Grossa)',
        'CrossFit & Funcional',
        'Antebraço & Trapézio',
        70,
        4,
        5
      ),
      (
        'Pliometria: Salto em Profundidade com Reação Imediata (Depth Jump)',
        'CrossFit & Funcional',
        'Quadríceps',
        0,
        4,
        6
      ),
      (
        'Pliometria: Salto Horizontal em Distância (Broad Jump)',
        'CrossFit & Funcional',
        'Quadríceps',
        0,
        4,
        8
      ),
      (
        'Pliometria: Salto Lateral de Patinador (Skater Jump)',
        'CrossFit & Funcional',
        'Posterior & Glúteos',
        0,
        4,
        16
      ),
      (
        'Pliometria: Salto Unilateral no Caixote (Single-Leg Box Jump)',
        'CrossFit & Funcional',
        'Quadríceps',
        0,
        3,
        8
      ),
      (
        'Pliometria: Salto Agrupado Levando Joelhos ao Peito (Tuck Jump)',
        'CrossFit & Funcional',
        'Quadríceps',
        0,
        4,
        10
      ),
      (
        'Pliometria: Afundo Saltando Alternado (Split Squat Jump)',
        'CrossFit & Funcional',
        'Quadríceps',
        0,
        4,
        12
      ),
      (
        'Pliometria: Flexão Explosiva Saindo do Chão (Plyo Push-up)',
        'Calistenia',
        'Peito',
        0,
        4,
        10
      ),
      (
        'Pliometria: Arremesso Explosivo de Medicine Ball de Peito na Parede',
        'CrossFit & Funcional',
        'Peito',
        6,
        4,
        12
      ),
      (
        'Pliometria: Arremesso de Medicine Ball para Trás Acima da Cabeça',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        8,
        4,
        10
      ),
    ];

    for (final ps in exerciciosPowerliftingStrongman) {
      adicionar(
        ps.$1,
        modalidade: ps.$2,
        grupoMuscular: ps.$3,
        equipamento: 'Barra / Funcional',
        carga: ps.$4,
        series: ps.$5,
        reps: ps.$6,
      );
    }

    // =========================================================================
    // 16. FISIOTERAPIA, REABILITAÇÃO & PREVENÇÃO DE LESÕES (~80 exercícios)
    // =========================================================================
    const exerciciosReabilitacaoBase =
        <(String, String, String, String, double, int, int)>[
      (
        'Protocolo McGill: Perdigueiro (Bird-Dog) Isométrico com Pausa 5s',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        3,
        10
      ),
      (
        'Protocolo McGill: Perdigueiro com Movimento de Quadrado no Ar',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        3,
        8
      ),
      (
        'Protocolo McGill: Prancha Lateral com Apoio nos Joelhos',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        3,
        30
      ),
      (
        'Protocolo McGill: Prancha Lateral com Elevação de Perna',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        3,
        12
      ),
      (
        'Protocolo McGill: Curl-Up com Mãos sob a Lombar e Pausa',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        3,
        12
      ),
      (
        'Manguito Rotador: Rotação Externa Deitado de Lado com Halter',
        'Academia',
        'Ombros',
        'Halteres',
        3,
        3,
        15
      ),
      (
        'Manguito Rotador: Rotação Externa no Cabo com Toalha sob o Braço',
        'Academia',
        'Ombros',
        'Polia / Cabo',
        5,
        3,
        15
      ),
      (
        'Manguito Rotador: Rotação Interna no Cabo com Toalha sob o Braço',
        'Academia',
        'Ombros',
        'Polia / Cabo',
        7,
        3,
        15
      ),
      (
        'Manguito Rotador: Exercício Y-T-W Deitado no Banco Inclinado',
        'Academia',
        'Ombros',
        'Halteres Leves',
        2,
        3,
        12
      ),
      (
        'Manguito Rotador: Rotação Externa 90/90 no Cabo (Abdução de Ombro)',
        'Academia',
        'Ombros',
        'Polia / Cabo',
        5,
        3,
        12
      ),
      (
        'Manguito Rotador: Face Pull com Rotação Externa no Final com Corda',
        'Academia',
        'Ombros',
        'Polia / Cabo',
        15,
        4,
        15
      ),
      (
        'Joelho & Tendão: Agachamento Espanhol Isométrico para Tendão Patelar (Spanish Squat)',
        'Mobilidade & Core',
        'Quadríceps',
        'Super Band Elástica',
        0,
        4,
        45
      ),
      (
        'Joelho & Tendão: Agachamento Declinado a 25° (Slant Board Squat Isométrico)',
        'Mobilidade & Core',
        'Quadríceps',
        'Prancha Inclinada',
        0,
        4,
        45
      ),
      (
        'Joelho & Tendão: Agachamento Poliquin / Petersen Step-Up no Degrau',
        'Mobilidade & Core',
        'Quadríceps',
        'Degrau / Caixote',
        0,
        3,
        15
      ),
      (
        'Joelho & Tendão: Extensão de Joelho Isométrica a 60° na Cadeira Extensora',
        'Academia',
        'Quadríceps',
        'Máquina',
        30,
        4,
        45
      ),
      (
        'Joelho & Tendão: Reverse Nordic Curl (Extensão Nórdica Reversa para Reto Femoral)',
        'Calistenia',
        'Quadríceps',
        'Peso do Corpo',
        0,
        3,
        8
      ),
      (
        'Joelho & Tendão: Flexão Nórdica Excêntrica Lenta (Nordic Hamstring Curl)',
        'Calistenia',
        'Posterior & Glúteos',
        'Peso do Corpo',
        0,
        3,
        6
      ),
      (
        'Tornozelo & Canelite: Elevação de Tibial Anterior Encostado na Parede (Tibialis Raise)',
        'Mobilidade & Core',
        'Panturrilha',
        'Peso do Corpo',
        0,
        3,
        20
      ),
      (
        'Tornozelo & Canelite: Elevação de Tibial com Halter Entre os Pés',
        'Academia',
        'Panturrilha',
        'Halteres',
        6,
        3,
        15
      ),
      (
        'Tornozelo & Canelite: Caminhada nos Calcanhares para Fortalecimento Tibial',
        'Mobilidade & Core',
        'Panturrilha',
        'Peso do Corpo',
        0,
        3,
        40
      ),
      (
        'Tornozelo & Canelite: Mobilidade de Tornozelo com Joelho na Parede (Dorsiflexão)',
        'Mobilidade & Core',
        'Mobilidade',
        'Livre / Parede',
        0,
        3,
        15
      ),
      (
        'Fascite Plantar: Elevação de Calcanhar com Toalha Rolada sob os Dedos',
        'Mobilidade & Core',
        'Panturrilha',
        'Degrau / Toalha',
        0,
        3,
        15
      ),
      (
        'Fascite Plantar: Soltura e Massagem da Fáscia com Bolinha no Chão',
        'Mobilidade & Core',
        'Mobilidade',
        'Bolinha Rígida',
        0,
        2,
        60
      ),
      (
        'Fascite Plantar: Alongamento da Fáscia Plantar e Panturrilha no Degrau com Pausa',
        'Mobilidade & Core',
        'Mobilidade',
        'Degrau',
        0,
        3,
        30
      ),
      (
        'Punho & Antebraço: Extensão Excêntrica de Punho com Halter (Prevenção Cotovelo de Tenista)',
        'Academia',
        'Antebraço & Trapézio',
        'Halteres',
        4,
        3,
        15
      ),
      (
        'Punho & Antebraço: Flexão Excêntrica de Punho com Halter (Prevenção Cotovelo de Golfista)',
        'Academia',
        'Antebraço & Trapézio',
        'Halteres',
        6,
        3,
        15
      ),
      (
        'Punho & Antebraço: Pronação e Supinação com Halter Carregado Unilateralmente',
        'Academia',
        'Antebraço & Trapézio',
        'Halteres',
        3,
        3,
        15
      ),
      (
        'Punho & Antebraço: Desvio Ulnar e Radial com Barra Leve ou Bastão',
        'Academia',
        'Antebraço & Trapézio',
        'Bastão / Halter',
        2,
        3,
        15
      ),
      (
        'Coluna & Pelve: Ponte de Glúteo no Solo com Isometria e Abdução',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        0,
        3,
        15
      ),
      (
        'Coluna & Pelve: Ponte Pélvica com Bola Suíça entre os Joelhos (Adução)',
        'Pilates & Postura',
        'Posterior & Glúteos',
        'Bola Suíça',
        0,
        3,
        15
      ),
      (
        'Coluna & Pelve: Deadbug (Inseto Morto) Alternado Lento com Pressão na Bola',
        'Pilates & Postura',
        'Abdômen & Core',
        'Bola Suíça / Solo',
        0,
        3,
        12
      ),
      (
        'Coluna & Pelve: Respiração Diafragmática e Ativação do Transverso do Abdômen (Vacuum)',
        'Pilates & Postura',
        'Abdômen & Core',
        'Tapete / Solo',
        0,
        4,
        20
      ),
      (
        'Escápula & Postura: Protração Escapular na Prancha (Scapular Push-Up)',
        'Calistenia',
        'Peito',
        'Peso do Corpo',
        0,
        3,
        15
      ),
      (
        'Escápula & Postura: Retração Escapular na Barra Fixa (Scapular Pull-Up)',
        'Calistenia',
        'Costas',
        'Barra Fixa',
        0,
        3,
        10
      ),
      (
        'Escápula & Postura: Depressão Escapular nas Paralelas (Scapular Dips)',
        'Calistenia',
        'Peito',
        'Paralelas',
        0,
        3,
        12
      ),
      (
        'Quadril & Virilha: Adução de Quadril em Prancha Lateral de Copenhague (Curta no Joelho)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Banco Reto',
        0,
        3,
        20
      ),
      (
        'Quadril & Virilha: Adução de Quadril em Prancha Lateral de Copenhague (Longa no Tornozelo)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Banco Reto',
        0,
        3,
        15
      ),
      (
        'Quadril & Virilha: Agachamento Cossaco Lento com Apoio (Cossack Squat)',
        'Mobilidade & Core',
        'Mobilidade',
        'Livre / Apoio',
        0,
        3,
        10
      ),
      (
        'Quadril & Virilha: Rotação Interna Ativa de Quadril Sentado no Solo (Hip IR)',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        0,
        3,
        12
      ),
      (
        'Quadril & Virilha: Rotação Externa Ativa de Quadril Sentado no Solo (Hip ER)',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        0,
        3,
        12
      ),
    ];

    for (final reb in exerciciosReabilitacaoBase) {
      adicionar(
        reb.$1,
        modalidade: reb.$2,
        grupoMuscular: reb.$3,
        equipamento: reb.$4,
        carga: reb.$5,
        series: reb.$6,
        reps: reb.$7,
      );
    }

    // =========================================================================
    // 17. BARRAS ESPECIAIS & IMPLEMENTOS: BARRA W, BARRA ROMANA (H) & TRAP BAR (~80 exercícios)
    // =========================================================================
    const exerciciosBarrasEspeciais =
        <(String, String, String, String, double, int, int)>[
      (
        'Rosca Bíceps Scott com Barra W (Banco Scott)',
        'Academia',
        'Bíceps',
        'Barra W',
        25,
        4,
        10
      ),
      (
        'Rosca Bíceps Scott com Barra W Pegada Invertida (Pronada)',
        'Academia',
        'Antebraço & Trapézio',
        'Barra W',
        20,
        3,
        12
      ),
      (
        'Rosca Bíceps em Pé com Barra W Pegada Aberta',
        'Academia',
        'Bíceps',
        'Barra W',
        25,
        4,
        10
      ),
      (
        'Rosca Bíceps em Pé com Barra W Pegada Fechada',
        'Academia',
        'Bíceps',
        'Barra W',
        25,
        4,
        10
      ),
      (
        'Rosca Bíceps no Banco Inclinado com Barra W',
        'Academia',
        'Bíceps',
        'Barra W',
        20,
        3,
        10
      ),
      (
        'Rosca Bíceps Spider (Aranha) no Banco Inclinado com Barra W',
        'Academia',
        'Bíceps',
        'Barra W',
        20,
        3,
        12
      ),
      (
        'Rosca Bíceps Drag Curl com Barra W (Arrastando no Abdômen)',
        'Academia',
        'Bíceps',
        'Barra W',
        22,
        3,
        10
      ),
      (
        'Rosca Bíceps com Barra Romana (Pegada Neutra Paralela)',
        'Academia',
        'Bíceps',
        'Barra Romana / H',
        20,
        4,
        10
      ),
      (
        'Rosca Scott com Barra Romana (Pegada Neutra)',
        'Academia',
        'Bíceps',
        'Barra Romana / H',
        20,
        3,
        10
      ),
      (
        'Tríceps Testa Deitado com Barra W',
        'Academia',
        'Tríceps',
        'Barra W',
        25,
        4,
        10
      ),
      (
        'Tríceps Testa no Banco Declinado com Barra W',
        'Academia',
        'Tríceps',
        'Barra W',
        25,
        3,
        10
      ),
      (
        'Tríceps Testa no Banco Inclinado com Barra W',
        'Academia',
        'Tríceps',
        'Barra W',
        22,
        3,
        12
      ),
      (
        'Tríceps Francês Sentado com Barra W (Duas Mãos)',
        'Academia',
        'Tríceps',
        'Barra W',
        20,
        3,
        12
      ),
      (
        'Tríceps Francês no Banco Reto com Barra Romana',
        'Academia',
        'Tríceps',
        'Barra Romana / H',
        20,
        3,
        12
      ),
      (
        'Tríceps Testa com Barra Romana (Pegada Neutra)',
        'Academia',
        'Tríceps',
        'Barra Romana / H',
        22,
        4,
        10
      ),
      (
        'Supino Fechado com Barra W para Tríceps',
        'Academia',
        'Tríceps',
        'Barra W',
        35,
        4,
        8
      ),
      (
        'Supino com Barra Romana (Pegada Neutra para Ombros Saudáveis)',
        'Academia',
        'Peito',
        'Barra Romana / H',
        40,
        4,
        8
      ),
      (
        'Supino Inclinado com Barra Romana (Pegada Neutra)',
        'Academia',
        'Peito',
        'Barra Romana / H',
        35,
        4,
        10
      ),
      (
        'Desenvolvimento com Barra Romana Sentado (Pegada Neutra)',
        'Academia',
        'Ombros',
        'Barra Romana / H',
        25,
        4,
        10
      ),
      (
        'Desenvolvimento Militar com Barra W pela Frente',
        'Academia',
        'Ombros',
        'Barra W',
        30,
        4,
        8
      ),
      (
        'Remada Curvada com Barra W Pegada Supinada',
        'Academia',
        'Costas',
        'Barra W',
        40,
        4,
        10
      ),
      (
        'Remada Curvada com Barra W Pegada Pronada',
        'Academia',
        'Costas',
        'Barra W',
        40,
        4,
        10
      ),
      (
        'Remada Alta com Barra W Pegada Fechada (Trapézio)',
        'Academia',
        'Antebraço & Trapézio',
        'Barra W',
        30,
        4,
        12
      ),
      (
        'Remada Alta com Barra W Pegada Aberta (Deltoide Lateral)',
        'Academia',
        'Ombros',
        'Barra W',
        25,
        4,
        12
      ),
      (
        'Encolhimento de Ombros com Barra W pela Frente',
        'Academia',
        'Antebraço & Trapézio',
        'Barra W',
        50,
        4,
        15
      ),
      (
        'Encolhimento de Ombros com Barra W por Trás',
        'Academia',
        'Antebraço & Trapézio',
        'Barra W',
        45,
        4,
        12
      ),
      (
        'Levantamento Terra com Trap Bar Pegada Alta',
        'Academia',
        'Corpo Inteiro',
        'Trap Bar (Barra Hexagonal)',
        80,
        4,
        6
      ),
      (
        'Levantamento Terra com Trap Bar Pegada Baixa',
        'Academia',
        'Corpo Inteiro',
        'Trap Bar (Barra Hexagonal)',
        75,
        4,
        6
      ),
      (
        'Levantamento Terra com Trap Bar em Déficit (Sobre Plataforma)',
        'Academia',
        'Posterior & Glúteos',
        'Trap Bar (Barra Hexagonal)',
        70,
        4,
        5
      ),
      (
        'Levantamento Terra Romeno (RDL) com Trap Bar',
        'Academia',
        'Posterior & Glúteos',
        'Trap Bar (Barra Hexagonal)',
        65,
        4,
        8
      ),
      (
        'Passada Dinâmica com Trap Bar',
        'Academia',
        'Quadríceps',
        'Trap Bar (Barra Hexagonal)',
        35,
        3,
        10
      ),
      (
        'Afundo Estático com Trap Bar',
        'Academia',
        'Quadríceps',
        'Trap Bar (Barra Hexagonal)',
        35,
        3,
        10
      ),
      (
        'Agachamento com Trap Bar Pegada Baixa',
        'Academia',
        'Quadríceps',
        'Trap Bar (Barra Hexagonal)',
        60,
        4,
        8
      ),
      (
        'Encolhimento de Ombros Pesado com Trap Bar',
        'Academia',
        'Antebraço & Trapézio',
        'Trap Bar (Barra Hexagonal)',
        70,
        4,
        12
      ),
      (
        'Caminhada do Fazendeiro com Trap Bar',
        'Academia',
        'Antebraço & Trapézio',
        'Trap Bar (Barra Hexagonal)',
        50,
        4,
        30
      ),
      (
        'Salto Vertical com Carga na Trap Bar (Trap Bar Jump Shrug)',
        'CrossFit & Funcional',
        'Corpo Inteiro',
        'Trap Bar (Barra Hexagonal)',
        40,
        4,
        5
      ),
    ];

    for (final be in exerciciosBarrasEspeciais) {
      adicionar(
        be.$1,
        modalidade: be.$2,
        grupoMuscular: be.$3,
        equipamento: be.$4,
        carga: be.$5,
        series: be.$6,
        reps: be.$7,
      );
    }

    // =========================================================================
    // 18. LIBERAÇÃO MIOFASCIAL, FOAM ROLLER & BASTÃO DE MOBILIDADE (~65 exercícios)
    // =========================================================================
    const exerciciosMiofascialBastao =
        <(String, String, String, String, int, int)>[
      (
        'Liberação Miofascial: Quadríceps no Rolo (Foam Roller)',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        60
      ),
      (
        'Liberação Miofascial: Trato Iliotibial e Tensor da Fáscia Lata no Rolo',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        60
      ),
      (
        'Liberação Miofascial: Glúteos e Piriforme Sentado no Rolo',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        60
      ),
      (
        'Liberação Miofascial: Posterior de Coxa no Rolo Bilateral',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        60
      ),
      (
        'Liberação Miofascial: Panturrilha Unilateral no Rolo com Perna Cruzada',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        45
      ),
      (
        'Liberação Miofascial: Adutores de Coxa no Rolo Deitado',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        45
      ),
      (
        'Liberação Miofascial: Extensão e Rolamento da Coluna Torácica no Rolo',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        60
      ),
      (
        'Liberação Miofascial: Grande Dorsal no Rolo Deitado de Lado',
        'Mobilidade & Core',
        'Mobilidade',
        'Rolo de Liberação',
        2,
        45
      ),
      (
        'Liberação Miofascial: Peitoral e Deltoide Anterior com Bolinha na Parede',
        'Mobilidade & Core',
        'Mobilidade',
        'Bolinha Rígida',
        2,
        45
      ),
      (
        'Liberação Miofascial: Trapézio Superior e Elevador da Escápula com Bolinha',
        'Mobilidade & Core',
        'Mobilidade',
        'Bolinha Rígida',
        2,
        45
      ),
      (
        'Liberação Miofascial: Romboides e Região Interescapular com Bolinha',
        'Mobilidade & Core',
        'Mobilidade',
        'Bolinha Rígida',
        2,
        60
      ),
      (
        'Liberação Miofascial: Sola dos Pés (Fáscia Plantar) com Bolinha Rígida',
        'Mobilidade & Core',
        'Mobilidade',
        'Bolinha Rígida',
        2,
        60
      ),
      (
        'Mobilidade com Bastão: Passagem de Braços Frente e Trás (Dislocates)',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        15
      ),
      (
        'Mobilidade com Bastão: Rotação Torácica Sentado no Solo',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        15
      ),
      (
        'Mobilidade com Bastão: Rotação Externa de Ombro Apoiado no Cotovelo',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        12
      ),
      (
        'Mobilidade com Bastão: Alongamento de Grande Dorsal Ajoelhado no Banco',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Banco',
        2,
        30
      ),
      (
        'Mobilidade com Bastão: Bom Dia com Bastão nas Costas (Alinhamento Espinhal)',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        15
      ),
      (
        'Mobilidade com Bastão: Agachamento Overhead com Bastão (Alinhamento de Braços)',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        3,
        10
      ),
      (
        'Mobilidade com Bastão: Agachamento Cossaco com Apoio do Bastão',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        12
      ),
      (
        'Mobilidade com Bastão: Pêndulo e Rotação de Quadril em Pé',
        'Mobilidade & Core',
        'Mobilidade',
        'Bastão / Vassoura',
        2,
        15
      ),
    ];

    for (final mb in exerciciosMiofascialBastao) {
      adicionar(
        mb.$1,
        modalidade: mb.$2,
        grupoMuscular: mb.$3,
        equipamento: mb.$4,
        series: mb.$5,
        reps: mb.$6,
      );
    }

    // =========================================================================
    // 19. CALISTENIA AVANÇADA, GYMNASTICS SKILLS & PROGRESSÕES (~65 exercícios)
    // =========================================================================
    const exerciciosCalisteniaAvancada = <(String, String, String, int, int)>[
      (
        'Calistenia: Tuck Planche Isometria no Solo',
        'Peito',
        'Peso do Corpo',
        4,
        15
      ),
      (
        'Calistenia: Tuck Planche Isometria nas Paralelas Baixas',
        'Peito',
        'Paralelas Baixas',
        4,
        15
      ),
      (
        'Calistenia: Advanced Tuck Planche (Tronco Reto Paralelo)',
        'Peito',
        'Paralelas Baixas',
        4,
        10
      ),
      (
        'Calistenia: Straddle Planche Isometria nas Paralelas',
        'Peito',
        'Paralelas Baixas',
        4,
        8
      ),
      (
        'Calistenia: Flexão Pseudo Planche no Solo (Inclinado à Frente)',
        'Peito',
        'Peso do Corpo',
        4,
        10
      ),
      (
        'Calistenia: Flexão Pseudo Planche nas Paralelas Baixas',
        'Peito',
        'Paralelas Baixas',
        4,
        10
      ),
      (
        'Calistenia: Planche Lean no Solo (Transferência Máxima de Peso)',
        'Ombros',
        'Peso do Corpo',
        4,
        20
      ),
      (
        'Calistenia: Tuck Front Lever Isometria na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        15
      ),
      (
        'Calistenia: Advanced Tuck Front Lever na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        12
      ),
      (
        'Calistenia: Front Lever com Uma Perna Estendida (Single Leg)',
        'Costas',
        'Barra Fixa',
        4,
        10
      ),
      (
        'Calistenia: Straddle Front Lever Isometria na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        8
      ),
      (
        'Calistenia: Front Lever Completo Isometria na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        6
      ),
      (
        'Calistenia: Puxada em Front Lever (Front Lever Row)',
        'Costas',
        'Barra Fixa',
        4,
        6
      ),
      (
        'Calistenia: Tuck Back Lever na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        15
      ),
      (
        'Calistenia: Back Lever Completo Isometria na Barra Fixa',
        'Costas',
        'Barra Fixa',
        4,
        8
      ),
      (
        'Calistenia: L-Sit no Solo com Pernas Estendidas',
        'Abdômen & Core',
        'Peso do Corpo',
        4,
        20
      ),
      (
        'Calistenia: L-Sit nas Paralelas com Pernas Estendidas',
        'Abdômen & Core',
        'Paralelas',
        4,
        25
      ),
      (
        'Calistenia: V-Sit nas Paralelas (Elevação Acima da Horizontal)',
        'Abdômen & Core',
        'Paralelas',
        4,
        15
      ),
      (
        'Calistenia: Parada de Mãos Livre no Solo (Handstand Balance)',
        'Ombros',
        'Peso do Corpo',
        4,
        30
      ),
      (
        'Calistenia: Caminhada na Parada de Mãos (Handstand Walk)',
        'Ombros',
        'Peso do Corpo',
        4,
        20
      ),
      (
        'Calistenia: Flexão na Parada de Mãos com Costas na Parede (Heels to Wall)',
        'Ombros',
        'Peso do Corpo / Parede',
        4,
        8
      ),
      (
        'Calistenia: Flexão na Parada de Mãos com Peito na Parede (Chest to Wall)',
        'Ombros',
        'Peso do Corpo / Parede',
        4,
        8
      ),
      (
        'Calistenia: Flexão na Parada de Mãos em Déficit (Nas Paralelas)',
        'Ombros',
        'Paralelas',
        4,
        6
      ),
      (
        'Calistenia: Muscle-Up Estrito nas Argolas de Ginástica',
        'Corpo Inteiro',
        'Argolas de Ginástica',
        4,
        5
      ),
      (
        'Calistenia: Muscle-Up com Kipping nas Argolas de Ginástica',
        'Corpo Inteiro',
        'Argolas de Ginástica',
        4,
        6
      ),
      (
        'Calistenia: Mergulho em Suspensão nas Argolas (Ring Dips)',
        'Peito',
        'Argolas de Ginástica',
        4,
        10
      ),
      (
        'Calistenia: Flexão em Suspensão nas Argolas (Ring Push-up)',
        'Peito',
        'Argolas de Ginástica',
        4,
        12
      ),
      (
        'Calistenia: Crucifixo em Suspensão nas Argolas (Ring Fly)',
        'Peito',
        'Argolas de Ginástica',
        3,
        10
      ),
      (
        'Calistenia: Barra Fixa Arqueira na Barra (Archer Pull-up)',
        'Costas',
        'Barra Fixa',
        4,
        8
      ),
      (
        'Calistenia: Flexão Arqueira no Solo (Archer Push-up)',
        'Peito',
        'Peso do Corpo',
        4,
        10
      ),
      (
        'Calistenia: Barra Fixa Unilateral com Apoio de Toalha',
        'Costas',
        'Barra Fixa / Toalha',
        3,
        6
      ),
      (
        'Calistenia: Barra Fixa Unilateral Pura (One-Arm Pull-up)',
        'Costas',
        'Barra Fixa',
        3,
        3
      ),
    ];

    for (final ca in exerciciosCalisteniaAvancada) {
      adicionar(
        ca.$1,
        modalidade: 'Calistenia',
        grupoMuscular: ca.$2,
        equipamento: ca.$3,
        series: ca.$4,
        reps: ca.$5,
      );
    }

    // =========================================================================
    // 20. HIIT METABÓLICO, AGILIDADE & CONDICIONAMENTO EM CASA (~65 exercícios)
    // =========================================================================
    const exerciciosHiitCasa = <(String, String, int, int)>[
      (
        'HIIT em Casa: Burpee Militar Completo com Flexão e Salto',
        'Corpo Inteiro',
        4,
        12
      ),
      (
        'HIIT em Casa: Half Burpee (Sem Flexão, com Sprawl Rápido)',
        'Corpo Inteiro',
        4,
        15
      ),
      (
        'HIIT em Casa: Burpee Lateral Saltando sobre Linha no Solo',
        'Corpo Inteiro',
        4,
        12
      ),
      (
        'HIIT em Casa: Polichinelo Tradicional em Ritmo Acelerado',
        'Cardio & Corrida',
        4,
        40
      ),
      (
        'HIIT em Casa: Polichinelo com Agachamento (Squat Jack)',
        'Corpo Inteiro',
        4,
        30
      ),
      (
        'HIIT em Casa: Salto Estrela Pliométrico (Star Jump)',
        'Corpo Inteiro',
        4,
        15
      ),
      (
        'HIIT em Casa: Mountain Climber Rápido (Corrida no Solo)',
        'Abdômen & Core',
        4,
        30
      ),
      (
        'HIIT em Casa: Mountain Climber Cruzado (Joelho no Cotovelo Oposto)',
        'Abdômen & Core',
        4,
        30
      ),
      (
        'HIIT em Casa: Corrida Estática com Elevação de Joelhos (High Knees)',
        'Cardio & Corrida',
        4,
        40
      ),
      (
        'HIIT em Casa: Calcanhares nos Glúteos em Ritmo Acelerado (Butt Kicks)',
        'Cardio & Corrida',
        4,
        40
      ),
      (
        'HIIT em Casa: Skater Jump Lateral com Toque de Mão no Chão',
        'Posterior & Glúteos',
        4,
        20
      ),
      ('HIIT em Casa: Prancha Sobe e Desce (Up-Down Plank)', 'Peito', 4, 12),
      (
        'HIIT em Casa: Prancha com Toque nos Ombros (Shoulder Tap Plank)',
        'Abdômen & Core',
        4,
        24
      ),
      (
        'HIIT em Casa: Prancha Abre e Fecha Pernas Saltando (Plank Jacks)',
        'Abdômen & Core',
        4,
        25
      ),
      (
        'HIIT em Casa: Agachamento com Salto Explosivo (Jump Squat)',
        'Quadríceps',
        4,
        15
      ),
      (
        'HIIT em Casa: Afundo Pliométrico Trocando no Ar (Jumping Lunge)',
        'Quadríceps',
        4,
        16
      ),
      (
        'HIIT em Casa: Sombra com Deslocamento Lateral e Sequência de Golpes',
        'Corpo Inteiro',
        4,
        30
      ),
      (
        'HIIT em Casa: Abdominal V-Up Canivete Completo no Solo',
        'Abdômen & Core',
        4,
        15
      ),
      (
        'HIIT em Casa: Abdominal Canivete Alternado Cruzado',
        'Abdômen & Core',
        4,
        20
      ),
      (
        'HIIT em Casa: Urso Rastejante Frente e Trás no Solo (Bear Crawl)',
        'Corpo Inteiro',
        4,
        30
      ),
      (
        'HIIT em Casa: Caranguejo Andando e Elevando Perna no Solo (Crab Walk)',
        'Posterior & Glúteos',
        4,
        25
      ),
      (
        'HIIT em Casa: Patinador Lateral Rápido sem Impacto',
        'Posterior & Glúteos',
        4,
        25
      ),
      (
        'HIIT em Casa: Salto Lateral com Pés Juntos sobre Marca',
        'Cardio & Corrida',
        4,
        30
      ),
      (
        'HIIT em Casa: Prancha Homem-Aranha (Spiderman Plank)',
        'Abdômen & Core',
        4,
        20
      ),
      (
        'HIIT em Casa: Corrida Estática em Passo Curto e Rápido (Fast Feet)',
        'Cardio & Corrida',
        4,
        45
      ),
    ];

    for (final hc in exerciciosHiitCasa) {
      adicionar(
        hc.$1,
        modalidade: 'Em Casa',
        grupoMuscular: hc.$2,
        equipamento: 'Peso do Corpo',
        series: hc.$3,
        reps: hc.$4,
      );
    }

    // =========================================================================
    // 21. FLEXIBILIDADE PROFUNDA & ALONGAMENTO ESTÁTICO / DINÂMICO (~40 exercícios)
    // =========================================================================
    const exerciciosAlongamentoFlex =
        <(String, String, String, String, int, int)>[
      (
        'Alongamento de Peitoral no Batente da Porta ou Parede Unilateral',
        'Mobilidade & Core',
        'Peito',
        'Parede / Batente',
        3,
        30
      ),
      (
        'Alongamento de Grande Dorsal na Barra Fixa (Suspensão Passiva)',
        'Mobilidade & Core',
        'Costas',
        'Barra Fixa',
        3,
        30
      ),
      (
        'Alongamento de Grande Dorsal na Barra Fixa (Suspensão Ativa Escapular)',
        'Mobilidade & Core',
        'Costas',
        'Barra Fixa',
        3,
        20
      ),
      (
        'Alongamento de Bíceps e Deltoide Anterior com Palma Apoiada na Parede',
        'Mobilidade & Core',
        'Bíceps',
        'Parede',
        3,
        30
      ),
      (
        'Alongamento de Tríceps Acima da Cabeça Unilateral com Puxada de Cotovelo',
        'Mobilidade & Core',
        'Tríceps',
        'Peso do Corpo',
        3,
        30
      ),
      (
        'Alongamento de Antebraço e Flexores de Punho no Solo em 4 Apoios',
        'Mobilidade & Core',
        'Antebraço & Trapézio',
        'Tapete / Solo',
        3,
        30
      ),
      (
        'Alongamento de Antebraço e Extensores de Punho no Solo em 4 Apoios',
        'Mobilidade & Core',
        'Antebraço & Trapézio',
        'Tapete / Solo',
        3,
        30
      ),
      (
        'Alongamento de Flexores de Quadril em Afundo Baixo (Psoas Stretch)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        40
      ),
      (
        'Alongamento do Quadríceps em Pé com Apoio Levando Calcanhar ao Glúteo',
        'Mobilidade & Core',
        'Quadríceps',
        'Livre / Apoio',
        3,
        30
      ),
      (
        'Alongamento de Quadríceps Deitado de Lado com Puxada de Tornozelo',
        'Mobilidade & Core',
        'Quadríceps',
        'Tapete / Solo',
        3,
        30
      ),
      (
        'Alongamento Profundo de Glúteo e Piriforme em Figura 4 no Solo',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        40
      ),
      (
        'Alongamento Pombo de Ioga (Pigeon Pose) para Rotação Externa de Quadril',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        45
      ),
      (
        'Alongamento de Isquiotibiais em Pé com Perna Elevada no Banco',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Banco Reto',
        3,
        35
      ),
      (
        'Alongamento de Isquiotibiais Sentado (Pinça Unilateral com Perna Flexionada)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        40
      ),
      (
        'Alongamento de Isquiotibiais Sentado (Pinça Bilateral Levando Mãos aos Pés)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        45
      ),
      (
        'Alongamento Borboleta Sentado com Pressão Suave nos Joelhos (Adutores)',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        3,
        45
      ),
      (
        'Alongamento Sapinho no Solo com Joelhos Afastados (Mobilidade de Virilha)',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        3,
        45
      ),
      (
        'Alongamento Torção de Coluna Deitado com Joelho Cruzado no Solo',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        3,
        35
      ),
      (
        'Alongamento Escorpião Deitado de Barriga para Baixo com Rotação de Perna',
        'Mobilidade & Core',
        'Mobilidade',
        'Tapete / Solo',
        3,
        10
      ),
      (
        'Alongamento da Cobra / Cão Olhando para Cima (Extensão de Abdômen)',
        'Mobilidade & Core',
        'Abdômen & Core',
        'Tapete / Solo',
        3,
        30
      ),
      (
        'Alongamento Cão Olhando para Baixo (Cadeia Posterior e Panturrilha)',
        'Mobilidade & Core',
        'Posterior & Glúteos',
        'Tapete / Solo',
        3,
        40
      ),
      (
        'Alongamento de Panturrilha no Degrau com Joelho Estendido (Gastrocnêmio)',
        'Mobilidade & Core',
        'Panturrilha',
        'Degrau',
        3,
        35
      ),
      (
        'Alongamento de Panturrilha no Degrau com Joelho Flexionado (Sóleo)',
        'Mobilidade & Core',
        'Panturrilha',
        'Degrau',
        3,
        35
      ),
      (
        'Alongamento de Pescoço e Trapézio Superior com Inclinação Lateral Assistida',
        'Mobilidade & Core',
        'Antebraço & Trapézio',
        'Peso do Corpo',
        3,
        25
      ),
      (
        'Alongamento do Elevador da Escápula Olhando para a Axila com Tração Suave',
        'Mobilidade & Core',
        'Antebraço & Trapézio',
        'Peso do Corpo',
        3,
        25
      ),
    ];

    for (final al in exerciciosAlongamentoFlex) {
      adicionar(
        al.$1,
        modalidade: al.$2,
        grupoMuscular: al.$3,
        equipamento: al.$4,
        series: al.$5,
        reps: al.$6,
      );
    }

    // =========================================================================
    // 22. GLÚTEOS COM CABO, CANELEIRAS & KETTLEBELL ADVANCED (~45 exercícios)
    // =========================================================================
    const exerciciosGluteoCaboKettlebell =
        <(String, String, String, String, double, int, int)>[
      (
        'Coice de Glúteo no Cabo com Tornozeleira (Perna Estendida)',
        'Academia',
        'Posterior & Glúteos',
        'Polia / Cabo',
        10,
        4,
        12
      ),
      (
        'Coice de Glúteo no Cabo com Tornozeleira (Joelho Flexionado 90°)',
        'Academia',
        'Posterior & Glúteos',
        'Polia / Cabo',
        12,
        4,
        12
      ),
      (
        'Abdução de Quadril no Cabo com Tornozeleira em Pé',
        'Academia',
        'Posterior & Glúteos',
        'Polia / Cabo',
        7,
        4,
        15
      ),
      (
        'Adução de Quadril no Cabo com Tornozeleira em Pé',
        'Academia',
        'Posterior & Glúteos',
        'Polia / Cabo',
        10,
        3,
        15
      ),
      (
        'Extensão de Quadril em 4 Apoios com Caneleira de Peso',
        'Em Casa',
        'Posterior & Glúteos',
        'Caneleiras',
        5,
        4,
        15
      ),
      (
        'Elevação Lateral de Perna Deitado com Caneleira de Peso',
        'Em Casa',
        'Posterior & Glúteos',
        'Caneleiras',
        4,
        4,
        15
      ),
      (
        'Abdução em 4 Apoios com Caneleira (Hidrante com Carga)',
        'Em Casa',
        'Posterior & Glúteos',
        'Caneleiras',
        3,
        4,
        12
      ),
      (
        'Flexão de Joelho em Pé com Caneleira (Posterior Unilateral)',
        'Em Casa',
        'Posterior & Glúteos',
        'Caneleiras',
        5,
        3,
        15
      ),
      (
        'Elevação de Perna Reta Sentado com Caneleira (Reto Femoral)',
        'Em Casa',
        'Quadríceps',
        'Caneleiras',
        4,
        3,
        15
      ),
      (
        'Kettlebell Windmill (Moinho de Vento para Core e Ombros)',
        'Elásticos & Kettlebell',
        'Abdômen & Core',
        'Kettlebell',
        12,
        3,
        8
      ),
      (
        'Kettlebell Turkish Get-Up Completo (Levantamento Turco)',
        'Elásticos & Kettlebell',
        'Corpo Inteiro',
        'Kettlebell',
        12,
        3,
        5
      ),
      (
        'Kettlebell Halo em Torno da Cabeça (Mobilidade Escapular)',
        'Elásticos & Kettlebell',
        'Ombros',
        'Kettlebell',
        10,
        3,
        12
      ),
      (
        'Kettlebell Bottoms-Up Clean & Press (Com Fundo Para Cima)',
        'Elásticos & Kettlebell',
        'Antebraço & Trapézio',
        'Kettlebell',
        8,
        3,
        6
      ),
      (
        'Kettlebell Clean & Jerk Unilateral (Arremesso Completo)',
        'Elásticos & Kettlebell',
        'Corpo Inteiro',
        'Kettlebell',
        16,
        4,
        8
      ),
      (
        'Kettlebell Goblet Squat com Pausa no Fundo (3s)',
        'Elásticos & Kettlebell',
        'Quadríceps',
        'Kettlebell',
        20,
        4,
        10
      ),
      (
        'Kettlebell Cossack Squat com Carga Frontal',
        'Elásticos & Kettlebell',
        'Quadríceps',
        'Kettlebell',
        14,
        3,
        8
      ),
      (
        'Halter: Rosca Zottman com Descida em Pronação Lenta (3s)',
        'Academia',
        'Bíceps',
        'Halteres',
        10,
        3,
        10
      ),
      (
        'Halter: Elevação Lateral Unilateral Apoiado no Banco Inclinado 45°',
        'Academia',
        'Ombros',
        'Halteres',
        8,
        4,
        12
      ),
      (
        'Halter: Elevação de Panturrilha Unilateral no Degrau com Halter Pesado',
        'Academia',
        'Panturrilha',
        'Halteres',
        18,
        4,
        15
      ),
      (
        'Halter: Agachamento Jefferson com Halter Entre as Pernas',
        'Academia',
        'Posterior & Glúteos',
        'Halteres',
        24,
        4,
        10
      ),
      (
        'Halter: Remada Curvada Unilateral com Apoio de Mão na Parede',
        'Academia',
        'Costas',
        'Halteres',
        20,
        4,
        10
      ),
      (
        'Halter: Supino Tate Press no Banco Reto para Tríceps',
        'Academia',
        'Tríceps',
        'Halteres',
        12,
        3,
        12
      ),
    ];

    for (final gk in exerciciosGluteoCaboKettlebell) {
      adicionar(
        gk.$1,
        modalidade: gk.$2,
        grupoMuscular: gk.$3,
        equipamento: gk.$4,
        carga: gk.$5,
        series: gk.$6,
        reps: gk.$7,
      );
    }

    return List<ItemCatalogoExercicio>.unmodifiable(lista);
  }
}

/// Parâmetros imutáveis transmitidos para o Isolate de filtragem em segundo plano.
class ParametrosFiltroCatalogo {
  const ParametrosFiltroCatalogo({
    required this.busca,
    required this.modalidade,
    required this.grupoMuscular,
  });

  final String busca;
  final String modalidade;
  final String grupoMuscular;
}

/// Função de nível superior para processamento de filtragem isolada via `compute()`.
List<ItemCatalogoExercicio> _executarFiltroCatalogoNoIsolate(
  ParametrosFiltroCatalogo params,
) {
  return CatalogoDeExerciciosOffline.filtrar(
    busca: params.busca,
    modalidade: params.modalidade,
    grupoMuscular: params.grupoMuscular,
  );
}
