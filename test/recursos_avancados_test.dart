import 'package:flutter_test/flutter_test.dart';

import 'package:offline_gym/dominio/recursos_avancados.dart';
import 'package:offline_gym/modelos/plano_de_treino.dart';

void main() {
  final data = DateTime(2026, 1, 2);

  SerieHistorica serie(double carga, int reps, {String nome = 'Supino'}) =>
      SerieHistorica(
        data: data,
        serie: SerieDoTreino(
          nomeExercicio: nome,
          cargaUtilizada: carga,
          serieNumero: 1,
          repeticoes: reps,
        ),
      );

  test('calcula 1RM estimado e recorde pelo melhor 1RM', () {
    final resultado = RecursosAvancados.recordes(<SerieHistorica>[
      serie(80, 5),
      serie(75, 8),
    ]);

    expect(resultado, hasLength(1));
    expect(resultado.single.estimativa1RM, closeTo(94.05, 0.2));
  });

  test('progressão aumenta carga quando meta e RPE estão controlados', () {
    final resultado = RecursosAvancados.progressao(
      cargaKg: 100,
      repeticoes: 10,
      alvoRepeticoes: 10,
      rpe: 7,
    );

    expect(resultado.cargaSugeridaKg, 102.5);
  });

  test('template versionado rejeita versão desconhecida', () {
    expect(
      () => RecursosAvancados.importarTemplate('{"versao":2,"exercicios":[]}'),
      throwsFormatException,
    );
  });

  test('streaks são separados por categoria', () {
    final hoje = DateTime(2026, 1, 3);
    final resultado = RecursosAvancados.streaks(
      treinos: <DateTime>{DateTime(2026, 1, 3), DateTime(2026, 1, 2)},
      habitos: <DateTime>{DateTime(2026, 1, 3)},
      hoje: hoje,
    );

    expect(resultado.treino, 2);
    expect(resultado.habitos, 1);
    expect(resultado.descanso, 0);
  });
}
