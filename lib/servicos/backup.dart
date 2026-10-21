import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../banco_dados/banco_de_dados.dart';
import 'criptografia_de_backup.dart';

class ErroDeBackup implements Exception {
  const ErroDeBackup(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class ResultadoDaExportacao {
  const ResultadoDaExportacao({
    required this.nomeDoArquivo,
    required this.imagensAusentes,
  });

  final String nomeDoArquivo;
  final int imagensAusentes;
}

class BackupLocalSalvo {
  const BackupLocalSalvo({
    required this.caminhoArquivo,
    required this.nomeArquivo,
    required this.criadoEm,
    required this.tamanhoBytes,
    required this.automatico,
  });

  final String caminhoArquivo;
  final String nomeArquivo;
  final DateTime criadoEm;
  final int tamanhoBytes;
  final bool automatico;
}

class DadosDoBackup {
  const DadosDoBackup({
    required this.exercicios,
    required this.treinos,
    required this.series,
    required this.pesosCorporais,
    this.medidasCorporais = const <Map<String, Object?>>[],
    this.diarios = const <Map<String, Object?>>[],
    this.fotosMensais = const <Map<String, Object?>>[],
    this.rotinas = const <Map<String, Object?>>[],
    this.habitos = const <Map<String, Object?>>[],
    this.conclusoesHabitos = const <Map<String, Object?>>[],
    this.tarefas = const <Map<String, Object?>>[],
    this.perfil,
    required this.imagens,
    this.conclusoesLegadas = false,
  });

  /// Cada exercício traz `arquivoGif`: o nome da imagem dentro do backup.
  final List<Map<String, Object?>> exercicios;
  final List<Map<String, Object?>> treinos;
  final List<Map<String, Object?>> series;
  final List<Map<String, Object?>> pesosCorporais;
  final List<Map<String, Object?>> medidasCorporais;
  final List<Map<String, Object?>> diarios;
  final List<Map<String, Object?>> fotosMensais;
  final List<Map<String, Object?>> rotinas;
  final List<Map<String, Object?>> habitos;
  final List<Map<String, Object?>> conclusoesHabitos;
  final List<Map<String, Object?>> tarefas;
  final Map<String, Object?>? perfil;
  final bool conclusoesLegadas;

  /// Caminho relativo no zip -> bytes da imagem.
  final Map<String, Uint8List> imagens;

  int get exerciseCount => exercicios.length;
  int get workoutCount => treinos.length;
  int get seriesCount => series.length;
  int get bodyWeightCount => pesosCorporais.length;
  int get diaryCount => diarios.length;
  int get imageCount => imagens.length;
  int get routineCount => rotinas.length;
  int get habitCount => habitos.length;
  int get taskCount => tarefas.length;
  bool get temPerfil => perfil != null && perfil!.isNotEmpty;

  /// Verdadeiro quando o backup contém apenas planos/exercícios, sem histórico,
  /// hábitos, tarefas, diário ou pesos corporais.
  bool get contemApenasExercicios =>
      treinos.isEmpty &&
      series.isEmpty &&
      pesosCorporais.isEmpty &&
      medidasCorporais.isEmpty &&
      diarios.isEmpty &&
      fotosMensais.isEmpty &&
      habitos.isEmpty &&
      tarefas.isEmpty;
}

class ServicoDeBackup {
  ServicoDeBackup(this._database);

  final BancoDeDados _database;

  static const String _appId = 'offline_gym';
  static const int _formatVersion = 3;
  static const String _dataFileName = 'dados.json';
  static const String _imagesFolder = 'exercise_gifs';
  static const String _diaryImagesFolder = 'diary_images';
  static const String _monthlyProgressImagesFolder = 'monthly_progress_photos';
  static const String _profileImagesFolder = 'profile_images';
  static const String _localBackupsFolder = 'backups_locais';
  static const int _maxBackupBytes = 100 * 1024 * 1024;
  static const int _maxJsonBytes = 10 * 1024 * 1024;
  static const int _maxArchiveEntries = 5000;
  static const int _maxRowsPerTable = 10000;
  static const int _maxImageBytes = 20 * 1024 * 1024;
  static const int _maxTotalImageBytes = 80 * 1024 * 1024;

  Future<({Uint8List zipBytes, int imagensAusentes})>
      _gerarZipBytesDoEstadoAtual() async {
    final tables = await _database.exportarTabelasDoBackup();

    final archive = Archive();
    final imageFiles = <String, File>{}; // zipEntryPath -> File
    var imagensAusentes = 0;

    // Exercícios
    final exercicios = <Map<String, Object?>>[];
    for (final row
        in tables['exercicios_plano'] ?? const <Map<String, Object?>>[]) {
      final item = Map<String, Object?>.from(row);
      final localPath = item.remove('caminhoLocalGif') as String?;
      String? imageName;
      if (localPath != null && localPath.isNotEmpty) {
        final arquivo = File(localPath);
        if (await arquivo.exists()) {
          imageName = p.basename(localPath);
          imageFiles['$_imagesFolder/$imageName'] = arquivo;
        } else {
          imagensAusentes++;
        }
      }
      item['arquivoGif'] = imageName;
      exercicios.add(item);
    }

    // Diários e imagens do diário
    final diarios = <Map<String, Object?>>[];
    for (final row
        in tables['diario_treino'] ?? const <Map<String, Object?>>[]) {
      final item = Map<String, Object?>.from(row);
      final rawImgs = item.remove('caminhosImagens');
      final relativeNames = <String>[];
      if (rawImgs is String && rawImgs.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawImgs);
          if (decoded is List) {
            for (final imgPath in decoded) {
              final arquivo = File(imgPath.toString());
              if (await arquivo.exists()) {
                final name = p.basename(imgPath.toString());
                imageFiles['$_diaryImagesFolder/$name'] = arquivo;
                relativeNames.add(name);
              } else {
                imagensAusentes++;
              }
            }
          }
        } catch (_) {}
      }
      item['arquivosImagens'] = jsonEncode(relativeNames);
      diarios.add(item);
    }

    final fotosMensais = <Map<String, Object?>>[];
    for (final row
        in tables['fotos_evolucao_mensal'] ?? const <Map<String, Object?>>[]) {
      final item = Map<String, Object?>.from(row);
      final localPath = item.remove('caminhoLocal') as String?;
      String? imageEntry;
      if (localPath != null && localPath.isNotEmpty) {
        final arquivo = File(localPath);
        if (await arquivo.exists()) {
          imageEntry = '$_monthlyProgressImagesFolder/${p.basename(localPath)}';
          imageFiles[imageEntry] = arquivo;
        } else {
          imagensAusentes++;
        }
      }
      item['arquivoFoto'] = imageEntry;
      fotosMensais.add(item);
    }

    final profileRows =
        tables['perfil_usuario'] ?? const <Map<String, Object?>>[];
    Map<String, Object?>? perfil;
    if (profileRows.isNotEmpty) {
      perfil = Map<String, Object?>.from(profileRows.first);
      final localPath = perfil.remove('caminhoFoto') as String?;
      String? imageEntry;
      if (localPath != null && localPath.isNotEmpty) {
        final arquivo = File(localPath);
        if (await arquivo.exists()) {
          imageEntry = '$_profileImagesFolder/${p.basename(localPath)}';
          imageFiles[imageEntry] = arquivo;
        } else {
          imagensAusentes++;
        }
      }
      perfil['arquivoFoto'] = imageEntry;
    }

    final payload = <String, Object?>{
      'app': _appId,
      'formato': _formatVersion,
      'exportadoEm': DateTime.now().toIso8601String(),
      'treinos_plano':
          tables['treinos_plano'] ?? const <Map<String, Object?>>[],
      'exercicios_plano': exercicios,
      'historico_treinos':
          tables['historico_treinos'] ?? const <Map<String, Object?>>[],
      'historico_series':
          tables['historico_series'] ?? const <Map<String, Object?>>[],
      'peso_corporal':
          tables['peso_corporal'] ?? const <Map<String, Object?>>[],
      'diario_treino': diarios,
      'fotos_evolucao_mensal': fotosMensais,
      'perfil_usuario': perfil == null
          ? <Map<String, Object?>>[]
          : <Map<String, Object?>>[perfil],
      'habitos': tables['habitos'] ?? const <Map<String, Object?>>[],
      'conclusoes_habitos':
          tables['conclusoes_habitos'] ?? const <Map<String, Object?>>[],
      'tarefas_todo': tables['tarefas_todo'] ?? const <Map<String, Object?>>[],
    };
    final dataBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    archive.addFile(ArchiveFile(_dataFileName, dataBytes.length, dataBytes));

    for (final entry in imageFiles.entries) {
      final bytes = await entry.value.readAsBytes();
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes.isEmpty) {
      throw const ErroDeBackup('Não foi possível gerar o arquivo de backup.');
    }
    return (
      zipBytes: Uint8List.fromList(zipBytes),
      imagensAusentes: imagensAusentes,
    );
  }

  /// Gera o .zip com dados e imagens e abre o compartilhamento.
  Future<ResultadoDaExportacao> exportarECompartilhar({
    required String password,
  }) async {
    final gerado = await _gerarZipBytesDoEstadoAtual();
    final encoded = await CriptografiaBackup.criptografar(
      gerado.zipBytes,
      password,
    );

    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(tempDir.path, 'backup'));
    await exportDir.create(recursive: true);
    final nomeDoArquivo =
        'offline_gym_backup_${_marcaTemporal(DateTime.now())}.ogb';
    final arquivo = File(p.join(exportDir.path, nomeDoArquivo));
    await arquivo.writeAsBytes(encoded, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(arquivo.path, mimeType: 'application/octet-stream'),
        ],
        subject: 'Backup Offline Gym',
      ),
    );

    return ResultadoDaExportacao(
      nomeDoArquivo: nomeDoArquivo,
      imagensAusentes: gerado.imagensAusentes,
    );
  }

  /// Salva um backup diretamente no armazenamento interno do celular (100% offline),
  /// sem exigir compartilhamento externo.
  Future<BackupLocalSalvo> salvarBackupNoCelular({
    bool automatico = false,
  }) async {
    final gerado = await _gerarZipBytesDoEstadoAtual();
    final documents = await getApplicationDocumentsDirectory();
    final localDir = Directory(p.join(documents.path, _localBackupsFolder));
    await localDir.create(recursive: true);

    final agora = DateTime.now();
    final prefixo = automatico ? 'auto_backup' : 'backup_local';
    final nomeDoArquivo = '${prefixo}_${_marcaTemporalComSegundos(agora)}.zip';
    final arquivo = File(p.join(localDir.path, nomeDoArquivo));
    await arquivo.writeAsBytes(gerado.zipBytes, flush: true);

    await _limparBackupsLocaisExcedentes(localDir);

    final stat = await arquivo.stat();
    return BackupLocalSalvo(
      caminhoArquivo: arquivo.path,
      nomeArquivo: nomeDoArquivo,
      criadoEm: stat.modified,
      tamanhoBytes: stat.size,
      automatico: automatico,
    );
  }

  Future<void> _limparBackupsLocaisExcedentes(Directory dir) async {
    try {
      final entidades = await dir.list().toList();
      final arquivos = <File>[];
      for (final item in entidades) {
        if (item is File &&
            (item.path.endsWith('.zip') || item.path.endsWith('.ogb'))) {
          arquivos.add(item);
        }
      }
      if (arquivos.length <= 15) return;
      arquivos.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      for (var i = 15; i < arquivos.length; i++) {
        try {
          await arquivos[i].delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Lista todos os backups salvos diretamente no celular (mais recentes primeiro).
  Future<List<BackupLocalSalvo>> listarBackupsLocais() async {
    final documents = await getApplicationDocumentsDirectory();
    final localDir = Directory(p.join(documents.path, _localBackupsFolder));
    if (!await localDir.exists()) return const <BackupLocalSalvo>[];

    final entidades = await localDir.list().toList();
    final lista = <BackupLocalSalvo>[];
    for (final item in entidades) {
      if (item is! File) continue;
      final nome = p.basename(item.path);
      if (!nome.endsWith('.zip') && !nome.endsWith('.ogb')) continue;
      final stat = await item.stat();
      lista.add(
        BackupLocalSalvo(
          caminhoArquivo: item.path,
          nomeArquivo: nome,
          criadoEm: stat.modified,
          tamanhoBytes: stat.size,
          automatico: nome.startsWith('auto_backup_'),
        ),
      );
    }
    lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return lista;
  }

  /// Verifica se um arquivo salvo localmente está criptografado com senha.
  Future<bool> arquivoLocalEstaCriptografado(String caminhoArquivo) async {
    final arquivo = File(caminhoArquivo);
    if (!await arquivo.exists()) return false;
    final bytes = await arquivo.readAsBytes();
    return CriptografiaBackup.ehBackupCriptografado(bytes);
  }

  /// Lê e valida um backup salvo localmente no celular.
  Future<DadosDoBackup> lerBackupDeArquivoLocal(
    String caminhoArquivo, {
    String? password,
  }) async {
    final arquivo = File(caminhoArquivo);
    if (!await arquivo.exists()) {
      throw const ErroDeBackup('O arquivo de backup local não foi encontrado.');
    }
    var bytes = await arquivo.readAsBytes();
    if (CriptografiaBackup.ehBackupCriptografado(bytes)) {
      bytes = await CriptografiaBackup.descriptografar(bytes, password ?? '');
    }
    return _parse(bytes);
  }

  /// Compartilha um backup salvo no celular.
  Future<void> compartilharBackupLocal(String caminhoArquivo) async {
    final arquivo = File(caminhoArquivo);
    if (!await arquivo.exists()) {
      throw const ErroDeBackup('O arquivo de backup local não foi encontrado.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(arquivo.path, mimeType: 'application/octet-stream'),
        ],
        subject: 'Backup Offline Gym',
      ),
    );
  }

  /// Exclui um backup salvo no celular.
  Future<void> excluirBackupLocal(String caminhoArquivo) async {
    final arquivo = File(caminhoArquivo);
    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  }

  /// Abre o seletor de arquivos primeiro e retorna o nome e os bytes do arquivo escolhido.
  /// Retorna null se o usuário cancelar a seleção.
  Future<({String nome, Uint8List bytes})?>
      escolherBytesDeArquivoDeBackup() async {
    const zipType = XTypeGroup(
      label: 'Backup Offline Gym',
      extensions: <String>['ogb', 'zip'],
      mimeTypes: <String>[
        'application/octet-stream',
        'application/zip',
        'application/x-zip-compressed',
      ],
    );
    final arquivo = await openFile(acceptedTypeGroups: <XTypeGroup>[zipType]);
    if (arquivo == null) return null;
    final bytes = await arquivo.readAsBytes();
    return (nome: arquivo.name, bytes: bytes);
  }

  /// Verifica se os bytes do arquivo selecionado exigem senha de descriptografia.
  bool bytesEstaoCriptografados(Uint8List bytes) {
    return CriptografiaBackup.ehBackupCriptografado(bytes);
  }

  /// Descriptografa (se necessário) e valida os bytes de um backup já selecionado.
  Future<DadosDoBackup> decodificarBytesDeBackup(
    Uint8List bytes, {
    String? password,
  }) async {
    var processados = bytes;
    if (CriptografiaBackup.ehBackupCriptografado(processados)) {
      processados = await CriptografiaBackup.descriptografar(
        processados,
        password ?? '',
      );
    }
    return _parse(processados);
  }

  /// Abre o seletor de arquivos e valida o backup. Retorna null se cancelado.
  Future<DadosDoBackup?> selecionarArquivoDeBackup({String? password}) async {
    final escolhido = await escolherBytesDeArquivoDeBackup();
    if (escolhido == null) return null;
    return decodificarBytesDeBackup(escolhido.bytes, password: password);
  }

  /// Substitui os dados locais pelos do backup numa única transação.
  ///
  /// Se [apenasPlanosEExercicios] não for informado, quando o backup contiver
  /// apenas planos/exercícios (`data.contemApenasExercicios`), preserva
  /// automaticamente o perfil, histórico, hábitos, tarefas, diário e pesos.
  Future<void> restaurarBackup(
    DadosDoBackup data, {
    bool? apenasPlanosEExercicios,
    bool manterPerfilSeAusente = true,
  }) async {
    final somentePlanos =
        apenasPlanosEExercicios ?? data.contemApenasExercicios;
    final documents = await getApplicationDocumentsDirectory();
    final exercisesImagesDir = Directory(p.join(documents.path, _imagesFolder));
    await exercisesImagesDir.create(recursive: true);
    final diaryImagesDir = Directory(
      p.join(documents.path, _diaryImagesFolder),
    );
    await diaryImagesDir.create(recursive: true);
    final monthlyProgressImagesDir = Directory(
      p.join(documents.path, _monthlyProgressImagesFolder),
    );
    await monthlyProgressImagesDir.create(recursive: true);
    final profileImagesDir = Directory(
      p.join(documents.path, _profileImagesFolder),
    );
    await profileImagesDir.create(recursive: true);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final storedNames = <String, String>{}; // originalRelativeEntry -> fullPath

    final regexNomeSeguro = RegExp(r'[^a-zA-Z0-9._-]');
    for (final entry in data.imagens.entries) {
      final originalPath = entry.key;
      final nomeBruto = p.basename(originalPath);
      final nomeDoArquivo = nomeBruto.replaceAll(regexNomeSeguro, '_');
      if (nomeDoArquivo.isEmpty ||
          nomeDoArquivo == '.' ||
          nomeDoArquivo == '..') {
        continue;
      }
      final isDiary = originalPath.startsWith('$_diaryImagesFolder/');
      final isMonthlyProgress = originalPath.startsWith(
        '$_monthlyProgressImagesFolder/',
      );
      final isProfile = originalPath.startsWith('$_profileImagesFolder/');
      if (somentePlanos && (isDiary || isMonthlyProgress || isProfile)) {
        continue;
      }
      final targetDir = isDiary
          ? diaryImagesDir
          : (isMonthlyProgress
              ? monthlyProgressImagesDir
              : (isProfile ? profileImagesDir : exercisesImagesDir));
      final storedName = 'restaurado_${stamp}_$nomeDoArquivo';
      final arquivo = File(p.join(targetDir.path, storedName));
      await arquivo.writeAsBytes(entry.value, flush: true);
      storedNames[originalPath] = arquivo.path;
      storedNames[nomeBruto] = arquivo.path;
      storedNames[nomeDoArquivo] = arquivo.path;
    }

    final exercicios = data.exercicios.map((row) {
      final item = Map<String, Object?>.from(row);
      final original = item.remove('arquivoGif') as String?;
      final targetPath = original == null ? null : storedNames[original];
      item['caminhoLocalGif'] = targetPath;
      item.putIfAbsent('tempoDescansoSegundos', () => 60);
      return item;
    }).toList(growable: false);

    final diarios = data.diarios.map((row) {
      final item = Map<String, Object?>.from(row);
      final rawNames = item.remove('arquivosImagens');
      final newPaths = <String>[];
      if (rawNames is String && rawNames.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawNames);
          if (decoded is List) {
            for (final name in decoded) {
              final mapped = storedNames[name.toString()];
              if (mapped != null) newPaths.add(mapped);
            }
          }
        } catch (_) {}
      }
      item['caminhosImagens'] = jsonEncode(newPaths);
      item.putIfAbsent(
        'dataAtualizacaoISO',
        () => DateTime.now().toIso8601String(),
      );
      return item;
    }).toList(growable: false);

    final fotosMensais = data.fotosMensais
        .map((row) {
          final item = Map<String, Object?>.from(row);
          final original = item.remove('arquivoFoto') as String?;
          item['caminhoLocal'] =
              original == null ? null : storedNames[original];
          return item;
        })
        .where((row) => row['caminhoLocal'] != null)
        .toList(growable: false);

    Map<String, Object?>? perfil;
    if (data.perfil != null) {
      perfil = <String, Object?>{
        ...data.perfil!,
        'caminhoFoto': data.perfil!['arquivoFoto'] == null
            ? null
            : storedNames[data.perfil!['arquivoFoto']],
      };
      perfil.remove('arquivoFoto');
    }

    try {
      await _database.restaurarTabelasDoBackup(
        exercicios: exercicios,
        treinos: data.treinos,
        series: data.series,
        pesosCorporais: data.pesosCorporais,
        medidasCorporais: data.medidasCorporais,
        diarios: diarios,
        fotosMensais: fotosMensais,
        rotinas: data.rotinas,
        habitos: data.habitos,
        conclusoesHabitos: data.conclusoesHabitos,
        tarefas: data.tarefas,
        perfil: perfil,
        conclusoesLegadas: data.conclusoesLegadas,
        apenasPlanosEExercicios: somentePlanos,
        manterPerfilSeAusente: manterPerfilSeAusente,
      );
    } catch (_) {
      for (final caminho in storedNames.values) {
        try {
          await File(caminho).delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  DadosDoBackup _parse(Uint8List bytes) {
    if (bytes.length > _maxBackupBytes) {
      throw const ErroDeBackup(
        'Backup recusado: o arquivo excede o limite de 100 MB.',
      );
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const ErroDeBackup(
        'O arquivo escolhido não é um backup do Offline Gym.',
      );
    }

    if (archive.files.length > _maxArchiveEntries) {
      throw const ErroDeBackup(
        'Backup recusado: quantidade excessiva de arquivos.',
      );
    }
    ArchiveFile? dataFile;
    final nomes = <String>{};
    var totalImagemBytes = 0;
    for (final arquivo in archive.files) {
      final nome = arquivo.name.replaceAll('\\', '/');
      if (!nomes.add(nome) || nome.startsWith('/') || nome.contains('../')) {
        throw const ErroDeBackup(
          'Backup recusado: caminho de arquivo inválido ou duplicado.',
        );
      }
      if (nome == _dataFileName) {
        if (!arquivo.isFile || arquivo.content.length > _maxJsonBytes) {
          throw const ErroDeBackup('Backup recusado: dados JSON inválidos.');
        }
        dataFile = arquivo;
      } else if (arquivo.isFile && _ehPastaDeImagem(nome)) {
        if (arquivo.content.length > _maxImageBytes) {
          throw const ErroDeBackup(
            'Backup recusado: uma imagem excede o limite de 20 MB.',
          );
        }
        totalImagemBytes += arquivo.content.length;
        if (totalImagemBytes > _maxTotalImageBytes) {
          throw const ErroDeBackup(
            'Backup recusado: imagens excedem o limite total permitido.',
          );
        }
      } else if (arquivo.isFile) {
        throw const ErroDeBackup(
          'Backup recusado: o arquivo contém uma entrada desconhecida.',
        );
      }
    }
    if (dataFile == null) {
      throw const ErroDeBackup(
        'Backup inválido: arquivo de dados não encontrado.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(dataFile.content));
    } catch (_) {
      throw const ErroDeBackup('Backup inválido: os dados estão corrompidos.');
    }

    if (decoded is! Map ||
        decoded['app'] != _appId ||
        !<int>{1, 2, _formatVersion}.contains(decoded['formato'])) {
      throw const ErroDeBackup(
        'Este arquivo não é um backup compatível com esta versão do app.',
      );
    }
    final root = decoded;
    final formato = (root['formato'] as num?)?.toInt() ?? 1;

    List<Map<String, Object?>> rowsOf(
      String table,
      List<String> requiredKeys, {
      bool optional = false,
    }) {
      final value = root[table];
      if (value == null && optional) {
        return const <Map<String, Object?>>[];
      }
      if (value is! List) {
        throw ErroDeBackup('Backup inválido: tabela "$table" ausente.');
      }
      final rows = <Map<String, Object?>>[];
      if (value.length > _maxRowsPerTable) {
        throw ErroDeBackup(
          'Backup recusado: tabela "$table" excede o limite de registros.',
        );
      }
      for (final item in value) {
        if (item is! Map) {
          throw ErroDeBackup(
            'Backup inválido: registro malformado em "$table".',
          );
        }
        final row = Map<String, Object?>.from(item);
        for (final key in requiredKeys) {
          if (row[key] == null) {
            throw ErroDeBackup(
              'Backup inválido: campo "$key" ausente em "$table".',
            );
          }
        }
        _validarTiposBasicos(table, row);
        rows.add(row);
      }
      return rows;
    }

    final exercicios = rowsOf('exercicios_plano', const <String>[
      'id',
      'diaSemana',
      'nome',
      'carga',
      'series',
      'repeticoes',
    ]);
    final treinos = rowsOf(
      'historico_treinos',
      const <String>['id', 'dataISO', 'tempoTotalSegundos', 'diaSemana'],
      optional: true,
    );
    final series = rowsOf(
      'historico_series',
      const <String>[
        'id',
        'idHistoricoTreino',
        'nomeExercicio',
        'cargaUtilizada',
        'serieNumero',
      ],
      optional: true,
    );
    final pesosCorporais = rowsOf(
      'peso_corporal',
      const <String>['id', 'dataISO', 'pesoKg'],
      optional: true,
    );
    final medidasCorporais = <Map<String, Object?>>[];
    final rawMedidas = root['medidas_corporais'];
    if (rawMedidas is List) {
      for (final item in rawMedidas) {
        if (item is Map) medidasCorporais.add(Map<String, Object?>.from(item));
      }
    }

    final rotinas = <Map<String, Object?>>[];
    final rawRoutines = root['treinos_plano'];
    if (rawRoutines is List) {
      for (final item in rawRoutines) {
        if (item is Map) rotinas.add(Map<String, Object?>.from(item));
      }
    }
    if (rotinas.isEmpty && exercicios.isNotEmpty) {
      final routineByDay = <int, int>{};
      for (final exercicio in exercicios) {
        final diaSemana = (exercicio['diaSemana'] as num).toInt();
        final idRotina = routineByDay.putIfAbsent(diaSemana, () => diaSemana);
        exercicio['idTreino'] = idRotina;
      }
      for (final entry in routineByDay.entries) {
        rotinas.add(<String, Object?>{
          'id': entry.value,
          'diaSemana': entry.key,
          'nome': 'Treino A',
          'selecionado': 1,
        });
      }
    } else {
      final routineIdsByDay = <int, int>{
        for (final rotina in rotinas)
          (rotina['diaSemana'] as num).toInt(): (rotina['id'] as num).toInt(),
      };
      for (final exercicio in exercicios) {
        exercicio.putIfAbsent(
          'idTreino',
          () => routineIdsByDay[(exercicio['diaSemana'] as num).toInt()],
        );
      }
    }

    Map<String, Object?>? perfil;
    final rawProfile = root['perfil_usuario'];
    if (rawProfile is List &&
        rawProfile.isNotEmpty &&
        rawProfile.first is Map) {
      perfil = Map<String, Object?>.from(rawProfile.first as Map);
    } else if (rawProfile is Map && rawProfile.isNotEmpty) {
      perfil = Map<String, Object?>.from(rawProfile);
    }

    final diarios = <Map<String, Object?>>[];
    final rawDiaries = root['diario_treino'];
    if (rawDiaries is List) {
      for (final item in rawDiaries) {
        if (item is Map) {
          diarios.add(Map<String, Object?>.from(item));
        }
      }
    }

    final fotosMensais = <Map<String, Object?>>[];
    final rawMonthlyPhotos = root['fotos_evolucao_mensal'];
    if (rawMonthlyPhotos is List) {
      for (final item in rawMonthlyPhotos) {
        if (item is Map) {
          fotosMensais.add(Map<String, Object?>.from(item));
        }
      }
    }

    final habitos = <Map<String, Object?>>[];
    final rawHabits = root['habitos'];
    if (rawHabits is List) {
      for (final item in rawHabits) {
        if (item is Map) habitos.add(Map<String, Object?>.from(item));
      }
    }

    final conclusoesHabitos = <Map<String, Object?>>[];
    final rawCompletions = root['conclusoes_habitos'];
    if (rawCompletions is List) {
      for (final item in rawCompletions) {
        if (item is Map) conclusoesHabitos.add(Map<String, Object?>.from(item));
      }
    }

    final tarefas = <Map<String, Object?>>[];
    final rawTasks = root['tarefas_todo'];
    if (rawTasks is List) {
      for (final item in rawTasks) {
        if (item is Map) tarefas.add(Map<String, Object?>.from(item));
      }
    }

    final imagens = <String, Uint8List>{};
    for (final arquivo in archive.files) {
      if (!arquivo.isFile) continue;
      if (arquivo.name.startsWith('$_imagesFolder/') ||
          arquivo.name.startsWith('$_diaryImagesFolder/') ||
          arquivo.name.startsWith('$_monthlyProgressImagesFolder/') ||
          arquivo.name.startsWith('$_profileImagesFolder/')) {
        imagens[arquivo.name] = Uint8List.fromList(arquivo.content);
      }
    }

    return DadosDoBackup(
      exercicios: exercicios,
      treinos: treinos,
      series: series,
      pesosCorporais: pesosCorporais,
      medidasCorporais: medidasCorporais,
      diarios: diarios,
      fotosMensais: fotosMensais,
      rotinas: rotinas,
      habitos: habitos,
      conclusoesHabitos: conclusoesHabitos,
      tarefas: tarefas,
      perfil: perfil,
      imagens: imagens,
      conclusoesLegadas: formato < 3,
    );
  }

  bool _ehPastaDeImagem(String nome) =>
      nome.startsWith('$_imagesFolder/') ||
      nome.startsWith('$_diaryImagesFolder/') ||
      nome.startsWith('$_monthlyProgressImagesFolder/') ||
      nome.startsWith('$_profileImagesFolder/');

  void _validarTiposBasicos(String tabela, Map<String, Object?> row) {
    const inteiros = <String>{
      'id',
      'idTreino',
      'idHistoricoTreino',
      'diaSemana',
      'serieNumero',
      'series',
      'repeticoes',
      'tempoTotalSegundos',
    };
    const numeros = <String>{'carga', 'cargaUtilizada', 'pesoKg', 'rpe'};
    for (final entry in row.entries) {
      final value = entry.value;
      if (inteiros.contains(entry.key) && value is! int && value is! num) {
        throw ErroDeBackup(
            'Backup inválido: tipo de "${entry.key}" em "$tabela".');
      }
      if (numeros.contains(entry.key) && value is! num) {
        throw ErroDeBackup(
            'Backup inválido: tipo de "${entry.key}" em "$tabela".');
      }
    }
    final dia = row['diaSemana'];
    if (dia is num && (dia < 1 || dia > 7)) {
      throw const ErroDeBackup('Backup inválido: dia da semana fora de 1 a 7.');
    }
    final data = row['dataISO'];
    if (data is String && DateTime.tryParse(data) == null) {
      throw ErroDeBackup('Backup inválido: data inválida em "$tabela".');
    }
    for (final chave in <String>['carga', 'cargaUtilizada', 'pesoKg', 'rpe']) {
      final numero = row[chave];
      if (numero is num && (!numero.isFinite || numero < 0)) {
        throw const ErroDeBackup('Backup inválido: valor negativo ou não finito.');
      }
    }
    for (final chave in <String>['series', 'repeticoes', 'serieNumero']) {
      final numero = row[chave];
      if (numero is num && numero < 0) {
        throw const ErroDeBackup('Backup inválido: quantidade negativa.');
      }
    }
  }

  String _marcaTemporal(DateTime value) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${dois(value.month)}${dois(value.day)}_'
        '${dois(value.hour)}${dois(value.minute)}';
  }

  String _marcaTemporalComSegundos(DateTime value) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${dois(value.month)}${dois(value.day)}_'
        '${dois(value.hour)}${dois(value.minute)}${dois(value.second)}';
  }
}
