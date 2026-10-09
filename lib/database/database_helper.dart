import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/workout_plan_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const String _databaseName = 'offline_gym.db';
  static const int _databaseVersion = 5;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final opened = await openDatabase(
      p.join(dbPath, _databaseName),
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _database = opened;
    return opened;
  }

  Future<void> _onConfigure(Database db) async {
    // Configure FKs before SQLite starts the create/upgrade transaction.
    await db.execute('PRAGMA foreign_keys = ON;');
    final result = await db.rawQuery('PRAGMA foreign_keys;');
    if (result.isNotEmpty && (result.first.values.first as int) != 1) {
      throw StateError('SQLite foreign-key enforcement could not be enabled.');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // onConfigure already enables FKs outside the schema transaction. Repeat
    // the pragma here for clarity; it remains enabled from onConfigure.
    await db.execute('PRAGMA foreign_keys = ON;');
    await _createSchema(db);
    await _seedWeekdays(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Additive migration: keep previous app data and legacy tables intact.
    await db.execute('PRAGMA foreign_keys = ON;');
    // If this database already contains the target tables from an earlier
    // iteration, add newly introduced columns before creating indexes.
    if (await _tableExists(db, 'exercicios_plano')) {
      await _ensureColumn(db, 'exercicios_plano', 'diaSemana', 'INTEGER NOT NULL DEFAULT 1');
      await _ensureColumn(db, 'exercicios_plano', 'nome', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(db, 'exercicios_plano', 'carga', 'REAL NOT NULL DEFAULT 0');
      await _ensureColumn(db, 'exercicios_plano', 'series', 'INTEGER NOT NULL DEFAULT 3');
      await _ensureColumn(db, 'exercicios_plano', 'repeticoes', 'INTEGER NOT NULL DEFAULT 10');
      await _ensureColumn(db, 'exercicios_plano', 'urlGif', 'TEXT');
      await _ensureColumn(db, 'exercicios_plano', 'caminhoLocalGif', 'TEXT');
    }
    if (await _tableExists(db, 'historico_treinos')) {
      await _ensureColumn(db, 'historico_treinos', 'dataISO', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(db, 'historico_treinos', 'tempoTotalSegundos', 'INTEGER NOT NULL DEFAULT 0');
      await _ensureColumn(db, 'historico_treinos', 'diaSemana', 'INTEGER NOT NULL DEFAULT 1');
    }
    if (await _tableExists(db, 'historico_series')) {
      await _ensureColumn(db, 'historico_series', 'idHistoricoTreino', 'INTEGER NOT NULL DEFAULT 0');
      await _ensureColumn(db, 'historico_series', 'nomeExercicio', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(db, 'historico_series', 'cargaUtilizada', 'REAL NOT NULL DEFAULT 0');
      await _ensureColumn(db, 'historico_series', 'serieNumero', 'INTEGER NOT NULL DEFAULT 1');
    }
    await _createSchema(db);
    await _seedWeekdays(db);
    await _migrateLegacyWorkoutData(db);
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dias_plano (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaSemana INTEGER NOT NULL UNIQUE CHECK(diaSemana BETWEEN 1 AND 7)
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercicios_plano (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaSemana INTEGER NOT NULL,
        nome TEXT NOT NULL,
        carga REAL NOT NULL DEFAULT 0,
        series INTEGER NOT NULL DEFAULT 3,
        repeticoes INTEGER NOT NULL DEFAULT 10,
        urlGif TEXT,
        caminhoLocalGif TEXT,
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historico_treinos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL,
        tempoTotalSegundos INTEGER NOT NULL DEFAULT 0,
        diaSemana INTEGER NOT NULL,
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE RESTRICT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historico_series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idHistoricoTreino INTEGER NOT NULL,
        nomeExercicio TEXT NOT NULL,
        cargaUtilizada REAL NOT NULL DEFAULT 0,
        serieNumero INTEGER NOT NULL,
        FOREIGN KEY(idHistoricoTreino) REFERENCES historico_treinos(id)
          ON UPDATE CASCADE ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS peso_corporal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL,
        pesoKg REAL NOT NULL CHECK(pesoKg > 0)
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS treino_em_andamento (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        dataInicioISO TEXT NOT NULL,
        diaSemana INTEGER NOT NULL,
        descansoSegundos INTEGER NOT NULL DEFAULT 60,
        descansoAteISO TEXT,
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE RESTRICT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS series_em_andamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idSessao INTEGER NOT NULL DEFAULT 1,
        idExercicioPlano INTEGER NOT NULL,
        diaSemana INTEGER NOT NULL,
        nomeExercicio TEXT NOT NULL,
        cargaPadrao REAL NOT NULL DEFAULT 0,
        seriesTotal INTEGER NOT NULL DEFAULT 3,
        repeticoes INTEGER NOT NULL DEFAULT 10,
        urlGif TEXT,
        caminhoLocalGif TEXT,
        serieNumero INTEGER NOT NULL,
        cargaAtual REAL NOT NULL DEFAULT 0,
        concluido INTEGER NOT NULL DEFAULT 0 CHECK(concluido IN (0, 1)),
        UNIQUE(idSessao, idExercicioPlano, serieNumero),
        FOREIGN KEY(idSessao) REFERENCES treino_em_andamento(id)
          ON UPDATE CASCADE ON DELETE CASCADE
      );
    ''');

    // These indexes speed up daily plan lookup, attendance calendar and trends.
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercicios_plano_dia
      ON exercicios_plano(diaSemana, id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_historico_data
      ON historico_treinos(dataISO);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_historico_series_exercicio
      ON historico_series(nomeExercicio, idHistoricoTreino);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_peso_corporal_data
      ON peso_corporal(dataISO DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_series_andamento_sessao
      ON series_em_andamento(idSessao, idExercicioPlano, serieNumero);
    ''');
  }

  Future<void> _ensureColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String declaration,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table);');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $declaration;');
    }
  }

  Future<void> _seedWeekdays(DatabaseExecutor db) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await db.insert(
        'dias_plano',
        <String, Object?>{'diaSemana': weekday},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1;",
      <Object?>[tableName],
    );
    return rows.isNotEmpty;
  }

  Future<Set<String>> _columnNames(DatabaseExecutor db, String tableName) async {
    final rows = await db.rawQuery('PRAGMA table_info($tableName);');
    return rows.map((row) => row['name'].toString()).toSet();
  }

  /// Carries data forward from the previous Offline Gym schema. Legacy tables
  /// are intentionally retained, so the migration is non-destructive.
  Future<void> _migrateLegacyWorkoutData(DatabaseExecutor db) async {
    final legacyPlansExist = await _tableExists(db, 'planos_treino') &&
        await _tableExists(db, 'itens_treino') &&
        await _tableExists(db, 'exercicios');

    final plannedCountRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM exercicios_plano;',
    );
    final plannedCount = (plannedCountRows.first['total'] as num).toInt();
    if (legacyPlansExist && plannedCount == 0) {
      final legacyPlanColumns = await _columnNames(db, 'planos_treino');
      final hadWeekdayColumn = legacyPlanColumns.contains('diaSemana');
      if (!hadWeekdayColumn) {
        await db.execute(
          'ALTER TABLE planos_treino ADD COLUMN diaSemana INTEGER NOT NULL DEFAULT 1;',
        );
      }

      final legacyPlans = await db.query('planos_treino', orderBy: 'id ASC');
      final exerciseColumns = await _columnNames(db, 'exercicios');
      final urlSelect = exerciseColumns.contains('urlRemotaGif')
          ? 'e.urlRemotaGif'
          : 'NULL AS urlRemotaGif';
      final localPathSelect = exerciseColumns.contains('caminhoLocalGif')
          ? 'e.caminhoLocalGif'
          : 'NULL AS caminhoLocalGif';

      for (var index = 0; index < legacyPlans.length; index++) {
        final legacyPlan = legacyPlans[index];
        final legacyPlanId = (legacyPlan['id'] as num).toInt();
        final int weekday;
        if (hadWeekdayColumn) {
          weekday = (((legacyPlan['diaSemana'] as num?)?.toInt() ?? ((index % 7) + 1))
              .clamp(1, 7)).toInt();
        } else {
          weekday = (index % 7) + 1;
          await db.update(
            'planos_treino',
            <String, Object?>{'diaSemana': weekday},
            where: 'id = ?',
            whereArgs: <Object?>[legacyPlanId],
          );
        }

        final itemRows = await db.rawQuery('''
          SELECT e.nome AS nome,
                 i.series AS series,
                 i.repeticoes AS repeticoes,
                 i.cargaPadrao AS carga,
                 $urlSelect AS urlRemotaGif,
                 $localPathSelect AS caminhoLocalGif
          FROM itens_treino AS i
          INNER JOIN exercicios AS e ON e.id = i.idExercicio
          WHERE i.idPlano = ?
          ORDER BY i.id ASC;
        ''', <Object?>[legacyPlanId]);

        for (final row in itemRows) {
          await db.insert(
            'exercicios_plano',
            <String, Object?>{
              'diaSemana': weekday,
              'nome': (row['nome'] ?? '').toString(),
              'carga': (row['carga'] as num?)?.toDouble() ?? 0,
              'series': (row['series'] as num?)?.toInt() ?? 3,
              'repeticoes': (row['repeticoes'] as num?)?.toInt() ?? 10,
              'urlGif': row['urlRemotaGif'],
              'caminhoLocalGif': row['caminhoLocalGif'],
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
    }

    final legacyHistoryExists = await _tableExists(db, 'registros_treino');
    final historyCountRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM historico_treinos;',
    );
    final historyCount = (historyCountRows.first['total'] as num).toInt();
    if (!legacyHistoryExists || historyCount > 0) return;

    final legacyHistoryColumns = await _columnNames(db, 'registros_treino');
    if (!legacyHistoryColumns.contains('data')) return;
    final legacyRows = await db.query('registros_treino', orderBy: 'id ASC');
    final canReadCompletionFlag = legacyHistoryColumns.contains('statusConcluido');
    final canReadDuration = legacyHistoryColumns.contains('tempoTotalSegundos');
    final seriesTableExists = await _tableExists(db, 'registros_serie');
    final exercisesTableExists = await _tableExists(db, 'exercicios');
    final seriesColumns = seriesTableExists
        ? await _columnNames(db, 'registros_serie')
        : <String>{};

    for (final legacy in legacyRows) {
      if (canReadCompletionFlag && (legacy['statusConcluido'] as num?)?.toInt() != 1) {
        continue;
      }
      final parsedDate = DateTime.tryParse((legacy['data'] ?? '').toString());
      if (parsedDate == null) continue;
      final legacyId = (legacy['id'] as num).toInt();
      final newId = await db.insert(
        'historico_treinos',
        <String, Object?>{
          'dataISO': parsedDate.toIso8601String(),
          'tempoTotalSegundos': canReadDuration
              ? ((legacy['tempoTotalSegundos'] as num?)?.toInt() ?? 0)
              : 0,
          'diaSemana': parsedDate.weekday,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      if (!seriesTableExists || !exercisesTableExists ||
          !seriesColumns.contains('idRegistroTreino') ||
          !seriesColumns.contains('idExercicio')) {
        continue;
      }
      final completedClause = seriesColumns.contains('concluido') ? 'AND s.concluido = 1' : '';
      final seriesRows = await db.rawQuery('''
        SELECT e.nome AS nomeExercicio,
               s.cargaUtilizada AS cargaUtilizada,
               s.numeroSerie AS serieNumero
        FROM registros_serie AS s
        INNER JOIN exercicios AS e ON e.id = s.idExercicio
        WHERE s.idRegistroTreino = ? $completedClause
        ORDER BY s.numeroSerie ASC;
      ''', <Object?>[legacyId]);
      for (final setRow in seriesRows) {
        await db.insert(
          'historico_series',
          <String, Object?>{
            'idHistoricoTreino': newId,
            'nomeExercicio': (setRow['nomeExercicio'] ?? '').toString(),
            'cargaUtilizada': (setRow['cargaUtilizada'] as num?)?.toDouble() ?? 0,
            'serieNumero': (setRow['serieNumero'] as num?)?.toInt() ?? 1,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    }
  }

  Future<List<WorkoutPlanModel>> getExercisesForDay(int weekday) async {
    final db = await database;
    final rows = await db.query(
      'exercicios_plano',
      where: 'diaSemana = ?',
      whereArgs: <Object?>[weekday],
      orderBy: 'id ASC',
    );
    return rows.map(WorkoutPlanModel.fromMap).toList(growable: false);
  }

  Future<Map<int, List<WorkoutPlanModel>>> getAllDayPlans() async {
    final db = await database;
    final rows = await db.query('exercicios_plano', orderBy: 'diaSemana, id');
    final grouped = <int, List<WorkoutPlanModel>>{
      for (var weekday = 1; weekday <= 7; weekday++) weekday: <WorkoutPlanModel>[],
    };
    for (final row in rows) {
      final plan = WorkoutPlanModel.fromMap(row);
      grouped.putIfAbsent(plan.diaSemana, () => <WorkoutPlanModel>[]).add(plan);
    }
    return grouped;
  }

  /// Replaces only a day's child rows in a transaction. It never uses
  /// INSERT OR REPLACE, so referenced primary keys are not deleted implicitly.
  Future<void> saveDayExercises(
    int weekday,
    List<WorkoutPlanModel> exercises,
  ) async {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(weekday, 'weekday', 'Must be 1 through 7.');
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'dias_plano',
        <String, Object?>{'diaSemana': weekday},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.delete(
        'exercicios_plano',
        where: 'diaSemana = ?',
        whereArgs: <Object?>[weekday],
      );
      for (final exercise in exercises) {
        final normalized = exercise.copyWith(diaSemana: weekday);
        await txn.insert(
          'exercicios_plano',
          normalized.toMap(includeId: false),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  /// Safe upsert: UPDATE the existing row or INSERT a new one. Never REPLACE.
  Future<int> upsertPlannedExercise(WorkoutPlanModel exercise) async {
    final db = await database;
    if (exercise.id != null) {
      final updated = await db.update(
        'exercicios_plano',
        exercise.toMap(includeId: false),
        where: 'id = ?',
        whereArgs: <Object?>[exercise.id],
      );
      if (updated > 0) return exercise.id!;
    }
    return db.insert(
      'exercicios_plano',
      exercise.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateExerciseLoad(int exerciseId, double loadKg) async {
    final db = await database;
    await db.update(
      'exercicios_plano',
      <String, Object?>{'carga': loadKg},
      where: 'id = ?',
      whereArgs: <Object?>[exerciseId],
    );
  }

  Future<void> saveActiveWorkoutSnapshot(ActiveWorkoutSnapshotModel snapshot) async {
    final db = await database;
    await db.transaction((txn) async {
      // Deleting this one draft cascades only its draft-series rows. The
      // completed history tables are never touched here.
      await txn.delete('treino_em_andamento', where: 'id = ?', whereArgs: <Object?>[1]);
      await txn.insert('treino_em_andamento', <String, Object?>{
        'id': 1,
        'dataInicioISO': snapshot.dataInicioISO,
        'diaSemana': snapshot.diaSemana,
        'descansoSegundos': snapshot.descansoSegundos,
        'descansoAteISO': snapshot.descansoAteISO,
      });
      for (final exerciseSnapshot in snapshot.exercises) {
        final exercise = exerciseSnapshot.exercise;
        final exerciseId = exercise.id;
        if (exerciseId == null) {
          throw StateError('Não é possível recuperar um exercício sem ID local.');
        }
        for (final progress in exerciseSnapshot.seriesProgress) {
          await txn.insert('series_em_andamento', <String, Object?>{
            'idSessao': 1,
            'idExercicioPlano': exerciseId,
            'diaSemana': exercise.diaSemana,
            'nomeExercicio': exercise.nome,
            'cargaPadrao': exercise.carga,
            'seriesTotal': exercise.series,
            'repeticoes': exercise.repeticoes,
            'urlGif': null,
            'caminhoLocalGif': exercise.caminhoLocalGif,
            'serieNumero': progress.numeroSerie,
            'cargaAtual': progress.cargaAtual,
            'concluido': progress.concluido ? 1 : 0,
          });
        }
      }
    });
  }

  Future<ActiveWorkoutSnapshotModel?> getActiveWorkoutSnapshot() async {
    final db = await database;
    final sessionRows = await db.query(
      'treino_em_andamento',
      where: 'id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    if (sessionRows.isEmpty) return null;
    final session = sessionRows.first;
    final rows = await db.query(
      'series_em_andamento',
      where: 'idSessao = ?',
      whereArgs: <Object?>[1],
      orderBy: 'idExercicioPlano ASC, serieNumero ASC',
    );

    final exerciseById = <int, WorkoutPlanModel>{};
    final seriesByExercise = <int, List<ActiveWorkoutSeriesModel>>{};
    for (final row in rows) {
      final exerciseId = (row['idExercicioPlano'] as num).toInt();
      exerciseById.putIfAbsent(exerciseId, () => WorkoutPlanModel(
            id: exerciseId,
            diaSemana: (row['diaSemana'] as num).toInt(),
            nome: row['nomeExercicio'] as String,
            carga: (row['cargaPadrao'] as num?)?.toDouble() ?? 0,
            series: (row['seriesTotal'] as num?)?.toInt() ?? 3,
            repeticoes: (row['repeticoes'] as num?)?.toInt() ?? 10,
            urlGif: null,
            caminhoLocalGif: row['caminhoLocalGif'] as String?,
          ));
      seriesByExercise.putIfAbsent(exerciseId, () => <ActiveWorkoutSeriesModel>[]).add(
            ActiveWorkoutSeriesModel(
              numeroSerie: (row['serieNumero'] as num).toInt(),
              cargaAtual: (row['cargaAtual'] as num?)?.toDouble() ?? 0,
              concluido: (row['concluido'] as num?)?.toInt() == 1,
            ),
          );
    }

    final snapshots = <ActiveWorkoutExerciseModel>[];
    for (final entry in exerciseById.entries) {
      snapshots.add(ActiveWorkoutExerciseModel(
        exercise: entry.value,
        seriesProgress: seriesByExercise[entry.key] ?? const <ActiveWorkoutSeriesModel>[],
      ));
    }
    final startedAt = DateTime.tryParse(session['dataInicioISO'] as String? ?? '');
    if (startedAt == null || snapshots.isEmpty) {
      await deleteActiveWorkout();
      return null;
    }
    return ActiveWorkoutSnapshotModel(
      dataInicioISO: startedAt.toIso8601String(),
      diaSemana: (session['diaSemana'] as num).toInt(),
      descansoSegundos: (session['descansoSegundos'] as num?)?.toInt() ?? 60,
      descansoAteISO: session['descansoAteISO'] as String?,
      exercises: snapshots,
    );
  }

  Future<void> updateActiveWorkoutSeries({
    required int exercisePlanId,
    required int serieNumero,
    required double cargaAtual,
    required bool concluido,
  }) async {
    final db = await database;
    await db.update(
      'series_em_andamento',
      <String, Object?>{
        'cargaAtual': cargaAtual,
        'concluido': concluido ? 1 : 0,
      },
      where: 'idSessao = ? AND idExercicioPlano = ? AND serieNumero = ?',
      whereArgs: <Object?>[1, exercisePlanId, serieNumero],
    );
  }

  Future<void> updateActiveWorkoutRest({
    required int descansoSegundos,
    required String? descansoAteISO,
  }) async {
    final db = await database;
    await db.update(
      'treino_em_andamento',
      <String, Object?>{
        'descansoSegundos': descansoSegundos,
        'descansoAteISO': descansoAteISO,
      },
      where: 'id = ?',
      whereArgs: <Object?>[1],
    );
  }

  Future<void> deleteActiveWorkout() async {
    final db = await database;
    await db.delete('treino_em_andamento', where: 'id = ?', whereArgs: <Object?>[1]);
  }

  Future<int> insertBodyWeight({required DateTime date, required double weightKg}) async {
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Informe um peso maior que zero.');
    }
    final db = await database;
    return db.insert('peso_corporal', <String, Object?>{
      'dataISO': date.toIso8601String(),
      'pesoKg': weightKg,
    });
  }

  Future<List<BodyWeightRecord>> getBodyWeights() async {
    final db = await database;
    final rows = await db.query('peso_corporal', orderBy: 'dataISO DESC, id DESC');
    return rows.map(BodyWeightRecord.fromMap).toList(growable: false);
  }

  Future<void> deleteBodyWeight(int id) async {
    final db = await database;
    await db.delete('peso_corporal', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<EvolutionPoint>> getBodyWeightEvolution() async {
    final db = await database;
    final rows = await db.query('peso_corporal', columns: <String>['dataISO', 'pesoKg'], orderBy: 'dataISO ASC, id ASC');
    final points = <EvolutionPoint>[];
    for (final row in rows) {
      final date = DateTime.tryParse(row['dataISO'] as String? ?? '');
      final weight = (row['pesoKg'] as num?)?.toDouble();
      if (date != null && weight != null) points.add(EvolutionPoint(date: date, loadKg: weight));
    }
    return points;
  }

  Future<int> saveWorkoutSession({
    required String dataISO,
    required int tempoTotalSegundos,
    required int diaSemana,
    required List<WorkoutSetModel> sets,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final historyId = await txn.insert(
        'historico_treinos',
        <String, Object?>{
          'dataISO': dataISO,
          'tempoTotalSegundos': tempoTotalSegundos,
          'diaSemana': diaSemana,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      for (final set in sets) {
        await txn.insert(
          'historico_series',
          set.toMap(idHistoricoTreino: historyId),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      await txn.delete('treino_em_andamento', where: 'id = ?', whereArgs: <Object?>[1]);
      return historyId;
    });
  }

  Future<void> deleteWorkoutSession(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'historico_series',
        where: 'idHistoricoTreino = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete(
        'historico_treinos',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  Future<List<HistoryWorkoutModel>> getWorkoutHistory() async {
    final db = await database;
    final rows = await db.query('historico_treinos', orderBy: 'dataISO DESC, id DESC');
    return rows.map(HistoryWorkoutModel.fromMap).toList(growable: false);
  }

  Future<List<String>> getDistinctPlannedExerciseNames() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT nome
      FROM exercicios_plano
      WHERE TRIM(nome) <> ''
      ORDER BY nome COLLATE NOCASE ASC;
    ''');
    return rows.map((row) => row['nome'] as String).toList(growable: false);
  }

  Future<List<EvolutionPoint>> getEvolutionPoints(String exerciseName) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT substr(h.dataISO, 1, 10) AS dataDia,
             MAX(s.cargaUtilizada) AS cargaMaxima
      FROM historico_series AS s
      INNER JOIN historico_treinos AS h ON h.id = s.idHistoricoTreino
      WHERE s.nomeExercicio = ?
      GROUP BY substr(h.dataISO, 1, 10)
      ORDER BY dataDia ASC;
    ''', <Object?>[exerciseName]);

    final points = <EvolutionPoint>[];
    for (final row in rows) {
      final date = DateTime.tryParse((row['dataDia'] ?? '').toString());
      final load = (row['cargaMaxima'] as num?)?.toDouble();
      if (date != null && load != null) {
        points.add(EvolutionPoint(date: date, loadKg: load));
      }
    }
    return points;
  }

  Future<Set<DateTime>> getCompletedWorkoutDates() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT substr(dataISO, 1, 10) AS dataDia
      FROM historico_treinos
      ORDER BY dataDia ASC;
    ''');
    final result = <DateTime>{};
    for (final row in rows) {
      final parsed = DateTime.tryParse((row['dataDia'] ?? '').toString());
      if (parsed != null) result.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    return result;
  }
}
