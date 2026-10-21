import '../modelos/plano_de_treino.dart';
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
  });

  final String saudacaoPersonalizada;
  final int indiceEquilibrioPercentual;
  final int indiceFadigaPercentual;
  final bool semanaSugeridaDeload;
  final List<ParecerDoCoach> pareceres;
  final String resumoGeral;
  final List<StatusRecuperacaoMuscular> recuperacaoMuscular;
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
  }) {
    final nome = (perfil?.nome.trim().isNotEmpty == true)
        ? perfil!.nome.trim().split(' ').first
        : 'Atleta';
    final nivel = perfil?.nivelExperiencia ?? 'Iniciante';
    final objetivo = perfil?.objetivoPrincipal ?? 'Hipertrofia';

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

    // 1. ANÁLISE BIOMECÂNICA: Peitoral vs Dorsal (Equilíbrio Postural Superior)
    if (peito >= 10 && costas > 0 && peito > (costas * 1.5)) {
      scoreSimetria -= 20;
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Alerta Postural: Dominância de Peitoral',
          mensagem:
              'Você completou $peito séries de Peito e apenas $costas de Costas nesta semana. '
              'Estudos de biomecânica apontam que a dominância dos rotadores internos (peitoral) sobre os retratores escapulares '
              'pode provocar protrusão de ombros e sobrecarga no manguito rotador.',
          recomendacaoPratica:
              'Aumente de 4 a 6 séries de remadas ou puxadas para equilibrar a cintura escapular.',
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
              'Essa harmonia protege os ombros e constrói uma postura atlética forte.',
          tipo: TipoDeParecer.sucesso,
        ),
      );
    }

    // 2. ANÁLISE DE MEMBROS INFERIORES: Quadríceps vs Posterior/Glúteos
    if (quad >= 10 && posterior > 0 && quad > (posterior * 1.7)) {
      scoreSimetria -= 25;
      pareceres.add(
        ParecerDoCoach(
          titulo: 'Prevenção de Lesões: Relação I:Q de Pernas',
          mensagem:
              'Você realizou $quad séries de Quadríceps contra apenas $posterior de Posterior/Glúteos. '
              'Na fisiologia esportiva, a razão de força isquiotibiais/quadríceps (razão I:Q) desbalanceada eleva o estresse no tendão patelar '
              'e no ligamento cruzado anterior (LCA).',
          recomendacaoPratica:
              'Inclua Stiff, mesa flexora ou elevação pélvica para blindar os joelhos.',
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
                'Se você sentir queda na força na próxima semana ou dores articulares, seu corpo está pedindo regeneração.',
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

    final recuperacao = estimarRecuperacaoMuscular(
      ultimosTreinosPorGrupo:
          ultimosTreinosPorGrupo ?? const <String, DateTime>{},
      agora: dataReferencia,
    );

    return DiagnosticoDoCoach(
      saudacaoPersonalizada: 'Coach Fisiológico · $nome ($nivel · $objetivo)',
      indiceEquilibrioPercentual: scoreSimetria.clamp(20, 100),
      indiceFadigaPercentual: indiceFadiga,
      semanaSugeridaDeload: sugerirDeload,
      pareceres: pareceres,
      resumoGeral: resumo,
      recuperacaoMuscular: recuperacao,
    );
  }
}
