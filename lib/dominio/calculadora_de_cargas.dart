import 'dart:math' as math;

/// Modelo de sugestão para séries de aquecimento graduais antes das séries de trabalho.
class SerieDeAquecimentoSugerida {
  const SerieDeAquecimentoSugerida({
    required this.percentual,
    required this.cargaKg,
    required this.repeticoes,
    required this.descricao,
  });

  final int percentual;
  final double cargaKg;
  final int repeticoes;
  final String descricao;
}

/// Motor de cálculos científicos para musculação e força:
/// - Estimativa de 1RM (1 Repetição Máxima) via Epley e Brzycki.
/// - Progressão de aquecimento neuromuscular.
/// - RPE / RIR (Repetições em Reserva).
class CalculadoraDeCargas {
  const CalculadoraDeCargas._();

  /// Estima o 1RM (1 Repetição Máxima) em kg com base na carga utilizada e repetições executadas.
  /// - Para 1 repetição: o próprio peso.
  /// - Para até 10 repetições: média ponderada entre Epley e Brzycki (padrão-ouro na literatura esportiva).
  /// - Acima de 10 repetições: fórmula clássica de Epley.
  static double estimar1RM({
    required double carga,
    required int repeticoes,
  }) {
    if (carga <= 0 || repeticoes <= 0) return 0.0;
    if (repeticoes == 1) return carga;

    // Fórmula de Epley: Carga * (1 + Reps / 30)
    final epley = carga * (1.0 + (repeticoes / 30.0));

    // Fórmula de Brzycki: Carga / (1.0278 - (0.0278 * Reps))
    if (repeticoes <= 10) {
      final divisor = 1.0278 - (0.0278 * repeticoes);
      if (divisor > 0) {
        final brzycki = carga / divisor;
        return _arredondar((epley + brzycki) / 2.0);
      }
    }

    return _arredondar(epley);
  }

  /// Converte RIR (Repetições em Reserva) para RPE (Escala de Esforço Percebido de Borg adaptada).
  /// Exemplo: RIR 2 -> RPE 8 (significa que conseguiria fazer mais 2 repetições antes da falha).
  static double rirParaRpe(int rir) {
    final clamped = rir.clamp(0, 5);
    return 10.0 - clamped;
  }

  /// Converte RPE para RIR aproximado.
  /// Exemplo: RPE 8.5 -> RIR 1-2.
  static int rpeParaRir(double rpe) {
    final clamped = rpe.clamp(6.0, 10.0);
    return (10.0 - clamped).round().clamp(0, 5);
  }

  /// Gera a pirâmide recomendada de aquecimento pré-série pesada:
  /// 1. 40% da carga alvo: fluxo sanguíneo e lubrificação sinovial (10 reps).
  /// 2. 60% da carga alvo: ativação do padrão motor e técnica (6 reps).
  /// 3. 80% da carga alvo: preparação neuromuscular sem gerar acúmulo de lactato (3 reps).
  /// 4. 90% da carga alvo (opcional para cargas > 50kg): aclimatação neural (1 rep).
  static List<SerieDeAquecimentoSugerida> calcularAquecimento({
    required double cargaAlvo,
    double pesoBarraKg = 20.0,
  }) {
    if (cargaAlvo <= 0) return const <SerieDeAquecimentoSugerida>[];

    if (cargaAlvo <= pesoBarraKg) {
      return <SerieDeAquecimentoSugerida>[
        SerieDeAquecimentoSugerida(
          percentual: 50,
          cargaKg: _arredondar(math.max(1.0, cargaAlvo * 0.5)),
          repeticoes: 10,
          descricao: 'Ativação leve inicial com a barra ou halteres leves',
        ),
      ];
    }

    final series = <SerieDeAquecimentoSugerida>[
      SerieDeAquecimentoSugerida(
        percentual: 40,
        cargaKg: _arredondar(math.max(pesoBarraKg, cargaAlvo * 0.40)),
        repeticoes: 10,
        descricao: 'Aquecimento articular e ativação da musculatura',
      ),
      SerieDeAquecimentoSugerida(
        percentual: 60,
        cargaKg: _arredondar(cargaAlvo * 0.60),
        repeticoes: 6,
        descricao: 'Ativação neuromuscular e refinamento do movimento',
      ),
      SerieDeAquecimentoSugerida(
        percentual: 80,
        cargaKg: _arredondar(cargaAlvo * 0.80),
        repeticoes: 3,
        descricao: 'Preparação do sistema nervoso (sem gerar fadiga)',
      ),
    ];

    if (cargaAlvo >= 50.0) {
      series.add(
        SerieDeAquecimentoSugerida(
          percentual: 90,
          cargaKg: _arredondar(cargaAlvo * 0.90),
          repeticoes: 1,
          descricao: 'Aclimatação de carga máxima antes da série de trabalho',
        ),
      );
    }

    return series;
  }

  static double _arredondar(double valor) {
    return (valor * 2.0).round() / 2.0;
  }
}
