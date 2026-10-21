// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/material.dart' show BuildContext, debugPrint;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../banco_dados/banco_de_dados.dart';
import '../dominio/calculadora_nutricional.dart';
import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';

/// Serviço 100% offline para geração nativa de arquivos PDF binários
/// de fichas de treino e relatórios executivos para Personal Trainer e Nutricionista.
class GeradorDePdfTreino {
  GeradorDePdfTreino._();

  static final GeradorDePdfTreino instance = GeradorDePdfTreino._();

  static final DateFormat _formatadorDataHora = DateFormat('dd/MM/yyyy HH:mm');

  static const PdfColor _corPrimaria = PdfColor.fromInt(0xFF6C5CE7);
  static const PdfColor _corSecundaria = PdfColor.fromInt(0xFF4834D4);
  static const PdfColor _corFundoCinza = PdfColor.fromInt(0xFFF1F2F6);
  static const PdfColor _corBorda = PdfColor.fromInt(0xFFDFE6E9);
  static const PdfColor _corTextoEscuro = PdfColor.fromInt(0xFF2D3436);
  static const PdfColor _corTextoMudo = PdfColor.fromInt(0xFF636E72);

  static String _sanitizarNomeArquivo(String nome) {
    return nome.replaceAll(RegExp(r'[\\/:*?"<>|\r\n]'), '_');
  }

  static String _nomeDoDiaSemana(int dia) {
    switch (dia) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Dia $dia';
    }
  }

  /// Exporta a Ficha de Treino Oficial do usuário em PDF vetorial nativo (sem HTML).
  /// Se [diaSemana] for informado, gera a ficha apenas daquele dia; se nulo, gera da semana inteira.
  Future<bool> exportarFichaTreinoPDF({
    required BuildContext context,
    required ProvedorDeTreino provedor,
    int? diaSemana,
  }) async {
    try {
      final perfil = provedor.perfil;
      final nomeAluno =
          perfil?.nome.isNotEmpty == true ? perfil!.nome : 'Atleta Offline Gym';
      final pesoAtual = provedor.pesoCorporalAtualKg;
      final metaPeso = perfil?.metaPesoKg;
      final dataEmissao = _formatadorDataHora.format(DateTime.now());

      final pdf = pw.Document(
        title: 'Ficha de Treinos — $nomeAluno',
        author: 'Offline Gym',
      );

      final diasParaIncluir = diaSemana != null
          ? <int>[diaSemana]
          : const <int>[1, 2, 3, 4, 5, 6, 7];

      final rotinasPorDia = <int, List<RotinaDeTreino>>{};
      for (final dia in diasParaIncluir) {
        final rotinas = provedor.rotinasDoDia(dia);
        if (rotinas.isNotEmpty && rotinas.any((r) => r.exercicios.isNotEmpty)) {
          rotinasPorDia[dia] = rotinas;
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (pw.Context ctx) => _construirCabecalhoDocumento(
            titulo: 'FICHA DE PRESCRIÇÃO DE TREINO',
            subtitulo:
                'Planejamento Individualizado de Musculação & Exercícios',
            ctx: ctx,
          ),
          footer: (pw.Context ctx) => _construirRodapeDocumento(ctx),
          build: (pw.Context ctx) {
            return <pw.Widget>[
              pw.SizedBox(height: 12),
              // Card com dados do aluno
              _construirCardIdentificacaoAluno(
                nomeAluno: nomeAluno,
                perfil: perfil,
                pesoAtual: pesoAtual,
                metaPeso: metaPeso,
                dataEmissao: dataEmissao,
              ),
              pw.SizedBox(height: 18),

              if (rotinasPorDia.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: _corFundoCinza,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _corBorda),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Nenhum treino planejado cadastrado para o período selecionado.',
                      style: pw.TextStyle(
                        color: _corTextoMudo,
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...rotinasPorDia.entries.map((entry) {
                  final dia = entry.key;
                  final rotinas = entry.value;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _corPrimaria,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          '📅 ${_nomeDoDiaSemana(dia).toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      ...rotinas.map((rotina) {
                        return _construirTabelaRotina(rotina);
                      }),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }),

              pw.SizedBox(height: 20),
              // Bloco de recomendações fisiológicas
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _corFundoCinza,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _corBorda),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECOMENDAÇÕES PARA O TREINAMENTO:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _corSecundaria,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '• Realize aquecimento neuromuscular prévio com cargas progressivas antes das séries válidas.\n'
                      '• Respeite o intervalo de descanso cronometrado para manutenção da intensidade mecânica.\n'
                      '• Registre a carga utilizada em cada sessão no Offline Gym para aplicar sobrecarga progressiva semanal.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _corTextoEscuro,
                        lineSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 36),
              // Assinaturas
              _construirAreaAssinaturas(nomeAluno),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final nomeSanitizado = _sanitizarNomeArquivo(
        nomeAluno.toLowerCase().replaceAll(' ', '_'),
      );
      final arquivo = File(
        '${tempDir.path}/ficha_treino_${nomeSanitizado}_$timestamp.pdf',
      );
      await arquivo.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(arquivo.path)],
          subject: 'Ficha de Treinos (PDF) — $nomeAluno',
          text:
              'Segue a ficha de treinos em PDF pronta para impressão ou acompanhamento na academia.',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar Ficha de Treino em PDF: $e');
      return false;
    }
  }

  /// Exporta o Relatório Executivo de Evolução, Cargas e Desempenho em PDF nativo.
  Future<bool> exportarRelatorioHistoricoPDF({
    required BuildContext context,
    required ProvedorDeTreino provedor,
  }) async {
    try {
      final db = BancoDeDados.instance;
      final perfil = provedor.perfil;
      final historico = await db.obterHistoricoDeTreinos();
      final pesos = await db.obterPesosCorporais();
      final medidas = await db.obterMedidasCorporais();
      final pesoAtual = provedor.pesoCorporalAtualKg;
      final metaPeso = perfil?.metaPesoKg;
      final nomeAluno =
          perfil?.nome.isNotEmpty == true ? perfil!.nome : 'Atleta Offline Gym';
      final dataEmissao = _formatadorDataHora.format(DateTime.now());

      final metas = perfil != null
          ? CalculadoraNutricional.calcularMetas(
              pesoKg: pesoAtual ?? perfil.metaPesoKg ?? 70.0,
              alturaCm: perfil.alturaCm ?? 175.0,
              idade: perfil.idade ?? 25,
              sexo: perfil.sexo,
              objetivo: perfil.objetivoPrincipal,
              fatorAtividade: perfil.fatorAtividade,
            )
          : null;

      var volumeTotalGeral = 0.0;
      var totalSeries = 0;
      final prs = <String, double>{};
      final sessoesDetalhadas = <Map<String, dynamic>>[];

      for (final sessao in historico) {
        final series = await db.obterSeriesDoTreino(sessao.id);
        totalSeries += series.length;
        var volumeSessao = 0.0;
        for (final s in series) {
          final vol = s.cargaUtilizada * s.repeticoes;
          volumeSessao += vol;
          volumeTotalGeral += vol;
          if (s.cargaUtilizada > (prs[s.nomeExercicio] ?? 0.0)) {
            prs[s.nomeExercicio] = s.cargaUtilizada;
          }
        }
        sessoesDetalhadas.add(<String, dynamic>{
          'sessao': sessao,
          'series': series,
          'volume': volumeSessao,
        });
      }

      final pdf = pw.Document(
        title: 'Relatório de Desempenho — $nomeAluno',
        author: 'Offline Gym',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (pw.Context ctx) => _construirCabecalhoDocumento(
            titulo: 'RELATÓRIO DE EVOLUÇÃO & DESEMPENHO',
            subtitulo: 'Acompanhamento para Personal Trainer & Nutricionista',
            ctx: ctx,
          ),
          footer: (pw.Context ctx) => _construirRodapeDocumento(ctx),
          build: (pw.Context ctx) {
            return <pw.Widget>[
              pw.SizedBox(height: 12),
              _construirCardIdentificacaoAluno(
                nomeAluno: nomeAluno,
                perfil: perfil,
                pesoAtual: pesoAtual,
                metaPeso: metaPeso,
                dataEmissao: dataEmissao,
                metasNutricionais: metas,
              ),
              pw.SizedBox(height: 16),

              // Grade com 4 caixas métricas
              pw.Row(
                children: [
                  _construirCaixaMetrica(
                    '${historico.length}',
                    'Sessões Concluídas',
                  ),
                  pw.SizedBox(width: 8),
                  _construirCaixaMetrica(
                    '$totalSeries',
                    'Séries Executadas',
                  ),
                  pw.SizedBox(width: 8),
                  _construirCaixaMetrica(
                    '${(volumeTotalGeral / 1000).toStringAsFixed(1)} t',
                    'Tonelagem Total',
                  ),
                  pw.SizedBox(width: 8),
                  _construirCaixaMetrica(
                    '${provedor.ofensivaAtual} dias',
                    'Ofensiva Ativa',
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // Tabela de Recordes Pessoais (PRs)
              pw.Text(
                '🏆 RECORDES PESSOAIS DE CARGA (PRs)',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _corSecundaria,
                ),
              ),
              pw.SizedBox(height: 6),
              _construirTabelaPRs(prs),
              pw.SizedBox(height: 18),

              // Sessões Recentes
              pw.Text(
                '📅 HISTÓRICO DE SESSÕES EXECUTADAS',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _corSecundaria,
                ),
              ),
              pw.SizedBox(height: 6),
              _construirTabelaSessoes(sessoesDetalhadas),
              pw.SizedBox(height: 18),

              // Medidas corporais com fita métrica (se houver)
              if (medidas.isNotEmpty) ...[
                pw.Text(
                  '📏 EVOLUÇÃO DE MEDIDAS CORPORAIS (FITA MÉTRICA)',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _corSecundaria,
                  ),
                ),
                pw.SizedBox(height: 6),
                _construirTabelaMedidas(medidas),
                pw.SizedBox(height: 18),
              ],

              // Pesagem corporal (se houver)
              if (pesos.isNotEmpty) ...[
                pw.Text(
                  '⚖️ HISTÓRICO DE PESAGEM CORPORAL',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _corSecundaria,
                  ),
                ),
                pw.SizedBox(height: 6),
                _construirTabelaPesos(pesos),
                pw.SizedBox(height: 18),
              ],

              // Área para parecer do Personal Trainer
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _corFundoCinza,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _corBorda),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PARECER TÉCNICO DO PERSONAL TRAINER / NUTRICIONISTA:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _corSecundaria,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: _corBorda, thickness: 0.8),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: _corBorda, thickness: 0.8),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: _corBorda, thickness: 0.8),
                  ],
                ),
              ),

              pw.SizedBox(height: 36),
              _construirAreaAssinaturas(nomeAluno),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final nomeSanitizado = _sanitizarNomeArquivo(
        nomeAluno.toLowerCase().replaceAll(' ', '_'),
      );
      final arquivo = File(
        '${tempDir.path}/relatorio_evolucao_${nomeSanitizado}_$timestamp.pdf',
      );
      await arquivo.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(arquivo.path)],
          subject: 'Relatório de Evolução e Desempenho (PDF) — $nomeAluno',
          text:
              'Segue anexo o relatório executivo de treinos e cargas do aluno $nomeAluno.',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar Relatório em PDF: $e');
      return false;
    }
  }

  // --- COMPONENTES VISUAIS AUXILIARES DO PDF ---

  static pw.Widget _construirCabecalhoDocumento({
    required String titulo,
    required String subtitulo,
    required pw.Context ctx,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _corPrimaria, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 15,
                  color: _corTextoEscuro,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitulo,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _corTextoMudo,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _corPrimaria,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'OFFLINE GYM',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _construirRodapeDocumento(pw.Context ctx) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _corBorda, width: 0.8),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Offline Gym — Treino, Cargas & Fisiologia 100% Offline',
            style: pw.TextStyle(fontSize: 8, color: _corTextoMudo),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _corTextoMudo),
          ),
        ],
      ),
    );
  }

  static pw.Widget _construirCardIdentificacaoAluno({
    required String nomeAluno,
    required PerfilDoUsuario? perfil,
    required double? pesoAtual,
    required double? metaPeso,
    required String dataEmissao,
    MetasNutricionais? metasNutricionais,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _corFundoCinza,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _corBorda),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ALUNO: $nomeAluno',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: _corTextoEscuro,
                ),
              ),
              pw.Text(
                'Emissão: $dataEmissao',
                style: pw.TextStyle(fontSize: 8, color: _corTextoMudo),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _corBorda, thickness: 0.6),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _itemInfo('Objetivo', perfil?.objetivoPrincipal ?? 'Hipertrofia'),
              _itemInfo('Nível', perfil?.nivelExperiencia ?? 'Iniciante'),
              _itemInfo(
                'Idade / Sexo',
                '${perfil?.idade != null ? "${perfil!.idade} anos" : "-"} / ${perfil?.sexo.isNotEmpty == true ? perfil!.sexo : "-"}',
              ),
              _itemInfo(
                'Altura',
                perfil?.alturaCm != null
                    ? '${perfil!.alturaCm!.toStringAsFixed(1)} cm'
                    : '-',
              ),
              _itemInfo(
                'Peso Atual',
                pesoAtual != null ? '${pesoAtual.toStringAsFixed(1)} kg' : '-',
              ),
              _itemInfo(
                'Meta Peso',
                metaPeso != null && metaPeso > 0
                    ? '${metaPeso.toStringAsFixed(1)} kg'
                    : '-',
              ),
            ],
          ),
          if (metasNutricionais != null) ...[
            pw.SizedBox(height: 6),
            pw.Divider(color: _corBorda, thickness: 0.6),
            pw.SizedBox(height: 6),
            pw.Text(
              'Metas Diárias Estimadas (Mifflin-St Jeor): '
              'TDEE: ${metasNutricionais.tdeeKcal.round()} kcal | '
              'Meta: ${metasNutricionais.caloriasAlvoKcal.round()} kcal | '
              'Proteína: ${metasNutricionais.proteinaGramas.round()}g | '
              'Carboidrato: ${metasNutricionais.carboidratoGramas.round()}g | '
              'Gordura: ${metasNutricionais.gorduraGramas.round()}g',
              style: pw.TextStyle(
                fontSize: 8,
                color: _corTextoEscuro,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _itemInfo(String label, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            color: _corTextoMudo,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 9,
            color: _corTextoEscuro,
          ),
        ),
      ],
    );
  }

  static pw.Widget _construirCaixaMetrica(String valor, String rotulo) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: _corFundoCinza,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _corBorda),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 14,
                color: _corPrimaria,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              rotulo,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8,
                color: _corTextoMudo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _construirTabelaRotina(RotinaDeTreino rotina) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            rotina.nome.isNotEmpty ? rotina.nome : 'Rotina de Treino',
            style: pw.TextStyle(
              fontSize: 10,
              color: _corTextoEscuro,
            ),
          ),
        ),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _corBorda, width: 0.5),
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: _corSecundaria),
          cellStyle: pw.TextStyle(fontSize: 8.5, color: _corTextoEscuro),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.5), // Exercício
            1: pw.FlexColumnWidth(1.2), // Séries
            2: pw.FlexColumnWidth(1.4), // Reps
            3: pw.FlexColumnWidth(1.5), // Carga Planejada
            4: pw.FlexColumnWidth(1.4), // Descanso
            5: pw.FlexColumnWidth(2.5), // Carga Anotada
          },
          headers: <String>[
            'Exercício',
            'Séries',
            'Reps',
            'Carga Base',
            'Descanso',
            'Carga Real / Check',
          ],
          data: rotina.exercicios.map((ex) {
            return <String>[
              ex.nome,
              '${ex.series}',
              '${ex.repeticoes}',
              ex.carga > 0 ? '${ex.carga.toStringAsFixed(1)} kg' : 'Livre',
              '${ex.tempoDescansoSegundos}s',
              '[   ] ______ kg',
            ];
          }).toList(),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _construirTabelaPRs(Map<String, double> prs) {
    final prsOrdenados = prs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (prsOrdenados.isEmpty) {
      return pw.Text(
        'Nenhum recorde registrado ainda.',
        style: pw.TextStyle(fontSize: 8.5, color: _corTextoMudo),
      );
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _corBorda, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 8.5,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _corSecundaria),
      cellStyle: pw.TextStyle(fontSize: 8.5, color: _corTextoEscuro),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      headers: <String>[
        'Exercício',
        'Maior Carga Registrada (kg)',
        'Classificação',
      ],
      data: prsOrdenados.take(12).map((pr) {
        return <String>[
          pr.key,
          '${pr.value.toStringAsFixed(1)} kg',
          '🏆 RECORDE PESSOAL',
        ];
      }).toList(),
    );
  }

  static pw.Widget _construirTabelaSessoes(
    List<Map<String, dynamic>> sessoesDetalhadas,
  ) {
    if (sessoesDetalhadas.isEmpty) {
      return pw.Text(
        'Nenhum treino no histórico.',
        style: pw.TextStyle(fontSize: 8.5, color: _corTextoMudo),
      );
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _corBorda, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 8.5,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _corSecundaria),
      cellStyle: pw.TextStyle(fontSize: 8.5, color: _corTextoEscuro),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      headers: <String>[
        'Data',
        'Rotina Realizada',
        'Duração',
        'Séries Feitas',
        'Volume Total (kg)',
      ],
      data: sessoesDetalhadas.take(10).map((item) {
        final sessao = item['sessao'] as TreinoDoHistorico;
        final series = item['series'] as List<SerieDoTreino>;
        final volume = item['volume'] as double;
        final dataSessao = DateTime.tryParse(sessao.dataISO) ?? DateTime.now();

        final minutos = sessao.tempoTotalSegundos ~/ 60;
        final duracaoStr =
            minutos > 0 ? '${minutos}min' : '${sessao.tempoTotalSegundos}s';

        return <String>[
          _formatadorDataHora.format(dataSessao),
          sessao.nomeTreino.isNotEmpty ? sessao.nomeTreino : 'Treino',
          duracaoStr,
          '${series.length} séries',
          '${volume.toStringAsFixed(1)} kg',
        ];
      }).toList(),
    );
  }

  static pw.Widget _construirTabelaMedidas(
    List<RegistroDeMedidasCorporais> medidas,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _corBorda, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _corSecundaria),
      cellStyle: pw.TextStyle(fontSize: 8, color: _corTextoEscuro),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headers: <String>[
        'Data',
        'Braço D/E',
        'Peitoral',
        'Cintura',
        'Abdômen',
        'Coxa D/E',
        'Panturrilha D/E',
      ],
      data: medidas.take(8).map((m) {
        final dataM = DateTime.tryParse(m.dataISO) ?? DateTime.now();
        final braco =
            '${m.bracoDireitoCm?.toStringAsFixed(1) ?? "-"}/${m.bracoEsquerdoCm?.toStringAsFixed(1) ?? "-"}';
        final coxa =
            '${m.coxaDireitaCm?.toStringAsFixed(1) ?? "-"}/${m.coxaEsquerdaCm?.toStringAsFixed(1) ?? "-"}';
        final panturrilha =
            '${m.panturrilhaDireitaCm?.toStringAsFixed(1) ?? "-"}/${m.panturrilhaEsquerdaCm?.toStringAsFixed(1) ?? "-"}';

        return <String>[
          DateFormat('dd/MM/yyyy').format(dataM),
          braco,
          m.peitoralCm != null ? '${m.peitoralCm!.toStringAsFixed(1)}cm' : '-',
          m.cinturaCm != null ? '${m.cinturaCm!.toStringAsFixed(1)}cm' : '-',
          m.abdomenCm != null ? '${m.abdomenCm!.toStringAsFixed(1)}cm' : '-',
          coxa,
          panturrilha,
        ];
      }).toList(),
    );
  }

  static pw.Widget _construirTabelaPesos(List<RegistroDePesoCorporal> pesos) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _corBorda, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 8.5,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _corSecundaria),
      cellStyle: pw.TextStyle(fontSize: 8.5, color: _corTextoEscuro),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      headers: <String>[
        'Data / Horário',
        'Peso Registrado (kg)',
      ],
      data: pesos.take(8).map((p) {
        final dataP = DateTime.tryParse(p.dataISO) ?? DateTime.now();
        return <String>[
          _formatadorDataHora.format(dataP),
          '${p.pesoKg.toStringAsFixed(1)} kg',
        ];
      }).toList(),
    );
  }

  static pw.Widget _construirAreaAssinaturas(String nomeAluno) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              pw.Container(
                height: 1,
                color: _corTextoMudo,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Assinatura do Aluno ($nomeAluno)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8, color: _corTextoMudo),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              pw.Container(
                height: 1,
                color: _corTextoMudo,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Assinatura do Personal Trainer / CREF',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8, color: _corTextoMudo),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
