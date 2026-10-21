import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../banco_dados/banco_de_dados.dart';
import '../provedores/estado_treino.dart';
import '../dominio/calculadora_nutricional.dart';
import 'gerador_de_pdf.dart';

class ServicoDeExportacaoDeRelatorio {
  ServicoDeExportacaoDeRelatorio._();

  static final ServicoDeExportacaoDeRelatorio instance =
      ServicoDeExportacaoDeRelatorio._();

  static final DateFormat _formatadorDataHora = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _formatadorData = DateFormat('dd/MM/yyyy');

  /// Sanitiza strings para inclusão segura em células de arquivo CSV.
  /// Previne ataques de CSV Formula Injection (quando células começam com =, +, -, @).
  static String _sanitizarCelulaCSV(String texto) {
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

  /// Sanitiza nomes de arquivos para evitar caracteres proibidos no sistema de arquivos.
  static String _sanitizarNomeArquivo(String nome) {
    return nome.replaceAll(RegExp(r'[\\/:*?"<>|\r\n]'), '_');
  }

  /// Exporta uma planilha CSV estruturada (com BOM UTF-8 para Excel / Google Sheets)
  Future<bool> exportarRelatorioCSV(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    try {
      final db = BancoDeDados.instance;
      final perfil = provedor.perfil;
      final historico = await db.obterHistoricoDeTreinos();
      final pesos = await db.obterPesosCorporais();
      final medidas = await db.obterMedidasCorporais();
      final pesoAtual = provedor.pesoCorporalAtualKg;
      final metaPeso = perfil?.metaPesoKg;

      final buffer = StringBuffer();
      // Byte Order Mark (BOM) UTF-8 para o Excel abrir com acentuação perfeita
      buffer.write('\uFEFF');

      // Cabeçalho institucional do aluno
      buffer.writeln(
          '# ========================================================');
      buffer.writeln('# RELATORIO DE TREINOS, CARGAS E MEDIDAS - OFFLINE GYM');
      buffer.writeln(
          '# Gerado em: ${_formatadorDataHora.format(DateTime.now())}');
      buffer.writeln(
        '# Aluno: ${perfil?.nome.isNotEmpty == true ? perfil!.nome : "Atleta Offline Gym"}',
      );
      if (perfil != null) {
        if (perfil.idade != null && perfil.idade! > 0) {
          buffer.writeln('# Idade: ${perfil.idade} anos');
        }
        if (perfil.sexo.isNotEmpty) {
          buffer.writeln('# Sexo: ${perfil.sexo}');
        }
        if (perfil.alturaCm != null && perfil.alturaCm! > 0) {
          buffer.writeln('# Altura: ${perfil.alturaCm!.toStringAsFixed(1)} cm');
        }
        buffer.writeln('# Nivel: ${perfil.nivelExperiencia}');
        buffer.writeln('# Objetivo: ${perfil.objetivoPrincipal}');

        final metas = CalculadoraNutricional.calcularMetas(
          pesoKg: pesoAtual ?? perfil.metaPesoKg ?? 70.0,
          alturaCm: perfil.alturaCm ?? 175.0,
          idade: perfil.idade ?? 25,
          sexo: perfil.sexo,
          objetivo: perfil.objetivoPrincipal,
          fatorAtividade: perfil.fatorAtividade,
        );
        buffer
            .writeln('# TMB (Gasto Basal): ${metas.tmbKcal.round()} kcal/dia');
        buffer.writeln(
            '# TDEE (Gasto Total): ${metas.tdeeKcal.round()} kcal/dia');
        buffer.writeln(
            '# Meta Calorica Diaria: ${metas.caloriasAlvoKcal.round()} kcal/dia');
        buffer.writeln(
            '# Meta de Proteina: ${metas.proteinaGramas.round()} g/dia');
        buffer.writeln(
            '# Meta de Carboidrato: ${metas.carboidratoGramas.round()} g/dia');
        buffer
            .writeln('# Meta de Gordura: ${metas.gorduraGramas.round()} g/dia');
        buffer.writeln(
            '# Meta de Agua: ${metas.aguaLitros.toStringAsFixed(1)} L/dia');
      }
      if (pesoAtual != null) {
        buffer.writeln('# Peso Atual: ${pesoAtual.toStringAsFixed(1)} kg');
      }
      if (metaPeso != null && metaPeso > 0) {
        buffer.writeln('# Meta de Peso: ${metaPeso.toStringAsFixed(1)} kg');
      }
      buffer.writeln('# Ofensiva Atual: ${provedor.ofensivaAtual} dias');
      buffer.writeln('# Total de Sessoes: ${historico.length}');
      buffer.writeln(
          '# ========================================================');
      buffer.writeln('');

      // 1. Tabela de Sessões e Séries Detalhadas
      buffer.writeln('# HISTORICO DE CARGAS E SERIES EXECUTADAS');
      buffer.writeln(
        'Data;Hora;Dia_Semana;Rotina;Exercicio;Serie_Num;Tipo_Serie;Carga_kg;Repeticoes;RPE;Volume_kg',
      );

      final prs = <String, double>{};
      var volumeTotalGeral = 0.0;

      for (final sessao in historico) {
        final dataSessao = DateTime.tryParse(sessao.dataISO) ?? DateTime.now();
        final dataStr = _formatadorData.format(dataSessao);
        final horaStr = DateFormat('HH:mm').format(dataSessao);
        final diaSemanaStr = _obterNomeDiaSemana(dataSessao.weekday);
        final nomeRotina = sessao.nomeTreino.isNotEmpty
            ? sessao.nomeTreino
            : 'Treino Realizado';

        final series = await db.obterSeriesDoTreino(sessao.id);
        for (final s in series) {
          final volume = s.cargaUtilizada * s.repeticoes;
          volumeTotalGeral += volume;

          // Atualiza recorde pessoal (PR)
          final cargaAtual = prs[s.nomeExercicio] ?? 0.0;
          if (s.cargaUtilizada > cargaAtual) {
            prs[s.nomeExercicio] = s.cargaUtilizada;
          }

          final rpeStr = s.rpe != null ? s.rpe!.toStringAsFixed(1) : '';
          buffer.writeln(
            '$dataStr;$horaStr;$diaSemanaStr;"${_sanitizarCelulaCSV(nomeRotina)}";"${_sanitizarCelulaCSV(s.nomeExercicio)}";${s.serieNumero};${s.tipo};${s.cargaUtilizada.toStringAsFixed(1)};${s.repeticoes};$rpeStr;${volume.toStringAsFixed(1)}',
          );
        }
      }

      buffer.writeln('');
      buffer.writeln(
          '# Volume Total Acumulado: ${volumeTotalGeral.toStringAsFixed(1)} kg');
      buffer.writeln('');

      // 2. Tabela de Recordes Pessoais (PRs)
      buffer.writeln(
          '# RECORDES PESSOAIS (MAIOR CARGA REGISTRADA POR EXERCICIO)');
      buffer.writeln('Exercicio;Carga_Maxima_kg');
      final prsOrdenados = prs.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final pr in prsOrdenados) {
        buffer.writeln(
          '"${_sanitizarCelulaCSV(pr.key)}";${pr.value.toStringAsFixed(1)}',
        );
      }

      buffer.writeln('');

      // 3. Tabela de Medidas Corporais de Fita Métrica
      buffer.writeln('# HISTORICO DE MEDIDAS CORPORAIS COM FITA METRICA');
      buffer.writeln(
        'Data;Hora;Braco_Dir_cm;Braco_Esq_cm;Peitoral_cm;Cintura_cm;Abdomen_cm;Coxa_Dir_cm;Coxa_Esq_cm;Panturrilha_Dir_cm;Panturrilha_Esq_cm;Observacoes',
      );
      for (final m in medidas) {
        final dataM = DateTime.tryParse(m.dataISO) ?? DateTime.now();
        buffer.writeln(
          '${_formatadorData.format(dataM)};${DateFormat('HH:mm').format(dataM)};'
          '${m.bracoDireitoCm?.toStringAsFixed(1) ?? ""};'
          '${m.bracoEsquerdoCm?.toStringAsFixed(1) ?? ""};'
          '${m.peitoralCm?.toStringAsFixed(1) ?? ""};'
          '${m.cinturaCm?.toStringAsFixed(1) ?? ""};'
          '${m.abdomenCm?.toStringAsFixed(1) ?? ""};'
          '${m.coxaDireitaCm?.toStringAsFixed(1) ?? ""};'
          '${m.coxaEsquerdaCm?.toStringAsFixed(1) ?? ""};'
          '${m.panturrilhaDireitaCm?.toStringAsFixed(1) ?? ""};'
          '${m.panturrilhaEsquerdaCm?.toStringAsFixed(1) ?? ""};'
          '"${_sanitizarCelulaCSV(m.observacoes ?? "")}"',
        );
      }

      buffer.writeln('');

      // 4. Tabela de Pesagem Corporal
      buffer.writeln('# HISTORICO DE PESAGEM CORPORAL');
      buffer.writeln('Data;Hora;Peso_kg');
      for (final p in pesos) {
        final dataP = DateTime.tryParse(p.dataISO) ?? DateTime.now();
        buffer.writeln(
          '${_formatadorData.format(dataP)};${DateFormat('HH:mm').format(dataP)};${p.pesoKg.toStringAsFixed(1)}',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final agora = DateTime.now();
      final timestamp =
          '${agora.year}${agora.month.toString().padLeft(2, '0')}${agora.day.toString().padLeft(2, '0')}_${agora.hour.toString().padLeft(2, '0')}${agora.minute.toString().padLeft(2, '0')}';
      final nomeAlunoLimpo = _sanitizarNomeArquivo(
        perfil?.nome.isNotEmpty == true
            ? perfil!.nome.toLowerCase().replaceAll(' ', '_')
            : 'offline_gym',
      );
      final arquivo = File(
        '${tempDir.path}/relatorio_${nomeAlunoLimpo}_$timestamp.csv',
      );
      await arquivo.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(arquivo.path)],
          subject: 'Relatório de Treinos (CSV / Planilha) — Offline Gym',
          text:
              'Segue anexo o relatório detalhado de treinos e cargas do aluno para acompanhamento.',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar CSV: $e');
      return false;
    }
  }

  /// Exporta o relatório executivo completo em arquivo PDF nativo (sem depender de HTML/navegador).
  Future<bool> exportarRelatorioPDF(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    return GeradorDePdfTreino.instance.exportarRelatorioHistoricoPDF(
      context: context,
      provedor: provedor,
    );
  }

  /// Exporta a ficha de prescrição de treino do aluno em arquivo PDF nativo.
  Future<bool> exportarFichaTreinoPDF(
    BuildContext context,
    ProvedorDeTreino provedor, {
    int? diaSemana,
  }) async {
    return GeradorDePdfTreino.instance.exportarFichaTreinoPDF(
      context: context,
      provedor: provedor,
      diaSemana: diaSemana,
    );
  }

  /// Exporta a ficha de prescrição de treino em formato de planilha CSV com codificação UTF-8 BOM.
  Future<bool> exportarFichaTreinoCSV(
    BuildContext context,
    ProvedorDeTreino provedor, {
    int? diaSemana,
  }) async {
    try {
      final perfil = provedor.perfil;
      final nomeAluno = perfil?.nome.isNotEmpty == true
          ? perfil!.nome
          : 'Atleta Offline Gym';
      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln(
          '# ========================================================');
      buffer.writeln('# FICHA DE PRESCRIÇÃO DE TREINO — OFFLINE GYM');
      buffer.writeln('# Aluno: $nomeAluno');
      buffer.writeln('# Objetivo: ${perfil?.objetivoPrincipal ?? "Hipertrofia"}');
      buffer.writeln('# Nível: ${perfil?.nivelExperiencia ?? "Iniciante"}');
      buffer.writeln(
          '# Gerado em: ${_formatadorDataHora.format(DateTime.now())}');
      buffer.writeln(
          '# ========================================================');
      buffer.writeln('');
      buffer.writeln(
          'Dia_Semana;Rotina;Exercicio;Series;Repeticoes;Carga_Base_kg;Descanso_seg;Observacao');

      final dias =
          diaSemana != null ? <int>[diaSemana] : const <int>[1, 2, 3, 4, 5, 6, 7];
      for (final dia in dias) {
        final rotinas = provedor.rotinasDoDia(dia);
        for (final rotina in rotinas) {
          for (final ex in rotina.exercicios) {
            buffer.writeln(
              '${_obterNomeDiaSemana(dia)};"${_sanitizarCelulaCSV(rotina.nome)}";"${_sanitizarCelulaCSV(ex.nome)}";${ex.series};${ex.repeticoes};${ex.carga.toStringAsFixed(1)};${ex.tempoDescansoSegundos};""',
            );
          }
        }
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final nomeAlunoLimpo = _sanitizarNomeArquivo(
          nomeAluno.toLowerCase().replaceAll(' ', '_'));
      final arquivo =
          File('${tempDir.path}/ficha_treino_${nomeAlunoLimpo}_$timestamp.csv');
      await arquivo.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(arquivo.path)],
          subject: 'Ficha de Treino (Planilha CSV) — $nomeAluno',
          text: 'Segue a ficha de treino em planilha para acompanhamento.',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar Ficha CSV: $e');
      return false;
    }
  }

  /// Exporta o relatório executivo em PDF nativo (mantido por compatibilidade com chamadas anteriores).
  Future<bool> exportarRelatorioPDFHtml(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    return exportarRelatorioPDF(context, provedor);
  }

  String _obterNomeDiaSemana(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda-feira';
      case DateTime.tuesday:
        return 'Terca-feira';
      case DateTime.wednesday:
        return 'Quarta-feira';
      case DateTime.thursday:
        return 'Quinta-feira';
      case DateTime.friday:
        return 'Sexta-feira';
      case DateTime.saturday:
        return 'Sabado';
      case DateTime.sunday:
      default:
        return 'Domingo';
    }
  }
}
