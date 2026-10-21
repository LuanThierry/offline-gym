import 'dart:convert';

class ExercicioPlanejado {
  const ExercicioPlanejado({
    this.id,
    this.idTreino,
    this.nomeTreino = 'Treino principal',
    required this.diaSemana,
    required this.nome,
    required this.carga,
    required this.series,
    required this.repeticoes,
    this.tempoDescansoSegundos = 60,
    this.urlGif,
    this.caminhoLocalGif,
    this.cargasPorSerie = const <double>[],
    this.repeticoesPorSerie = const <int>[],
    this.grupoSuperSerie,
  });

  final int? id;
  final int? idTreino;
  final String nomeTreino;

  /// Dia ISO: segunda-feira = 1 ... domingo = 7.
  final int diaSemana;
  final String nome;
  final double carga;
  final int series;
  final int repeticoes;
  final int tempoDescansoSegundos;
  final String?
      urlGif; // Mantido para compatibilidade com dados antigos; não é usado para rede.
  final String? caminhoLocalGif;

  /// Valores personalizados por série; índices ausentes usam os valores base.
  final List<double> cargasPorSerie;
  final List<int> repeticoesPorSerie;

  /// Identificador opcional para agrupar exercícios em Bi-set / Super-série (ex: 'A', 'B').
  final String? grupoSuperSerie;

  double cargaDaSerie(int indice) =>
      indice >= 0 && indice < cargasPorSerie.length
          ? cargasPorSerie[indice]
          : carga;

  int repeticoesDaSerie(int indice) =>
      indice >= 0 && indice < repeticoesPorSerie.length
          ? repeticoesPorSerie[indice]
          : repeticoes;

  static const List<String> nomesDosDiasDaSemana = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static String nomeDoDiaDaSemana(int diaSemana) {
    if (diaSemana < 1 || diaSemana > 7) return 'Dia inválido';
    return nomesDosDiasDaSemana[diaSemana - 1];
  }

  factory ExercicioPlanejado.deMapa(Map<String, Object?> map) {
    return ExercicioPlanejado(
      id: (map['id'] as num?)?.toInt(),
      idTreino: (map['idTreino'] as num?)?.toInt(),
      nomeTreino: (map['nomeTreino'] as String?) ?? 'Treino principal',
      diaSemana: (map['diaSemana'] as num).toInt(),
      nome: (map['nome'] as String?) ?? '',
      carga: (map['carga'] as num?)?.toDouble() ?? 0,
      series: (map['series'] as num?)?.toInt() ?? 3,
      repeticoes: (map['repeticoes'] as num?)?.toInt() ?? 10,
      tempoDescansoSegundos:
          (map['tempoDescansoSegundos'] as num?)?.toInt() ?? 60,
      urlGif: map['urlGif'] as String?,
      caminhoLocalGif: map['caminhoLocalGif'] as String?,
      cargasPorSerie: _decodificarDoubles(map['cargasPorSerie']),
      repeticoesPorSerie: _decodificarInteiros(map['repeticoesPorSerie']),
      grupoSuperSerie: map['grupoSuperSerie'] as String?,
    );
  }

  factory ExercicioPlanejado.deJson(Map<String, dynamic> json) {
    return ExercicioPlanejado(
      id: (json['id'] as num?)?.toInt(),
      idTreino: (json['idTreino'] as num?)?.toInt(),
      nomeTreino: (json['nomeTreino'] as String?) ?? 'Treino principal',
      diaSemana: (json['diaSemana'] as num?)?.toInt() ?? 1,
      nome: (json['nome'] as String?) ?? '',
      carga: (json['carga'] as num?)?.toDouble() ?? 0,
      series: (json['series'] as num?)?.toInt() ?? 3,
      repeticoes: (json['repeticoes'] as num?)?.toInt() ?? 10,
      tempoDescansoSegundos:
          (json['tempoDescansoSegundos'] as num?)?.toInt() ?? 60,
      urlGif: json['urlGif'] as String?,
      caminhoLocalGif: json['caminhoLocalGif'] as String?,
      cargasPorSerie: _decodificarDoubles(json['cargasPorSerie']),
      repeticoesPorSerie: _decodificarInteiros(json['repeticoesPorSerie']),
      grupoSuperSerie: json['grupoSuperSerie'] as String?,
    );
  }

  Map<String, Object?> paraMapa({bool incluirId = true}) {
    final map = <String, Object?>{
      'diaSemana': diaSemana,
      if (idTreino != null) 'idTreino': idTreino,
      'nome': nome,
      'carga': carga,
      'series': series,
      'repeticoes': repeticoes,
      'tempoDescansoSegundos': tempoDescansoSegundos,
      'urlGif': urlGif,
      'caminhoLocalGif': caminhoLocalGif,
      'cargasPorSerie': jsonEncode(cargasPorSerie),
      'repeticoesPorSerie': jsonEncode(repeticoesPorSerie),
      if (grupoSuperSerie != null) 'grupoSuperSerie': grupoSuperSerie,
    };
    if (incluirId && id != null) map['id'] = id;
    return map;
  }

  Map<String, dynamic> paraJson() => <String, dynamic>{
        'id': id,
        'idTreino': idTreino,
        'nomeTreino': nomeTreino,
        'diaSemana': diaSemana,
        'nome': nome,
        'carga': carga,
        'series': series,
        'repeticoes': repeticoes,
        'tempoDescansoSegundos': tempoDescansoSegundos,
        'urlGif': urlGif,
        'caminhoLocalGif': caminhoLocalGif,
        'cargasPorSerie': cargasPorSerie,
        'repeticoesPorSerie': repeticoesPorSerie,
        'grupoSuperSerie': grupoSuperSerie,
      };

  ExercicioPlanejado copiarCom({
    int? id,
    int? idTreino,
    String? nomeTreino,
    int? diaSemana,
    String? nome,
    double? carga,
    int? series,
    int? repeticoes,
    int? tempoDescansoSegundos,
    String? urlGif,
    String? caminhoLocalGif,
    bool limparUrlGif = false,
    bool limparCaminhoLocalGif = false,
    List<double>? cargasPorSerie,
    List<int>? repeticoesPorSerie,
    String? grupoSuperSerie,
    bool limparGrupoSuperSerie = false,
  }) {
    return ExercicioPlanejado(
      id: id ?? this.id,
      idTreino: idTreino ?? this.idTreino,
      nomeTreino: nomeTreino ?? this.nomeTreino,
      diaSemana: diaSemana ?? this.diaSemana,
      nome: nome ?? this.nome,
      carga: carga ?? this.carga,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      tempoDescansoSegundos:
          tempoDescansoSegundos ?? this.tempoDescansoSegundos,
      urlGif: limparUrlGif ? null : (urlGif ?? this.urlGif),
      caminhoLocalGif: limparCaminhoLocalGif
          ? null
          : (caminhoLocalGif ?? this.caminhoLocalGif),
      cargasPorSerie: cargasPorSerie ?? this.cargasPorSerie,
      repeticoesPorSerie: repeticoesPorSerie ?? this.repeticoesPorSerie,
      grupoSuperSerie: limparGrupoSuperSerie
          ? null
          : (grupoSuperSerie ?? this.grupoSuperSerie),
    );
  }

  static List<double> _decodificarDoubles(Object? valor) {
    final decoded = _decodificarLista(valor);
    return decoded
        .whereType<num>()
        .map((item) => item.toDouble())
        .toList(growable: false);
  }

  static List<int> _decodificarInteiros(Object? valor) => _decodificarLista(
        valor,
      ).whereType<num>().map((item) => item.toInt()).toList(growable: false);

  static List<Object?> _decodificarLista(Object? valor) {
    if (valor is List) return List<Object?>.from(valor);
    if (valor is! String || valor.isEmpty) return const <Object?>[];
    try {
      final decoded = jsonDecode(valor);
      return decoded is List ? List<Object?>.from(decoded) : const <Object?>[];
    } on FormatException {
      return const <Object?>[];
    }
  }
}

class RotinaDeTreino {
  const RotinaDeTreino({
    this.id,
    required this.diaSemana,
    required this.nome,
    this.selecionado = true,
    this.exercicios = const <ExercicioPlanejado>[],
  });

  final int? id;
  final int diaSemana;
  final String nome;
  final bool selecionado;
  final List<ExercicioPlanejado> exercicios;
}

class PerfilDoUsuario {
  const PerfilDoUsuario({
    required this.nome,
    this.idade,
    this.caminhoFoto,
    this.lembretesAtivos = true,
    this.horaLembrete = 9,
    this.minutoLembrete = 0,
    this.metaPesoKg,
    this.objetivoPrincipal = 'Hipertrofia',
    this.nivelExperiencia = 'Iniciante',
    this.onboardingConcluido = true,
    this.alturaCm,
    this.sexo = 'Masculino',
    this.fatorAtividade = 1.55,
  });

  final String nome;
  final int? idade;
  final String? caminhoFoto;
  final bool lembretesAtivos;
  final int horaLembrete;
  final int minutoLembrete;
  final double? metaPesoKg;
  final String objetivoPrincipal;
  final String nivelExperiencia;
  final bool onboardingConcluido;
  final double? alturaCm;
  final String sexo;
  final double fatorAtividade;

  factory PerfilDoUsuario.deMapa(Map<String, Object?> map) => PerfilDoUsuario(
        nome: (map['nome'] as String?) ?? '',
        idade: (map['idade'] as num?)?.toInt(),
        caminhoFoto: map['caminhoFoto'] as String?,
        lembretesAtivos: ((map['lembretesAtivos'] as num?)?.toInt() ?? 1) == 1,
        horaLembrete: (map['horaLembrete'] as num?)?.toInt() ?? 9,
        minutoLembrete: (map['minutoLembrete'] as num?)?.toInt() ?? 0,
        metaPesoKg: (map['metaPesoKg'] as num?)?.toDouble(),
        objetivoPrincipal:
            (map['objetivoPrincipal'] as String?) ?? 'Hipertrofia',
        nivelExperiencia: (map['nivelExperiencia'] as String?) ?? 'Iniciante',
        onboardingConcluido:
            ((map['onboardingConcluido'] as num?)?.toInt() ?? 1) == 1,
        alturaCm: (map['alturaCm'] as num?)?.toDouble(),
        sexo: (map['sexo'] as String?) ?? 'Masculino',
        fatorAtividade: (map['fatorAtividade'] as num?)?.toDouble() ?? 1.55,
      );

  Map<String, Object?> paraMapa({bool incluirCaminhoLocal = true}) =>
      <String, Object?>{
        'id': 1,
        'nome': nome,
        'idade': idade,
        if (incluirCaminhoLocal) 'caminhoFoto': caminhoFoto,
        'lembretesAtivos': lembretesAtivos ? 1 : 0,
        'horaLembrete': horaLembrete,
        'minutoLembrete': minutoLembrete,
        'metaPesoKg': metaPesoKg,
        'objetivoPrincipal': objetivoPrincipal,
        'nivelExperiencia': nivelExperiencia,
        'onboardingConcluido': onboardingConcluido ? 1 : 0,
        'alturaCm': alturaCm,
        'sexo': sexo,
        'fatorAtividade': fatorAtividade,
      };

  PerfilDoUsuario copiarCom({
    String? nome,
    int? idade,
    String? caminhoFoto,
    bool? lembretesAtivos,
    int? horaLembrete,
    int? minutoLembrete,
    double? metaPesoKg,
    String? objetivoPrincipal,
    String? nivelExperiencia,
    bool? onboardingConcluido,
    double? alturaCm,
    String? sexo,
    double? fatorAtividade,
  }) {
    return PerfilDoUsuario(
      nome: nome ?? this.nome,
      idade: idade ?? this.idade,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      lembretesAtivos: lembretesAtivos ?? this.lembretesAtivos,
      horaLembrete: horaLembrete ?? this.horaLembrete,
      minutoLembrete: minutoLembrete ?? this.minutoLembrete,
      metaPesoKg: metaPesoKg ?? this.metaPesoKg,
      objetivoPrincipal: objetivoPrincipal ?? this.objetivoPrincipal,
      nivelExperiencia: nivelExperiencia ?? this.nivelExperiencia,
      onboardingConcluido: onboardingConcluido ?? this.onboardingConcluido,
      alturaCm: alturaCm ?? this.alturaCm,
      sexo: sexo ?? this.sexo,
      fatorAtividade: fatorAtividade ?? this.fatorAtividade,
    );
  }
}

/// Registro de evolução antropométrica com fita métrica (circunferências corporais em cm).
class RegistroDeMedidasCorporais {
  const RegistroDeMedidasCorporais({
    this.id,
    required this.dataISO,
    this.bracoDireitoCm,
    this.bracoEsquerdoCm,
    this.peitoralCm,
    this.cinturaCm,
    this.abdomenCm,
    this.coxaDireitaCm,
    this.coxaEsquerdaCm,
    this.panturrilhaDireitaCm,
    this.panturrilhaEsquerdaCm,
    this.observacoes,
  });

  final int? id;
  final String dataISO;
  final double? bracoDireitoCm;
  final double? bracoEsquerdoCm;
  final double? peitoralCm;
  final double? cinturaCm;
  final double? abdomenCm;
  final double? coxaDireitaCm;
  final double? coxaEsquerdaCm;
  final double? panturrilhaDireitaCm;
  final double? panturrilhaEsquerdaCm;
  final String? observacoes;

  factory RegistroDeMedidasCorporais.deMapa(Map<String, Object?> map) =>
      RegistroDeMedidasCorporais(
        id: (map['id'] as num?)?.toInt(),
        dataISO:
            (map['dataISO'] as String?) ?? DateTime.now().toIso8601String(),
        bracoDireitoCm: (map['bracoDireitoCm'] as num?)?.toDouble(),
        bracoEsquerdoCm: (map['bracoEsquerdoCm'] as num?)?.toDouble(),
        peitoralCm: (map['peitoralCm'] as num?)?.toDouble(),
        cinturaCm: (map['cinturaCm'] as num?)?.toDouble(),
        abdomenCm: (map['abdomenCm'] as num?)?.toDouble(),
        coxaDireitaCm: (map['coxaDireitaCm'] as num?)?.toDouble(),
        coxaEsquerdaCm: (map['coxaEsquerdaCm'] as num?)?.toDouble(),
        panturrilhaDireitaCm: (map['panturrilhaDireitaCm'] as num?)?.toDouble(),
        panturrilhaEsquerdaCm:
            (map['panturrilhaEsquerdaCm'] as num?)?.toDouble(),
        observacoes: map['observacoes'] as String?,
      );

  Map<String, Object?> paraMapa({bool incluirId = false}) => <String, Object?>{
        if (incluirId && id != null) 'id': id,
        'dataISO': dataISO,
        'bracoDireitoCm': bracoDireitoCm,
        'bracoEsquerdoCm': bracoEsquerdoCm,
        'peitoralCm': peitoralCm,
        'cinturaCm': cinturaCm,
        'abdomenCm': abdomenCm,
        'coxaDireitaCm': coxaDireitaCm,
        'coxaEsquerdaCm': coxaEsquerdaCm,
        'panturrilhaDireitaCm': panturrilhaDireitaCm,
        'panturrilhaEsquerdaCm': panturrilhaEsquerdaCm,
        'observacoes': observacoes,
      };

  RegistroDeMedidasCorporais copiarCom({
    int? id,
    String? dataISO,
    double? bracoDireitoCm,
    double? bracoEsquerdoCm,
    double? peitoralCm,
    double? cinturaCm,
    double? abdomenCm,
    double? coxaDireitaCm,
    double? coxaEsquerdaCm,
    double? panturrilhaDireitaCm,
    double? panturrilhaEsquerdaCm,
    String? observacoes,
  }) {
    return RegistroDeMedidasCorporais(
      id: id ?? this.id,
      dataISO: dataISO ?? this.dataISO,
      bracoDireitoCm: bracoDireitoCm ?? this.bracoDireitoCm,
      bracoEsquerdoCm: bracoEsquerdoCm ?? this.bracoEsquerdoCm,
      peitoralCm: peitoralCm ?? this.peitoralCm,
      cinturaCm: cinturaCm ?? this.cinturaCm,
      abdomenCm: abdomenCm ?? this.abdomenCm,
      coxaDireitaCm: coxaDireitaCm ?? this.coxaDireitaCm,
      coxaEsquerdaCm: coxaEsquerdaCm ?? this.coxaEsquerdaCm,
      panturrilhaDireitaCm: panturrilhaDireitaCm ?? this.panturrilhaDireitaCm,
      panturrilhaEsquerdaCm:
          panturrilhaEsquerdaCm ?? this.panturrilhaEsquerdaCm,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

class SerieDoTreino {
  const SerieDoTreino({
    required this.nomeExercicio,
    required this.cargaUtilizada,
    required this.serieNumero,
    this.repeticoes = 10,
    this.tipo = 'normal',
    this.rpe,
  });

  final String nomeExercicio;
  final double cargaUtilizada;
  final int serieNumero;
  final int repeticoes;
  final String tipo;
  final double? rpe;

  factory SerieDoTreino.deMapa(Map<String, Object?> map) {
    return SerieDoTreino(
      nomeExercicio: (map['nomeExercicio'] as String?) ?? '',
      cargaUtilizada: (map['cargaUtilizada'] as num?)?.toDouble() ?? 0,
      serieNumero: (map['serieNumero'] as num?)?.toInt() ?? 1,
      repeticoes: (map['repeticoes'] as num?)?.toInt() ?? 10,
      tipo: (map['tipo'] as String?) ?? 'normal',
      rpe: (map['rpe'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> paraMapa({required int idHistoricoTreino}) =>
      <String, Object?>{
        'idHistoricoTreino': idHistoricoTreino,
        'nomeExercicio': nomeExercicio,
        'cargaUtilizada': cargaUtilizada,
        'serieNumero': serieNumero,
        'repeticoes': repeticoes,
        'tipo': tipo,
        if (rpe != null) 'rpe': rpe,
      };
}

class DetalheEvolucaoDoExercicio {
  const DetalheEvolucaoDoExercicio({
    required this.idDoTreino,
    required this.dataISO,
    required this.series,
    required this.cargaMaxima,
  });

  final int idDoTreino;
  final String dataISO;
  final List<SerieDoTreino> series;
  final double cargaMaxima;
}

class TreinoDoHistorico {
  const TreinoDoHistorico({
    required this.id,
    required this.dataISO,
    required this.tempoTotalSegundos,
    required this.diaSemana,
    this.nomeTreino = '',
  });

  final int id;
  final String dataISO;
  final int tempoTotalSegundos;
  final int diaSemana;
  final String nomeTreino;

  factory TreinoDoHistorico.deMapa(Map<String, Object?> map) {
    return TreinoDoHistorico(
      id: (map['id'] as num).toInt(),
      dataISO: map['dataISO'] as String,
      tempoTotalSegundos: (map['tempoTotalSegundos'] as num?)?.toInt() ?? 0,
      diaSemana: (map['diaSemana'] as num?)?.toInt() ?? 1,
      nomeTreino: (map['nomeTreino'] as String?) ?? '',
    );
  }
}

class PontoDeEvolucao {
  const PontoDeEvolucao({required this.data, required this.cargaKg});

  final DateTime data;
  final double cargaKg;
}

class RegistroDePesoCorporal {
  const RegistroDePesoCorporal({
    required this.id,
    required this.dataISO,
    required this.pesoKg,
  });

  final int id;
  final String dataISO;
  final double pesoKg;

  factory RegistroDePesoCorporal.deMapa(Map<String, Object?> map) {
    return RegistroDePesoCorporal(
      id: (map['id'] as num).toInt(),
      dataISO: map['dataISO'] as String,
      pesoKg: (map['pesoKg'] as num).toDouble(),
    );
  }
}

class FotoMensalDeEvolucao {
  const FotoMensalDeEvolucao({
    required this.id,
    required this.mesISO,
    required this.caminhoLocal,
    required this.dataCriacaoISO,
  });

  final int id;
  final String mesISO;
  final String caminhoLocal;
  final String dataCriacaoISO;

  factory FotoMensalDeEvolucao.deMapa(Map<String, Object?> map) {
    return FotoMensalDeEvolucao(
      id: (map['id'] as num).toInt(),
      mesISO: map['mesISO'] as String,
      caminhoLocal: map['caminhoLocal'] as String,
      dataCriacaoISO: map['dataCriacaoISO'] as String,
    );
  }
}

class SerieDoTreinoEmAndamento {
  const SerieDoTreinoEmAndamento({
    required this.numeroSerie,
    required this.cargaAtual,
    required this.repeticoesAtual,
    required this.concluido,
  });

  final int numeroSerie;
  final double cargaAtual;
  final int repeticoesAtual;
  final bool concluido;
}

class ExercicioDoTreinoEmAndamento {
  const ExercicioDoTreinoEmAndamento({
    required this.exercicio,
    required this.progressoDasSeries,
  });

  final ExercicioPlanejado exercicio;
  final List<SerieDoTreinoEmAndamento> progressoDasSeries;
}

class TreinoEmAndamento {
  const TreinoEmAndamento({
    required this.dataInicioISO,
    required this.diaSemana,
    required this.descansoSegundos,
    required this.exercicios,
    this.descansoAteISO,
    this.idExercicioDescanso,
  });

  final String dataInicioISO;
  final int diaSemana;
  final int descansoSegundos;
  final String? descansoAteISO;
  final int? idExercicioDescanso;
  final List<ExercicioDoTreinoEmAndamento> exercicios;
}
