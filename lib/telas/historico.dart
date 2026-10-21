import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../componentes/botao_de_perfil.dart';
import '../componentes/card_coach_fisiologico.dart';
import '../componentes/card_compartilhamento_treino.dart';
import '../componentes/faixa_semana_ofensiva.dart';
import '../componentes/radar_simetria_muscular.dart';
import '../dominio/coach_cientifico.dart';
import '../dominio/volume_muscular.dart';
import 'diario_treino.dart';
import 'galeria.dart';
import 'historico_treinos_completo.dart';
import 'insights.dart';
import 'pesos_corporais_completo.dart';
import '../servicos/exportacao_relatorio.dart';

class TelaDeHistorico extends StatefulWidget {
  const TelaDeHistorico({super.key});

  @override
  State<TelaDeHistorico> createState() => _EstadoDaTelaDeHistorico();
}

class _EstadoDaTelaDeHistorico extends State<TelaDeHistorico> {
  DateTime? _selectedDay;
  bool _showBodyWeightChart = false;
  String? _chaveDiarioCache;
  Future<Map<String, Object?>?>? _diarioFutureCache;

  Future<Map<String, Object?>?> _obterDiarioCacheado(
    ProvedorDeTreino provedor,
    DateTime data,
  ) {
    final chave =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    if (_chaveDiarioCache != chave || _diarioFutureCache == null) {
      _chaveDiarioCache = chave;
      _diarioFutureCache = provedor.obterDiarioNaData(data);
    }
    return _diarioFutureCache!;
  }

  void _invalidarCacheDiario() {
    _chaveDiarioCache = null;
    _diarioFutureCache = null;
  }

  void _abrirModalExportacaoRelatorio(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relatório para Personal Trainer',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Compartilhe seu progresso de cargas e treinos.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.redAccent),
                  title: const Text('Relatório Completo em PDF / Impressão',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Com PRs, histórico de séries e parecer do treinador.'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ServicoDeExportacaoDeRelatorio.instance
                        .exportarRelatorioPDF(context, provedor);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined,
                      color: Colors.green),
                  title: const Text('Planilha de Cargas (CSV / Excel)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Ideal para abrir no Microsoft Excel ou Google Planilhas.'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ServicoDeExportacaoDeRelatorio.instance
                        .exportarRelatorioCSV(context, provedor);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirCalendario(ProvedorDeTreino provedor) async {
    final data = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute<DateTime>(
        builder: (_) => TelaDeCalendarioDoHistorico(
          dataInicial: _selectedDay ?? DateTime.now(),
        ),
      ),
    );
    if (data != null && mounted) {
      setState(() {
        _selectedDay = data;
        _invalidarCacheDiario();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final hasPlannedExercises =
            provedor.nomesDosExerciciosPlanejados.isNotEmpty;
        final hasCompletedWorkouts = provedor.historico.isNotEmpty;
        final selectedDate = _selectedDay ?? DateTime.now();
        final temaEscuro = Theme.of(context).brightness == Brightness.dark;
        final now = DateTime.now();
        final isToday = _selectedDay == null ||
            (_selectedDay!.year == now.year &&
                _selectedDay!.month == now.month &&
                _selectedDay!.day == now.day);
        final hasTrainingSelected = provedor.treinoConcluidoNaData(
          selectedDate,
        );
        final visibleHistory =
            provedor.historico.take(1).toList(growable: false);
        final visibleBodyWeights =
            provedor.pesosCorporais.take(1).toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Histórico de evolução'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Insights, PRs e Deload',
                icon: const Icon(Icons.insights_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TelaDeInsights(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Exportar relatório para Personal Trainer',
                icon: const Icon(Icons.share_outlined),
                onPressed: () =>
                    _abrirModalExportacaoRelatorio(context, provedor),
              ),
              const BotaoDePerfil(),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              FaixaSemanaDeOfensiva(provedor: provedor),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: _CartaoHeatmapConsistencia(
                  provedor: provedor,
                  aoSelecionarDia: (dia) {
                    setState(() {
                      _selectedDay = dia;
                      _invalidarCacheDiario();
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              _CartaoVolumeSemanalPorMusculo(provedor: provedor),
              const SizedBox(height: 10),
              if (!hasPlannedExercises || !hasCompletedWorkouts) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.insights_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhum histórico de evolução disponível. Conclua seu primeiro treino!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (!isToday) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visualizando data do calendário',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => setState(() => _selectedDay = null),
                        icon: const Icon(Icons.today, size: 16),
                        label: const Text('Voltar para hoje'),
                      ),
                    ],
                  ),
                ),
              ],
              Material(
                color: hasTrainingSelected
                    ? (temaEscuro
                        ? const Color(0xFF183629)
                        : const Color(0xFFEAF8F0))
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: hasTrainingSelected
                        ? (temaEscuro
                            ? const Color(0xFF285B40)
                            : const Color(0xFFBDE8CD))
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _abrirCalendario(provedor),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          hasTrainingSelected
                              ? Icons.check_circle
                              : Icons.event_available,
                          color: hasTrainingSelected
                              ? (temaEscuro
                                  ? const Color(0xFF6FD39A)
                                  : const Color(0xFF238754))
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasTrainingSelected
                                ? 'Treino concluído em ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                                : 'Nenhum treino concluído em ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Toque para abrir o calendário',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: temaEscuro ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Datas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _construirCartaoDoDiarioDoDia(context, provedor, selectedDate),
              if (isToday) ...<Widget>[
                const SizedBox(height: 24),
                const _TituloDaSecaoDoHistorico(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Evolução',
                ),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TelaDaGaleria(),
                      ),
                    ),
                    leading: Icon(
                      Icons.photo_camera_back_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Foto mensal'),
                    subtitle: Text(
                      provedor.temFotoMensalDeEvolucao(DateTime.now())
                          ? 'Fotos deste mês registradas'
                          : provedor.desafioFotoMensalAtivo(DateTime.now())
                              ? 'Registrar ou pular o desafio deste mês'
                              : 'Desafio pulado; você pode registrar a foto quando quiser',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Exercício'),
                      selected: !_showBodyWeightChart,
                      onSelected: (_) =>
                          setState(() => _showBodyWeightChart = false),
                    ),
                    ChoiceChip(
                      label: const Text('Peso corporal'),
                      selected: _showBodyWeightChart,
                      onSelected: (_) =>
                          setState(() => _showBodyWeightChart = true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _showBodyWeightChart
                        ? _construirGraficoDePesoCorporal(context, provedor)
                        : _construirGraficoDoExercicio(
                            context,
                            provedor,
                            hasPlannedExercises,
                            hasCompletedWorkouts,
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                _TituloDaSecaoDoHistorico(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Peso corporal',
                  action: IconButton.filledTonal(
                    tooltip: 'Registrar peso corporal',
                    onPressed: () => _registrarPesoCorporal(context, provedor),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                if (provedor.perfil?.metaPesoKg != null)
                  _CartaoMetaDePeso(
                    metaPesoKg: provedor.perfil!.metaPesoKg!,
                    pesoAtualKg: provedor.pesoCorporalAtualKg,
                  ),
                if (provedor.pesosCorporais.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum peso corporal registrado ainda.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else ...<Widget>[
                  ...visibleBodyWeights.map((record) {
                    final data =
                        DateTime.tryParse(record.dataISO) ?? DateTime.now();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.monitor_weight_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            '${record.pesoKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            toBeginningOfSentenceCase(
                                  DateFormat("MMMM 'de' yyyy", 'pt_BR')
                                      .format(data),
                                ) ??
                                DateFormat("MMMM 'de' yyyy", 'pt_BR')
                                    .format(data),
                          ),
                          trailing: IconButton(
                            tooltip: 'Excluir registro de peso',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFD63031),
                            ),
                            onPressed: () => _excluirPesoCorporal(
                              context,
                              provedor,
                              record.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (provedor.pesosCorporais.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TelaDePesosCorporais(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          'Ver todos (${provedor.pesosCorporais.length})',
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 22),
                _TituloDaSecaoDoHistorico(
                  icon: Icons.straighten_rounded,
                  title: 'Medidas corporais (Fita métrica)',
                  action: IconButton.filledTonal(
                    tooltip: 'Registrar medidas corporais',
                    onPressed: () =>
                        _registrarMedidasCorporais(context, provedor),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                _SecaoDeMedidasCorporais(
                  provedor: provedor,
                  aoAdicionar: () =>
                      _registrarMedidasCorporais(context, provedor),
                  aoEditar: (m) =>
                      _registrarMedidasCorporais(context, provedor, m),
                  aoExcluir: (id) =>
                      _excluirMedidasCorporais(context, provedor, id),
                ),
                if (provedor.habitos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _TituloDaSecaoDoHistorico(
                    icon: Icons.stars_rounded,
                    title: 'Consistência de hábitos',
                  ),
                  const SizedBox(height: 10),
                  _CartaoConsistenciaHabitos(provedor: provedor),
                ],
                const SizedBox(height: 18),
                const _TituloDaSecaoDoHistorico(
                  icon: Icons.fitness_center_outlined,
                  title: 'Último treino',
                ),
                const SizedBox(height: 10),
                if (provedor.historico.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum treino concluído foi registrado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else ...<Widget>[
                  ...visibleHistory.map((treino) {
                    final data =
                        DateTime.tryParse(treino.dataISO) ?? DateTime.now();
                    final duracao = Duration(
                      seconds: treino.tempoTotalSegundos,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          isThreeLine: true,
                          onTap: () => _mostrarDetalhesDoTreino(
                            context,
                            provedor,
                            treino,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            treino.nomeTreino.isEmpty
                                ? 'Treino'
                                : treino.nomeTreino,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(height: 3),
                              Text(
                                '${toBeginningOfSentenceCase(DateFormat('EEEE', 'pt_BR').format(data))} · ${DateFormat('dd/MM/yyyy').format(data)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Horário: ${DateFormat('HH:mm').format(data)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 115,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _textoDaDuracao(duracao),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Excluir treino do histórico',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFD63031),
                                  ),
                                  onPressed: () => _excluirTreino(
                                    context,
                                    provedor,
                                    treino.id,
                                    data,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (provedor.historico.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const TelaDeHistoricoCompletoDeTreinos(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Ver todos (${provedor.historico.length})'),
                      ),
                    ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _construirGraficoDoExercicio(
    BuildContext context,
    ProvedorDeTreino provedor,
    bool hasPlannedExercises,
    bool hasCompletedWorkouts,
  ) {
    if (!hasPlannedExercises || !hasCompletedWorkouts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          'Nenhum histórico de evolução disponível. Conclua seu primeiro treino!',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: provedor.exercicioSelecionadoNaEvolucao,
          decoration: const InputDecoration(
            labelText: 'Exercício do seu plano',
            prefixIcon: Icon(Icons.fitness_center),
          ),
          items: provedor.nomesDosExerciciosPlanejados
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) provedor.selecionarExercicioDaEvolucao(value);
          },
        ),
        const SizedBox(height: 18),
        if (provedor.pontosDeEvolucao.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Text(
              'Ainda não há séries concluídas para este exercício. Marque séries durante um treino e finalize a sessão para registrar a evolução.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else ...<Widget>[
          Text(
            'Carga máxima por dia (kg)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: _GraficoDeEvolucao(points: provedor.pontosDeEvolucao),
          ),
        ],
      ],
    );
  }

  Widget _construirGraficoDePesoCorporal(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) {
    if (provedor.pontosDePesoCorporal.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          'Registre seu peso corporal para acompanhar sua evolução.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    final meta = provedor.perfil?.metaPesoKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Evolução do peso corporal (kg)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (meta != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Meta: ${meta.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _GraficoDeEvolucao(points: provedor.pontosDePesoCorporal),
        ),
      ],
    );
  }

  Future<void> _registrarPesoCorporal(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    final input = await showDialog<_EntradaDePesoCorporal>(
      context: context,
      builder: (_) => const _DialogoDePesoCorporal(),
    );
    if (input == null || !context.mounted) return;
    try {
      await provedor.salvarPesoCorporal(
        data: input.data,
        weightKg: input.weightKg,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso corporal registrado.')),
      );
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar o peso: $erro')),
      );
    }
  }

  Future<void> _excluirPesoCorporal(
    BuildContext context,
    ProvedorDeTreino provedor,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro de peso?'),
        content: const Text('Este registro será removido permanentemente.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await provedor.excluirPesoCorporal(id);
  }

  Future<void> _registrarMedidasCorporais(
    BuildContext context,
    ProvedorDeTreino provedor, [
    RegistroDeMedidasCorporais? medidaExistente,
  ]) async {
    final resultado = await showDialog<RegistroDeMedidasCorporais>(
      context: context,
      builder: (_) =>
          _DialogoDeMedidasCorporais(medidaExistente: medidaExistente),
    );
    if (resultado == null || !context.mounted) return;
    try {
      await provedor.salvarMedidasCorporais(resultado);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medidas corporais salvas com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar as medidas: $erro')),
      );
    }
  }

  Future<void> _excluirMedidasCorporais(
    BuildContext context,
    ProvedorDeTreino provedor,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir medidas corporais?'),
        content: const Text(
          'Este registro de medidas será removido permanentemente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await provedor.excluirMedidasCorporais(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro de medidas removido.')),
    );
  }

  Future<void> _excluirTreino(
    BuildContext context,
    ProvedorDeTreino provedor,
    int id,
    DateTime data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir treino do histórico?'),
        content: Text(
          'O treino de ${DateFormat('dd/MM/yyyy HH:mm').format(data)} e suas séries serão removidos.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provedor.excluirSessaoDeTreino(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino removido do histórico.')),
      );
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o treino: $erro')),
      );
    }
  }

  void _mostrarDetalhesDoTreino(
    BuildContext context,
    ProvedorDeTreino provedor,
    TreinoDoHistorico treino,
  ) {
    final data = DateTime.tryParse(treino.dataISO) ?? DateTime.now();
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final seriesFuture = provedor.obterSeriesDoTreino(treino.id);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FutureBuilder<List<SerieDoTreino>>(
        future: seriesFuture,
        builder: (context, estadoSalvo) {
          final sets = estadoSalvo.data ?? <SerieDoTreino>[];
          final setsByExercise = <String, List<SerieDoTreino>>{};
          for (final s in sets) {
            setsByExercise.putIfAbsent(s.nomeExercicio, () => []).add(s);
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: temaEscuro
                          ? const Color(0xFF444451)
                          : const Color(0xFFDFE2E7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        treino.nomeTreino.isEmpty
                            ? ExercicioPlanejado.nomeDoDiaDaSemana(
                                treino.diaSemana,
                              )
                            : treino.nomeTreino,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _textoDaDuracao(
                        Duration(seconds: treino.tempoTotalSegundos),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 20),
                      tooltip: 'Compartilhar Story / WhatsApp',
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        final tonelagem = sets.fold<double>(
                          0.0,
                          (acc, s) => acc + (s.cargaUtilizada * s.repeticoes),
                        );
                        ModalCompartilharTreino.exibir(
                          context,
                          nomeTreino: treino.nomeTreino.isEmpty
                              ? ExercicioPlanejado.nomeDoDiaDaSemana(
                                  treino.diaSemana,
                                )
                              : treino.nomeTreino,
                          duracaoSegundos: treino.tempoTotalSegundos,
                          tonelagemKg: tonelagem,
                          totalSeries: sets.length,
                          ofensivaDias: provedor.ofensivaAtual,
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(data),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                if (estadoSalvo.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (sets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma série detalhada encontrada.'),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: setsByExercise.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: entry.value.map((s) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${s.serieNumero}ª · ${s.repeticoes} reps · ${_formatLoad(s.cargaUtilizada)} kg',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirCartaoDoDiarioDoDia(
    BuildContext context,
    ProvedorDeTreino provedor,
    DateTime data,
  ) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(data);

    return FutureBuilder<Map<String, Object?>?>(
      future: _obterDiarioCacheado(provedor, data),
      builder: (context, estadoSalvo) {
        final entry = estadoSalvo.data;
        var content = (entry?['conteudo'] as String?)?.trim() ?? '';
        var hasStructuredFormatting = false;
        try {
          final formatted = jsonDecode(content);
          if (formatted is Map && formatted['type'] == 'offline_gym_diary_v1') {
            hasStructuredFormatting = true;
            content = (formatted['text']?.toString() ?? '').trim();
          }
        } catch (_) {}
        if (!hasStructuredFormatting) {
          content = content
              .replaceAllMapped(
                RegExp(r'(^|\n)\s*#+\s*'),
                (match) => match.group(1) ?? '',
              )
              .replaceAll('**', '');
        }
        final rawImgs = entry?['caminhosImagens'];
        List<String> imagens = <String>[];
        if (rawImgs is String && rawImgs.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawImgs);
            if (decoded is List) {
              imagens = decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }

        final hasContent = content.isNotEmpty || imagens.isNotEmpty;
        if (estadoSalvo.connectionState == ConnectionState.waiting &&
            !estadoSalvo.hasData) {
          return const SizedBox.shrink();
        }

        if (!hasContent) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await _abrirDiarioNaData(context, data);
                if (mounted) {
                  setState(_invalidarCacheDiario);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diário · $dateFormatted',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Toque para adicionar anotações sobre este dia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await _abrirDiarioNaData(context, data);
              if (mounted) {
                setState(_invalidarCacheDiario);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diário · $dateFormatted',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Anotações salvas · toque para ver',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirDiarioNaData(BuildContext context, DateTime data) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TelaDeDiario(data: data)));
  }

  static String _formatLoad(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _EntradaDePesoCorporal {
  const _EntradaDePesoCorporal({required this.data, required this.weightKg});

  final DateTime data;
  final double weightKg;
}

class _DialogoDePesoCorporal extends StatefulWidget {
  const _DialogoDePesoCorporal();

  @override
  State<_DialogoDePesoCorporal> createState() =>
      _EstadoDoDialogoDePesoCorporal();
}

class _EstadoDoDialogoDePesoCorporal extends State<_DialogoDePesoCorporal> {
  final TextEditingController _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      locale: const Locale('pt', 'BR'),
    );
    if (selected != null && mounted) setState(() => _selectedDate = selected);
  }

  void _salvar() {
    final parsed = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed > 500) {
      setState(() => _error = 'Informe um peso válido em kg.');
      return;
    }
    Navigator.of(context).pop(
      _EntradaDePesoCorporal(
        data: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        weightKg: parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar meu peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _escolherData,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso corporal (kg)',
              hintText: 'Ex.: 68,5',
              suffixText: 'kg',
            ),
            onSubmitted: (_) => _salvar(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD63031), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

class _DiaDoCalendarioHistorico extends StatelessWidget {
  const _DiaDoCalendarioHistorico({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasWorkout,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool hasWorkout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temaEscuro = theme.brightness == Brightness.dark;
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final weekendColor = theme.colorScheme.primary;
    final weekdayColor =
        temaEscuro ? const Color(0xFFE8E6F0) : const Color(0xFF2D3436);

    final Color? backgroundColor = isSelected
        ? theme.colorScheme.primary
        : (isWeekend
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null);
    final textColor = isSelected && isWeekend
        ? Colors.white
        : (isWeekend ? weekendColor : weekdayColor);

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(
                  color: isWeekend
                      ? weekendColor
                      : theme.colorScheme.outlineVariant,
                  width: 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isWeekend ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            if (hasWorkout)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Calendário mensal separado da tela principal para manter o histórico compacto.
class TelaDeCalendarioDoHistorico extends StatefulWidget {
  const TelaDeCalendarioDoHistorico({super.key, required this.dataInicial});

  final DateTime dataInicial;

  @override
  State<TelaDeCalendarioDoHistorico> createState() =>
      _EstadoDaTelaDeCalendarioDoHistorico();
}

class _EstadoDaTelaDeCalendarioDoHistorico
    extends State<TelaDeCalendarioDoHistorico> {
  late DateTime _diaEmFoco = widget.dataInicial;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) => Scaffold(
        appBar: AppBar(title: const Text('Calendário de treinos')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar<String>(
                  locale: 'pt_BR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2100, 12, 31),
                  focusedDay: _diaEmFoco,
                  selectedDayPredicate: (dia) =>
                      DateUtils.isSameDay(dia, widget.dataInicial),
                  eventLoader: (dia) => provedor.treinoConcluidoNaData(dia)
                      ? const <String>['Treino concluído']
                      : const <String>[],
                  onDaySelected: (selecionado, focado) {
                    Navigator.of(context).pop(selecionado);
                  },
                  onPageChanged: (focado) => _diaEmFoco = focado,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                  calendarBuilders: CalendarBuilders<String>(
                    defaultBuilder: (context, dia, focado) =>
                        _DiaDoCalendarioHistorico(
                      day: dia,
                      isSelected: false,
                      isToday: false,
                      hasWorkout: provedor.treinoConcluidoNaData(dia),
                    ),
                    selectedBuilder: (context, dia, focado) =>
                        _DiaDoCalendarioHistorico(
                      day: dia,
                      isSelected: true,
                      isToday: DateUtils.isSameDay(dia, DateTime.now()),
                      hasWorkout: provedor.treinoConcluidoNaData(dia),
                    ),
                    todayBuilder: (context, dia, focado) =>
                        _DiaDoCalendarioHistorico(
                      day: dia,
                      isSelected: false,
                      isToday: true,
                      hasWorkout: provedor.treinoConcluidoNaData(dia),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: Color(0xFF2ECC71),
                ),
                title: Text('Dia com treino concluído'),
                subtitle: Text(
                  'Toque em uma data para ver o registro e o diário daquele dia.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficoDeEvolucao extends StatelessWidget {
  const _GraficoDeEvolucao({required this.points});

  final List<PontoDeEvolucao> points;
  static const String unidade = 'kg';

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final axisColor = theme.colorScheme.onSurfaceVariant;
    final gridColor = theme.colorScheme.outlineVariant;
    final spots = <FlSpot>[
      for (var indice = 0; indice < points.length; indice++)
        FlSpot(indice.toDouble(), points[indice].cargaKg),
    ];
    final loads = points.map((point) => point.cargaKg).toList(growable: false);
    final minLoad = loads.reduce((a, b) => math.min(a, b).toDouble());
    final maxLoad = loads.reduce((a, b) => math.max(a, b).toDouble());
    final minY =
        math.max(0.0, minLoad - (minLoad > 0 ? minLoad * 0.12 : 0)).toDouble();
    final maxY = (maxLoad + (maxLoad > 0 ? maxLoad * 0.12 : 5)).toDouble();
    final maxX = points.length <= 1 ? 0.5 : (points.length - 1).toDouble();
    final interval =
        points.length > 6 ? (points.length / 5).ceilToDouble() : 1.0;

    return RepaintBoundary(
      child: LineChart(
        LineChartData(
        minX: points.length == 1 ? -0.5 : 0.0,
        maxX: maxX,
        minY: minY,
        maxY: maxY <= minY ? minY + 5 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              unidade,
              style: TextStyle(fontSize: 11, color: axisColor),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 10, color: axisColor),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final indice = value.round();
                if ((value - indice).abs() > 0.15 ||
                    indice < 0 ||
                    indice >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(points[indice].data),
                    style: TextStyle(fontSize: 10, color: axisColor),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final indice = spot.x.round().clamp(0, points.length - 1).toInt();
              final point = points[indice];
              return LineTooltipItem(
                '${point.cargaKg.toStringAsFixed(unidade == 'kg' ? 1 : 0)} $unidade\n${DateFormat('dd/MM/yyyy').format(point.data)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(growable: false),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _TituloDaSecaoDoHistorico extends StatelessWidget {
  const _TituloDaSecaoDoHistorico({
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

String _textoDaDuracao(Duration duracao) {
  final hours = duracao.inHours;
  final minutes = duracao.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = duracao.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m ${segundos}s';
}

class _CartaoMetaDePeso extends StatelessWidget {
  const _CartaoMetaDePeso({
    required this.metaPesoKg,
    required this.pesoAtualKg,
  });

  final double metaPesoKg;
  final double? pesoAtualKg;

  @override
  Widget build(BuildContext context) {
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final diferenca = pesoAtualKg == null ? null : (pesoAtualKg! - metaPesoKg);
    final atingida = diferenca != null && diferenca.abs() <= 0.2;

    String mensagem;
    if (pesoAtualKg == null) {
      mensagem =
          'Registre seu peso atual para acompanhar o progresso até a meta.';
    } else if (atingida) {
      mensagem = '🎉 Meta atingida! Você está exatamente no seu peso objetivo!';
    } else if (diferenca! > 0) {
      mensagem =
          'Faltam ${diferenca.toStringAsFixed(1)} kg para sua meta de redução de peso.';
    } else {
      mensagem =
          'Faltam ${(-diferenca).toStringAsFixed(1)} kg para sua meta de ganho de peso.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: atingida
              ? const Color(0xFF00E676)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: atingida
                  ? const Color(0xFF00E676).withValues(alpha: 0.18)
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              atingida ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: atingida
                  ? const Color(0xFF00E676)
                  : Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meta: ${metaPesoKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (pesoAtualKg != null)
                      Text(
                        'Atual: ${pesoAtualKg!.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  mensagem,
                  style: TextStyle(
                    fontSize: 12,
                    color: atingida
                        ? (temaEscuro
                            ? const Color(0xFF8BE0A6)
                            : const Color(0xFF238754))
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoConsistenciaHabitos extends StatelessWidget {
  const _CartaoConsistenciaHabitos({required this.provedor});

  final ProvedorDeTreino provedor;

  @override
  Widget build(BuildContext context) {
    final habitos = provedor.habitos;
    final total = habitos.length;
    final concluidosHoje = provedor.habitosConcluidosHoje;
    final totalHoje = provedor.totalHabitosDeHoje;
    final taxa = provedor.taxaConclusaoHabitosHoje;
    final maiorOfensiva = habitos.isEmpty
        ? 0
        : habitos.map((h) => h.ofensivaAtual).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total ${total == 1 ? 'hábito ativo' : 'hábitos ativos'} cadastrados',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hoje: $concluidosHoje de $totalHoje concluídos (${(taxa * 100).toInt()}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (maiorOfensiva > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF6D00),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${maiorOfensiva}d',
                          style: const TextStyle(
                            color: Color(0xFFFF6D00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: taxa,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (habitos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: habitos.take(4).map((h) {
                  final cor = Color(h.corValor);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(h.icone, color: cor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          h.titulo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cor,
                          ),
                        ),
                        if (h.ofensivaAtual > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '🔥${h.ofensivaAtual}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoHeatmapConsistencia extends StatelessWidget {
  const _CartaoHeatmapConsistencia({
    required this.provedor,
    required this.aoSelecionarDia,
  });

  final ProvedorDeTreino provedor;
  final ValueChanged<DateTime> aoSelecionarDia;

  static String _chaveISO(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final mapasHabitos = provedor.contagemHabitosPorData;
    final datasProtegidas = provedor.datasProtegidasPorEscudo;

    // Monta grade de 12 semanas (84 dias) alinhada de segunda (1) a domingo (7)
    const int totalSemanas = 12;
    final inicioSemanaAtual = hoje.subtract(Duration(days: hoje.weekday - 1));
    final primeiroDiaGrade = inicioSemanaAtual.subtract(
      const Duration(days: (totalSemanas - 1) * 7),
    );

    int diasAtivosNoPeriodo = 0;
    for (int i = 0; i < totalSemanas * 7; i++) {
      final data = primeiroDiaGrade.add(Duration(days: i));
      if (data.isAfter(hoje)) continue;
      final treinou = provedor.treinoConcluidoNaData(data);
      final habitosConcluidos = mapasHabitos[_chaveISO(data)] ?? 0;
      if (treinou || habitosConcluidos > 0) {
        diasAtivosNoPeriodo++;
      }
    }

    Color corDoNivel(int nivel, bool protegido) {
      if (protegido && nivel == 0) {
        return const Color(0xFF00B8D4).withValues(alpha: 0.45);
      }
      switch (nivel) {
        case 0:
          return temaEscuro
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : const Color(0xFFECE8F8);
        case 1:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.38);
        case 2:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.72);
        default:
          return Theme.of(context).colorScheme.primary;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.grid_view_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mapa de Consistência (Últimas 12 semanas)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$diasAtivosNoPeriodo dias ativos',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(totalSemanas, (semanaIdx) {
                return Column(
                  children: List<Widget>.generate(7, (diaIdx) {
                    final data = primeiroDiaGrade.add(
                      Duration(days: semanaIdx * 7 + diaIdx),
                    );
                    final futuro = data.isAfter(hoje);
                    final treinou =
                        !futuro && provedor.treinoConcluidoNaData(data);
                    final qtdHabitos =
                        futuro ? 0 : (mapasHabitos[_chaveISO(data)] ?? 0);
                    final protegido = !futuro && datasProtegidas.contains(data);

                    int nivel = 0;
                    if (treinou && qtdHabitos > 0) {
                      nivel = 3;
                    } else if (treinou) {
                      nivel = 2;
                    } else if (qtdHabitos > 0) {
                      nivel = 1;
                    }

                    final ehHoje = data.year == hoje.year &&
                        data.month == hoje.month &&
                        data.day == hoje.day;

                    return GestureDetector(
                      onTap: futuro ? null : () => aoSelecionarDia(data),
                      child: Tooltip(
                        message:
                            '${DateFormat('dd/MM').format(data)}: ${treinou ? 'Treino concluído' : 'Sem treino'}${qtdHabitos > 0 ? ' • $qtdHabitos hábito(s)' : ''}${protegido ? ' • Escudo 🛡️' : ''}',
                        child: Container(
                          width: 18,
                          height: 12,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: futuro
                                ? Colors.transparent
                                : corDoNivel(nivel, protegido),
                            borderRadius: BorderRadius.circular(3.5),
                            border: ehHoje
                                ? Border.all(color: cs.primary, width: 1.5)
                                : (futuro
                                    ? Border.all(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.25,
                                        ),
                                      )
                                    : null),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Toque em um bloco para ver o dia',
                  style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Menos',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    for (final n in <int>[0, 1, 2, 3])
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: corDoNivel(n, false),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Mais',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoVolumeSemanalPorMusculo extends StatelessWidget {
  const _CartaoVolumeSemanalPorMusculo({required this.provedor});

  final ProvedorDeTreino provedor;

  void _confirmarEAplicarDeload(
      BuildContext context, ProvedorDeTreino provedor) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.healing_rounded, color: Color(0xFFE67E22)),
            SizedBox(width: 10),
            Text('Semana Regenerativa'),
          ],
        ),
        content: const Text(
          'Deseja aplicar uma Semana de Deload em todas as suas rotinas?\n\n'
          'O volume de séries dos exercícios será reduzido em 40% para descarregar o estresse '
          'articular e neuromuscular acumulado, ressensibilizando as fibras musculares para novos picos de força!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final qtd =
                  await provedor.aplicarSemanaDeload(reducaoVolume: 0.40);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Semana de Deload ativada! $qtd exercícios ajustados (-40% de volume).',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Ativar Deload (-40%)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<List<MarcoDeVolumeMuscular>>(
      future: provedor.obterVolumeSemanalPorMusculo(),
      builder: (context, snapshot) {
        final marcos = snapshot.data ?? const <MarcoDeVolumeMuscular>[];
        final totalSeriesSemana = marcos.fold<int>(
          0,
          (acc, m) => acc + m.seriesCompletadas,
        );

        final diagnostico = CoachCientificoOffline.analisarTreinamento(
          perfil: provedor.perfil,
          volumeSemanal: marcos,
          historico: provedor.historico,
          diasOfensiva: provedor.ofensivaAtual,
          pesoAtualKg: provedor.pesoCorporalAtualKg,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardCoachFisiologico(
              diagnostico: diagnostico,
              aoTocarDeload: () => _confirmarEAplicarDeload(context, provedor),
            ),
            const SizedBox(height: 12),
            RadarSimetriaMuscular(
              volumes: marcos,
              scoreSimetria: diagnostico.indiceEquilibrioPercentual,
            ),
            const SizedBox(height: 12),
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.bar_chart_rounded,
                                size: 20,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Volume Semanal por Músculo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Marcos hipertróficos (Últimos 7 dias)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalSeriesSemana séries',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (marcos.isEmpty || totalSeriesSemana == 0)
                      Text(
                        'Nenhum treino registrado nesta semana. Conclua treinos para ver seus marcos de volume!',
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      )
                    else ...[
                      ...marcos.map((m) {
                        final corStatus =
                            m.obterCor(Theme.of(context).colorScheme.primary);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    m.grupoMuscular,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${m.seriesCompletadas} séries',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: corStatus,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              corStatus.withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.status,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: corStatus,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Stack(
                                children: [
                                  Container(
                                    height: 7,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: m.progressoRelativo,
                                    child: Container(
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: corStatus,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SecaoDeMedidasCorporais extends StatelessWidget {
  const _SecaoDeMedidasCorporais({
    required this.provedor,
    required this.aoAdicionar,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final ProvedorDeTreino provedor;
  final VoidCallback aoAdicionar;
  final ValueChanged<RegistroDeMedidasCorporais> aoEditar;
  final ValueChanged<int> aoExcluir;

  void _abrirHistoricoCompletoDeMedidas(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            final lista = provedor.medidasCorporais;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Histórico de Medidas (${lista.length})',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar nova medição',
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          aoAdicionar();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final item = lista[index];
                        final data =
                            DateTime.tryParse(item.dataISO) ?? DateTime.now();
                        final anterior = (index + 1 < lista.length)
                            ? lista[index + 1]
                            : null;

                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd/MM/yyyy · HH:mm')
                                              .format(data),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20),
                                          tooltip: 'Editar medição',
                                          onPressed: () {
                                            Navigator.of(sheetContext).pop();
                                            aoEditar(item);
                                          },
                                        ),
                                        if (item.id != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Color(0xFFD63031),
                                            ),
                                            tooltip: 'Excluir medição',
                                            onPressed: () {
                                              Navigator.of(sheetContext).pop();
                                              aoExcluir(item.id!);
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildGridMedidas(item, anterior),
                                if (item.observacoes?.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Obs: ${item.observacoes!}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildGridMedidas(
    RegistroDeMedidasCorporais m, [
    RegistroDeMedidasCorporais? anterior,
  ]) {
    final itens = <Widget>[];

    void addMetric(String label, double? valor, double? valorAnterior) {
      if (valor == null || valor <= 0) return;
      double? diff;
      if (valorAnterior != null && valorAnterior > 0) {
        diff = valor - valorAnterior;
      }
      itens.add(_ItemMedidaChip(
        label: label,
        valorCm: valor,
        diferencaCm: diff,
      ));
    }

    addMetric('Braço D', m.bracoDireitoCm, anterior?.bracoDireitoCm);
    addMetric('Braço E', m.bracoEsquerdoCm, anterior?.bracoEsquerdoCm);
    addMetric('Peitoral', m.peitoralCm, anterior?.peitoralCm);
    addMetric('Cintura', m.cinturaCm, anterior?.cinturaCm);
    addMetric('Abdômen', m.abdomenCm, anterior?.abdomenCm);
    addMetric('Coxa D', m.coxaDireitaCm, anterior?.coxaDireitaCm);
    addMetric('Coxa E', m.coxaEsquerdaCm, anterior?.coxaEsquerdaCm);
    addMetric('Panturrilha D', m.panturrilhaDireitaCm,
        anterior?.panturrilhaDireitaCm);
    addMetric('Panturrilha E', m.panturrilhaEsquerdaCm,
        anterior?.panturrilhaEsquerdaCm);

    if (itens.isEmpty) {
      return const Text(
        'Nenhum dado numérico registrado.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: itens,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lista = provedor.medidasCorporais;

    if (lista.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhuma medida com fita métrica registrada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Acompanhe a evolução de braços, peito, cintura, coxas e panturrilhas em centímetros.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: aoAdicionar,
                icon: const Icon(Icons.straighten_rounded),
                label: const Text('Registrar primeira medição'),
              ),
            ],
          ),
        ),
      );
    }

    final ultimas = lista.first;
    final anterior = lista.length > 1 ? lista[1] : null;
    final data = DateTime.tryParse(ultimas.dataISO) ?? DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.straighten_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Últimas Medidas',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy · HH:mm').format(data),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Editar medição',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => aoEditar(ultimas),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildGridMedidas(ultimas, anterior),
            if (ultimas.observacoes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                'Obs: ${ultimas.observacoes!}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: aoAdicionar,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nova medição'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _abrirHistoricoCompletoDeMedidas(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text('Histórico (${lista.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMedidaChip extends StatelessWidget {
  const _ItemMedidaChip({
    required this.label,
    required this.valorCm,
    this.diferencaCm,
  });

  final String label;
  final double valorCm;
  final double? diferencaCm;

  @override
  Widget build(BuildContext context) {
    final diff = diferencaCm;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '${valorCm.toStringAsFixed(1)} cm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (diff != null && diff.abs() >= 0.05) ...[
            const SizedBox(width: 4),
            Text(
              diff > 0
                  ? '+${diff.toStringAsFixed(1)}'
                  : diff.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: diff > 0
                    ? const Color(0xFF00B894)
                    : const Color(0xFFE17055),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogoDeMedidasCorporais extends StatefulWidget {
  const _DialogoDeMedidasCorporais({this.medidaExistente});

  final RegistroDeMedidasCorporais? medidaExistente;

  @override
  State<_DialogoDeMedidasCorporais> createState() =>
      _EstadoDoDialogoDeMedidasCorporais();
}

class _EstadoDoDialogoDeMedidasCorporais
    extends State<_DialogoDeMedidasCorporais> {
  late DateTime _data;
  late final TextEditingController _bracoDir;
  late final TextEditingController _bracoEsq;
  late final TextEditingController _peitoral;
  late final TextEditingController _cintura;
  late final TextEditingController _abdomen;
  late final TextEditingController _coxaDir;
  late final TextEditingController _coxaEsq;
  late final TextEditingController _panturrilhaDir;
  late final TextEditingController _panturrilhaEsq;
  late final TextEditingController _obs;

  @override
  void initState() {
    super.initState();
    final m = widget.medidaExistente;
    _data = m != null
        ? (DateTime.tryParse(m.dataISO) ?? DateTime.now())
        : DateTime.now();

    String f(double? v) => v == null
        ? ''
        : (v == v.roundToDouble()
            ? v.toStringAsFixed(0)
            : v.toStringAsFixed(1));

    _bracoDir = TextEditingController(text: f(m?.bracoDireitoCm));
    _bracoEsq = TextEditingController(text: f(m?.bracoEsquerdoCm));
    _peitoral = TextEditingController(text: f(m?.peitoralCm));
    _cintura = TextEditingController(text: f(m?.cinturaCm));
    _abdomen = TextEditingController(text: f(m?.abdomenCm));
    _coxaDir = TextEditingController(text: f(m?.coxaDireitaCm));
    _coxaEsq = TextEditingController(text: f(m?.coxaEsquerdaCm));
    _panturrilhaDir = TextEditingController(text: f(m?.panturrilhaDireitaCm));
    _panturrilhaEsq = TextEditingController(text: f(m?.panturrilhaEsquerdaCm));
    _obs = TextEditingController(text: m?.observacoes ?? '');
  }

  @override
  void dispose() {
    _bracoDir.dispose();
    _bracoEsq.dispose();
    _peitoral.dispose();
    _cintura.dispose();
    _abdomen.dispose();
    _coxaDir.dispose();
    _coxaEsq.dispose();
    _panturrilhaDir.dispose();
    _panturrilhaEsq.dispose();
    _obs.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return (v != null && v > 0 && v <= 300) ? v : null;
  }

  void _salvar() {
    final bracoD = _parse(_bracoDir);
    final bracoE = _parse(_bracoEsq);
    final peitoral = _parse(_peitoral);
    final cintura = _parse(_cintura);
    final abdomen = _parse(_abdomen);
    final coxaD = _parse(_coxaDir);
    final coxaE = _parse(_coxaEsq);
    final panturrilhaD = _parse(_panturrilhaDir);
    final panturrilhaE = _parse(_panturrilhaEsq);
    final obs = _obs.text.trim().isEmpty ? null : _obs.text.trim();

    if (bracoD == null &&
        bracoE == null &&
        peitoral == null &&
        cintura == null &&
        abdomen == null &&
        coxaD == null &&
        coxaE == null &&
        panturrilhaD == null &&
        panturrilhaE == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha ao menos uma medida corporal em cm.'),
        ),
      );
      return;
    }

    final novo = RegistroDeMedidasCorporais(
      id: widget.medidaExistente?.id,
      dataISO: _data.toIso8601String(),
      bracoDireitoCm: bracoD,
      bracoEsquerdoCm: bracoE,
      peitoralCm: peitoral,
      cinturaCm: cintura,
      abdomenCm: abdomen,
      coxaDireitaCm: coxaD,
      coxaEsquerdaCm: coxaE,
      panturrilhaDireitaCm: panturrilhaD,
      panturrilhaEsquerdaCm: panturrilhaE,
      observacoes: obs,
    );

    Navigator.of(context).pop(novo);
  }

  Future<void> _escolherData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _data = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _data.hour,
          _data.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.medidaExistente == null
            ? 'Registrar Medidas (Fita Métrica)'
            : 'Editar Medidas Corporais',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _escolherData,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(_data)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Alterar',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Braços (circunferência em cm)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bracoDir,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Braço Dir.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _bracoEsq,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Braço Esq.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Tronco (circunferência em cm)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _peitoral,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peitoral (tórax)',
                  suffixText: 'cm',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cintura,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cintura',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _abdomen,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Abdômen',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Membros Inferiores (cm)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _coxaDir,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Coxa Dir.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _coxaEsq,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Coxa Esq.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _panturrilhaDir,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pant. Dir.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _panturrilhaEsq,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pant. Esq.',
                        suffixText: 'cm',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obs,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Ex: Medido em jejum pela manhã',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          child: const Text('Salvar Medidas'),
        ),
      ],
    );
  }
}
