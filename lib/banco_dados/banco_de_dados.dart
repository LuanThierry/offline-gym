import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../modelos/habito.dart';
import '../modelos/plano_de_treino.dart';

class BancoDeDados {
  BancoDeDados._();

  static final BancoDeDados instance = BancoDeDados._();
  static const String _databaseName = 'offline_gym.db';
  static const int _databaseVersion = 16;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final opened = await openDatabase(
      p.join(dbPath, _databaseName),
      version: _databaseVersion,
      onConfigure: _configurarBanco,
      onCreate: _criarBanco,
      onUpgrade: _atualizarBanco,
      onOpen: _abrirBanco,
    );
    _database = opened;
    return opened;
  }

  Future<void> _configurarBanco(Database db) async {
    // Ativa chaves estrangeiras antes da transação que cria ou atualiza o esquema.
    await db.execute('PRAGMA foreign_keys = ON;');
    final resultado = await db.rawQuery('PRAGMA foreign_keys;');
    if (resultado.isNotEmpty && (resultado.first.values.first as int) != 1) {
      throw StateError('SQLite foreign-key enforcement could not be enabled.');
    }
  }

  Future<void> _criarBanco(Database db, int version) async {
    // Repete a configuração dentro da criação do banco para manter a regra
    // explícita; o onConfigure também a ativa antes desta transação.
    await db.execute('PRAGMA foreign_keys = ON;');
    await _criarEstruturaDoBanco(db);
    await _preencherDiasDaSemana(db);
  }

  Future<void> _abrirBanco(Database db) async {
    await _criarEstruturaDoBanco(db);
    await _garantirTodasAsColunas(db);
    await _preencherGruposAntigosDeRotina(db);
  }

  Future<void> _atualizarBanco(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migração aditiva: mantém os dados anteriores e as tabelas legadas intactos.
    await db.execute('PRAGMA foreign_keys = ON;');
    await _criarEstruturaDoBanco(db);
    await _garantirTodasAsColunas(db);
    if (oldVersion < 11 && await _tabelaExiste(db, 'series_em_andamento')) {
      await db.execute('''
        UPDATE series_em_andamento
        SET repeticoesAtual = repeticoes
      ''');
    }
    await _preencherDiasDaSemana(db);
    await _migrarDadosLegadosDeTreino(db);
    await _preencherGruposAntigosDeRotina(db);
    if (oldVersion < 16) {
      await normalizarConclusoesLegadasDeHabitos(db);
    }
  }

  /// Antes do progresso incremental, toda conclusão era gravada com valor 1.
  /// Converte esses registros antigos (dias anteriores a hoje) para a meta do
  /// hábito, mantendo o histórico e a ofensiva de hábitos com meta maior que 1.
  static Future<void> normalizarConclusoesLegadasDeHabitos(
    DatabaseExecutor db, {
    bool incluirHoje = false,
  }) async {
    if (!await _tabelaExisteEstatico(db, 'conclusoes_habitos') ||
        !await _tabelaExisteEstatico(db, 'habitos')) {
      return;
    }
    final filtroData = incluirHoje
        ? ''
        : "AND substr(conclusoes_habitos.dataISO, 1, 10) < date('now', 'localtime')";
    await db.execute('''
      UPDATE conclusoes_habitos
      SET valor = (
        SELECT h.metaValor FROM habitos h
        WHERE h.id = conclusoes_habitos.idHabito
      )
      WHERE valor <= 1
        AND EXISTS (
          SELECT 1 FROM habitos h
          WHERE h.id = conclusoes_habitos.idHabito AND h.metaValor > 1
        )
        $filtroData;
    ''');
  }

  static Future<bool> _tabelaExisteEstatico(
    DatabaseExecutor db,
    String tabela,
  ) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      <Object?>[tabela],
    );
    return rows.isNotEmpty;
  }

  Future<void> _garantirTodasAsColunas(DatabaseExecutor db) async {
    if (await _tabelaExiste(db, 'exercicios_plano')) {
      await _garantirColuna(
        db,
        'exercicios_plano',
        'diaSemana',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'nome',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'carga',
        'REAL NOT NULL DEFAULT 0',
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'series',
        'INTEGER NOT NULL DEFAULT 3',
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'repeticoes',
        'INTEGER NOT NULL DEFAULT 10',
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'tempoDescansoSegundos',
        'INTEGER NOT NULL DEFAULT 60',
      );
      await _garantirColuna(db, 'exercicios_plano', 'urlGif', 'TEXT');
      await _garantirColuna(db, 'exercicios_plano', 'caminhoLocalGif', 'TEXT');
      await _garantirColuna(
        db,
        'exercicios_plano',
        'cargasPorSerie',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'repeticoesPorSerie',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'idTreino',
        'INTEGER REFERENCES treinos_plano(id) ON DELETE CASCADE',
      );
      await _garantirColuna(
        db,
        'exercicios_plano',
        'grupoSuperSerie',
        'TEXT',
      );
    }
    if (await _tabelaExiste(db, 'series_em_andamento')) {
      await _garantirColuna(
        db,
        'series_em_andamento',
        'tempoDescansoSegundos',
        'INTEGER NOT NULL DEFAULT 60',
      );
      await _garantirColuna(
        db,
        'series_em_andamento',
        'repeticoesAtual',
        'INTEGER NOT NULL DEFAULT 10',
      );
      await _garantirColuna(db, 'series_em_andamento', 'idTreino', 'INTEGER');
      await _garantirColuna(
        db,
        'series_em_andamento',
        'nomeTreino',
        "TEXT NOT NULL DEFAULT 'Treino principal'",
      );
    }
    if (await _tabelaExiste(db, 'treino_em_andamento')) {
      await _garantirColuna(
        db,
        'treino_em_andamento',
        'idExercicioDescanso',
        'INTEGER',
      );
    }
    if (await _tabelaExiste(db, 'historico_treinos')) {
      await _garantirColuna(
        db,
        'historico_treinos',
        'dataISO',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'historico_treinos',
        'tempoTotalSegundos',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _garantirColuna(
        db,
        'historico_treinos',
        'diaSemana',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _garantirColuna(
        db,
        'historico_treinos',
        'nomeTreino',
        "TEXT NOT NULL DEFAULT ''",
      );
    }
    if (await _tabelaExiste(db, 'treinos_plano')) {
      await _garantirColuna(
        db,
        'treinos_plano',
        'selecionado',
        'INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (await _tabelaExiste(db, 'historico_series')) {
      await _garantirColuna(
        db,
        'historico_series',
        'idHistoricoTreino',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _garantirColuna(
        db,
        'historico_series',
        'nomeExercicio',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'historico_series',
        'cargaUtilizada',
        'REAL NOT NULL DEFAULT 0',
      );
      await _garantirColuna(
        db,
        'historico_series',
        'serieNumero',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _garantirColuna(
        db,
        'historico_series',
        'repeticoes',
        'INTEGER NOT NULL DEFAULT 10',
      );
      await _garantirColuna(
        db,
        'historico_series',
        'tipo',
        "TEXT NOT NULL DEFAULT 'normal'",
      );
      await _garantirColuna(
        db,
        'historico_series',
        'rpe',
        'REAL',
      );
    }
    if (await _tabelaExiste(db, 'diario_treino')) {
      await _garantirColuna(
        db,
        'diario_treino',
        'dataISO',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'diario_treino',
        'conteudo',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'diario_treino',
        'caminhosImagens',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _garantirColuna(
        db,
        'diario_treino',
        'dataAtualizacaoISO',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _garantirColuna(
        db,
        'diario_treino',
        'figurinhas',
        "TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (await _tabelaExiste(db, 'perfil_usuario')) {
      await _garantirColuna(db, 'perfil_usuario', 'metaPesoKg', 'REAL');
      await _garantirColuna(
        db,
        'perfil_usuario',
        'objetivoPrincipal',
        "TEXT NOT NULL DEFAULT 'Hipertrofia'",
      );
      await _garantirColuna(
        db,
        'perfil_usuario',
        'nivelExperiencia',
        "TEXT NOT NULL DEFAULT 'Iniciante'",
      );
      await _garantirColuna(
        db,
        'perfil_usuario',
        'onboardingConcluido',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _garantirColuna(db, 'perfil_usuario', 'alturaCm', 'REAL');
      await _garantirColuna(
        db,
        'perfil_usuario',
        'sexo',
        "TEXT NOT NULL DEFAULT 'Masculino'",
      );
      await _garantirColuna(
        db,
        'perfil_usuario',
        'fatorAtividade',
        'REAL NOT NULL DEFAULT 1.55',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medidas_corporais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL,
        bracoDireitoCm REAL,
        bracoEsquerdoCm REAL,
        peitoralCm REAL,
        cinturaCm REAL,
        abdomenCm REAL,
        coxaDireitaCm REAL,
        coxaEsquerdaCm REAL,
        panturrilhaDireitaCm REAL,
        panturrilhaEsquerdaCm REAL,
        observacoes TEXT
      );
    ''');
    if (await _tabelaExiste(db, 'habitos')) {
      await _garantirColuna(
        db,
        'habitos',
        'diasSemana',
        "TEXT NOT NULL DEFAULT '[1,2,3,4,5,6,7]'",
      );
      await _garantirColuna(
        db,
        'habitos',
        'metaValor',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _garantirColuna(
        db,
        'habitos',
        'metaUnidade',
        "TEXT NOT NULL DEFAULT 'vez'",
      );
      await _garantirColuna(
        db,
        'habitos',
        'ordem',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (await _tabelaExiste(db, 'conclusoes_habitos')) {
      await _garantirColuna(
        db,
        'conclusoes_habitos',
        'valor',
        'REAL NOT NULL DEFAULT 1.0',
      );
    }
    if (await _tabelaExiste(db, 'tarefas_todo')) {
      await _garantirColuna(
        db,
        'tarefas_todo',
        'prioridade',
        "TEXT NOT NULL DEFAULT 'media'",
      );
      await _garantirColuna(
        db,
        'tarefas_todo',
        'categoria',
        "TEXT NOT NULL DEFAULT 'Geral'",
      );
      await _garantirColuna(
        db,
        'tarefas_todo',
        'ordem',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _preencherGruposAntigosDeRotina(DatabaseExecutor db) async {
    final ungrouped = await db.rawQuery('''
      SELECT DISTINCT diaSemana
      FROM exercicios_plano
      WHERE idTreino IS NULL
      ORDER BY diaSemana ASC;
    ''');
    for (final row in ungrouped) {
      final diaSemana = (row['diaSemana'] as num).toInt();
      final idRotina = await db.insert(
          'treinos_plano',
          <String, Object?>{
            'diaSemana': diaSemana,
            'nome': 'Treino A',
            'selecionado': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.abort);
      await db.update(
        'exercicios_plano',
        <String, Object?>{'idTreino': idRotina},
        where: 'diaSemana = ? AND idTreino IS NULL',
        whereArgs: <Object?>[diaSemana],
      );
    }
  }

  Future<void> _criarEstruturaDoBanco(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dias_plano (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaSemana INTEGER NOT NULL UNIQUE CHECK(diaSemana BETWEEN 1 AND 7)
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS treinos_plano (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaSemana INTEGER NOT NULL,
        nome TEXT NOT NULL,
        selecionado INTEGER NOT NULL DEFAULT 1 CHECK(selecionado IN (0, 1)),
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercicios_plano (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaSemana INTEGER NOT NULL,
        idTreino INTEGER,
        nome TEXT NOT NULL,
        carga REAL NOT NULL DEFAULT 0,
        series INTEGER NOT NULL DEFAULT 3,
        repeticoes INTEGER NOT NULL DEFAULT 10,
        tempoDescansoSegundos INTEGER NOT NULL DEFAULT 60,
        urlGif TEXT,
        caminhoLocalGif TEXT,
        cargasPorSerie TEXT NOT NULL DEFAULT '[]',
        repeticoesPorSerie TEXT NOT NULL DEFAULT '[]',
        grupoSuperSerie TEXT,
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY(idTreino) REFERENCES treinos_plano(id)
          ON UPDATE CASCADE ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historico_treinos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL,
        tempoTotalSegundos INTEGER NOT NULL DEFAULT 0,
        diaSemana INTEGER NOT NULL,
        nomeTreino TEXT NOT NULL DEFAULT '',
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
        repeticoes INTEGER NOT NULL DEFAULT 10,
        tipo TEXT NOT NULL DEFAULT 'normal',
        rpe REAL,
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
      CREATE TABLE IF NOT EXISTS medidas_corporais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL,
        bracoDireitoCm REAL,
        bracoEsquerdoCm REAL,
        peitoralCm REAL,
        cinturaCm REAL,
        abdomenCm REAL,
        coxaDireitaCm REAL,
        coxaEsquerdaCm REAL,
        panturrilhaDireitaCm REAL,
        panturrilhaEsquerdaCm REAL,
        observacoes TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fotos_evolucao_mensal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mesISO TEXT NOT NULL,
        caminhoLocal TEXT NOT NULL,
        dataCriacaoISO TEXT NOT NULL,
        UNIQUE(mesISO, caminhoLocal)
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS treino_em_andamento (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        dataInicioISO TEXT NOT NULL,
        diaSemana INTEGER NOT NULL,
        descansoSegundos INTEGER NOT NULL DEFAULT 60,
        descansoAteISO TEXT,
        idExercicioDescanso INTEGER,
        FOREIGN KEY(diaSemana) REFERENCES dias_plano(diaSemana)
          ON UPDATE CASCADE ON DELETE RESTRICT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS series_em_andamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idSessao INTEGER NOT NULL DEFAULT 1,
        idExercicioPlano INTEGER NOT NULL,
        idTreino INTEGER,
        diaSemana INTEGER NOT NULL,
        nomeExercicio TEXT NOT NULL,
        nomeTreino TEXT NOT NULL DEFAULT 'Treino principal',
        cargaPadrao REAL NOT NULL DEFAULT 0,
        seriesTotal INTEGER NOT NULL DEFAULT 3,
        repeticoes INTEGER NOT NULL DEFAULT 10,
        repeticoesAtual INTEGER NOT NULL DEFAULT 10,
        tempoDescansoSegundos INTEGER NOT NULL DEFAULT 60,
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS diario_treino (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataISO TEXT NOT NULL UNIQUE,
        conteudo TEXT NOT NULL DEFAULT '',
        caminhosImagens TEXT NOT NULL DEFAULT '[]',
        figurinhas TEXT NOT NULL DEFAULT '[]',
        dataAtualizacaoISO TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS perfil_usuario (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        nome TEXT NOT NULL,
        idade INTEGER,
        caminhoFoto TEXT,
        lembretesAtivos INTEGER NOT NULL DEFAULT 1,
        horaLembrete INTEGER NOT NULL DEFAULT 9,
        minutoLembrete INTEGER NOT NULL DEFAULT 0,
        metaPesoKg REAL,
        objetivoPrincipal TEXT NOT NULL DEFAULT 'Hipertrofia',
        nivelExperiencia TEXT NOT NULL DEFAULT 'Iniciante',
        onboardingConcluido INTEGER NOT NULL DEFAULT 1,
        alturaCm REAL,
        sexo TEXT NOT NULL DEFAULT 'Masculino',
        fatorAtividade REAL NOT NULL DEFAULT 1.55
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habitos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL DEFAULT '',
        categoria TEXT NOT NULL DEFAULT 'Geral',
        iconeCodePoint INTEGER NOT NULL DEFAULT 58715,
        corValor INTEGER NOT NULL DEFAULT 4285283559,
        diasSemana TEXT NOT NULL DEFAULT '[1,2,3,4,5,6,7]',
        metaValor INTEGER NOT NULL DEFAULT 1,
        metaUnidade TEXT NOT NULL DEFAULT 'vez',
        ordem INTEGER NOT NULL DEFAULT 0,
        ativo INTEGER NOT NULL DEFAULT 1,
        dataCriacaoISO TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conclusoes_habitos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idHabito INTEGER NOT NULL,
        dataISO TEXT NOT NULL,
        valor REAL NOT NULL DEFAULT 1.0,
        UNIQUE(idHabito, dataISO),
        FOREIGN KEY(idHabito) REFERENCES habitos(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tarefas_todo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        dataLimiteISO TEXT,
        concluida INTEGER NOT NULL DEFAULT 0,
        prioridade TEXT NOT NULL DEFAULT 'media',
        categoria TEXT NOT NULL DEFAULT 'Geral',
        ordem INTEGER NOT NULL DEFAULT 0,
        dataCriacaoISO TEXT NOT NULL
      );
    ''');

    // Índices aceleram a busca de planos, as marcações do calendário e os gráficos.
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habitos_ordem
      ON habitos(ordem, id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_conclusoes_habitos_data
      ON conclusoes_habitos(dataISO, idHabito);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tarefas_todo_concluida
      ON tarefas_todo(concluida, ordem, id);
    ''');
  }

  Future<void> _garantirColuna(
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

  Future<void> _preencherDiasDaSemana(DatabaseExecutor db) async {
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      await db.insert(
          'dias_plano',
          <String, Object?>{
            'diaSemana': diaSemana,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<bool> _tabelaExiste(DatabaseExecutor db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1;",
      <Object?>[tableName],
    );
    return rows.isNotEmpty;
  }

  Future<Set<String>> _columnNames(
    DatabaseExecutor db,
    String tableName,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($tableName);');
    return rows.map((row) => row['name'].toString()).toSet();
  }

  /// Migra dados do esquema anterior do Offline Gym.
  /// As tabelas antigas são mantidas para a migração não descartar registros.
  Future<void> _migrarDadosLegadosDeTreino(DatabaseExecutor db) async {
    final legacyPlansExist = await _tabelaExiste(db, 'planos_treino') &&
        await _tabelaExiste(db, 'itens_treino') &&
        await _tabelaExiste(db, 'exercicios');

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

      for (var indice = 0; indice < legacyPlans.length; indice++) {
        final legacyPlan = legacyPlans[indice];
        final legacyPlanId = (legacyPlan['id'] as num).toInt();
        final int diaSemana;
        if (hadWeekdayColumn) {
          diaSemana = (((legacyPlan['diaSemana'] as num?)?.toInt() ??
                      ((indice % 7) + 1))
                  .clamp(1, 7))
              .toInt();
        } else {
          diaSemana = (indice % 7) + 1;
          await db.update(
            'planos_treino',
            <String, Object?>{'diaSemana': diaSemana},
            where: 'id = ?',
            whereArgs: <Object?>[legacyPlanId],
          );
        }

        final itemRows = await db.rawQuery(
          '''
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
        ''',
          <Object?>[legacyPlanId],
        );

        for (final row in itemRows) {
          await db.insert(
              'exercicios_plano',
              <String, Object?>{
                'diaSemana': diaSemana,
                'nome': (row['nome'] ?? '').toString(),
                'carga': (row['carga'] as num?)?.toDouble() ?? 0,
                'series': (row['series'] as num?)?.toInt() ?? 3,
                'repeticoes': (row['repeticoes'] as num?)?.toInt() ?? 10,
                'urlGif': row['urlRemotaGif'],
                'caminhoLocalGif': row['caminhoLocalGif'],
              },
              conflictAlgorithm: ConflictAlgorithm.abort);
        }
      }
    }

    final legacyHistoryExists = await _tabelaExiste(db, 'registros_treino');
    final historyCountRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM historico_treinos;',
    );
    final historyCount = (historyCountRows.first['total'] as num).toInt();
    if (!legacyHistoryExists || historyCount > 0) return;

    final legacyHistoryColumns = await _columnNames(db, 'registros_treino');
    if (!legacyHistoryColumns.contains('data')) return;
    final legacyRows = await db.query('registros_treino', orderBy: 'id ASC');
    final canReadCompletionFlag = legacyHistoryColumns.contains(
      'statusConcluido',
    );
    final canReadDuration = legacyHistoryColumns.contains('tempoTotalSegundos');
    final seriesTableExists = await _tabelaExiste(db, 'registros_serie');
    final exercisesTableExists = await _tabelaExiste(db, 'exercicios');
    final seriesColumns = seriesTableExists
        ? await _columnNames(db, 'registros_serie')
        : <String>{};

    for (final legacy in legacyRows) {
      if (canReadCompletionFlag &&
          (legacy['statusConcluido'] as num?)?.toInt() != 1) {
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
          conflictAlgorithm: ConflictAlgorithm.abort);

      if (!seriesTableExists ||
          !exercisesTableExists ||
          !seriesColumns.contains('idRegistroTreino') ||
          !seriesColumns.contains('idExercicio')) {
        continue;
      }
      final completedClause =
          seriesColumns.contains('concluido') ? 'AND s.concluido = 1' : '';
      final seriesRows = await db.rawQuery(
        '''
        SELECT e.nome AS nomeExercicio,
               s.cargaUtilizada AS cargaUtilizada,
               s.numeroSerie AS serieNumero
        FROM registros_serie AS s
        INNER JOIN exercicios AS e ON e.id = s.idExercicio
        WHERE s.idRegistroTreino = ? $completedClause
        ORDER BY s.numeroSerie ASC;
      ''',
        <Object?>[legacyId],
      );
      for (final setRow in seriesRows) {
        await db.insert(
            'historico_series',
            <String, Object?>{
              'idHistoricoTreino': newId,
              'nomeExercicio': (setRow['nomeExercicio'] ?? '').toString(),
              'cargaUtilizada':
                  (setRow['cargaUtilizada'] as num?)?.toDouble() ?? 0,
              'serieNumero': (setRow['serieNumero'] as num?)?.toInt() ?? 1,
              'repeticoes': (setRow['repeticoes'] as num?)?.toInt() ?? 10,
            },
            conflictAlgorithm: ConflictAlgorithm.abort);
      }
    }
  }

  Future<Map<int, List<RotinaDeTreino>>> obterRotinasDeTodosOsDias() async {
    final db = await database;
    final routineRows = await db.query(
      'treinos_plano',
      orderBy: 'diaSemana ASC, id ASC',
    );
    final exerciseRows = await db.rawQuery('''
      SELECT e.*, t.nome AS nomeTreino
      FROM exercicios_plano AS e
      LEFT JOIN treinos_plano AS t ON t.id = e.idTreino
      ORDER BY e.diaSemana ASC, t.id ASC, e.id ASC;
    ''');
    final exerciciosPorRotina = <int, List<ExercicioPlanejado>>{};
    for (final row in exerciseRows) {
      final idRotina = (row['idTreino'] as num?)?.toInt();
      if (idRotina == null) continue;
      exerciciosPorRotina
          .putIfAbsent(idRotina, () => <ExercicioPlanejado>[])
          .add(ExercicioPlanejado.deMapa(row));
    }

    final grouped = <int, List<RotinaDeTreino>>{
      for (var diaSemana = 1; diaSemana <= 7; diaSemana++)
        diaSemana: <RotinaDeTreino>[],
    };
    for (final row in routineRows) {
      final id = (row['id'] as num).toInt();
      final diaSemana = (row['diaSemana'] as num).toInt();
      grouped.putIfAbsent(diaSemana, () => <RotinaDeTreino>[]).add(
            RotinaDeTreino(
              id: id,
              diaSemana: diaSemana,
              nome: (row['nome'] as String?) ?? 'Treino',
              selecionado: ((row['selecionado'] as num?)?.toInt() ?? 1) == 1,
              exercicios: List<ExercicioPlanejado>.unmodifiable(
                exerciciosPorRotina[id] ?? const <ExercicioPlanejado>[],
              ),
            ),
          );
    }
    return grouped;
  }

  Future<int> salvarRotinaDeTreino(RotinaDeTreino rotina) async {
    if (rotina.diaSemana < 1 || rotina.diaSemana > 7) {
      throw ArgumentError.value(
        rotina.diaSemana,
        'weekday',
        'Must be 1 through 7.',
      );
    }
    final db = await database;
    return db.transaction((txn) async {
      await txn.insert(
          'dias_plano',
          <String, Object?>{
            'diaSemana': rotina.diaSemana,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
      var idRotina = rotina.id;
      if (idRotina != null) {
        final updated = await txn.update(
          'treinos_plano',
          <String, Object?>{
            'nome': rotina.nome,
            'selecionado': rotina.selecionado ? 1 : 0,
          },
          where: 'id = ? AND diaSemana = ?',
          whereArgs: <Object?>[idRotina, rotina.diaSemana],
        );
        if (updated == 0) idRotina = null;
      }
      idRotina ??= await txn.insert(
          'treinos_plano',
          <String, Object?>{
            'diaSemana': rotina.diaSemana,
            'nome': rotina.nome,
            'selecionado': rotina.selecionado ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.abort);

      final linhasExistentes = await txn.query(
        'exercicios_plano',
        columns: <String>['id'],
        where: 'idTreino = ?',
        whereArgs: <Object?>[idRotina],
      );
      final idsExistentes =
          linhasExistentes.map((linha) => (linha['id'] as num).toInt()).toSet();
      final idsMantidos = <int>{};
      for (final exercicio in rotina.exercicios) {
        final normalized = exercicio.copiarCom(
          diaSemana: rotina.diaSemana,
          idTreino: idRotina,
          nomeTreino: rotina.nome,
        );
        final idExercicio = normalized.id;
        if (idExercicio != null && idsExistentes.contains(idExercicio)) {
          await txn.update(
            'exercicios_plano',
            normalized.paraMapa(incluirId: false),
            where: 'id = ? AND idTreino = ?',
            whereArgs: <Object?>[idExercicio, idRotina],
          );
          idsMantidos.add(idExercicio);
        } else {
          final novoId = await txn.insert(
            'exercicios_plano',
            normalized.paraMapa(incluirId: false),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          idsMantidos.add(novoId);
        }
      }
      for (final idAntigo in idsExistentes.difference(idsMantidos)) {
        await txn.delete(
          'exercicios_plano',
          where: 'id = ?',
          whereArgs: <Object?>[idAntigo],
        );
      }
      return idRotina;
    });
  }

  Future<void> excluirRotinaDeTreino(int diaSemana, int idRotina) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'exercicios_plano',
        where: 'idTreino = ?',
        whereArgs: <Object?>[idRotina],
      );
      await txn.delete(
        'treinos_plano',
        where: 'id = ? AND diaSemana = ?',
        whereArgs: <Object?>[idRotina, diaSemana],
      );
    });
  }

  Future<void> definirSelecaoDeRotinas(
    int diaSemana,
    Set<int> selectedRoutineIds,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'treinos_plano',
        columns: <String>['id'],
        where: 'diaSemana = ?',
        whereArgs: <Object?>[diaSemana],
      );
      for (final row in rows) {
        final id = (row['id'] as num).toInt();
        await txn.update(
          'treinos_plano',
          <String, Object?>{
            'selecionado': selectedRoutineIds.contains(id) ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
    });
  }

  Future<PerfilDoUsuario?> obterPerfilDoUsuario() async {
    final db = await database;
    final rows = await db.query(
      'perfil_usuario',
      where: 'id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    return rows.isEmpty ? null : PerfilDoUsuario.deMapa(rows.first);
  }

  Future<void> salvarPerfilDoUsuario(
    PerfilDoUsuario perfil, {
    double? currentWeightKg,
  }) async {
    if (currentWeightKg != null &&
        (!currentWeightKg.isFinite ||
            currentWeightKg <= 0 ||
            currentWeightKg > 500)) {
      throw ArgumentError.value(
        currentWeightKg,
        'currentWeightKg',
        'Informe um peso corporal válido.',
      );
    }
    final db = await database;
    final values = perfil.paraMapa();
    await db.transaction((txn) async {
      final updated = await txn.update(
        'perfil_usuario',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[1],
      );
      if (updated == 0) {
        await txn.insert(
          'perfil_usuario',
          values,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      if (currentWeightKg != null) {
        final latestWeights = await txn.query(
          'peso_corporal',
          columns: <String>['pesoKg'],
          orderBy: 'dataISO DESC, id DESC',
          limit: 1,
        );
        final latestWeight = latestWeights.isEmpty
            ? null
            : (latestWeights.first['pesoKg'] as num?)?.toDouble();
        if (latestWeight == null ||
            (latestWeight - currentWeightKg).abs() > 0.0001) {
          await txn.insert('peso_corporal', <String, Object?>{
            'dataISO': DateTime.now().toIso8601String(),
            'pesoKg': currentWeightKg,
          });
        }
      }
    });
  }

  Future<Map<int, List<ExercicioPlanejado>>> obterPlanosDeTodosOsDias() async {
    final rotinas = await obterRotinasDeTodosOsDias();
    final grouped = <int, List<ExercicioPlanejado>>{
      for (var diaSemana = 1; diaSemana <= 7; diaSemana++)
        diaSemana: <ExercicioPlanejado>[],
    };
    for (final dayEntry in rotinas.entries) {
      grouped[dayEntry.key] = dayEntry.value
          .expand((rotina) => rotina.exercicios)
          .toList(growable: false);
    }
    return grouped;
  }

  /// Troca somente os exercícios filhos de um dia dentro de uma transação.
  /// Evita `INSERT OR REPLACE`, que apagaria chaves primárias referenciadas.
  Future<void> salvarExerciciosDoDia(
    int diaSemana,
    List<ExercicioPlanejado> exercicios,
  ) async {
    if (diaSemana < 1 || diaSemana > 7) {
      throw ArgumentError.value(diaSemana, 'weekday', 'Must be 1 through 7.');
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
          'dias_plano',
          <String, Object?>{
            'diaSemana': diaSemana,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
      final existingRoutines = await txn.query(
        'treinos_plano',
        where: 'diaSemana = ?',
        whereArgs: <Object?>[diaSemana],
        orderBy: 'id ASC',
      );
      final int idRotina;
      if (existingRoutines.isEmpty) {
        idRotina = await txn.insert('treinos_plano', <String, Object?>{
          'diaSemana': diaSemana,
          'nome': 'Treino A',
          'selecionado': 1,
        });
      } else {
        idRotina = (existingRoutines.first['id'] as num).toInt();
        for (final row in existingRoutines.skip(1)) {
          final extraId = (row['id'] as num).toInt();
          await txn.delete(
            'exercicios_plano',
            where: 'idTreino = ?',
            whereArgs: <Object?>[extraId],
          );
          await txn.delete(
            'treinos_plano',
            where: 'id = ?',
            whereArgs: <Object?>[extraId],
          );
        }
      }
      await txn.delete(
        'exercicios_plano',
        where: 'diaSemana = ?',
        whereArgs: <Object?>[diaSemana],
      );
      for (final exercicio in exercicios) {
        final normalized = exercicio.copiarCom(
          diaSemana: diaSemana,
          idTreino: idRotina,
        );
        await txn.insert(
          'exercicios_plano',
          normalized.paraMapa(incluirId: false),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<void> atualizarCargaDoExercicio(
    int idDoExercicio,
    double cargaKg,
  ) async {
    final db = await database;
    await db.update(
      'exercicios_plano',
      <String, Object?>{'carga': cargaKg},
      where: 'id = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
  }

  Future<void> atualizarImagemLocalDoExercicio(
    int idDoExercicio,
    String? localPath,
  ) async {
    final db = await database;
    await db.update(
      'exercicios_plano',
      <String, Object?>{'caminhoLocalGif': localPath},
      where: 'id = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
  }

  Future<void> salvarTreinoEmAndamento(TreinoEmAndamento estadoSalvo) async {
    final db = await database;
    await db.transaction((txn) async {
      // Excluir este rascunho remove apenas suas séries provisórias em cascata;
      // as tabelas de treinos concluídos não são alteradas neste fluxo.
      await txn.delete(
        'treino_em_andamento',
        where: 'id = ?',
        whereArgs: <Object?>[1],
      );
      await txn.insert('treino_em_andamento', <String, Object?>{
        'id': 1,
        'dataInicioISO': estadoSalvo.dataInicioISO,
        'diaSemana': estadoSalvo.diaSemana,
        'descansoSegundos': estadoSalvo.descansoSegundos,
        'descansoAteISO': estadoSalvo.descansoAteISO,
        'idExercicioDescanso': estadoSalvo.idExercicioDescanso,
      });
      for (final estadoDoExercicio in estadoSalvo.exercicios) {
        final exercicio = estadoDoExercicio.exercicio;
        final idDoExercicio = exercicio.id;
        if (idDoExercicio == null) {
          throw StateError(
            'Não é possível recuperar um exercício sem ID local.',
          );
        }
        for (final progress in estadoDoExercicio.progressoDasSeries) {
          await txn.insert('series_em_andamento', <String, Object?>{
            'idSessao': 1,
            'idExercicioPlano': idDoExercicio,
            'idTreino': exercicio.idTreino,
            'diaSemana': exercicio.diaSemana,
            'nomeExercicio': exercicio.nome,
            'nomeTreino': exercicio.nomeTreino,
            'cargaPadrao': exercicio.carga,
            'seriesTotal': exercicio.series,
            'repeticoes': exercicio.repeticoes,
            'repeticoesAtual': progress.repeticoesAtual,
            'tempoDescansoSegundos': exercicio.tempoDescansoSegundos,
            'urlGif': null,
            'caminhoLocalGif': exercicio.caminhoLocalGif,
            'serieNumero': progress.numeroSerie,
            'cargaAtual': progress.cargaAtual,
            'concluido': progress.concluido ? 1 : 0,
          });
        }
      }
    });
  }

  Future<TreinoEmAndamento?> obterTreinoEmAndamento() async {
    final db = await database;
    final sessionRows = await db.query(
      'treino_em_andamento',
      where: 'id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    if (sessionRows.isEmpty) return null;
    final sessao = sessionRows.first;
    final rows = await db.query(
      'series_em_andamento',
      where: 'idSessao = ?',
      whereArgs: <Object?>[1],
      orderBy: 'idExercicioPlano ASC, serieNumero ASC',
    );

    final exerciseById = <int, ExercicioPlanejado>{};
    final seriesByExercise = <int, List<SerieDoTreinoEmAndamento>>{};
    for (final row in rows) {
      final idDoExercicio = (row['idExercicioPlano'] as num).toInt();
      exerciseById.putIfAbsent(
        idDoExercicio,
        () => ExercicioPlanejado(
          id: idDoExercicio,
          idTreino: (row['idTreino'] as num?)?.toInt(),
          diaSemana: (row['diaSemana'] as num).toInt(),
          nome: row['nomeExercicio'] as String,
          nomeTreino: (row['nomeTreino'] as String?) ?? 'Treino principal',
          carga: (row['cargaPadrao'] as num?)?.toDouble() ?? 0,
          series: (row['seriesTotal'] as num?)?.toInt() ?? 3,
          repeticoes: (row['repeticoes'] as num?)?.toInt() ?? 10,
          tempoDescansoSegundos:
              (row['tempoDescansoSegundos'] as num?)?.toInt() ?? 60,
          urlGif: null,
          caminhoLocalGif: row['caminhoLocalGif'] as String?,
        ),
      );
      seriesByExercise
          .putIfAbsent(idDoExercicio, () => <SerieDoTreinoEmAndamento>[])
          .add(
            SerieDoTreinoEmAndamento(
              numeroSerie: (row['serieNumero'] as num).toInt(),
              cargaAtual: (row['cargaAtual'] as num?)?.toDouble() ?? 0,
              repeticoesAtual: (row['repeticoesAtual'] as num?)?.toInt() ??
                  (row['repeticoes'] as num?)?.toInt() ??
                  10,
              concluido: (row['concluido'] as num?)?.toInt() == 1,
            ),
          );
    }

    final snapshots = <ExercicioDoTreinoEmAndamento>[];
    for (final entry in exerciseById.entries) {
      snapshots.add(
        ExercicioDoTreinoEmAndamento(
          exercicio: entry.value,
          progressoDasSeries:
              seriesByExercise[entry.key] ?? const <SerieDoTreinoEmAndamento>[],
        ),
      );
    }
    final startedAt = DateTime.tryParse(
      sessao['dataInicioISO'] as String? ?? '',
    );
    if (startedAt == null || snapshots.isEmpty) {
      await excluirTreinoEmAndamento();
      return null;
    }
    return TreinoEmAndamento(
      dataInicioISO: startedAt.toIso8601String(),
      diaSemana: (sessao['diaSemana'] as num).toInt(),
      descansoSegundos: (sessao['descansoSegundos'] as num?)?.toInt() ?? 60,
      descansoAteISO: sessao['descansoAteISO'] as String?,
      idExercicioDescanso: (sessao['idExercicioDescanso'] as num?)?.toInt(),
      exercicios: snapshots,
    );
  }

  Future<void> atualizarSeriesDoTreinoEmAndamento({
    required int exercisePlanId,
    required int serieNumero,
    required double cargaAtual,
    required int repeticoesAtual,
    required bool concluido,
  }) async {
    final db = await database;
    await db.update(
      'series_em_andamento',
      <String, Object?>{
        'cargaAtual': cargaAtual,
        'repeticoesAtual': repeticoesAtual,
        'concluido': concluido ? 1 : 0,
      },
      where: 'idSessao = ? AND idExercicioPlano = ? AND serieNumero = ?',
      whereArgs: <Object?>[1, exercisePlanId, serieNumero],
    );
  }

  Future<void> atualizarDescansoDoTreinoEmAndamento({
    required int descansoSegundos,
    required String? descansoAteISO,
    required int? idExercicioDescanso,
  }) async {
    final db = await database;
    await db.update(
      'treino_em_andamento',
      <String, Object?>{
        'descansoSegundos': descansoSegundos,
        'descansoAteISO': descansoAteISO,
        'idExercicioDescanso': idExercicioDescanso,
      },
      where: 'id = ?',
      whereArgs: <Object?>[1],
    );
  }

  Future<void> excluirTreinoEmAndamento() async {
    final db = await database;
    await db.delete(
      'treino_em_andamento',
      where: 'id = ?',
      whereArgs: <Object?>[1],
    );
  }

  Future<int> inserirPesoCorporal({
    required DateTime data,
    required double weightKg,
  }) async {
    if (!weightKg.isFinite || weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Informe um peso maior que zero.',
      );
    }
    final db = await database;
    return db.insert('peso_corporal', <String, Object?>{
      'dataISO': data.toIso8601String(),
      'pesoKg': weightKg,
    });
  }

  Future<List<RegistroDePesoCorporal>> obterPesosCorporais() async {
    final db = await database;
    final rows = await db.query(
      'peso_corporal',
      orderBy: 'dataISO DESC, id DESC',
    );
    return rows.map(RegistroDePesoCorporal.deMapa).toList(growable: false);
  }

  Future<void> excluirPesoCorporal(int id) async {
    final db = await database;
    await db.delete('peso_corporal', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<int> salvarMedidasCorporais(RegistroDeMedidasCorporais medidas) async {
    final db = await database;
    if (medidas.id != null) {
      await db.update(
        'medidas_corporais',
        medidas.paraMapa(incluirId: false),
        where: 'id = ?',
        whereArgs: <Object?>[medidas.id],
      );
      return medidas.id!;
    }
    return db.insert(
      'medidas_corporais',
      medidas.paraMapa(incluirId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<RegistroDeMedidasCorporais>> obterMedidasCorporais() async {
    final db = await database;
    final rows = await db.query(
      'medidas_corporais',
      orderBy: 'dataISO DESC, id DESC',
    );
    return rows.map(RegistroDeMedidasCorporais.deMapa).toList(growable: false);
  }

  Future<void> excluirMedidasCorporais(int id) async {
    final db = await database;
    await db.delete(
      'medidas_corporais',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<PontoDeEvolucao>> obterEvolucaoDoPesoCorporal() async {
    final db = await database;
    final rows = await db.query(
      'peso_corporal',
      columns: <String>['dataISO', 'pesoKg'],
      orderBy: 'dataISO ASC, id ASC',
    );
    final points = <PontoDeEvolucao>[];
    for (final row in rows) {
      final data = DateTime.tryParse(row['dataISO'] as String? ?? '');
      final weight = (row['pesoKg'] as num?)?.toDouble();
      if (data != null && weight != null) {
        points.add(PontoDeEvolucao(data: data, cargaKg: weight));
      }
    }
    return points;
  }

  Future<int> salvarSessaoDeTreino({
    required String dataISO,
    required int tempoTotalSegundos,
    required int diaSemana,
    required String nomeTreino,
    required List<SerieDoTreino> sets,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final historyId = await txn.insert(
          'historico_treinos',
          <String, Object?>{
            'dataISO': dataISO,
            'tempoTotalSegundos': tempoTotalSegundos,
            'diaSemana': diaSemana,
            'nomeTreino': nomeTreino,
          },
          conflictAlgorithm: ConflictAlgorithm.abort);
      for (final set in sets) {
        await txn.insert(
          'historico_series',
          set.paraMapa(idHistoricoTreino: historyId),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      // Persiste a carga máxima e os valores de cada série no plano para os próximos treinos
      final setsByExercise = <String, List<SerieDoTreino>>{};
      for (final set in sets) {
        setsByExercise
            .putIfAbsent(set.nomeExercicio, () => <SerieDoTreino>[])
            .add(set);
      }

      for (final entry in setsByExercise.entries) {
        final exerciseName = entry.key;
        final exerciseSets = entry.value
          ..sort((a, b) => a.serieNumero.compareTo(b.serieNumero));
        final maxLoad = exerciseSets.fold<double>(
          0.0,
          (prev, s) => s.cargaUtilizada > prev ? s.cargaUtilizada : prev,
        );

        final planRows = await txn.query(
          'exercicios_plano',
          where: 'diaSemana = ? AND nome = ?',
          whereArgs: <Object?>[diaSemana, exerciseName],
        );

        for (final row in planRows) {
          final id = (row['id'] as num).toInt();
          final seriesTotal =
              (row['series'] as num?)?.toInt() ?? exerciseSets.length;

          List<double> existingCargas;
          try {
            existingCargas =
                (jsonDecode((row['cargasPorSerie'] as String?) ?? '[]') as List)
                    .map((e) => (e as num).toDouble())
                    .toList();
          } catch (_) {
            existingCargas = <double>[];
          }

          List<int> existingReps;
          try {
            existingReps =
                (jsonDecode((row['repeticoesPorSerie'] as String?) ?? '[]')
                        as List)
                    .map((e) => (e as num).toInt())
                    .toList();
          } catch (_) {
            existingReps = <int>[];
          }

          final targetLength = math.max(seriesTotal, exerciseSets.length);
          final newCargas = List<double>.generate(
            targetLength,
            (i) => i < existingCargas.length
                ? existingCargas[i]
                : ((row['carga'] as num?)?.toDouble() ?? 0.0),
          );
          final newReps = List<int>.generate(
            targetLength,
            (i) => i < existingReps.length
                ? existingReps[i]
                : ((row['repeticoes'] as num?)?.toInt() ?? 10),
          );

          for (final s in exerciseSets) {
            final idx = s.serieNumero - 1;
            if (idx >= 0 && idx < targetLength) {
              newCargas[idx] = s.cargaUtilizada;
              newReps[idx] = s.repeticoes;
            }
          }

          final updateValues = <String, Object?>{
            'cargasPorSerie': jsonEncode(newCargas),
            'repeticoesPorSerie': jsonEncode(newReps),
          };
          if (maxLoad > 0) {
            updateValues['carga'] = maxLoad;
          }

          await txn.update(
            'exercicios_plano',
            updateValues,
            where: 'id = ?',
            whereArgs: <Object?>[id],
          );
        }
      }

      await txn.delete(
        'treino_em_andamento',
        where: 'id = ?',
        whereArgs: <Object?>[1],
      );
      return historyId;
    });
  }

  Future<void> atualizarDuracaoDoDescanso(
    int idDoExercicio,
    int segundos,
  ) async {
    final db = await database;
    await db.update(
      'exercicios_plano',
      <String, Object?>{'tempoDescansoSegundos': segundos},
      where: 'id = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
    await db.update(
      'series_em_andamento',
      <String, Object?>{'tempoDescansoSegundos': segundos},
      where: 'idExercicioPlano = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
  }

  Future<void> atualizarDetalhesDoExercicio(
    int idDoExercicio, {
    String? nome,
    double? carga,
    int? series,
    int? repeticoes,
    int? tempoDescansoSegundos,
  }) async {
    final db = await database;
    final values = <String, Object?>{};
    if (nome != null) values['nome'] = nome;
    if (carga != null) values['carga'] = carga;
    if (series != null) values['series'] = series;
    if (repeticoes != null) values['repeticoes'] = repeticoes;
    if (tempoDescansoSegundos != null) {
      values['tempoDescansoSegundos'] = tempoDescansoSegundos;
    }

    if (values.isEmpty) return;
    await db.update(
      'exercicios_plano',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
  }

  /// Guarda carga e repetições individualmente sem alterar o padrão do exercício.
  Future<void> atualizarValoresDasSeriesDoExercicio(
    int idDoExercicio, {
    required List<double> cargas,
    required List<int> repeticoes,
  }) async {
    final db = await database;
    await db.update(
      'exercicios_plano',
      <String, Object?>{
        'cargasPorSerie': jsonEncode(cargas),
        'repeticoesPorSerie': jsonEncode(repeticoes),
      },
      where: 'id = ?',
      whereArgs: <Object?>[idDoExercicio],
    );
  }

  /// Retorna o recorde pessoal (maior carga histórica já registrada) para cada exercício.
  /// As chaves do mapa são normalizadas (`trim().toLowerCase()`) para busca rápida O(1).
  Future<Map<String, double>> obterRecordesDeCargaPorExercicio() async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT LOWER(TRIM(nomeExercicio)) AS nomeNormalizado,
               MAX(cargaUtilizada) AS maxCarga
        FROM historico_series
        GROUP BY LOWER(TRIM(nomeExercicio));
      ''');
      final resultado = <String, double>{};
      for (final row in rows) {
        final nome = (row['nomeNormalizado'] as String?)?.trim().toLowerCase();
        final maxCarga = (row['maxCarga'] as num?)?.toDouble();
        if (nome != null &&
            nome.isNotEmpty &&
            maxCarga != null &&
            maxCarga > 0) {
          resultado[nome] = maxCarga;
        }
      }
      return resultado;
    } catch (_) {
      return <String, double>{};
    }
  }

  /// Retorna as séries executadas na sessão mais recente de cada exercício (Ghost/Previous Set).
  /// As chaves são os nomes normalizados (`trim().toLowerCase()`).
  Future<Map<String, List<SerieDoTreino>>>
      obterUltimasSeriesPorExercicio() async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT s.nomeExercicio, s.serieNumero, s.cargaUtilizada, s.repeticoes,
               COALESCE(s.tipo, 'normal') AS tipo, s.rpe
        FROM historico_series AS s
        INNER JOIN (
          SELECT LOWER(TRIM(s2.nomeExercicio)) AS chaveExercicio, MAX(h2.id) AS maxWorkoutId
          FROM historico_series AS s2
          INNER JOIN historico_treinos AS h2 ON h2.id = s2.idHistoricoTreino
          GROUP BY LOWER(TRIM(s2.nomeExercicio))
        ) AS latest ON LOWER(TRIM(s.nomeExercicio)) = latest.chaveExercicio
                    AND s.idHistoricoTreino = latest.maxWorkoutId
        ORDER BY s.serieNumero ASC;
      ''');
      final resultado = <String, List<SerieDoTreino>>{};
      for (final row in rows) {
        final nome = (row['nomeExercicio'] as String?)?.trim().toLowerCase();
        if (nome == null || nome.isEmpty) continue;
        resultado.putIfAbsent(nome, () => <SerieDoTreino>[]).add(
              SerieDoTreino(
                nomeExercicio: (row['nomeExercicio'] as String?) ?? '',
                cargaUtilizada:
                    (row['cargaUtilizada'] as num?)?.toDouble() ?? 0,
                serieNumero: (row['serieNumero'] as num?)?.toInt() ?? 1,
                repeticoes: (row['repeticoes'] as num?)?.toInt() ?? 10,
                tipo: (row['tipo'] as String?) ?? 'normal',
                rpe: (row['rpe'] as num?)?.toDouble(),
              ),
            );
      }
      return resultado;
    } catch (_) {
      return <String, List<SerieDoTreino>>{};
    }
  }

  /// Retorna as séries realizadas nos treinos concluídos nos últimos [dias] dias para cálculo de volume muscular.
  Future<List<SerieDoTreino>> obterSeriesConcluidasNosUltimosDias(
      int dias) async {
    try {
      final db = await database;
      final dataLimite =
          DateTime.now().subtract(Duration(days: dias)).toIso8601String();
      final rows = await db.rawQuery('''
        SELECT s.idHistoricoTreino, h.dataISO, s.nomeExercicio, s.serieNumero, s.cargaUtilizada, s.repeticoes,
               COALESCE(s.tipo, 'normal') AS tipo, s.rpe
        FROM historico_series AS s
        INNER JOIN historico_treinos AS h ON h.id = s.idHistoricoTreino
        WHERE h.dataISO >= ?
        ORDER BY h.dataISO DESC, s.idHistoricoTreino DESC, s.serieNumero ASC;
      ''', <Object?>[dataLimite]);

      return rows
          .map((row) => SerieDoTreino.deMapa(row))
          .toList(growable: false);
    } catch (_) {
      return const <SerieDoTreino>[];
    }
  }

  /// Retorna o nome do exercício e a data/hora ISO mais recente em que ele foi executado.
  Future<List<Map<String, String>>>
      obterUltimaDataPorExercicioConcluido() async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT s.nomeExercicio, MAX(h.dataISO) AS ultimaData
        FROM historico_series AS s
        INNER JOIN historico_treinos AS h ON h.id = s.idHistoricoTreino
        GROUP BY s.nomeExercicio;
      ''');
      return rows
          .map((r) => <String, String>{
                'nomeExercicio': (r['nomeExercicio'] ?? '').toString(),
                'ultimaData': (r['ultimaData'] ?? '').toString(),
              })
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, String>>[];
    }
  }

  /// Retorna a quantidade de hábitos concluídos por data (YYYY-MM-DD) para o Heatmap.
  Future<Map<String, int>> obterContagemDeHabitosPorData() async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT substr(c.dataISO, 1, 10) AS dataDia,
               COUNT(DISTINCT c.idHabito) AS total
        FROM conclusoes_habitos AS c
        LEFT JOIN habitos AS h ON h.id = c.idHabito
        WHERE c.valor >= COALESCE(CASE WHEN h.metaValor > 0 THEN h.metaValor ELSE 1 END, 1)
        GROUP BY substr(c.dataISO, 1, 10);
      ''');
      final resultado = <String, int>{};
      for (final row in rows) {
        final dataDia = (row['dataDia'] as String?)?.trim();
        final total = (row['total'] as num?)?.toInt() ?? 0;
        if (dataDia != null && dataDia.isNotEmpty && total > 0) {
          resultado[dataDia] = total;
        }
      }
      return resultado;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<List<DetalheEvolucaoDoExercicio>> obterDetalhesDeEvolucaoDoExercicio(
    String nomeDoExercicio,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT h.id AS workoutId,
             h.dataISO AS dataISO,
             s.serieNumero AS serieNumero,
             s.repeticoes AS repeticoes,
             s.cargaUtilizada AS cargaUtilizada
      FROM historico_series AS s
      INNER JOIN historico_treinos AS h ON h.id = s.idHistoricoTreino
      WHERE s.nomeExercicio = ?
      ORDER BY h.dataISO DESC, s.serieNumero ASC;
    ''',
      <Object?>[nomeDoExercicio],
    );

    final grouped = <int, List<SerieDoTreino>>{};
    final dataPorTreino = <int, String>{};

    for (final row in rows) {
      final idDoTreino = (row['workoutId'] as num).toInt();
      final data = row['dataISO'] as String;
      dataPorTreino[idDoTreino] = data;
      grouped.putIfAbsent(idDoTreino, () => <SerieDoTreino>[]).add(
            SerieDoTreino(
              nomeExercicio: nomeDoExercicio,
              cargaUtilizada: (row['cargaUtilizada'] as num?)?.toDouble() ?? 0,
              serieNumero: (row['serieNumero'] as num?)?.toInt() ?? 1,
              repeticoes: (row['repeticoes'] as num?)?.toInt() ?? 10,
            ),
          );
    }

    final resultado = <DetalheEvolucaoDoExercicio>[];
    for (final entry in grouped.entries) {
      final idDoTreino = entry.key;
      final sets = entry.value;
      final maxLoad = sets.fold<double>(
        0.0,
        (prev, s) => s.cargaUtilizada > prev ? s.cargaUtilizada : prev,
      );
      resultado.add(
        DetalheEvolucaoDoExercicio(
          idDoTreino: idDoTreino,
          dataISO: dataPorTreino[idDoTreino] ?? '',
          series: sets,
          cargaMaxima: maxLoad,
        ),
      );
    }
    return resultado;
  }

  Future<List<SerieDoTreino>> obterSeriesDoTreino(int idDoTreino) async {
    final db = await database;
    final rows = await db.query(
      'historico_series',
      where: 'idHistoricoTreino = ?',
      whereArgs: <Object?>[idDoTreino],
      orderBy: 'id ASC, serieNumero ASC',
    );
    return rows.map(SerieDoTreino.deMapa).toList(growable: false);
  }

  Future<void> excluirSessaoDeTreino(int id) async {
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

  Future<List<TreinoDoHistorico>> obterHistoricoDeTreinos() async {
    final db = await database;
    final rows = await db.query(
      'historico_treinos',
      orderBy: 'dataISO DESC, id DESC',
    );
    return rows.map(TreinoDoHistorico.deMapa).toList(growable: false);
  }

  Future<List<String>> obterNomesDeExerciciosPlanejados() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT nome
      FROM exercicios_plano
      WHERE TRIM(nome) <> ''
      ORDER BY nome COLLATE NOCASE ASC;
    ''');
    return rows.map((row) => row['nome'] as String).toList(growable: false);
  }

  Future<List<PontoDeEvolucao>> obterPontosDeEvolucao(
    String nomeDoExercicio,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT substr(h.dataISO, 1, 10) AS dataDia,
             MAX(s.cargaUtilizada) AS cargaMaxima
      FROM historico_series AS s
      INNER JOIN historico_treinos AS h ON h.id = s.idHistoricoTreino
      WHERE s.nomeExercicio = ?
      GROUP BY substr(h.dataISO, 1, 10)
      ORDER BY dataDia ASC;
    ''',
      <Object?>[nomeDoExercicio],
    );

    final points = <PontoDeEvolucao>[];
    for (final row in rows) {
      final data = DateTime.tryParse((row['dataDia'] ?? '').toString());
      final carga = (row['cargaMaxima'] as num?)?.toDouble();
      if (data != null && carga != null) {
        points.add(PontoDeEvolucao(data: data, cargaKg: carga));
      }
    }
    return points;
  }

  Future<Set<DateTime>> obterDatasDeTreinosConcluidos() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT substr(dataISO, 1, 10) AS dataDia
      FROM historico_treinos
      ORDER BY dataDia ASC;
    ''');
    final resultado = <DateTime>{};
    for (final row in rows) {
      final parsed = DateTime.tryParse((row['dataDia'] ?? '').toString());
      if (parsed != null) {
        resultado.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }

    return resultado;
  }

  Future<Map<String, Object?>?> obterDiarioNaData(String dataISO) async {
    final db = await database;
    final chaveDaData =
        dataISO.length >= 10 ? dataISO.substring(0, 10) : dataISO;
    final rows = await db.query(
      'diario_treino',
      where: 'substr(dataISO, 1, 10) = ?',
      whereArgs: <Object?>[chaveDaData],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> salvarDiario({
    required String dataISO,
    required String conteudo,
    required List<String> caminhosImagens,
    List<FigurinhaDiario> figurinhas = const <FigurinhaDiario>[],
  }) async {
    final db = await database;
    final chaveDaData =
        dataISO.length >= 10 ? dataISO.substring(0, 10) : dataISO;
    final nowISO = DateTime.now().toIso8601String();
    final jsonImagens = jsonEncode(caminhosImagens);
    final jsonFigurinhas = jsonEncode(
      figurinhas.map((f) => f.paraMapa()).toList(),
    );
    await db.insert(
        'diario_treino',
        <String, Object?>{
          'dataISO': chaveDaData,
          'conteudo': conteudo,
          'caminhosImagens': jsonImagens,
          'figurinhas': jsonFigurinhas,
          'dataAtualizacaoISO': nowISO,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==================== HÁBITOS (Habit Tracker Gamificado) ====================

  Future<List<Habito>> obterHabitos({
    bool apenasAtivos = false,
    String? dataReferenciaISO,
  }) async {
    final db = await database;
    final where = apenasAtivos ? 'ativo = 1' : null;
    final rows = await db.query(
      'habitos',
      where: where,
      orderBy: 'ordem ASC, id ASC',
    );
    if (rows.isEmpty) return const <Habito>[];

    final refDate = dataReferenciaISO != null
        ? (dataReferenciaISO.length >= 10
            ? dataReferenciaISO.substring(0, 10)
            : dataReferenciaISO)
        : DateTime.now().toIso8601String().substring(0, 10);

    final conclusoesHoje = await db.query(
      'conclusoes_habitos',
      where: 'substr(dataISO, 1, 10) = ?',
      whereArgs: <Object?>[refDate],
    );
    final progressoHojePorHabito = <int, int>{
      for (final r in conclusoesHoje)
        (r['idHabito'] as num).toInt(): (r['valor'] as num?)?.round() ?? 1,
    };

    final allCompletions = await db.rawQuery('''
      SELECT idHabito, substr(dataISO, 1, 10) AS dia, valor
      FROM conclusoes_habitos
      ORDER BY dia DESC;
    ''');
    final completionsByHabit = <int, Map<String, int>>{};
    for (final r in allCompletions) {
      final hId = (r['idHabito'] as num).toInt();
      final dia = (r['dia'] ?? '').toString();
      final val = (r['valor'] as num?)?.round() ?? 1;
      completionsByHabit.putIfAbsent(hId, () => <String, int>{})[dia] = val;
    }

    final hoje = DateTime.now();
    final hojeZero = DateTime(hoje.year, hoje.month, hoje.day);

    return rows.map((r) {
      final h = Habito.deMapa(r);
      final id = h.id ?? 0;
      final meta = h.metaValor > 0 ? h.metaValor : 1;
      final mapaDias = completionsByHabit[id] ?? const <String, int>{};
      final completedDates = mapaDias.entries
          .where((e) => e.value >= meta)
          .map((e) => e.key)
          .toSet();

      var streak = 0;
      final hojeStr = refDate;
      var checkDate = completedDates.contains(hojeStr)
          ? hojeZero
          : hojeZero.subtract(const Duration(days: 1));

      while (true) {
        final dateKey =
            '${checkDate.year.toString().padLeft(4, '0')}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (h.seAplicaAoDia(checkDate.weekday)) {
          if (completedDates.contains(dateKey)) {
            streak++;
          } else {
            break;
          }
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
        if (streak > 1000) break;
      }

      final progHoje = progressoHojePorHabito[id] ?? 0;

      return h.copiarCom(
        concluidoHoje: progHoje >= meta,
        progressoHoje: progHoje,
        ofensivaAtual: streak,
        totalConclusoes: completedDates.length,
      );
    }).toList(growable: false);
  }

  Future<int> salvarHabito(Habito habito) async {
    final db = await database;
    final map = habito.paraMapa(incluirId: false);
    if (habito.id != null) {
      final idExistente = habito.id!;
      final atualizado = await db.transaction<bool>((txn) async {
        final anteriores = await txn.query(
          'habitos',
          columns: <String>['metaValor'],
          where: 'id = ?',
          whereArgs: <Object?>[idExistente],
          limit: 1,
        );
        if (anteriores.isEmpty) return false;
        final metaAntiga =
            (anteriores.first['metaValor'] as num?)?.toInt() ?? 1;
        final metaNova = habito.metaValor > 0 ? habito.metaValor : 1;
        await txn.update(
          'habitos',
          map,
          where: 'id = ?',
          whereArgs: <Object?>[idExistente],
        );
        if (metaAntiga != metaNova) {
          // Dias que já estavam completos continuam completos com a nova meta.
          await txn.update(
            'conclusoes_habitos',
            <String, Object?>{'valor': metaNova.toDouble()},
            where: 'idHabito = ? AND valor >= ?',
            whereArgs: <Object?>[idExistente, metaAntiga > 0 ? metaAntiga : 1],
          );
        }
        return true;
      });
      if (atualizado) return idExistente;
    }
    return db.insert('habitos', map,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> excluirHabito(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'conclusoes_habitos',
        where: 'idHabito = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete('habitos', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  Future<bool> alternarConclusaoHabito({
    required int idHabito,
    required String dataISO,
    double? valor,
  }) async {
    final db = await database;
    final chaveDaData =
        dataISO.length >= 10 ? dataISO.substring(0, 10) : dataISO;
    return db.transaction((txn) async {
      final habitoRows = await txn.query(
        'habitos',
        columns: <String>['metaValor'],
        where: 'id = ?',
        whereArgs: <Object?>[idHabito],
        limit: 1,
      );
      final metaAlvo = valor ??
          ((habitoRows.isNotEmpty
                  ? (habitoRows.first['metaValor'] as num?)?.toDouble()
                  : null) ??
              1.0);

      final existing = await txn.query(
        'conclusoes_habitos',
        where: 'idHabito = ? AND substr(dataISO, 1, 10) = ?',
        whereArgs: <Object?>[idHabito, chaveDaData],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final valorAtual = (existing.first['valor'] as num?)?.toDouble() ?? 0.0;
        if (valorAtual >= metaAlvo) {
          await txn.delete(
            'conclusoes_habitos',
            where: 'id = ?',
            whereArgs: <Object?>[existing.first['id']],
          );
          return false;
        } else {
          await txn.update(
            'conclusoes_habitos',
            <String, Object?>{'valor': metaAlvo},
            where: 'id = ?',
            whereArgs: <Object?>[existing.first['id']],
          );
          return true;
        }
      } else {
        await txn.insert('conclusoes_habitos', <String, Object?>{
          'idHabito': idHabito,
          'dataISO': chaveDaData,
          'valor': metaAlvo,
        });
        return true;
      }
    });
  }

  Future<int> atualizarProgressoDoHabito({
    required int idHabito,
    required String dataISO,
    required int novoProgresso,
  }) async {
    final db = await database;
    final chaveDaData =
        dataISO.length >= 10 ? dataISO.substring(0, 10) : dataISO;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'conclusoes_habitos',
        where: 'idHabito = ? AND substr(dataISO, 1, 10) = ?',
        whereArgs: <Object?>[idHabito, chaveDaData],
        limit: 1,
      );
      if (novoProgresso <= 0) {
        if (existing.isNotEmpty) {
          await txn.delete(
            'conclusoes_habitos',
            where: 'id = ?',
            whereArgs: <Object?>[existing.first['id']],
          );
        }
        return 0;
      }
      if (existing.isNotEmpty) {
        await txn.update(
          'conclusoes_habitos',
          <String, Object?>{'valor': novoProgresso.toDouble()},
          where: 'id = ?',
          whereArgs: <Object?>[existing.first['id']],
        );
      } else {
        await txn.insert('conclusoes_habitos', <String, Object?>{
          'idHabito': idHabito,
          'dataISO': chaveDaData,
          'valor': novoProgresso.toDouble(),
        });
      }
      return novoProgresso;
    });
  }

  Future<Set<String>> obterDatasDeConclusaoDoHabito(int idHabito) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT substr(c.dataISO, 1, 10) AS dataDia
      FROM conclusoes_habitos AS c
      LEFT JOIN habitos AS h ON h.id = c.idHabito
      WHERE c.idHabito = ?
        AND c.valor >= COALESCE(CASE WHEN h.metaValor > 0 THEN h.metaValor ELSE 1 END, 1)
      ORDER BY dataDia ASC;
    ''', <Object?>[idHabito]);
    return rows
        .map((r) => (r['dataDia'] ?? '').toString().trim())
        .where((d) => d.isNotEmpty)
        .toSet();
  }

  // ==================== TAREFAS TO-DO (Organizador) ====================

  Future<List<TarefaToDo>> obterTarefasToDo({bool? apenasPendentes}) async {
    final db = await database;
    String? where;
    List<Object?>? whereArgs;
    if (apenasPendentes != null) {
      where = 'concluida = ?';
      whereArgs = <Object?>[apenasPendentes ? 0 : 1];
    }
    final rows = await db.query(
      'tarefas_todo',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'concluida ASC, ordem ASC, id DESC',
    );
    return rows.map(TarefaToDo.deMapa).toList(growable: false);
  }

  Future<int> salvarTarefaToDo(TarefaToDo tarefa) async {
    final db = await database;
    final map = tarefa.paraMapa(incluirId: false);
    if (tarefa.id != null) {
      final updated = await db.update(
        'tarefas_todo',
        map,
        where: 'id = ?',
        whereArgs: <Object?>[tarefa.id],
      );
      if (updated > 0) return tarefa.id!;
    }
    return db.insert(
      'tarefas_todo',
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> alternarConclusaoTarefa(int id, bool concluida) async {
    final db = await database;
    await db.update(
      'tarefas_todo',
      <String, Object?>{'concluida': concluida ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> excluirTarefaToDo(int id) async {
    final db = await database;
    await db.delete('tarefas_todo', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<FotoMensalDeEvolucao>> obterFotosMensaisDeEvolucao() async {
    final db = await database;
    final rows = await db.query(
      'fotos_evolucao_mensal',
      orderBy: 'mesISO DESC, id DESC',
    );
    return rows.map(FotoMensalDeEvolucao.deMapa).toList(growable: false);
  }

  Future<void> salvarFotosMensaisDeEvolucao({
    required String mesISO,
    required List<String> caminhosLocais,
  }) async {
    final db = await database;
    final savedAt = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final caminho in caminhosLocais.toSet()) {
        await txn.insert(
            'fotos_evolucao_mensal',
            <String, Object?>{
              'mesISO': mesISO,
              'caminhoLocal': caminho,
              'dataCriacaoISO': savedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> excluirFotoMensalDeEvolucao(int id) async {
    final db = await database;
    await db.delete(
      'fotos_evolucao_mensal',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Lê as tabelas de dados para o backup. O treino em andamento não entra.
  Future<Map<String, List<Map<String, Object?>>>>
      exportarTabelasDoBackup() async {
    final db = await database;
    return <String, List<Map<String, Object?>>>{
      'treinos_plano': await db.query(
        'treinos_plano',
        orderBy: 'diaSemana ASC, id ASC',
      ),
      'exercicios_plano': await db.query('exercicios_plano', orderBy: 'id ASC'),
      'historico_treinos': await db.query(
        'historico_treinos',
        orderBy: 'id ASC',
      ),
      'historico_series': await db.query('historico_series', orderBy: 'id ASC'),
      'peso_corporal': await db.query('peso_corporal', orderBy: 'id ASC'),
      'medidas_corporais':
          await db.query('medidas_corporais', orderBy: 'id ASC'),
      'diario_treino': await db.query('diario_treino', orderBy: 'id ASC'),
      'fotos_evolucao_mensal': await db.query(
        'fotos_evolucao_mensal',
        orderBy: 'id ASC',
      ),
      'perfil_usuario': await db.query('perfil_usuario', orderBy: 'id ASC'),
      'habitos': await db.query('habitos', orderBy: 'ordem ASC, id ASC'),
      'conclusoes_habitos': await db.query(
        'conclusoes_habitos',
        orderBy: 'id ASC',
      ),
      'tarefas_todo': await db.query(
        'tarefas_todo',
        orderBy: 'ordem ASC, id ASC',
      ),
    };
  }

  /// Substitui os dados do usuário numa única transação. Os IDs originais são
  /// mantidos para que as relações entre tabelas continuem válidas.
  ///
  /// Quando [apenasPlanosEExercicios] é `true`, apenas os planos semanais e
  /// exercícios são substituídos, preservando perfil, histórico de treinos,
  /// séries, hábitos, tarefas, diário, fotos e peso corporal.
  /// Quando [manterPerfilSeAusente] é `true` (padrão), o perfil atual do
  /// usuário não é apagado caso o backup não contenha perfil.
  Future<void> restaurarTabelasDoBackup({
    required List<Map<String, Object?>> exercicios,
    required List<Map<String, Object?>> treinos,
    required List<Map<String, Object?>> series,
    required List<Map<String, Object?>> pesosCorporais,
    List<Map<String, Object?>> medidasCorporais =
        const <Map<String, Object?>>[],
    List<Map<String, Object?>> diarios = const <Map<String, Object?>>[],
    List<Map<String, Object?>> fotosMensais = const <Map<String, Object?>>[],
    List<Map<String, Object?>> rotinas = const <Map<String, Object?>>[],
    List<Map<String, Object?>> habitos = const <Map<String, Object?>>[],
    List<Map<String, Object?>> conclusoesHabitos =
        const <Map<String, Object?>>[],
    List<Map<String, Object?>> tarefas = const <Map<String, Object?>>[],
    Map<String, Object?>? perfil,
    bool conclusoesLegadas = false,
    bool apenasPlanosEExercicios = false,
    bool manterPerfilSeAusente = true,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // A ordem das deleções respeita as chaves estrangeiras.
      await txn.delete('series_em_andamento');
      await txn.delete('treino_em_andamento');
      await txn.delete('exercicios_plano');
      await txn.delete('treinos_plano');
      await _preencherDiasDaSemana(txn);

      for (final row in rotinas) {
        await txn.insert(
          'treinos_plano',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in exercicios) {
        await txn.insert(
          'exercicios_plano',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (apenasPlanosEExercicios) {
        return;
      }

      await txn.delete('historico_series');
      await txn.delete('historico_treinos');
      await txn.delete('peso_corporal');
      await txn.delete('medidas_corporais');
      await txn.delete('diario_treino');
      await txn.delete('fotos_evolucao_mensal');
      await txn.delete('conclusoes_habitos');
      await txn.delete('habitos');
      await txn.delete('tarefas_todo');
      if (perfil != null || !manterPerfilSeAusente) {
        await txn.delete('perfil_usuario');
      }

      for (final row in treinos) {
        await txn.insert(
          'historico_treinos',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in series) {
        await txn.insert(
          'historico_series',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in pesosCorporais) {
        await txn.insert(
          'peso_corporal',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in medidasCorporais) {
        await txn.insert(
          'medidas_corporais',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in diarios) {
        await txn.insert(
          'diario_treino',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in fotosMensais) {
        await txn.insert(
          'fotos_evolucao_mensal',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in habitos) {
        await txn.insert(
          'habitos',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in conclusoesHabitos) {
        await txn.insert(
          'conclusoes_habitos',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in tarefas) {
        await txn.insert(
          'tarefas_todo',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (perfil != null) {
        final perfilNormalizado = Map<String, Object?>.from(perfil);
        perfilNormalizado['onboardingConcluido'] = 1;
        await txn.insert(
          'perfil_usuario',
          perfilNormalizado,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (conclusoesLegadas) {
        await normalizarConclusoesLegadasDeHabitos(txn, incluirHoje: true);
      }
    });
  }
}
