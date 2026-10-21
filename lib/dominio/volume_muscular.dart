import 'package:flutter/material.dart';

/// Define os marcos de volume semanal para hipertrofia baseados nas diretrizes do Dr. Mike Israetel:
/// - MEV (Minimum Effective Volume): Mínimo para haver hipertrofia (abaixo disso é apenas manutenção).
/// - MAV (Maximum Adaptive Volume): Faixa ideal de maior ganho de massa muscular.
/// - MRV (Maximum Recoverable Volume): Teto fisiológico de recuperação semanal.
class MarcoDeVolumeMuscular {
  const MarcoDeVolumeMuscular({
    required this.grupoMuscular,
    required this.seriesCompletadas,
    required this.mev,
    required this.mavMin,
    required this.mavMax,
    required this.mrv,
  });

  final String grupoMuscular;
  final int seriesCompletadas;
  final int mev;
  final int mavMin;
  final int mavMax;
  final int mrv;

  /// Retorna a classificação do volume semanal.
  String get status {
    if (seriesCompletadas == 0) return 'Sem estímulo';
    if (seriesCompletadas < mev) return 'Manutenção';
    if (seriesCompletadas < mavMin) return 'Volume Efetivo';
    if (seriesCompletadas <= mavMax) return 'Volume Ótimo 🔥';
    if (seriesCompletadas <= mrv) return 'Volume Alto';
    return 'Sobrecarga (MRV)';
  }

  /// Cor temática do status para a interface.
  Color obterCor([Color? corDestaque]) {
    if (seriesCompletadas == 0) return const Color(0xFF636E72);
    if (seriesCompletadas < mev) return const Color(0xFF00B8D4);
    if (seriesCompletadas < mavMin) {
      return corDestaque ?? const Color(0xFF0984E3);
    }
    if (seriesCompletadas <= mavMax) return const Color(0xFF00B894);
    if (seriesCompletadas <= mrv) return const Color(0xFFFFA726);
    return const Color(0xFFFF5252);
  }

  Color get cor => obterCor();

  /// Percentual de progresso normalizado para a barra visual (0.0 a 1.0 relativo ao MRV).
  double get progressoRelativo {
    if (mrv <= 0) return 0.0;
    return (seriesCompletadas / mrv).clamp(0.0, 1.0);
  }

  /// Valores padrão de referência da literatura para os principais grupos musculares.
  static final Map<String, ({int mev, int mavMin, int mavMax, int mrv})>
      referencias = {
    'Peito': (mev: 8, mavMin: 12, mavMax: 20, mrv: 22),
    'Costas': (mev: 10, mavMin: 14, mavMax: 22, mrv: 25),
    'Quadríceps': (mev: 8, mavMin: 12, mavMax: 18, mrv: 20),
    'Posterior & Glúteos': (mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
    'Ombros': (mev: 8, mavMin: 12, mavMax: 20, mrv: 24),
    'Bíceps': (mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
    'Tríceps': (mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
    'Panturrilhas': (mev: 6, mavMin: 8, mavMax: 16, mrv: 20),
    'Abdômen & Core': (mev: 0, mavMin: 6, mavMax: 12, mrv: 16),
  };

  /// Cria a instância com os marcos teóricos padrão para o grupo informado.
  factory MarcoDeVolumeMuscular.criar({
    required String grupoMuscular,
    required int seriesCompletadas,
  }) {
    final ref =
        referencias[grupoMuscular] ?? (mev: 6, mavMin: 10, mavMax: 16, mrv: 20);
    return MarcoDeVolumeMuscular(
      grupoMuscular: grupoMuscular,
      seriesCompletadas: seriesCompletadas,
      mev: ref.mev,
      mavMin: ref.mavMin,
      mavMax: ref.mavMax,
      mrv: ref.mrv,
    );
  }
}
