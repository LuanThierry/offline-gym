import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_gym/dominio/recursos_avancados.dart';
import 'package:offline_gym/modelos/plano_de_treino.dart';
import 'package:offline_gym/servicos/criptografia_de_backup.dart';

void main() {
  group('Segurança e Sanitização contra Injeção de Fórmulas CSV', () {
    String sanitizarCelulaCSV(String texto) {
      var limpo = texto.replaceAll('"', '""');
      if (limpo.isNotEmpty &&
          (limpo.startsWith('=') ||
              limpo.startsWith('+') ||
              limpo.startsWith('-') ||
              limpo.startsWith('@') ||
              limpo.startsWith('\t') ||
              limpo.startsWith('\r'))) {
        limpo = "'$limpo";
      }
      return limpo;
    }

    test('bloqueia injeção de fórmulas iniciadas por =', () {
      const perigoso = '=cmd|"/C calc"!A0';
      final resultado = sanitizarCelulaCSV(perigoso);
      expect(resultado.startsWith("'="), isTrue);
    });

    test('bloqueia injeção de fórmulas iniciadas por +, -, @', () {
      expect(sanitizarCelulaCSV('+1234').startsWith("'+"), isTrue);
      expect(sanitizarCelulaCSV('-2+5').startsWith("'-"), isTrue);
      expect(sanitizarCelulaCSV('@SUM(A1:A10)').startsWith("'@"), isTrue);
    });

    test('preserva texto normal e escapa aspas duplas internas', () {
      const normal = 'Supino Reto 4x10 "Pesado"';
      final resultado = sanitizarCelulaCSV(normal);
      expect(resultado, 'Supino Reto 4x10 ""Pesado""');
      expect(resultado.startsWith("'"), isFalse);
    });
  });

  group('Parsing de Cargas e Notação Decimal Brasileira', () {
    double? parseCarga(String entrada) {
      final normalizado = entrada.trim().replaceAll(',', '.');
      return double.tryParse(normalizado);
    }

    test('aceita decimais com vírgula e com ponto', () {
      expect(parseCarga('12,5'), 12.5);
      expect(parseCarga('12.5'), 12.5);
      expect(parseCarga(' 7,25 '), 7.25);
      expect(parseCarga('100'), 100.0);
    });

    test('rejeita entradas inválidas ou vazias', () {
      expect(parseCarga(''), isNull);
      expect(parseCarga('abc'), isNull);
      expect(parseCarga('12,34,56'), isNull);
    });
  });

  group('Criptografia e Integridade de Backup (.ogb)', () {
    test('falha com senha incorreta', () async {
      final payload = utf8.encode('{"versao": 1, "dados": "segredo"}');
      final criptografado =
          await CriptografiaBackup.criptografar(payload, 'senha_correta_123');

      expect(
        () async =>
            await CriptografiaBackup.descriptografar(criptografado, 'senha_errada'),
        throwsA(isA<Exception>()),
      );
    });

    test('falha ao tentar descriptografar bytes corrompidos ou adulterados', () async {
      final payload = utf8.encode('{"versao": 1, "dados": "segredo"}');
      final criptografado =
          await CriptografiaBackup.criptografar(payload, 'senha_valida');

      final corrompido = Uint8List.fromList(criptografado);
      // Altera o último byte do ciphertext/MAC
      corrompido[corrompido.length - 1] ^= 0xFF;

      expect(
        () async =>
            await CriptografiaBackup.descriptografar(corrompido, 'senha_valida'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejeita payload menor que o cabeçalho mínimo', () async {
      final cabecalhoIncompleto = Uint8List.fromList([1, 2, 3, 4]);
      expect(
        () async => await CriptografiaBackup.descriptografar(
            cabecalhoIncompleto, 'qualquer_senha'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Recursos Avançados e Casos Limite', () {
    test('estimar1RM com 1 repetição retorna a própria carga', () {
      expect(RecursosAvancados.estimar1RM(100.0, 1), 100.0);
    });

    test('estimar1RM com carga ou repetições zero/negativas retorna 0', () {
      expect(RecursosAvancados.estimar1RM(0.0, 10), 0.0);
      expect(RecursosAvancados.estimar1RM(-50.0, 5), 0.0);
      expect(RecursosAvancados.estimar1RM(80.0, 0), 0.0);
      expect(RecursosAvancados.estimar1RM(80.0, -2), 0.0);
    });

    test('progressão mantém carga e sugere +1 repetição se meta não foi alcançada', () {
      final resultado = RecursosAvancados.progressao(
        cargaKg: 80.0,
        repeticoes: 8,
        alvoRepeticoes: 10,
        rpe: 8.5,
      );

      expect(resultado.cargaSugeridaKg, 80.0);
      expect(resultado.repeticoesSugeridas, 9);
      expect(resultado.motivo.contains('Mantenha a carga'), isTrue);
    });

    test('progressão não sobe carga se RPE for alto (> 7) mesmo atingindo reps', () {
      final resultado = RecursosAvancados.progressao(
        cargaKg: 80.0,
        repeticoes: 10,
        alvoRepeticoes: 10,
        rpe: 9.5, // Quase falha
      );

      expect(resultado.cargaSugeridaKg, 80.0);
      expect(resultado.repeticoesSugeridas, 10);
      expect(resultado.motivo.contains('esforço ficar mais consistente'), isTrue);
    });

    test('detectarDeload identifica sobrecarga acumulada acima de 35% da média', () {
      final hoje = DateTime(2026, 4, 28);
      final series = <SerieHistorica>[
        // Semana 1 (anterior): 1000 kg volume
        SerieHistorica(
          data: hoje.subtract(const Duration(days: 8)),
          serie: const SerieDoTreino(
            nomeExercicio: 'Agachamento',
            cargaUtilizada: 100.0,
            serieNumero: 1,
            repeticoes: 10,
          ),
        ),
        // Semana 2 (anterior): 1000 kg volume
        SerieHistorica(
          data: hoje.subtract(const Duration(days: 15)),
          serie: const SerieDoTreino(
            nomeExercicio: 'Agachamento',
            cargaUtilizada: 100.0,
            serieNumero: 1,
            repeticoes: 10,
          ),
        ),
        // Semana 0 (atual): 2000 kg volume (2x a média -> pico de estresse)
        SerieHistorica(
          data: hoje.subtract(const Duration(days: 2)),
          serie: const SerieDoTreino(
            nomeExercicio: 'Agachamento',
            cargaUtilizada: 100.0,
            serieNumero: 1,
            repeticoes: 20,
          ),
        ),
      ];

      final diag = RecursosAvancados.detectarDeload(series, hoje);
      expect(diag.recomendado, isTrue);
      expect(diag.motivo.contains('acima da média recente'), isTrue);
    });

    test('template versionado rejeita JSON com mais de 1MB ou mais de 200 exercícios', () {
      // Cria string simulando template gigante
      final jsonGigante = jsonEncode({
        'versao': 1,
        'nome': 'Template Gigante',
        'exercicios': List.generate(
          250,
          (i) => {'nome': 'Exercicio $i', 'diaSemana': 1},
        ),
      });

      expect(
        () => RecursosAvancados.importarTemplate(jsonGigante),
        throwsFormatException,
      );
    });
  });
}
