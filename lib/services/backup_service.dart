import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupExportResult {
  const BackupExportResult({
    required this.fileName,
    required this.missingImages,
  });

  final String fileName;
  final int missingImages;
}

class BackupData {
  const BackupData({
    required this.exercises,
    required this.workouts,
    required this.series,
    required this.bodyWeights,
    required this.images,
  });

  /// Cada exercício traz `arquivoGif`: o nome da imagem dentro do backup.
  final List<Map<String, Object?>> exercises;
  final List<Map<String, Object?>> workouts;
  final List<Map<String, Object?>> series;
  final List<Map<String, Object?>> bodyWeights;

  /// Nome original do arquivo -> bytes da imagem.
  final Map<String, Uint8List> images;

  int get exerciseCount => exercises.length;
  int get workoutCount => workouts.length;
  int get seriesCount => series.length;
  int get bodyWeightCount => bodyWeights.length;
  int get imageCount => images.length;
}

class BackupService {
  BackupService(this._database);

  final DatabaseHelper _database;

  static const String _appId = 'offline_gym';
  static const int _formatVersion = 1;
  static const String _dataFileName = 'dados.json';
  static const String _imagesFolder = 'exercise_gifs';

  /// Gera o .zip com dados e imagens e abre o compartilhamento do Android.
  Future<BackupExportResult> exportAndShare() async {
    final tables = await _database.exportBackupTables();

    final archive = Archive();
    final imageFiles = <String, File>{};
    var missingImages = 0;

    // Caminhos absolutos mudam de celular para celular, então o backup guarda
    // só o nome do arquivo. O import recria o caminho no aparelho novo.
    final exercises = <Map<String, Object?>>[];
    for (final row in tables['exercicios_plano'] ?? const <Map<String, Object?>>[]) {
      final item = Map<String, Object?>.from(row);
      final localPath = item.remove('caminhoLocalGif') as String?;
      String? imageName;
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          imageName = p.basename(localPath);
          imageFiles[imageName] = file;
        } else {
          missingImages++;
        }
      }
      item['arquivoGif'] = imageName;
      exercises.add(item);
    }

    final payload = <String, Object?>{
      'app': _appId,
      'formato': _formatVersion,
      'exportadoEm': DateTime.now().toIso8601String(),
      'exercicios_plano': exercises,
      'historico_treinos': tables['historico_treinos'] ?? const <Map<String, Object?>>[],
      'historico_series': tables['historico_series'] ?? const <Map<String, Object?>>[],
      'peso_corporal': tables['peso_corporal'] ?? const <Map<String, Object?>>[],
    };
    final dataBytes = utf8.encode(JsonEncoder.withIndent('  ').convert(payload));
    archive.addFile(ArchiveFile(_dataFileName, dataBytes.length, dataBytes));

    for (final entry in imageFiles.entries) {
      final bytes = await entry.value.readAsBytes();
      archive.addFile(ArchiveFile('$_imagesFolder/${entry.key}', bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw const BackupException('Não foi possível gerar o arquivo de backup.');
    }

    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(tempDir.path, 'backup'));
    await exportDir.create(recursive: true);
    final fileName = 'offline_gym_backup_${_timestamp(DateTime.now())}.zip';
    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsBytes(encoded, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'application/zip')],
        subject: 'Backup Offline Gym',
      ),
    );

    return BackupExportResult(fileName: fileName, missingImages: missingImages);
  }

  /// Abre o seletor de arquivos e valida o backup. Retorna null se cancelado.
  Future<BackupData?> pickBackup() async {
    final zipType = XTypeGroup(
      label: 'Backup Offline Gym',
      extensions: <String>['zip'],
      mimeTypes: <String>['application/zip', 'application/x-zip-compressed'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[zipType]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return _parse(bytes);
  }

  /// Substitui todos os dados locais pelos do backup. O banco é atualizado
  /// numa única transação: se algo falhar, nada muda.
  Future<void> restore(BackupData data) async {
    final documents = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(documents.path, _imagesFolder));
    await imagesDir.create(recursive: true);

    // Cada imagem recebe um nome novo. Assim um arquivo que os dados atuais
    // ainda usam nunca é sobrescrito.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final storedNames = <String, String>{}; // nome original -> nome salvo
    for (final entry in data.images.entries) {
      final storedName = 'restaurado_${stamp}_${entry.key}';
      await File(p.join(imagesDir.path, storedName)).writeAsBytes(entry.value, flush: true);
      storedNames[entry.key] = storedName;
    }

    final exercises = data.exercises.map((row) {
      final item = Map<String, Object?>.from(row);
      final original = item.remove('arquivoGif') as String?;
      final storedName = original == null ? null : storedNames[original];
      item['caminhoLocalGif'] =
      storedName == null ? null : p.join(imagesDir.path, storedName);
      return item;
    }).toList(growable: false);

    try {
      await _database.restoreBackupTables(
        exercises: exercises,
        workouts: data.workouts,
        series: data.series,
        bodyWeights: data.bodyWeights,
      );
    } catch (_) {
      // Remove as imagens recém-copiadas, já que o banco não foi alterado.
      for (final storedName in storedNames.values) {
        try {
          await File(p.join(imagesDir.path, storedName)).delete();
        } catch (_) {}
      }
      rethrow;
    }

    // Só depois do sucesso: remove imagens que nenhum exercício referencia.
    final keep = storedNames.values.toSet();
    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File && !keep.contains(p.basename(entity.path))) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  BackupData _parse(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('O arquivo escolhido não é um backup do Offline Gym.');
    }

    ArchiveFile? dataFile;
    for (final file in archive.files) {
      if (file.isFile && file.name == _dataFileName) dataFile = file;
    }
    if (dataFile == null) {
      throw const BackupException('Backup inválido: arquivo de dados não encontrado.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(dataFile.content));
    } catch (_) {
      throw const BackupException('Backup inválido: os dados estão corrompidos.');
    }

    if (decoded is! Map || decoded['app'] != _appId || decoded['formato'] != _formatVersion) {
      throw const BackupException('Este arquivo não é um backup compatível com esta versão do app.');
    }
    final root = decoded;

    List<Map<String, Object?>> rowsOf(String table, List<String> requiredKeys) {
      final value = root[table];
      if (value is! List) {
        throw BackupException('Backup inválido: tabela "$table" ausente.');
      }
      final rows = <Map<String, Object?>>[];
      for (final item in value) {
        if (item is! Map) {
          throw BackupException('Backup inválido: registro malformado em "$table".');
        }
        final row = Map<String, Object?>.from(item);
        for (final key in requiredKeys) {
          if (row[key] == null) {
            throw BackupException('Backup inválido: campo "$key" ausente em "$table".');
          }
        }
        rows.add(row);
      }
      return rows;
    }

    final exercises = rowsOf('exercicios_plano',
        const <String>['id', 'diaSemana', 'nome', 'carga', 'series', 'repeticoes']);
    final workouts = rowsOf('historico_treinos',
        const <String>['id', 'dataISO', 'tempoTotalSegundos', 'diaSemana']);
    final series = rowsOf('historico_series',
        const <String>['id', 'idHistoricoTreino', 'nomeExercicio', 'cargaUtilizada', 'serieNumero']);
    final bodyWeights = rowsOf('peso_corporal',
        const <String>['id', 'dataISO', 'pesoKg']);

    final images = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('$_imagesFolder/')) continue;
      final name = p.basename(file.name);
      if (name.isEmpty) continue;
      images[name] = Uint8List.fromList(file.content);
    }

    return BackupData(
      exercises: exercises,
      workouts: workouts,
      series: series,
      bodyWeights: bodyWeights,
      images: images,
    );
  }

  String _timestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}';
  }
}