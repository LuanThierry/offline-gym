class WorkoutPlanModel {
  const WorkoutPlanModel({
    this.id,
    required this.diaSemana,
    required this.nome,
    required this.carga,
    required this.series,
    required this.repeticoes,
    this.urlGif,
    this.caminhoLocalGif,
  });

  final int? id;

  /// Dia ISO: segunda-feira = 1 ... domingo = 7.
  final int diaSemana;
  final String nome;
  final double carga;
  final int series;
  final int repeticoes;
  final String? urlGif; // Mantido para compatibilidade com dados antigos; não é usado para rede.
  final String? caminhoLocalGif;

  static const List<String> weekdayNames = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static String weekdayName(int weekday) {
    if (weekday < 1 || weekday > 7) return 'Dia inválido';
    return weekdayNames[weekday - 1];
  }

  factory WorkoutPlanModel.fromMap(Map<String, Object?> map) {
    return WorkoutPlanModel(
      id: (map['id'] as num?)?.toInt(),
      diaSemana: (map['diaSemana'] as num).toInt(),
      nome: (map['nome'] as String?) ?? '',
      carga: (map['carga'] as num?)?.toDouble() ?? 0,
      series: (map['series'] as num?)?.toInt() ?? 3,
      repeticoes: (map['repeticoes'] as num?)?.toInt() ?? 10,
      urlGif: map['urlGif'] as String?,
      caminhoLocalGif: map['caminhoLocalGif'] as String?,
    );
  }

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: (json['id'] as num?)?.toInt(),
      diaSemana: (json['diaSemana'] as num?)?.toInt() ?? 1,
      nome: (json['nome'] as String?) ?? '',
      carga: (json['carga'] as num?)?.toDouble() ?? 0,
      series: (json['series'] as num?)?.toInt() ?? 3,
      repeticoes: (json['repeticoes'] as num?)?.toInt() ?? 10,
      urlGif: json['urlGif'] as String?,
      caminhoLocalGif: json['caminhoLocalGif'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'diaSemana': diaSemana,
      'nome': nome,
      'carga': carga,
      'series': series,
      'repeticoes': repeticoes,
      'urlGif': urlGif,
      'caminhoLocalGif': caminhoLocalGif,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'diaSemana': diaSemana,
        'nome': nome,
        'carga': carga,
        'series': series,
        'repeticoes': repeticoes,
        'urlGif': urlGif,
        'caminhoLocalGif': caminhoLocalGif,
      };

  WorkoutPlanModel copyWith({
    int? id,
    int? diaSemana,
    String? nome,
    double? carga,
    int? series,
    int? repeticoes,
    String? urlGif,
    String? caminhoLocalGif,
    bool clearUrlGif = false,
    bool clearLocalGif = false,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      diaSemana: diaSemana ?? this.diaSemana,
      nome: nome ?? this.nome,
      carga: carga ?? this.carga,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      urlGif: clearUrlGif ? null : (urlGif ?? this.urlGif),
      caminhoLocalGif: clearLocalGif ? null : (caminhoLocalGif ?? this.caminhoLocalGif),
    );
  }
}

class WorkoutSetModel {
  const WorkoutSetModel({
    required this.nomeExercicio,
    required this.cargaUtilizada,
    required this.serieNumero,
  });

  final String nomeExercicio;
  final double cargaUtilizada;
  final int serieNumero;

  Map<String, Object?> toMap({required int idHistoricoTreino}) => <String, Object?>{
        'idHistoricoTreino': idHistoricoTreino,
        'nomeExercicio': nomeExercicio,
        'cargaUtilizada': cargaUtilizada,
        'serieNumero': serieNumero,
      };
}

class HistoryWorkoutModel {
  const HistoryWorkoutModel({
    required this.id,
    required this.dataISO,
    required this.tempoTotalSegundos,
    required this.diaSemana,
  });

  final int id;
  final String dataISO;
  final int tempoTotalSegundos;
  final int diaSemana;

  factory HistoryWorkoutModel.fromMap(Map<String, Object?> map) {
    return HistoryWorkoutModel(
      id: (map['id'] as num).toInt(),
      dataISO: map['dataISO'] as String,
      tempoTotalSegundos: (map['tempoTotalSegundos'] as num?)?.toInt() ?? 0,
      diaSemana: (map['diaSemana'] as num?)?.toInt() ?? 1,
    );
  }
}

class EvolutionPoint {
  const EvolutionPoint({required this.date, required this.loadKg});

  final DateTime date;
  final double loadKg;
}

class BodyWeightRecord {
  const BodyWeightRecord({
    required this.id,
    required this.dataISO,
    required this.pesoKg,
  });

  final int id;
  final String dataISO;
  final double pesoKg;

  factory BodyWeightRecord.fromMap(Map<String, Object?> map) {
    return BodyWeightRecord(
      id: (map['id'] as num).toInt(),
      dataISO: map['dataISO'] as String,
      pesoKg: (map['pesoKg'] as num).toDouble(),
    );
  }
}

class ActiveWorkoutSeriesModel {
  const ActiveWorkoutSeriesModel({
    required this.numeroSerie,
    required this.cargaAtual,
    required this.concluido,
  });

  final int numeroSerie;
  final double cargaAtual;
  final bool concluido;
}

class ActiveWorkoutExerciseModel {
  const ActiveWorkoutExerciseModel({
    required this.exercise,
    required this.seriesProgress,
  });

  final WorkoutPlanModel exercise;
  final List<ActiveWorkoutSeriesModel> seriesProgress;
}

class ActiveWorkoutSnapshotModel {
  const ActiveWorkoutSnapshotModel({
    required this.dataInicioISO,
    required this.diaSemana,
    required this.descansoSegundos,
    required this.exercises,
    this.descansoAteISO,
  });

  final String dataInicioISO;
  final int diaSemana;
  final int descansoSegundos;
  final String? descansoAteISO;
  final List<ActiveWorkoutExerciseModel> exercises;
}
