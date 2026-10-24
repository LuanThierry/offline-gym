import '../modelos/plano_de_treino.dart';
import 'catalogo_exercicios_offline.dart';
import 'volume_muscular.dart';

/// Nível de gravidade ou tom do parecer do Coach Fisiológico.
enum TipoDeParecer {
  destaque,
  alertaFisiologico,
  otimizacao,
  sucesso,
}

/// Representa um parecer individual gerado pelo Coach Científico Offline.
class ParecerDoCoach {
  const ParecerDoCoach({
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    this.recomendacaoPratica,
    this.iconeCodePoint,
  });

  final String titulo;
  final String mensagem;
  final TipoDeParecer tipo;
  final String? recomendacaoPratica;
  final int? iconeCodePoint;
}

/// Registro rápido de prontidão diária (biofeedback do atleta: energia, sono, articulações).
class RegistroDeProntidaoDiaria {
  const RegistroDeProntidaoDiaria({
    required this.energia,
    required this.sono,
    required this.dorArticular,
    this.articulacaoComDor,
  });

  final int energia; // 1 a 5
  final int sono; // 1 a 5
  final int dorArticular; // 0 a 5 (0 = sem dor)
  final String? articulacaoComDor;

  factory RegistroDeProntidaoDiaria.deMapa(Map<String, Object?> mapa) {
    return RegistroDeProntidaoDiaria(
      energia: (mapa['energia'] as num?)?.toInt() ?? 3,
      sono: (mapa['sono'] as num?)?.toInt() ?? 3,
      dorArticular: (mapa['dorArticular'] as num?)?.toInt() ?? 0,
      articulacaoComDor: mapa['articulacaoComDor'] as String?,
    );
  }

  Map<String, Object?> paraMapa() => <String, Object?>{
        'energia': energia,
        'sono': sono,
        'dorArticular': dorArticular,
        'articulacaoComDor': articulacaoComDor,
      };
}

/// Identificação de estagnação de carga/repetições em um exercício específico.
class DeteccaoDePlato {
  const DeteccaoDePlato({
    required this.nomeExercicio,
    required this.sessoesSemEvolucao,
    required this.cargaKg,
    required this.repeticoes,
    required this.estrategiaSugerida,
  });

  final String nomeExercicio;
  final int sessoesSemEvolucao;
  final double cargaKg;
  final int repeticoes;
  final String estrategiaSugerida;
}

/// Estimativa individual de recuperação e fadiga residual por grupo muscular.
class StatusRecuperacaoMuscular {
  const StatusRecuperacaoMuscular({
    required this.grupoMuscular,
    required this.percentualRecuperado,
    required this.horasDesdeUltimoTreino,
    required this.tempoTotalRecuperacaoHoras,
    required this.statusTexto,
  });

  final String grupoMuscular;
  final int percentualRecuperado; // 5 a 100
  final int? horasDesdeUltimoTreino; // nulo se nunca estimulado
  final int tempoTotalRecuperacaoHoras;
  final String statusTexto;

  bool get prontoParaTreinar => percentualRecuperado >= 85;
}

/// Diagnóstico completo de simetria, fadiga e recomendações de treino.
class DiagnosticoDoCoach {
  const DiagnosticoDoCoach({
    required this.saudacaoPersonalizada,
    required this.indiceEquilibrioPercentual,
    required this.indiceFadigaPercentual,
    required this.semanaSugeridaDeload,
    required this.pareceres,
    required this.resumoGeral,
    this.recuperacaoMuscular = const <StatusRecuperacaoMuscular>[],
    this.volumeSemanal = const <MarcoDeVolumeMuscular>[],
  });

  final String saudacaoPersonalizada;
  final int indiceEquilibrioPercentual;
  final int indiceFadigaPercentual;
  final bool semanaSugeridaDeload;
  final List<ParecerDoCoach> pareceres;
  final String resumoGeral;
  final List<StatusRecuperacaoMuscular> recuperacaoMuscular;
  final List<MarcoDeVolumeMuscular> volumeSemanal;
}

/// Motor de Inteligência Própria Offline de Treinamento e Biomecânica.
/// Analisa o perfil inicial do usuário em conjunto com o volume semanal de séries
/// e o histórico de treinos, gerando recomendações baseadas na ciência do exercício.
class CoachCientificoOffline {
  const CoachCientificoOffline._();

  /// Janelas fisiológicas de recuperação base por grupo muscular (em horas).
  static const Map<String, int> tempoBaseRecuperacaoHoras = <String, int>{
    'Peito': 60,
    'Costas': 60,
    'Quadríceps': 72,
    'Posterior & Glúteos': 60,
    'Ombros': 48,
    'Bíceps': 48,
    'Tríceps': 48,
    'Panturrilhas': 36,
    'Abdômen & Core': 36,
  };

  /// Detecta se algum exercício nas últimas séries históricas está estagnado
  /// com a mesma carga e repetições por 3 ou mais sessões distintas e consecutivas.
  static List<DeteccaoDePlato> detectarPlatos(List<SerieDoTreino> seriesRecentes) {
    final porExercicio = <String, List<SerieDoTreino>>{};
    for (final s in seriesRecentes) {
      if (s.tipo == 'aquecimento' || s.cargaUtilizada <= 0) continue;
      porExercicio.putIfAbsent(s.nomeExercicio, () => []).add(s);
    }

    final platos = <DeteccaoDePlato>[];
    for (final entry in porExercicio.entries) {
      final nome = entry.key;
      final series = entry.value;

      // Agrupa séries por sessão distinta de treino (preserva ordem do banco)
      final sessoesMap = <String, List<SerieDoTreino>>{};
      for (var i = 0; i < series.length; i++) {
        final s = series[i];
        final sessionKey = s.idHistoricoTreino?.toString() ??
            (s.dataISO != null && s.dataISO!.isNotEmpty
                ? s.dataISO!.split('T').first
                : 'sessao_avulsa_');
        sessoesMap.putIfAbsent(sessionKey, () => []).add(s);
      }

      // Se o exercício foi realizado em menos de 3 sessões distintas, não há histórico suficiente para platô
      if (sessoesMap.length < 3) continue;

      // Obtém as 3 sessões mais recentes
      final ultimas3Sessoes = sessoesMap.values.take(3).toList();

      // Para cada sessão, identifica o melhor desempenho (maior carga de trabalho e reps nessa carga)
      final desempenhosPorSessao = ultimas3Sessoes.map((sessoesSeries) {
        double maxCarga = 0;
        int maxReps = 0;
        for (final s in sessoesSeries) {
          if (s.cargaUtilizada > maxCarga) {
            maxCarga = s.cargaUtilizada;
            maxReps = s.repeticoes;
          } else if (s.cargaUtilizada == maxCarga && s.repeticoes > maxReps) {
            maxReps = s.repeticoes;
          }
        }
        return (carga: maxCarga, reps: maxReps);
      }).toList();

      final sessaoRecente = desempenhosPorSessao[0];
      final sessaoIntermediaria = desempenhosPorSessao[1];
      final sessaoAntiga = desempenhosPorSessao[2];

      if (sessaoRecente.carga <= 0) continue;

      final mesmaCargaNas3 = sessaoRecente.carga == sessaoIntermediaria.carga &&
          sessaoIntermediaria.carga == sessaoAntiga.carga;

      // Platô: mesma carga nas 3 sessões e repetições não aumentaram na sessão recente
      final semEvolucaoDeReps = sessaoRecente.reps <= sessaoIntermediaria.reps &&
          sessaoIntermediaria.reps <= sessaoAntiga.reps;

      if (mesmaCargaNas3 && semEvolucaoDeReps) {
        platos.add(
          DeteccaoDePlato(
            nomeExercicio: nome,
            sessoesSemEvolucao: ultimas3Sessoes.length,
            cargaKg: sessaoRecente.carga,
            repeticoes: sessaoRecente.reps,
            estrategiaSugerida:
                'Aplique micro-sobrecarga (+0.5 ou +1 kg) ou execute a fase excêntrica em 3 segundos controlados.',
          ),
        );
      }
    }
    return platos;
  }

  /// Calcula a estimativa científica de recuperação individual por grupo muscular.
  static List<StatusRecuperacaoMuscular> estimarRecuperacaoMuscular({
    required Map<String, DateTime> ultimosTreinosPorGrupo,
    DateTime? agora,
  }) {
    final momentoAtual = agora ?? DateTime.now();
    final resultado = <StatusRecuperacaoMuscular>[];

    for (final entry in tempoBaseRecuperacaoHoras.entries) {
      final grupo = entry.key;
      final tempoBase = entry.value;
      final ultimoTreino = ultimosTreinosPorGrupo[grupo];

      if (ultimoTreino == null) {
        resultado.add(
          StatusRecuperacaoMuscular(
            grupoMuscular: grupo,
            percentualRecuperado: 100,
            horasDesdeUltimoTreino: null,
            tempoTotalRecuperacaoHoras: tempoBase,
            statusTexto: '100% pronto · Totalmente recuperado',
          ),
        );
        continue;
      }

      final diferencaHoras =
          momentoAtual.difference(ultimoTreino).inHours.clamp(0, 999);
      final percentual =
          ((diferencaHoras / tempoBase) * 100).round().clamp(5, 100);

      String status;
      if (percentual >= 90) {
        status = '$percentual% recuperado · Pronto para novo estímulo';
      } else if (percentual >= 70) {
        status =
            '$percentual% recuperado · Recuperação avançada (Há ${diferencaHoras}h)';
      } else if (percentual >= 40) {
        status =
            '$percentual% recuperado · Em regeneração miofibrilar (Há ${diferencaHoras}h)';
      } else {
        status =
            '$percentual% recuperado · Fadiga residual alta (Há ${diferencaHoras}h)';
      }

      resultado.add(
        StatusRecuperacaoMuscular(
          grupoMuscular: grupo,
          percentualRecuperado: percentual,
          horasDesdeUltimoTreino: diferencaHoras,
          tempoTotalRecuperacaoHoras: tempoBase,
          statusTexto: status,
        ),
      );
    }

    return List<StatusRecuperacaoMuscular>.unmodifiable(resultado);
  }

  /// Analisa os dados reais do atleta e sintetiza o diagnóstico inteligente.
  static DiagnosticoDoCoach analisarTreinamento({
    required PerfilDoUsuario? perfil,
    required List<MarcoDeVolumeMuscular> volumeSemanal,
    required List<TreinoDoHistorico> historico,
    required int diasOfensiva,
    double? pesoAtualKg,
    Map<String, DateTime>? ultimosTreinosPorGrupo,
    DateTime? dataReferencia,
    List<ExercicioPlanejado>? exerciciosPlanejados,
    RegistroDeProntidaoDiaria? prontidaoHoje,
    List<DeteccaoDePlato>? platosDetectados,
  }) {
    final nome = (perfil?.nome.trim().isNotEmpty == true)
        ? perfil!.nome.trim().split(' ').first
        : 'Atleta';
    final nivel = perfil?.nivelExperiencia ?? 'Iniciante';
    final objetivo = perfil?.objetivoPrincipal ?? 'Hipertrofia';

    final agora = dataReferencia ?? DateTime.now();
    final recuperacao = estimarRecuperacaoMuscular(
      ultimosTreinosPorGrupo:
          ultimosTreinosPorGrupo ?? const <String, DateTime>{},
      agora: agora,
    );

    final pareceres = <ParecerDoCoach>[];
    final mapVolume = <String, int>{};
    for (final m in volumeSemanal) {
      mapVolume[m.grupoMuscular] = m.seriesCompletadas;
    }

    final peito = mapVolume['Peito'] ?? 0;
    final costas = mapVolume['Costas'] ?? 0;
    final quad = mapVolume['Quadríceps'] ?? 0;
    final posterior = mapVolume['Posterior & Glúteos'] ?? 0;
    final ombros = mapVolume['Ombros'] ?? 0;
    final biceps = mapVolume['Bíceps'] ?? 0;
    final triceps = mapVolume['Tríceps'] ?? 0;
    final core = mapVolume['Abdômen & Core'] ?? 0;

    var scoreSimetria = 100;

    // 0.0 BIOFEEDBACK DE PRONTIDÃO DIÁRIA (ENERGIA / SONO / ARTICULAÇÕES)
    if (prontidaoHoje != null) {
      if (prontidaoHoje.dorArticular >= 3 && prontidaoHoje.articulacaoComDor != null) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Atenção Articular: ${prontidaoHoje.articulacaoComDor}',
            mensagem:
                'Você registrou desconforto em ${prontidaoHoje.articulacaoComDor} (nível ${prontidaoHoje.dorArticular}/5). '
                'Respeitar a sensibilidade articular previne compensações motoras indesejadas.',
            recomendacaoPratica:
                'Aqueça em amplitude progressiva, reduza a sobrecarga axial e evite posições de hiperextensão.',
            tipo: TipoDeParecer.alertaFisiologico,
          ),
        );
      } else if (prontidaoHoje.energia <= 2 || prontidaoHoje.sono <= 2) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Prontidão Moderada (Energia: ${prontidaoHoje.energia}/5 · Sono: ${prontidaoHoje.sono}/5)',
            mensagem:
                'Com nível de energia ou descanso reduzido, a taxa de disparo neural e a recuperação entre séries tornam-se mais lentas.',
            recomendacaoPratica:
                'Mantenha as cargas com 2 a 3 repetições de reserva (RIR 2-3). Evite ir até a falha concêntrica nesta sessão.',
            tipo: TipoDeParecer.otimizacao,
          ),
        );
      } else if (prontidaoHoje.energia >= 4 && prontidaoHoje.sono >= 4 && prontidaoHoje.dorArticular <= 1) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Prontidão Máxima de Treino! ⚡',
            mensagem:
                'Alta energia (${prontidaoHoje.energia}/5) e sono reparador (${prontidaoHoje.sono}/5) registrados. Seu organismo está em ótimo estado de prontidão física.',
            recomendacaoPratica:
                'Excelente oportunidade para tentar progredir 1 a 2 kg nas primeiras séries de trabalho!',
            tipo: TipoDeParecer.destaque,
          ),
        );
      }
    }

    // 0.01 ALERTA DE PLATÔ DE CARGA
    if (platosDetectados != null && platosDetectados.isNotEmpty) {
      for (final p in platosDetectados.take(2)) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Superando Platô: ${p.nomeExercicio}',
            mensagem:
                'A carga de ${p.cargaKg.toStringAsFixed(1).replaceAll(".0", "")} kg '
                'permaneceu estável nas últimas ${p.sessoesSemEvolucao} sessões sem aumento de repetições.',
            recomendacaoPratica: p.estrategiaSugerida,
            tipo: TipoDeParecer.otimizacao,
          ),
        );
      }
    }

    // 0. ANÁLISE INTEGRADA DO PLANO DE TREINO (OFFLINE)
    if (exerciciosPlanejados != null && exerciciosPlanejados.isNotEmpty) {
      final volumePlanejadoPorGrupo = <String, int>{};
      final volumePlanejadoPorDia = <int, int>{};
      final exerciciosPorDia = <int, List<ExercicioPlanejado>>{};

      for (final ex in exerciciosPlanejados) {
        final grupo =
            CatalogoDeExerciciosOffline.identificarGrupoMuscular(ex.nome);
        volumePlanejadoPorGrupo[grupo] =
            (volumePlanejadoPorGrupo[grupo] ?? 0) + ex.series;
        volumePlanejadoPorDia[ex.diaSemana] =
            (volumePlanejadoPorDia[ex.diaSemana] ?? 0) + ex.series;
        exerciciosPorDia
            .putIfAbsent(ex.diaSemana, () => <ExercicioPlanejado>[])
            .add(ex);
      }

      // 0.1 Prontidão Fisiológica para o Treino de Hoje
      final diaHoje = agora.weekday;
      final exerciciosDeHoje =
          exerciciosPorDia[diaHoje] ?? const <ExercicioPlanejado>[];
      if (exerciciosDeHoje.isNotEmpty) {
        final gruposDeHoje = exerciciosDeHoje
            .map((e) =>
                CatalogoDeExerciciosOffline.identificarGrupoMuscular(e.nome))
            .toSet();

        final gruposFadigadosHoje = <StatusRecuperacaoMuscular>[];
        final gruposProntosHoje = <String>[];

        for (final g in gruposDeHoje) {
          final status = recuperacao.firstWhere(
            (r) => r.grupoMuscular == g,
            orElse: () => StatusRecuperacaoMuscular(
              grupoMuscular: g,
              percentualRecuperado: 100,
              horasDesdeUltimoTreino: null,
              tempoTotalRecuperacaoHoras: 48,
              statusTexto: 'Pronto',
            ),
          );
          if (status.percentualRecuperado < 55 &&
              status.horasDesdeUltimoTreino != null) {
            gruposFadigadosHoje.add(status);
          } else if (status.percentualRecuperado >= 90) {
            gruposProntosHoje.add(g);
          }
        }

        if (gruposFadigadosHoje.isNotEmpty) {
          final nomesFadigados = gruposFadigadosHoje
              .map((s) => '${s.grupoMuscular} (${s.percentualRecuperado}%)')
              .join(', ');
          pareceres.add(
            ParecerDoCoach(
              titulo: 'Atenção ao Treino de Hoje: Fadiga Residual',
              mensagem:
                  'Seu plano reserva hoje exercícios para $nomesFadigados, grupos que ainda estão na janela ativa de regeneração. '
                  'Treinar com fadiga residual elevada pode reduzir o rendimento de carga e limitar o estímulo.',
              recomendacaoPratica:
                  'Aumente as séries de aquecimento específico ou reduza 1 série de trabalho para garantir boa técnica biomecânica.',
              tipo: TipoDeParecer.alertaFisiologico,
            ),
          );
        } else if (gruposProntosHoje.length == gruposDeHoje.length &&
            gruposDeHoje.isNotEmpty) {
          pareceres.add(
            ParecerDoCoach(
              titulo: 'Luz Verde para o Treino de Hoje! 🟢',
              mensagem:
                  'Todos os grupos musculares programados para hoje (${gruposProntosHoje.join(', ')}) estão 100% recuperados e prontos para estímulo máximo.',
              recomendacaoPratica:
                  'Momento ideal para buscar progressão de carga ou repetições mantendo a execução biomecânica impecável.',
              tipo: TipoDeParecer.destaque,
            ),
          );
        }
      }

      // 0.2 Sobrecarga em Sessão Única do Plano (> 24 séries no mesmo dia)
      for (final entry in volumePlanejadoPorDia.entries) {
        final dia = entry.key;
        final series = entry.value;
        if (series > 24) {
          final nomeDia = ExercicioPlanejado.nomeDoDiaDaSemana(dia);
          pareceres.add(
            ParecerDoCoach(
              titulo: 'Volume Excessivo no Plano ($nomeDia)',
              mensagem:
                  'Você programou $series séries em $nomeDia. '
                  'A literatura científica aponta que sessões com mais de 20 a 24 séries atingem o limite de volume efetivo (junk volume), aumentando o desgaste sem ganhos proporcionais.',
              recomendacaoPratica:
                  'Considere transferir 4 a 6 séries para outro dia da semana para manter alta intensidade de contração.',
              tipo: TipoDeParecer.alertaFisiologico,
            ),
          );
          break;
        }
      }

      // 0.3 Grupos Musculares Essenciais Ausentes no Plano
      if (exerciciosPlanejados.length >= 6) {
        const gruposEssenciais = <String>[
          'Peito',
          'Costas',
          'Quadríceps',
          'Posterior & Glúteos',
          'Ombros',
        ];
        final gruposFaltantesNoPlano = gruposEssenciais
            .where((g) => (volumePlanejadoPorGrupo[g] ?? 0) == 0)
            .toList();

        if (gruposFaltantesNoPlano.isNotEmpty) {
          final faltantesStr = gruposFaltantesNoPlano.join(', ');
          pareceres.add(
            ParecerDoCoach(
              titulo: 'Grupo Ausente no Plano: $faltantesStr',
              mensagem:
                  'Seu plano de treino possui ${exerciciosPlanejados.length} exercícios programados, mas nenhum mapeado para $faltantesStr. '
                  'Desenvolver todos os grandes grupos previne descompensações articulares e assimetrias posturais.',
              recomendacaoPratica:
                  'Adicione ao menos 2 a 4 séries semanais para $faltantesStr na sua rotina.',
              tipo: TipoDeParecer.alertaFisiologico,
            ),
          );
        }
      }

      // 0.4 Desproporção Empurrar vs Puxar no Plano Semanal
      final empurrarPlano = (volumePlanejadoPorGrupo['Peito'] ?? 0) +
          (volumePlanejadoPorGrupo['Tríceps'] ?? 0);
      final puxarPlano = (volumePlanejadoPorGrupo['Costas'] ?? 0) +
          (volumePlanejadoPorGrupo['Bíceps'] ?? 0);
      if (empurrarPlano >= 12 &&
          puxarPlano > 0 &&
          empurrarPlano > (puxarPlano * 2)) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Desproporção no Plano: Empurrar vs Puxar',
            mensagem:
                'Seu plano semanal programa $empurrarPlano séries de empurrar contra apenas $puxarPlano séries de puxar. '
                'Equilibrar os dois padrões constrói postura estável e desenvolvimento harmônico.',
            recomendacaoPratica:
                'Inclua mais remadas ou puxadas no plano para equiparar o volume com os supinos.',
            tipo: TipoDeParecer.otimizacao,
          ),
        );
      }

      // 0.5 Adesão Semanal ao Plano (Executado vs Planejado)
      final totalSeriesPlanejadas =
          volumePlanejadoPorGrupo.values.fold<int>(0, (a, b) => a + b);
      final totalSeriesExecutadas =
          mapVolume.values.fold<int>(0, (a, b) => a + b);
      if (totalSeriesPlanejadas >= 12 &&
          totalSeriesExecutadas >= (totalSeriesPlanejadas * 0.85)) {
        final percAdesao =
            ((totalSeriesExecutadas / totalSeriesPlanejadas) * 100).round();
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Excelente Adesão ao Plano ($percAdesao%)',
            mensagem:
                'Parabéns pela dedicação! Você já completou $totalSeriesExecutadas das $totalSeriesPlanejadas séries programadas nesta semana.',
            recomendacaoPratica:
                'Mantenha a regularidade para colher adaptações neuromusculares contínuas.',
            tipo: TipoDeParecer.sucesso,
          ),
        );
      }
    }

    // 1. ANÁLISE BIOMECÂNICA: Peitoral vs Dorsal (Equilíbrio Postural Superior)
    if (peito >= 10 && costas > 0 && peito > (costas * 1.5)) {
      scoreSimetria -= 20;
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Equilíbrio Muscular: Dominância de Peitoral',
          mensagem:
              'Você completou $peito séries de Peito e apenas $costas de Costas nesta semana. '
              'Estudos de biomecânica apontam que a dominância dos rotadores internos (peitoral) sobre os retratores escapulares '
              'pode alterar o alinhamento postural da cintura escapular.',
          recomendacaoPratica:
              'Aumente de 4 a 6 séries de remadas ou puxadas para equilibrar o desenvolvimento muscular.',
          tipo: TipoDeParecer.alertaFisiologico,
        ),
      );
    } else if (costas >= 10 && peito > 0 && costas > (peito * 1.6)) {
      scoreSimetria -= 10;
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Oportunidade de Estímulo: Peitoral',
          mensagem:
              'Seu volume de Costas ($costas séries) está bem superior ao de Peito ($peito séries). '
              'Para um desenvolvimento torácico harmonioso em $objetivo, seu peitoral responde bem a mais estímulos.',
          recomendacaoPratica:
              'Considere adicionar um supino inclinado ou crucifixo para acompanhar o progresso das costas.',
          tipo: TipoDeParecer.otimizacao,
        ),
      );
    } else if (peito >= 8 && costas >= 8) {
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Excelente Simetria Torácica',
          mensagem:
              'Sua proporção Peitoral ($peito séries) vs Costas ($costas séries) está biomecanicamente equilibrada. '
              'Essa harmonia constrói uma postura atlética forte e estável.',
          tipo: TipoDeParecer.sucesso,
        ),
      );
    }

    // 2. ANÁLISE DE MEMBROS INFERIORES: Quadríceps vs Posterior/Glúteos
    if (quad >= 10 && posterior > 0 && quad > (posterior * 1.7)) {
      scoreSimetria -= 25;
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Equilíbrio Muscular: Relação Posterior vs Quadríceps',
          mensagem:
              'Você realizou $quad séries de Quadríceps contra $posterior de Posterior/Glúteos. '
              'Na fisiologia esportiva, um volume equilibrado entre a musculatura anterior e posterior de pernas '
              'favorece uma distribuição biomecânica mais estável e harmônica.',
          recomendacaoPratica:
              'Considere incluir Stiff, mesa flexora ou elevação pélvica para equilibrar o desenvolvimento dos membros inferiores.',
          tipo: TipoDeParecer.alertaFisiologico,
        ),
      );
    } else if (quad >= 8 && posterior >= 8) {
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Cadeia Inferior Forte & Estável',
          mensagem:
              'Equilíbrio exemplar entre cadeia anterior ($quad séries) e cadeia posterior ($posterior séries). '
              'Isso garante transferência máxima de força em agachamentos e saltos.',
          tipo: TipoDeParecer.sucesso,
        ),
      );
    }

    // 3. ANÁLISE DE BRAÇOS (Bíceps vs Tríceps)
    if (biceps > 0 &&
        triceps > 0 &&
        (triceps > biceps * 1.8 || biceps > triceps * 1.8)) {
      scoreSimetria -= 10;
      final dominante =
          biceps > triceps ? 'Bíceps ($biceps)' : 'Tríceps ($triceps)';
      final atrasado =
          biceps > triceps ? 'Tríceps ($triceps)' : 'Bíceps ($biceps)';
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Ajuste de Proporção nos Braços',
          mensagem:
              'Seu volume de $dominante está divergindo significativamente de $atrasado. '
              'Como o tríceps compõe ~60% do volume do braço e o bíceps ~40%, doses proporcionais garantem estabilidade de cotovelo.',
          recomendacaoPratica:
              'Equilibre as séries de flexão e extensão de cotovelo.',
          tipo: TipoDeParecer.otimizacao,
        ),
      );
    }

    // Ombros e Core
    if (ombros >= 8) {
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Deltoides em Bom Estímulo',
          mensagem:
              'Você completou $ombros séries de Ombros nesta semana, garantindo largura clavicular e estabilidade glenoumeral.',
          tipo: TipoDeParecer.sucesso,
        ),
      );
    }

    if (core < 4 && (quad >= 8 || costas >= 8)) {
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Estabilidade Lombar: Fortaleça o Core',
          mensagem:
              'Seu volume de grandes levantamentos está expressivo, mas o Core registrou apenas $core séries. '
              'Exercícios para abdômen e eretores da espinha blindam a coluna em agachamentos e remadas.',
          recomendacaoPratica:
              'Dedique 2 a 4 séries de estabilização do core no fim do treino.',
          tipo: TipoDeParecer.otimizacao,
        ),
      );
    }

    // 4. ANÁLISE DE VOLUME VS OBJETIVO DO ATLETA (Cutting, Bulking, Iniciante, Avançado)
    final gruposEmSobrecarga =
        volumeSemanal.where((m) => m.status == 'Sobrecarga (MRV)').toList();
    if (gruposEmSobrecarga.isNotEmpty) {
      final nomesGrupos =
          gruposEmSobrecarga.map((m) => m.grupoMuscular).join(', ');
      if (objetivo.toLowerCase().contains('emagrecimento') ||
          objetivo.toLowerCase().contains('defini')) {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Cuidado Fisiológico em Déficit Calórico',
            mensagem:
                '$nome, você está em fase de $objetivo e os grupos ($nomesGrupos) ultrapassaram o teto MRV de recuperação. '
                'Com menor disponibilidade de energia, treinar acima do MRV não gera hipertrofia extra e acelera a perda de massa magra por excesso de cortisol.',
            recomendacaoPratica:
                'Reduza 2 a 4 séries desses grupos, focando em manter a intensidade de carga pesada.',
            tipo: TipoDeParecer.alertaFisiologico,
          ),
        );
      } else {
        pareceres.add(
          ParecerDoCoach(
            titulo: 'Sinal de Alerta de Sobrecarga (MRV)',
            mensagem:
                'Os grupos ($nomesGrupos) entraram na faixa de sobrecarga máxima recuperável. '
                'Se você sentir queda no rendimento na próxima semana ou cansaço acumulado, seu corpo está pedindo regeneração.',
            recomendacaoPratica:
                'Mantenha o foco no sono e na ingestão proteica.',
            tipo: TipoDeParecer.alertaFisiologico,
          ),
        );
      }
    }

    // Grupos em Manutenção ou Sem Estímulo
    final gruposSemEstimulo = volumeSemanal
        .where((m) =>
            m.seriesCompletadas < m.mev && m.grupoMuscular != 'Abdômen & Core')
        .map((m) => m.grupoMuscular)
        .toList();
    if (gruposSemEstimulo.length >= 3) {
      final gruposFormatados = gruposSemEstimulo.join(', ');
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Oportunidade para seu Nível ($nivel)',
          mensagem:
              'Os grupos $gruposFormatados estão recebendo estímulo abaixo do Mínimo Efetivo (MEV). '
              'Nessa faixa, os músculos entram em conservação, mas não desenvolvem novas fibras.',
          recomendacaoPratica:
              'Para $objetivo, experimente espalhar 2 a 3 séries adicionais desses músculos nos dias da semana.',
          tipo: TipoDeParecer.otimizacao,
        ),
      );
    }

    // 5. MONITOR DE DELOAD & FADIGA NEUROMUSCULAR ACUMULADA
    // Estima fadiga com base no histórico recente de sessões
    final sessoesRecentes = historico.take(24).toList();
    int sessoesPesadas = 0;
    for (final s in sessoesRecentes) {
      if (s.tempoTotalSegundos >= 2700) sessoesPesadas++; // treinos > 45min
    }

    // Índice de fadiga (0 a 100)
    int indiceFadiga =
        ((sessoesPesadas * 4) + (diasOfensiva * 2)).clamp(10, 95);
    bool sugerirDeload = false;

    if (historico.length >= 20 && sessoesPesadas >= 16) {
      sugerirDeload = true;
      indiceFadiga = 90;
      pareceres.insert(
        0,
        ParecerDoCoach(
          titulo: 'Hora do Deload: Semana Regenerativa Recomendada',
          mensagem:
              '$nome, seus dados mostram alta consistência de sobrecarga contínua nas últimas 4 a 6 semanas. '
              'Estudos com atletas demonstram que aplicar um Deload reduzindo 40% a 50% do volume semanal ressensibiliza os receptores hipertróficos '
              'e restaura os tendões, resultando em saltos maiores de força na semana seguinte!',
          recomendacaoPratica:
              'Ative o modo Deload temporário ou faça menos séries mantendo a boa técnica.',
          tipo: TipoDeParecer.destaque,
        ),
      );
    }

    // Resumo conversacional inteligente
    String resumo;
    if (sugerirDeload) {
      resumo =
          'Fadiga acumulada alta. Seu corpo construiu muito estímulo, mas uma semana regenerativa trará supercompensação de hipertrofia!';
    } else if (scoreSimetria >= 85) {
      resumo =
          'Treinamento de alto nível! Seus grupos musculares estão equilibrados e ajustados ao seu objetivo de $objetivo.';
    } else {
      resumo =
          'Bons treinos realizados! Pequenos ajustes de volume entre agonistas e antagonistas maximizarão sua evolução e postura.';
    }

    return DiagnosticoDoCoach(
      saudacaoPersonalizada: 'Coach Fisiológico · $nome ($nivel · $objetivo)',
      indiceEquilibrioPercentual: scoreSimetria.clamp(20, 100),
      indiceFadigaPercentual: indiceFadiga,
      semanaSugeridaDeload: sugerirDeload,
      pareceres: pareceres,
      resumoGeral: resumo,
      recuperacaoMuscular: recuperacao,
      volumeSemanal: volumeSemanal,
    );
  }
}
