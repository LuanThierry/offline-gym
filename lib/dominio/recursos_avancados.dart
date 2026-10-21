import 'dart:convert';

import '../modelos/plano_de_treino.dart';

class SerieHistorica {
  const SerieHistorica({
    required this.data,
    required this.serie,
  });

  final DateTime data;
  final SerieDoTreino serie;
}

class RecordePessoal {
  const RecordePessoal({
    required this.exercicio,
    required this.cargaKg,
    required this.repeticoes,
    required this.estimativa1RM,
    required this.data,
  });

  final String exercicio;
  final double cargaKg;
  final int repeticoes;
  final double estimativa1RM;
  final DateTime data;
}

class PontoDe1RM {
  const PontoDe1RM({required this.data, required this.valorKg});

  final DateTime data;
  final double valorKg;
}

class RecomendacaoDeProgressao {
  const RecomendacaoDeProgressao({
    required this.cargaSugeridaKg,
    required this.repeticoesSugeridas,
    required this.motivo,
  });

  final double cargaSugeridaKg;
  final int repeticoesSugeridas;
  final String motivo;
}

class ResumoDeStreaks {
  const ResumoDeStreaks({
    required this.treino,
    required this.habitos,
    required this.descanso,
  });

  final int treino;
  final int habitos;
  final int descanso;
}

class ComparacaoDeMedidas {
  const ComparacaoDeMedidas(this.valores);

  final Map<String, double> valores;
}

class DiagnosticoDeDeload {
  const DiagnosticoDeDeload({required this.recomendado, required this.motivo});

  final bool recomendado;
  final String motivo;
}

class TemplateTreinoVersionado {
  const TemplateTreinoVersionado(
      {required this.versao, required this.nome, required this.exercicios});

  final int versao;
  final String nome;
  final List<ExercicioPlanejado> exercicios;

  Map<String, Object?> paraMapa() => <String, Object?>{
        'versao': versao,
        'nome': nome,
        'exercicios':
            exercicios.map((item) => item.paraJson()).toList(growable: false),
      };
}

class RecursosAvancados {
  RecursosAvancados._();

  static double estimar1RM(double cargaKg, int repeticoes) {
    if (cargaKg <= 0 || repeticoes <= 0) return 0;
    if (repeticoes == 1) return cargaKg;
    final epley = cargaKg * (1 + repeticoes / 30);
    final brzycki = cargaKg * 36 / (37 - repeticoes);
    return repeticoes >= 37 ? epley : (epley + brzycki) / 2;
  }

  static List<RecordePessoal> recordes(List<SerieHistorica> series) {
    final melhores = <String, RecordePessoal>{};
    for (final item in series) {
      final serie = item.serie;
      if (serie.tipo == 'aquecimento' || serie.cargaUtilizada <= 0) continue;
      final chave = serie.nomeExercicio.trim().toLowerCase();
      final candidato = RecordePessoal(
        exercicio: serie.nomeExercicio,
        cargaKg: serie.cargaUtilizada,
        repeticoes: serie.repeticoes,
        estimativa1RM: estimar1RM(serie.cargaUtilizada, serie.repeticoes),
        data: item.data,
      );
      final atual = melhores[chave];
      if (atual == null || candidato.estimativa1RM > atual.estimativa1RM) {
        melhores[chave] = candidato;
      }
    }
    return melhores.values.toList(growable: false)
      ..sort((a, b) => b.estimativa1RM.compareTo(a.estimativa1RM));
  }

  static Map<String, double> volumePorGrupo(
    List<SerieHistorica> series, {
    required String Function(String exercicio) grupoDoExercicio,
  }) {
    final volume = <String, double>{};
    for (final item in series) {
      if (item.serie.tipo == 'aquecimento') continue;
      final grupo = grupoDoExercicio(item.serie.nomeExercicio);
      volume[grupo] = (volume[grupo] ?? 0) +
          item.serie.cargaUtilizada * item.serie.repeticoes;
    }
    return volume;
  }

  static List<PontoDe1RM> historicoDe1RM(
    List<SerieHistorica> series,
    String exercicio,
  ) {
    return series
        .where((item) =>
            item.serie.nomeExercicio.trim().toLowerCase() ==
            exercicio.trim().toLowerCase())
        .map((item) => PontoDe1RM(
              data: item.data,
              valorKg:
                  estimar1RM(item.serie.cargaUtilizada, item.serie.repeticoes),
            ))
        .toList(growable: false);
  }

  static RecomendacaoDeProgressao progressao({
    required double cargaKg,
    required int repeticoes,
    required int alvoRepeticoes,
    double? rpe,
  }) {
    if (rpe != null && rpe <= 7 && repeticoes >= alvoRepeticoes) {
      return RecomendacaoDeProgressao(
        cargaSugeridaKg: _arredondar(cargaKg * 1.025),
        repeticoesSugeridas: alvoRepeticoes,
        motivo: 'RPE controlado e meta atingida: subir aproximadamente 2,5%.',
      );
    }
    if (repeticoes < alvoRepeticoes) {
      return RecomendacaoDeProgressao(
        cargaSugeridaKg: cargaKg,
        repeticoesSugeridas: repeticoes + 1,
        motivo: 'Mantenha a carga e aproxime-se da faixa de repetições.',
      );
    }
    return RecomendacaoDeProgressao(
      cargaSugeridaKg: cargaKg,
      repeticoesSugeridas: repeticoes,
      motivo: 'Mantenha a carga até o esforço ficar mais consistente.',
    );
  }

  static ResumoDeStreaks streaks({
    required Set<DateTime> treinos,
    required Set<DateTime> habitos,
    required DateTime hoje,
  }) {
    int calcular(Set<DateTime> datas) {
      var dia = DateTime(hoje.year, hoje.month, hoje.day);
      var total = 0;
      while (datas.contains(dia)) {
        total++;
        dia = dia.subtract(const Duration(days: 1));
      }
      return total;
    }

    final descanso = treinos.contains(DateTime(hoje.year, hoje.month, hoje.day))
        ? 0
        : calcularSemTreino(treinos, hoje);
    return ResumoDeStreaks(
        treino: calcular(treinos),
        habitos: calcular(habitos),
        descanso: descanso);
  }

  static int calcularSemTreino(Set<DateTime> treinos, DateTime hoje) {
    var dia = DateTime(hoje.year, hoje.month, hoje.day);
    var total = 0;
    while (!treinos.contains(dia)) {
      total++;
      dia = dia.subtract(const Duration(days: 1));
      if (total > 3650) break;
    }
    return total;
  }

  static DiagnosticoDeDeload detectarDeload(
      List<SerieHistorica> series, DateTime hoje) {
    final recentes = series
        .where((item) => hoje.difference(item.data).inDays <= 28)
        .toList(growable: false);
    final semanas = <int, double>{};
    for (final item in recentes) {
      final semana = hoje.difference(item.data).inDays ~/ 7;
      semanas[semana] = (semanas[semana] ?? 0) +
          item.serie.cargaUtilizada * item.serie.repeticoes;
    }
    final atual = semanas[0] ?? 0;
    final anteriores = semanas.entries
        .where((entry) => entry.key > 0)
        .map((entry) => entry.value)
        .toList(growable: false);
    final media = anteriores.isEmpty
        ? 0
        : anteriores.reduce((a, b) => a + b) / anteriores.length;
    final recomendado = media > 0 && atual > media * 1.35;
    return DiagnosticoDeDeload(
      recomendado: recomendado,
      motivo: recomendado
          ? 'O volume das últimas sessões está muito acima da média recente.'
          : 'Não há sinal claro de sobrecarga acumulada.',
    );
  }

  static ComparacaoDeMedidas comparar(
      RegistroDeMedidasCorporais anterior, RegistroDeMedidasCorporais atual) {
    final pares = <String, double?>{
      'Braço direito':
          atual.bracoDireitoCm != null && anterior.bracoDireitoCm != null
              ? atual.bracoDireitoCm! - anterior.bracoDireitoCm!
              : null,
      'Braço esquerdo':
          atual.bracoEsquerdoCm != null && anterior.bracoEsquerdoCm != null
              ? atual.bracoEsquerdoCm! - anterior.bracoEsquerdoCm!
              : null,
      'Peitoral': atual.peitoralCm != null && anterior.peitoralCm != null
          ? atual.peitoralCm! - anterior.peitoralCm!
          : null,
      'Cintura': atual.cinturaCm != null && anterior.cinturaCm != null
          ? atual.cinturaCm! - anterior.cinturaCm!
          : null,
      'Abdômen': atual.abdomenCm != null && anterior.abdomenCm != null
          ? atual.abdomenCm! - anterior.abdomenCm!
          : null,
    };
    return ComparacaoDeMedidas(<String, double>{
      for (final entry in pares.entries)
        if (entry.value != null) entry.key: entry.value!
    });
  }

  static TemplateTreinoVersionado importarTemplate(String json) {
    if (json.length > 1024 * 1024) {
      throw const FormatException('Template excede 1 MB.');
    }
    final decoded = jsonDecode(json);
    if (decoded is! Map ||
        decoded['versao'] != 1 ||
        decoded['exercicios'] is! List) {
      throw const FormatException('Template incompatível.');
    }
    final items = decoded['exercicios'] as List;
    if (items.length > 200) {
      throw const FormatException('Template excede 200 exercícios.');
    }
    final exercicios = <ExercicioPlanejado>[];
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Exercício inválido.');
      }
      final map = Map<String, Object?>.from(item);
      final nome = map['nome'];
      if (nome is! String || nome.trim().isEmpty) {
        throw const FormatException('Nome de exercício inválido.');
      }
      exercicios.add(ExercicioPlanejado.deMapa(<String, Object?>{
        ...map,
        'id': null,
        'idTreino': null,
        'diaSemana': (map['diaSemana'] as num?)?.toInt() ?? 1,
      }));
    }
    return TemplateTreinoVersionado(
        versao: 1,
        nome: decoded['nome'] as String? ?? 'Template',
        exercicios: exercicios);
  }

  static double _arredondar(double valor) => (valor * 2).round() / 2;
}
