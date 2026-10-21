import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../componentes/botao_de_perfil.dart';
import '../componentes/card_compartilhamento_treino.dart';
import '../componentes/modal_conquista_ofensiva.dart';
import '../componentes/modal_editar_habito.dart';
import '../componentes/modal_editar_tarefa.dart';
import '../dominio/calculadora_de_cargas.dart';
import '../dominio/catalogo_exercicios_offline.dart';
import '../dominio/recursos_avancados.dart';
import '../dominio/sistema_gamificacao.dart';
import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../servicos/som_do_alarme.dart';

enum _AbaHoje { treino, habitos, tarefas }

class TelaDeHoje extends StatefulWidget {
  const TelaDeHoje({super.key, required this.aoConfigurarPlano});

  final VoidCallback aoConfigurarPlano;

  @override
  State<TelaDeHoje> createState() => _EstadoDaTelaDeHoje();
}

class _EstadoDaTelaDeHoje extends State<TelaDeHoje> {
  _AbaHoje _abaAtual = _AbaHoje.treino;
  ValueListenable<int>? _abrirHabitosListenable;
  int _ultimoValorAbrirHabitos = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final novoListenable =
        context.read<ProvedorDeTreino>().abrirHabitosHojeListenable;
    if (_abrirHabitosListenable != novoListenable) {
      _abrirHabitosListenable?.removeListener(_aoSolicitarAbrirHabitosHoje);
      _abrirHabitosListenable = novoListenable;
      _abrirHabitosListenable!.addListener(_aoSolicitarAbrirHabitosHoje);
      if (novoListenable.value != _ultimoValorAbrirHabitos) {
        _ultimoValorAbrirHabitos = novoListenable.value;
        _abaAtual = _AbaHoje.habitos;
      }
    }
  }

  @override
  void dispose() {
    _abrirHabitosListenable?.removeListener(_aoSolicitarAbrirHabitosHoje);
    super.dispose();
  }

  void _aoSolicitarAbrirHabitosHoje() {
    _ultimoValorAbrirHabitos = _abrirHabitosListenable?.value ?? 0;
    if (mounted && _abaAtual != _AbaHoje.habitos) {
      setState(() => _abaAtual = _AbaHoje.habitos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final diaSemanaDeHoje = DateTime.now().weekday;
        final diaSemana = provedor.sessaoAtiva && provedor.diaDaSessao != null
            ? provedor.diaDaSessao!
            : diaSemanaDeHoje;
        final nomeDoDia = ExercicioPlanejado.nomeDoDiaDaSemana(diaSemana);
        final exercicios = provedor.sessaoAtiva
            ? provedor.exerciciosDaSessao
            : provedor.exerciciosSelecionadosDoDia(diaSemana);
        final rotinasDoDia = provedor.rotinasDoDia(diaSemana);

        if (!provedor.inicializado && provedor.ultimoErro != null) {
          return _ErroDeCarregamento(
            erro: provedor.ultimoErro!,
            onRetry: provedor.tentarInicializacaoNovamente,
          );
        }
        if (!provedor.inicializado) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: Text('Carregando seus dados locais...')),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _abaAtual == _AbaHoje.treino
                  ? 'Hoje'
                  : _abaAtual == _AbaHoje.habitos
                      ? 'Hábitos de Hoje'
                      : 'Tarefas de Hoje',
            ),
            actions: <Widget>[
              _BadgeOfensivaAppBar(provedor: provedor),
              const SizedBox(width: 8),
              const BotaoDePerfil(),
              const SizedBox(width: 12),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      _ItemSegmentoHoje(
                        titulo: 'Treino',
                        icone: Icons.fitness_center_rounded,
                        selecionado: _abaAtual == _AbaHoje.treino,
                        onTap: () =>
                            setState(() => _abaAtual = _AbaHoje.treino),
                      ),
                      _ItemSegmentoHoje(
                        titulo: 'Hábitos',
                        icone: Icons.stars_rounded,
                        selecionado: _abaAtual == _AbaHoje.habitos,
                        badge: provedor.totalHabitosDeHoje == 0
                            ? null
                            : '${provedor.habitosConcluidosHoje}/${provedor.totalHabitosDeHoje}',
                        onTap: () =>
                            setState(() => _abaAtual = _AbaHoje.habitos),
                      ),
                      _ItemSegmentoHoje(
                        titulo: 'Tarefas',
                        icone: Icons.checklist_rounded,
                        selecionado: _abaAtual == _AbaHoje.tarefas,
                        badge: provedor.tarefasPendentes.isEmpty
                            ? null
                            : '${provedor.tarefasPendentes.length}',
                        onTap: () =>
                            setState(() => _abaAtual = _AbaHoje.tarefas),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: _abaAtual == _AbaHoje.habitos
                ? _SecaoDeHabitosHoje(provedor: provedor)
                : _abaAtual == _AbaHoje.tarefas
                    ? _SecaoDeTarefasHoje(provedor: provedor)
                    : _SecaoDeTreinoHoje(
                        provedor: provedor,
                        diaSemana: diaSemana,
                        nomeDoDia: nomeDoDia,
                        exercicios: exercicios,
                        rotinasDoDia: rotinasDoDia,
                        aoConfigurarPlano: widget.aoConfigurarPlano,
                        aoIniciarTreino: () =>
                            _iniciarTreino(provedor, diaSemana),
                        aoFinalizarTreino: () =>
                            _finalizarTreino(context, provedor),
                      ),
          ),
        );
      },
    );
  }

  Future<void> _iniciarTreino(ProvedorDeTreino provedor, int diaSemana) async {
    try {
      await provedor.iniciarTreino(diaSemana);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível iniciar o treino: $erro')),
      );
    }
  }

  Future<void> _finalizarTreino(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar treino?'),
        content: const Text(
          'A sessão será salva no histórico e as cargas utilizadas ficarão salvas para os próximos treinos.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar treinando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (shouldFinish != true || !context.mounted) return;
    try {
      final nomeTreinoSnapshot = provedor.nomeDoTreinoDaSessao;
      final duracaoSegundosSnapshot = provedor.duracaoDaSessao.inSeconds;
      final tonelagemSnapshot = provedor.volumeTotalDaSessaoKg;
      final totalSeriesSnapshot = provedor.exerciciosDaSessao.fold<int>(
        0,
        (prev, e) =>
            prev +
            List.generate(e.series, (i) => i)
                .where((i) => provedor.serieEstaConcluida(e, i))
                .length,
      );
      final prsBatidos = <String>[];
      for (final ex in provedor.exerciciosDaSessao) {
        final rec = provedor.recordePessoalDoExercicio(ex.nome);
        for (var i = 0; i < ex.series; i++) {
          if (provedor.serieEstaConcluida(ex, i)) {
            final c = provedor.cargaAtual(ex, i);
            if (c > rec && c > 0) {
              prsBatidos.add(
                '${ex.nome}: ${c.toStringAsFixed(c == c.roundToDouble() ? 0 : 1)} kg',
              );
              break;
            }
          }
        }
      }

      final historyId = await provedor.finalizarTreino();
      if (!context.mounted) return;
      if (historyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Marque pelo menos uma série concluída para salvar o treino.',
            ),
          ),
        );
        return;
      }
      final greeting = provedor.perfil?.nome;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            greeting == null || greeting.isEmpty
                ? 'Treino concluído e dados salvos com sucesso!'
                : 'Mandou bem, $greeting! Treino registrado e salvo.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await ModalConquistaOfensiva.exibir(
        context,
        diasSeguidos: provedor.ofensivaAtual,
        totalTreinos: provedor.historico.length,
        treinosNaSemana: provedor.treinosNaSemana(DateTime.now()),
        acabouDeConcluir: true,
      );

      if (context.mounted) {
        await ModalCompartilharTreino.exibir(
          context,
          nomeTreino: nomeTreinoSnapshot,
          duracaoSegundos: duracaoSegundosSnapshot,
          tonelagemKg: tonelagemSnapshot,
          totalSeries: totalSeriesSnapshot,
          ofensivaDias: provedor.ofensivaAtual,
          recordesBatidos: prsBatidos,
        );
      }
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o treino: $erro')),
      );
    }
  }
}

class _SecaoDeTreinoHoje extends StatelessWidget {
  const _SecaoDeTreinoHoje({
    required this.provedor,
    required this.diaSemana,
    required this.nomeDoDia,
    required this.exercicios,
    required this.rotinasDoDia,
    required this.aoConfigurarPlano,
    required this.aoIniciarTreino,
    required this.aoFinalizarTreino,
  });

  final ProvedorDeTreino provedor;
  final int diaSemana;
  final String nomeDoDia;
  final List<ExercicioPlanejado> exercicios;
  final List<RotinaDeTreino> rotinasDoDia;
  final VoidCallback aoConfigurarPlano;
  final VoidCallback aoIniciarTreino;
  final VoidCallback aoFinalizarTreino;

  @override
  Widget build(BuildContext context) {
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;

    if (exercicios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bedtime_rounded,
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                rotinasDoDia.isEmpty
                    ? 'Hoje é seu Dia de Descanso! 🧘'
                    : 'Não há exercícios selecionados para $nomeDoDia.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                rotinasDoDia.isEmpty
                    ? 'O descanso faz parte da sua evolução muscular. Aproveite para se recuperar, hidratar e cumprir seus hábitos e tarefas!'
                    : 'Aproveite para descansar, manter a ofensiva e cumprir seus hábitos saudáveis diários.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF636E72),
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: aoConfigurarPlano,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Escolher ou criar treinos'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isSessionActive =
        provedor.sessaoAtiva && provedor.diaDaSessao == diaSemana;
    final allSetsCompleted =
        isSessionActive && provedor.todasAsSeriesDoTreinoEstaoConcluidas();

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: exercicios.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CabecalhoDoTreinoHoje(
                    provedor: provedor,
                    diaSemana: diaSemana,
                    nomeDoDia: nomeDoDia,
                    exercicios: exercicios,
                    rotinasDoDia: rotinasDoDia,
                    isSessionActive: isSessionActive,
                    aoIniciarTreino: aoIniciarTreino,
                  );
                }

                final exercicio = exercicios[index - 1];
                return _CartaoDeExercicioDoTreino(
                  key: ValueKey(
                    'exercise-${exercicio.id}-${exercicio.tempoDescansoSegundos}',
                  ),
                  exercicio: exercicio,
                  enabled: isSessionActive,
                );
              },
            ),
          ),
        ),
        if (isSessionActive)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.45),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allSetsCompleted
                      ? (temaEscuro
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFA5D6A7))
                      : (temaEscuro
                          ? const Color(0xFF353545)
                          : const Color(0xFF2D3436)),
                  foregroundColor: allSetsCompleted && !temaEscuro
                      ? const Color(0xFF1B5E20)
                      : Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 2,
                ),
                onPressed: aoFinalizarTreino,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  allSetsCompleted ? 'Finalizar Treino' : 'Finalizar Treino',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CabecalhoDoTreinoHoje extends StatelessWidget {
  const _CabecalhoDoTreinoHoje({
    required this.provedor,
    required this.diaSemana,
    required this.nomeDoDia,
    required this.exercicios,
    required this.rotinasDoDia,
    required this.isSessionActive,
    required this.aoIniciarTreino,
  });

  final ProvedorDeTreino provedor;
  final int diaSemana;
  final String nomeDoDia;
  final List<ExercicioPlanejado> exercicios;
  final List<RotinaDeTreino> rotinasDoDia;
  final bool isSessionActive;
  final VoidCallback aoIniciarTreino;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final seriesTotais = exercicios.fold<int>(0, (acc, e) => acc + e.series);
    final seriesConcluidas = isSessionActive
        ? exercicios.fold<int>(
            0,
            (acc, e) =>
                acc +
                List.generate(
                  e.series,
                  (i) => provedor.serieEstaConcluida(e, i) ? 1 : 0,
                ).fold(0, (a, b) => a + b),
          )
        : 0;
    final progresso = seriesTotais == 0
        ? 0.0
        : (seriesConcluidas / seriesTotais).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nomeDoDia,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (isSessionActive &&
                      provedor.nomeDoTreinoDaSessao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${provedor.nomeDoTreinoDaSessao} em andamento',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${exercicios.length} ${exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isSessionActive && rotinasDoDia.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: rotinasDoDia.map((rotina) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(rotina.nome),
                    selected: rotina.selecionado,
                    onSelected: (selected) async {
                      final ids = rotinasDoDia
                          .where((item) => item.selecionado)
                          .map((item) => item.id!)
                          .toSet();
                      final id = rotina.id;
                      if (id == null) return;
                      if (selected) {
                        ids.add(id);
                      } else {
                        ids.remove(id);
                      }
                      if (ids.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Escolha pelo menos um treino para hoje.'),
                          ),
                        );
                        return;
                      }
                      try {
                        await provedor.definirRotinasSelecionadas(
                            diaSemana, ids);
                      } catch (erro) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Não foi possível atualizar: $erro'),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
        if (!isSessionActive) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: exercicios.isEmpty ? null : aoIniciarTreino,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Iniciar Treino'),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Preencher com cargas da última sessão',
                child: OutlinedButton.icon(
                  onPressed: exercicios.isEmpty
                      ? null
                      : () async {
                          await provedor
                              .repetirUltimaSessaoComCargas(diaSemana);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cargas anteriores aplicadas aos exercícios de hoje.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Repetir'),
                ),
              ),
            ],
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        ValueListenableBuilder<Duration>(
                          valueListenable: provedor.duracaoDaSessaoListenable,
                          builder: (context, duracao, _) {
                            final min =
                                duracao.inMinutes.toString().padLeft(2, '0');
                            final seg = (duracao.inSeconds % 60)
                                .toString()
                                .padLeft(2, '0');
                            final vol = provedor.volumeTotalDaSessaoKg;
                            final volTxt = vol > 0
                                ? (vol >= 1000
                                    ? ' · ${(vol / 1000).toStringAsFixed(1)} ton'
                                    : ' · ${vol.toStringAsFixed(0)} kg')
                                : '';
                            return Text(
                              'Sessão ($min:$seg)$volTxt · $seriesConcluidas/$seriesTotais séries',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      '${(progresso * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 5,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progresso == 1.0
                          ? const Color(0xFF00E676)
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CartaoDeExercicioDoTreino extends StatelessWidget {
  const _CartaoDeExercicioDoTreino({
    super.key,
    required this.exercicio,
    required this.enabled,
  });

  final ExercicioPlanejado exercicio;
  final bool enabled;

  void _abrirSeletorDeDescanso(
    BuildContext context,
    ProvedorDeTreino provedor,
    ExercicioPlanejado targetExercise,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _PainelDeSelecaoDoDescanso(
        nomeDoExercicio: targetExercise.nome,
        initialSeconds: targetExercise.tempoDescansoSegundos,
        onConfirm: (segundos) {
          if (targetExercise.id != null) {
            provedor.atualizarDuracaoDoDescanso(targetExercise.id!, segundos);
          }
        },
      ),
    );
  }

  static String _formatarCarga(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);

  void _abrirCronometroDeDescanso(
    BuildContext context,
    ProvedorDeTreino provedor,
    ExercicioPlanejado targetExercise,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PainelDoCronometroDeDescanso(
        provedor: provedor,
        exercicio: targetExercise,
      ),
    );
  }

  void _abrirCalculadoraDoExercicio(
    BuildContext context,
    ProvedorDeTreino provedor,
    ExercicioPlanejado targetExercise,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalCalculadoraEAquecimento(
        provedor: provedor,
        exercicio: targetExercise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final idDoExercicio = exercicio.id ?? -1;
        final currentExercise = provedor.sessaoAtiva
            ? provedor.exerciciosDaSessao.firstWhere(
                (e) => e.id == exercicio.id,
                orElse: () => exercicio,
              )
            : provedor
                .exerciciosSelecionadosDoDia(exercicio.diaSemana)
                .firstWhere(
                  (e) => e.id == exercicio.id,
                  orElse: () => exercicio,
                );
        final localPath = currentExercise.caminhoLocalGif;
        final hasLocalFile = localPath != null &&
            localPath.isNotEmpty &&
            File(localPath).existsSync();

        final temaEscuro = Theme.of(context).brightness == Brightness.dark;
        final exerciseComplete =
            enabled && provedor.exercicioEstaConcluido(currentExercise);
        final completionColor =
            temaEscuro ? const Color(0xFF1B3026) : const Color(0xFFE8F2EA);
        final completionBorderColor =
            temaEscuro ? const Color(0xFF315B41) : const Color(0xFFB7D7BE);
        final ehUltimoExercicioPendente =
            enabled && provedor.ehUltimoExercicioPendente(currentExercise);
        final allWorkoutSetsCompleted =
            enabled && provedor.todasAsSeriesDoTreinoEstaoConcluidas();

        return Card(
          color: exerciseComplete ? completionColor : null,
          shape: exerciseComplete
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: completionBorderColor, width: 1.2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (hasLocalFile) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Image.file(
                          File(localPath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const _ImagemAlternativa(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (currentExercise.grupoSuperSerie != null &&
                              currentExercise.grupoSuperSerie!
                                  .trim()
                                  .isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SUPER-SÉRIE / BI-SET ${currentExercise.grupoSuperSerie!.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Text(
                            currentExercise.nome,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${currentExercise.series} séries',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (ehUltimoExercicioPendente)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Último pendente',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botões de ação do exercício
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            minimumSize: const Size(32, 32),
                            maximumSize: const Size(32, 32),
                          ),
                          icon: const Icon(Icons.remove_rounded, size: 17),
                          tooltip: 'Remover série',
                          onPressed: currentExercise.series > 1
                              ? () => provedor.removerSerieDoExercicio(
                                    currentExercise,
                                  )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            minimumSize: const Size(32, 32),
                            maximumSize: const Size(32, 32),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 17),
                          tooltip: 'Adicionar série',
                          onPressed: () => provedor.adicionarSerieAoExercicio(
                            currentExercise,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            minimumSize: const Size(32, 32),
                            maximumSize: const Size(32, 32),
                          ),
                          icon: const Icon(Icons.calculate_outlined, size: 17),
                          tooltip: 'Calculadora de Cargas, Aquecimento e 1RM',
                          onPressed: () => _abrirCalculadoraDoExercicio(
                            context,
                            provedor,
                            currentExercise,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFFFA726).withValues(alpha: 0.16),
                            foregroundColor: const Color(0xFFFFA726),
                            minimumSize: const Size(32, 32),
                            maximumSize: const Size(32, 32),
                          ),
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          tooltip: 'Rampa de Aquecimento (1-Toque)',
                          onPressed: () async {
                            final ok = await provedor
                                .inserirRampaDeAquecimento(currentExercise);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? '⚡ Séries de aquecimento adicionadas a ${currentExercise.nome}!'
                                        : 'Defina a carga do exercício primeiro para calcular o aquecimento.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                if (!allWorkoutSetsCompleted) ...[
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: provedor.tempoRestanteDescansoListenable,
                    builder: (context, __, ___) {
                      final isTimerRunning =
                          provedor.cronometroEstaAtivoPara(idDoExercicio);
                      final isTimerFinished =
                          provedor.cronometroTerminouPara(idDoExercicio);
                      final remainingSeconds =
                          provedor.tempoRestantePara(idDoExercicio);
                      return _ControleDoCronometroDeDescanso(
                        isRunning: isTimerRunning,
                        isFinished: isTimerFinished,
                        remainingSeconds: remainingSeconds,
                        totalSeconds: provedor.duracaoTotalDoCronometro,
                        selectedDuration: currentExercise.tempoDescansoSegundos,
                        aoDispensar: isTimerFinished
                            ? () => provedor.cancelarCronometroDeDescanso()
                            : null,
                        onTap: () {
                          if (isTimerRunning || isTimerFinished) {
                            _abrirCronometroDeDescanso(
                              context,
                              provedor,
                              currentExercise,
                            );
                          } else {
                            _abrirSeletorDeDescanso(
                              context,
                              provedor,
                              currentExercise,
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),

                // Lista de Séries
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 0, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SÉRIE',
                          style: _setColumnLabelStyle(context),
                        ),
                      ),
                      SizedBox(
                        width: 172,
                        child: Center(
                          child: Text(
                            'REPS & CARGA',
                            style: _setColumnLabelStyle(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...List<Widget>.generate(currentExercise.series, (seriesIndex) {
                  final completed = provedor.serieEstaConcluida(
                    currentExercise,
                    seriesIndex,
                  );
                  final tipoSerie = provedor.tipoDaSerie(
                    currentExercise,
                    seriesIndex,
                  );
                  final cargaDaSerie = provedor.cargaAtual(
                    currentExercise,
                    seriesIndex,
                  );
                  final recordeHistorico = provedor.recordePessoalDoExercicio(
                    currentExercise.nome,
                  );
                  final ehRecordePessoal = cargaDaSerie > 0 &&
                      recordeHistorico > 0 &&
                      cargaDaSerie >= recordeHistorico;

                  String siglaTipo;
                  String? rotuloTipo;
                  Color corTipo;
                  switch (tipoSerie) {
                    case 'aquecimento':
                      siglaTipo = 'A';
                      rotuloTipo = 'Aquec.';
                      corTipo = const Color(0xFFFFA726);
                      break;
                    case 'dropset':
                      siglaTipo = 'D';
                      rotuloTipo = 'Drop';
                      corTipo = const Color(0xFF00B8D4);
                      break;
                    case 'falha':
                      siglaTipo = 'F';
                      rotuloTipo = 'Falha 🔥';
                      corTipo = const Color(0xFFFF5252);
                      break;
                    default:
                      siglaTipo = '${seriesIndex + 1}';
                      rotuloTipo = null;
                      corTipo = Theme.of(context).colorScheme.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: <Widget>[
                        Semantics(
                          label:
                              'Marcar série ${seriesIndex + 1} de ${currentExercise.nome} como concluída',
                          child: Checkbox(
                            value: completed,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: enabled
                                ? (value) {
                                      ServicoDeSomDoAlarme.instance
                                          .vibrarImpacto();
                                      provedor.alternarConclusaoDaSerie(
                                        currentExercise,
                                        seriesIndex,
                                      );
                                    }
                                : null,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              ServicoDeSomDoAlarme.instance.vibrarClique();
                              provedor.alternarTipoDaSerie(
                                currentExercise,
                                seriesIndex,
                              );
                            },
                            onLongPress: () {
                              ServicoDeSomDoAlarme.instance.vibrarImpacto();
                              _abrirCalculadoraDoExercicio(
                                context,
                                provedor,
                                currentExercise,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: corTipo.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: corTipo.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      siglaTipo,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: corTipo,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          rotuloTipo ??
                                              'Série ${seriesIndex + 1}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: rotuloTipo != null
                                                ? corTipo
                                                : null,
                                            decoration: completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (ehRecordePessoal)
                                          const Text(
                                            '🏆 Recorde PR',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFFFB300),
                                            ),
                                          ),
                                        Builder(
                                          builder: (context) {
                                            final ultima =
                                                provedor.ultimaExecucaoDaSerie(
                                              currentExercise.nome,
                                              seriesIndex,
                                            );
                                            final rpe = provedor.rpeDaSerie(
                                              currentExercise,
                                              seriesIndex,
                                            );
                                            if (ultima == null && rpe == null) {
                                              return const SizedBox.shrink();
                                            }
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (ultima != null)
                                                  Flexible(
                                                    child: Text(
                                                      'Ant: ${_formatarCarga(ultima.cargaUtilizada)}kg × ${ultima.repeticoes}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.72,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                if (ultima != null &&
                                                    rpe != null)
                                                  const SizedBox(width: 4),
                                                if (rpe != null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF9C27B0,
                                                      ).withValues(alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '@${rpe.toStringAsFixed(rpe.truncateToDouble() == rpe ? 0 : 1)}',
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                          0xFF9C27B0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _BotaoMedidasSerieHoje(
                          key: ValueKey<String>(
                            'measures-${currentExercise.id ?? currentExercise.nome}-$seriesIndex',
                          ),
                          exercicio: currentExercise,
                          provedor: provedor,
                          seriesIndex: seriesIndex,
                        ),
                      ],
                    ),
                  );
                }),

                Builder(
                  builder: (context) {
                    if (!provedor.sessaoAtiva || currentExercise.series == 0) {
                      return const SizedBox.shrink();
                    }
                    final bateuTodasAsSeries = List.generate(
                      currentExercise.series,
                      (i) => i,
                    ).every(
                      (i) =>
                          provedor.serieEstaConcluida(currentExercise, i) &&
                          provedor.repeticoesAtuais(currentExercise, i) >=
                              currentExercise.repeticoes,
                    );
                    if (!bateuTodasAsSeries) return const SizedBox.shrink();

                    final incrementoKg = currentExercise.carga >= 40.0 ? 2 : 1;
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Meta dominada em todas as séries! Sugestão para o próximo treino: suba +$incrementoKg kg (Sobrecarga Progressiva).',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                if (!enabled && !provedor.sessaoAtiva)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Você pode editar cargas e séries livremente. Inicie o treino para marcar a execução.',
                      style: TextStyle(color: Color(0xFF636E72), fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _setColumnLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
}

class _ControleDoCronometroDeDescanso extends StatelessWidget {
  const _ControleDoCronometroDeDescanso({
    required this.isRunning,
    required this.isFinished,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.selectedDuration,
    required this.onTap,
    this.aoDispensar,
  });

  final bool isRunning;
  final bool isFinished;
  final int remainingSeconds;
  final int totalSeconds;
  final int selectedDuration;
  final VoidCallback onTap;
  final VoidCallback? aoDispensar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temaEscuro = theme.brightness == Brightness.dark;
    const finishedColor = Color(0xFF00B894);
    final accent = isFinished ? finishedColor : theme.colorScheme.primary;
    final background = isFinished
        ? (temaEscuro ? const Color(0xFF143026) : const Color(0xFFE8F8F2))
        : theme.colorScheme.surfaceContainerHighest;
    final progress = totalSeconds <= 0
        ? 0.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

    return Semantics(
      button: true,
      label: isFinished
          ? 'Descanso concluído. Toque para redefinir ou dispensar.'
          : isRunning
              ? 'Descanso em andamento: $remainingSeconds segundos restantes.'
              : 'Tempo de descanso: ${_formatarDuracaoDoDescanso(selectedDuration)}. Toque para alterar.',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isFinished ? finishedColor : accent.withValues(alpha: 0.25),
                width: isFinished ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isFinished ? Icons.alarm_on_rounded : Icons.timer_outlined,
                  size: 22,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFinished
                        ? 'Descanso concluído! 💪'
                        : isRunning
                            ? 'Descanso: $remainingSeconds seg restantes'
                            : 'Descanso entre as séries',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFinished
                          ? (temaEscuro
                              ? const Color(0xFF55EFC4)
                              : const Color(0xFF007A58))
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isFinished && aoDispensar != null)
                  IconButton(
                    tooltip: 'Dispensar descanso',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: aoDispensar,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: finishedColor,
                      size: 24,
                    ),
                  )
                else if (isRunning)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: accent.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        Text(
                          '$remainingSeconds',
                          style: TextStyle(
                            fontSize: remainingSeconds >= 100 ? 9 : 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatarDuracaoDoDescanso(selectedDuration),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.unfold_more_rounded,
                            size: 16, color: accent),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoMedidasSerieHoje extends StatelessWidget {
  const _BotaoMedidasSerieHoje({
    super.key,
    required this.exercicio,
    required this.provedor,
    required this.seriesIndex,
  });

  final ExercicioPlanejado exercicio;
  final ProvedorDeTreino provedor;
  final int seriesIndex;

  static String _formatarCarga(double valor) =>
      valor == valor.roundToDouble()
          ? valor.toStringAsFixed(0)
          : valor.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reps = provedor.repeticoesAtuais(exercicio, seriesIndex);
    final carga = provedor.cargaAtual(exercicio, seriesIndex);
    final cargaTxt = carga <= 0 ? 'Livre' : '${_formatarCarga(carga)} kg';

    return Semantics(
      button: true,
      label:
          'Ajustar repetições e carga da série ${seriesIndex + 1}: $reps reps e $cargaTxt',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          ServicoDeSomDoAlarme.instance.vibrarClique();
          _ModalSeletorDeslizanteSerie.exibir(
            context,
            provedor: provedor,
            exercicio: exercicio,
            seriesIndex: seriesIndex,
          );
        },
        child: Container(
          width: 172,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.28),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '$reps ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'reps   •   ',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                      TextSpan(
                        text: cargaTxt,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalSeletorDeslizanteSerie extends StatefulWidget {
  const _ModalSeletorDeslizanteSerie({
    required this.provedor,
    required this.exercicio,
    required this.seriesIndex,
  });

  final ProvedorDeTreino provedor;
  final ExercicioPlanejado exercicio;
  final int seriesIndex;

  static Future<void> exibir(
    BuildContext context, {
    required ProvedorDeTreino provedor,
    required ExercicioPlanejado exercicio,
    required int seriesIndex,
  }) async {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalSeletorDeslizanteSerie(
        provedor: provedor,
        exercicio: exercicio,
        seriesIndex: seriesIndex,
      ),
    );
  }

  @override
  State<_ModalSeletorDeslizanteSerie> createState() =>
      _EstadoDoModalSeletorDeslizanteSerie();
}

class _EstadoDoModalSeletorDeslizanteSerie
    extends State<_ModalSeletorDeslizanteSerie> {
  // Atalhos de 0,5 kg; a carga também pode ser digitada livremente.
  static final List<double> _opcoesCargaKg = <double>[
    for (int meioKg = 0; meioKg <= 1800; meioKg++) meioKg / 2,
  ];

  late int _repeticoesSelecionadas;
  late int _indiceCargaSelecionada;
  bool _aplicarEmTodasAsSeries = false;
  late FixedExtentScrollController _repsScrollController;
  late FixedExtentScrollController _cargaScrollController;
  late TextEditingController _cargaTextController;

  @override
  void initState() {
    super.initState();
    final repsAtual = widget.provedor.repeticoesAtuais(
      widget.exercicio,
      widget.seriesIndex,
    );
    _repeticoesSelecionadas = repsAtual.clamp(1, 100);

    final cargaAtual = widget.provedor.cargaAtual(
      widget.exercicio,
      widget.seriesIndex,
    );
    if (cargaAtual <= 0) {
      _indiceCargaSelecionada = 0;
    } else {
      final meioKgArredondado = (cargaAtual * 2).round().clamp(1, 1800);
      _indiceCargaSelecionada = meioKgArredondado.clamp(
        1,
        _opcoesCargaKg.length - 1,
      );
    }

    _repsScrollController = FixedExtentScrollController(
      initialItem: _repeticoesSelecionadas - 1,
    );
    _cargaScrollController = FixedExtentScrollController(
      initialItem: _indiceCargaSelecionada,
    );
    _cargaTextController = TextEditingController(
      text: _formatarCarga(_opcoesCargaKg[_indiceCargaSelecionada]),
    );
  }

  @override
  void dispose() {
    _repsScrollController.dispose();
    _cargaScrollController.dispose();
    _cargaTextController.dispose();
    super.dispose();
  }

  double get _cargaSelecionadaKg => _opcoesCargaKg[_indiceCargaSelecionada];

  static String _formatarCarga(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);

  void _irParaIndiceCarga(int novoIndice) {
    final clamped = novoIndice.clamp(0, _opcoesCargaKg.length - 1);
    if (clamped == _indiceCargaSelecionada) return;
    _cargaScrollController.animateToItem(
      clamped,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmar() async {
    final digitada =
        double.tryParse(_cargaTextController.text.trim().replaceAll(',', '.'));
    final cargaKg =
        (digitada ?? _cargaSelecionadaKg).clamp(0.0, 900.0).toDouble();
    final reps = _repeticoesSelecionadas;
    if (_aplicarEmTodasAsSeries) {
      for (var i = 0; i < widget.exercicio.series; i++) {
        await widget.provedor.definirRepeticoesECargaDaSerie(
          widget.exercicio,
          i,
          repeticoes: reps,
          carga: cargaKg,
        );
      }
    } else {
      await widget.provedor.definirRepeticoesECargaDaSerie(
        widget.exercicio,
        widget.seriesIndex,
        repeticoes: reps,
        carga: cargaKg,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final temaEscuro = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: temaEscuro
                  ? const Color(0xFF444451)
                  : const Color(0xFFDFE2E7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${widget.exercicio.nome} · Série ${widget.seriesIndex + 1}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha em passos de 0,5 kg ou digite a carga exata',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cargaTextController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Carga exata',
              suffixText: 'kg',
              helperText: 'Aceita valores como 2,5; 7,5 ou 12 kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (valor) {
              final carga = double.tryParse(valor.trim().replaceAll(',', '.'));
              if (carga == null || carga < 0 || carga > 900) return;
              final indice = (carga * 2).round().clamp(0, 1800);
              if (indice != _indiceCargaSelecionada) {
                setState(() => _indiceCargaSelecionada = indice);
                _cargaScrollController.jumpToItem(indice);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              // Coluna Repetições (1 a 100)
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      'REPETIÇÕES (1–100)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 175,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: CupertinoPicker.builder(
                        scrollController: _repsScrollController,
                        itemExtent: 40,
                        magnification: 1.12,
                        useMagnifier: true,
                        childCount: 100,
                        onSelectedItemChanged: (index) {
                          ServicoDeSomDoAlarme.instance.vibrarClique();
                          setState(() => _repeticoesSelecionadas = index + 1);
                        },
                        itemBuilder: (context, index) {
                          final valor = index + 1;
                          final selecionado = valor == _repeticoesSelecionadas;
                          return Center(
                            child: Text(
                              '$valor reps',
                              style: TextStyle(
                                fontSize: selecionado ? 18 : 15,
                                fontWeight: selecionado
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: selecionado
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Coluna Carga (0,5 kg a 900 kg)
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      'CARGA (0,5 EM 0,5 KG)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 175,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: CupertinoPicker.builder(
                        scrollController: _cargaScrollController,
                        itemExtent: 40,
                        magnification: 1.12,
                        useMagnifier: true,
                        childCount: _opcoesCargaKg.length,
                        onSelectedItemChanged: (index) {
                          ServicoDeSomDoAlarme.instance.vibrarClique();
                          setState(() {
                            _indiceCargaSelecionada = index;
                            _cargaTextController.text = _formatarCarga(
                              _opcoesCargaKg[index],
                            );
                          });
                        },
                        itemBuilder: (context, index) {
                          final kg = _opcoesCargaKg[index];
                          final selecionado = index == _indiceCargaSelecionada;
                          return Center(
                            child: Text(
                              kg == 0 ? '0 kg (Livre)' : '$kg kg',
                              style: TextStyle(
                                fontSize: selecionado ? 18 : 15,
                                fontWeight: selecionado
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: selecionado
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Atalhos de salto rápido de carga
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  <int>[10, 20, 40, 60, 80, 100, 150, 200, 300].map((kgAtalho) {
                final selecionado = _cargaSelecionadaKg == kgAtalho;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        selecionado ? cs.primary.withValues(alpha: 0.18) : null,
                    label: Text(
                      '${kgAtalho}kg',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            selecionado ? FontWeight.w800 : FontWeight.w600,
                        color: selecionado ? cs.primary : null,
                      ),
                    ),
                    onPressed: () {
                      final idx = _opcoesCargaKg.indexOf(kgAtalho.toDouble());
                      if (idx >= 0) _irParaIndiceCarga(idx);
                    },
                  ),
                );
              }).toList(growable: false),
            ),
          ),
          if (_cargaSelecionadaKg >= 20) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cargaSelecionadaKg == 20
                          ? 'Barra olímpica de 20 kg (sem anilhas)'
                          : 'Por lado (barra 20kg): ${CatalogoDeExerciciosOffline.calcularAnilhasPorLado(_cargaSelecionadaKg.toDouble()).anilhasPorLado.map((p) => p == p.roundToDouble() ? '${p.toInt()}kg' : '${p}kg').join(' + ')}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.exercicio.series > 1) ...<Widget>[
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _aplicarEmTodasAsSeries,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Aplicar $_repeticoesSelecionadas reps e $_cargaSelecionadaKg kg em todas as ${widget.exercicio.series} séries deste exercício',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _aplicarEmTodasAsSeries = val ?? false),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmar,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salvar série'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PainelDoCronometroDeDescanso extends StatelessWidget {
  const _PainelDoCronometroDeDescanso({
    required this.provedor,
    required this.exercicio,
  });

  final ProvedorDeTreino provedor;
  final ExercicioPlanejado exercicio;

  @override
  Widget build(BuildContext context) {
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final idDoExercicio = exercicio.id ?? -1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Consumer<ProvedorDeTreino>(
        builder: (context, state, _) {
          return ValueListenableBuilder<int>(
            valueListenable: state.tempoRestanteDescansoListenable,
            builder: (context, __, ___) {
              final remaining = state.tempoRestantePara(idDoExercicio);
              final total = state.duracaoTotalDoCronometro;
              final finished = state.cronometroTerminouPara(idDoExercicio);
              const finishedColor = Color(0xFFFFA726);
              final timerColor = finished
                  ? finishedColor
                  : Theme.of(context).colorScheme.primary;
              final progress = total <= 0
                  ? 0.0
                  : (remaining / total).clamp(0.0, 1.0).toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: temaEscuro
                          ? const Color(0xFF444451)
                          : const Color(0xFFDFE2E7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Icon(
                    finished
                        ? Icons.check_circle_rounded
                        : Icons.timer_outlined,
                    size: 38,
                    color: timerColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    finished
                        ? 'Descanso concluído!'
                        : 'Descanso entre as séries',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: finished ? timerColor : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercicio.nome,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: temaEscuro
                                ? const Color(0xFF343044)
                                : const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              timerColor,
                            ),
                          ),
                        ),
                        Text(
                          _formatarDuracaoDoDescanso(remaining),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    finished
                        ? 'Você pode continuar para a próxima série.'
                        : 'Recupere-se e prepare-se para a próxima série.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        state.cancelarCronometroDeDescanso();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        finished ? 'Continuar treino' : 'Pular descanso',
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PainelDeSelecaoDoDescanso extends StatefulWidget {
  const _PainelDeSelecaoDoDescanso({
    required this.nomeDoExercicio,
    required this.initialSeconds,
    required this.onConfirm,
  });

  final String nomeDoExercicio;
  final int initialSeconds;
  final ValueChanged<int> onConfirm;

  @override
  State<_PainelDeSelecaoDoDescanso> createState() =>
      _EstadoDoPainelDeSelecaoDoDescanso();
}

class _EstadoDoPainelDeSelecaoDoDescanso
    extends State<_PainelDeSelecaoDoDescanso> {
  static const int _maxSeconds = 600;
  static const double _dialSize = 240;

  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds.clamp(0, _maxSeconds);
  }

  void _atualizarPelaPosicao(Offset posicao) {
    final center = const Offset(_dialSize / 2, _dialSize / 2);
    final dx = posicao.dx - center.dx;
    final dy = posicao.dy - center.dy;

    if (math.sqrt(dx * dx + dy * dy) < 45) return;

    final angle = math.atan2(dy, dx);
    final fraction = ((angle + math.pi / 2) / (2 * math.pi)) % 1.0;
    final newSeconds = (fraction * _maxSeconds).round().clamp(0, _maxSeconds);

    if (newSeconds != _seconds) {
      setState(() => _seconds = newSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Descanso: ${widget.nomeDoExercicio}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Cada exercício tem seu próprio tempo de descanso salvo.',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Atalhos rápidos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [30, 45, 60, 90, 120, 180].map((sec) {
              final isSelected = _seconds == sec;
              return ChoiceChip(
                label: Text(_formatarDuracaoDoDescanso(sec)),
                selected: isSelected,
                onSelected: (_) => setState(() => _seconds = sec),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) =>
                _atualizarPelaPosicao(details.localPosition),
            onPanUpdate: (details) =>
                _atualizarPelaPosicao(details.localPosition),
            onTapDown: (details) =>
                _atualizarPelaPosicao(details.localPosition),
            child: SizedBox(
              width: _dialSize,
              height: _dialSize,
              child: CustomPaint(
                painter: _DesenhadorDoSeletorDeDescanso(
                  segundos: _seconds,
                  temaEscuro: temaEscuro,
                  corPrimaria: Theme.of(context).colorScheme.primary,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.timer_outlined,
                        size: 26,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatarDuracaoDoDescanso(_seconds),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MIN : SEG',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_seconds);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar descanso'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesenhadorDoSeletorDeDescanso extends CustomPainter {
  const _DesenhadorDoSeletorDeDescanso({
    required this.segundos,
    required this.temaEscuro,
    required this.corPrimaria,
  });

  final int segundos;
  final bool temaEscuro;
  final Color corPrimaria;

  @override
  void paint(Canvas canvas, Size size) {
    const maxSeconds = 600;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = temaEscuro
          ? const Color(0xFF262630)
          : corPrimaria.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = corPrimaria
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progress = segundos / maxSeconds;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final markerCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    canvas.drawCircle(
      markerCenter,
      9,
      Paint()..color = corPrimaria,
    );
    canvas.drawCircle(markerCenter, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DesenhadorDoSeletorDeDescanso oldDelegate) {
    return oldDelegate.segundos != segundos ||
        oldDelegate.temaEscuro != temaEscuro ||
        oldDelegate.corPrimaria != corPrimaria;
  }
}

class _ImagemAlternativa extends StatelessWidget {
  const _ImagemAlternativa();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fitness_center,
        color: Theme.of(context).colorScheme.primary,
        size: 26,
      ),
    );
  }
}

class _ErroDeCarregamento extends StatelessWidget {
  const _ErroDeCarregamento({required this.erro, required this.onRetry});
  final String erro;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(erro, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatarDuracaoDoDescanso(int segundos) {
  final minutes = segundos ~/ 60;
  final remainingSeconds = segundos % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainingSeconds.toString().padLeft(2, '0')}';
}

class _BadgeOfensivaAppBar extends StatefulWidget {
  const _BadgeOfensivaAppBar({required this.provedor});

  final ProvedorDeTreino provedor;

  @override
  State<_BadgeOfensivaAppBar> createState() => _EstadoDoBadgeOfensivaAppBar();
}

class _EstadoDoBadgeOfensivaAppBar extends State<_BadgeOfensivaAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fireAnim;

  @override
  void initState() {
    super.initState();
    _fireAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sincronizarAnimacao();
  }

  @override
  void didUpdateWidget(covariant _BadgeOfensivaAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarAnimacao();
  }

  void _sincronizarAnimacao() {
    final ativo = widget.provedor.ofensivaAtual > 0;
    if (ativo && !_fireAnim.isAnimating) {
      _fireAnim.repeat(reverse: true);
    } else if (!ativo && _fireAnim.isAnimating) {
      _fireAnim.stop();
      _fireAnim.value = 0;
    }
  }

  @override
  void dispose() {
    _fireAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ofensiva = widget.provedor.ofensivaAtual;
    final classe = SistemaGamificacao.obterClasseAtual(ofensiva);
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final fogoAtivo = ofensiva > 0;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: fogoAtivo
            ? 'Ofensiva ativa de $ofensiva ${ofensiva == 1 ? 'dia' : 'dias'}. Nível ${classe.nome}. Toque para abrir painel de conquistas.'
            : 'Ofensiva zerada. Treine hoje para acender a chama. Toque para ver conquistas.',
        child: Tooltip(
          message: fogoAtivo
              ? '🔥 $ofensiva ${ofensiva == 1 ? 'dia seguido' : 'dias seguidos'} · Nível ${classe.nome}'
              : 'Treine hoje para acender sua ofensiva!',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => ModalConquistaOfensiva.exibir(
                context,
                diasSeguidos: ofensiva,
                totalTreinos: widget.provedor.historico.length,
                treinosNaSemana: widget.provedor.treinosNaSemana(
                  DateTime.now(),
                ),
                acabouDeConcluir: false,
              ),
              child: AnimatedBuilder(
                animation: _fireAnim,
                builder: (context, child) {
                  final scale =
                      fogoAtivo ? 1.0 + (_fireAnim.value * 0.10) : 1.0;
                  return Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: fogoAtivo
                          ? (temaEscuro
                              ? classe.cor.withValues(alpha: 0.18)
                              : classe.cor.withValues(alpha: 0.12))
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: fogoAtivo
                            ? classe.cor.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Icon(
                            fogoAtivo
                                ? Icons.local_fire_department_rounded
                                : Icons.local_fire_department_outlined,
                            color: fogoAtivo
                                ? const Color(0xFFFF6D00)
                                : (temaEscuro
                                    ? const Color(0xFF7E7796)
                                    : const Color(0xFF9E98B3)),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          fogoAtivo
                              ? '$ofensiva ${ofensiva == 1 ? 'dia' : 'dias'}'
                              : '0 dias',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: fogoAtivo
                                ? (temaEscuro ? Colors.white : classe.cor)
                                : (temaEscuro
                                    ? const Color(0xFF9E98B3)
                                    : const Color(0xFF5E5978)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemSegmentoHoje extends StatelessWidget {
  const _ItemSegmentoHoje({
    required this.titulo,
    required this.icone,
    required this.selecionado,
    required this.onTap,
    this.badge,
  });

  final String titulo;
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selecionado
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 16,
                color: selecionado
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                  color: selecionado
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? Colors.white.withValues(alpha: 0.25)
                        : theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selecionado
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoDeHabitosHoje extends StatelessWidget {
  const _SecaoDeHabitosHoje({required this.provedor});

  final ProvedorDeTreino provedor;

  @override
  Widget build(BuildContext context) {
    final habitos = provedor.habitosDeHoje;
    final total = habitos.length;
    final concluidos = habitos.where((h) => h.concluidoHoje).length;
    final taxa = total == 0 ? 0.0 : (concluidos / total);
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Card de Progresso Diário de Hábitos
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: taxa == 1.0 && total > 0
                  ? (temaEscuro
                      ? [const Color(0xFF3A2D12), const Color(0xFF1F2B22)]
                      : [const Color(0xFFFFF8E1), const Color(0xFFE8F8F0)])
                  : [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: taxa == 1.0 && total > 0
                  ? const Color(0xFFFFB300).withValues(alpha: 0.65)
                  : Theme.of(context).colorScheme.outlineVariant,
              width: taxa == 1.0 && total > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: taxa == 1.0 && total > 0
                          ? const Color(0xFFFFB300).withValues(alpha: 0.22)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      taxa == 1.0 && total > 0
                          ? Icons.emoji_events_rounded
                          : Icons.stars_rounded,
                      color: taxa == 1.0 && total > 0
                          ? const Color(0xFFFFB300)
                          : Theme.of(context).colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taxa == 1.0 && total > 0
                              ? 'Dia Perfeito! 100% Concluído 🏆'
                              : 'Hábitos de Hoje ($concluidos/$total)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          taxa == 1.0 && total > 0
                              ? 'Parabéns! Todos os $total hábitos de hoje foram cumpridos.'
                              : '$concluidos de $total hábitos completados · ${(taxa * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final novo = await ModalEditarHabito.exibir(context);
                      if (novo != null && context.mounted) {
                        await provedor.salvarHabito(novo);
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Novo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: taxa,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    taxa == 1.0
                        ? const Color(0xFF00E676)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (habitos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.repeat_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum hábito programado para hoje',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie novos hábitos para hoje ou ajuste os dias da semana na aba Semana.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final novo = await ModalEditarHabito.exibir(context);
                      if (novo != null && context.mounted) {
                        await provedor.salvarHabito(novo);
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar Hábito'),
                  ),
                ],
              ),
            ),
          )
        else
          ...habitos.map((habito) {
            final cor = Color(habito.corValor);
            final feito = habito.concluidoHoje;
            final multiMeta = habito.metaValor > 1;
            final passo = habito.passoIncremento;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: feito ? 1 : 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onLongPress: () async {
                  final editado = await ModalEditarHabito.exibir(
                    context,
                    habito: habito,
                  );
                  if (editado != null && context.mounted) {
                    await provedor.salvarHabito(editado);
                  }
                },
                onTap: () {
                  if (habito.id == null) return;
                  if (multiMeta && !feito) {
                    provedor.incrementarProgressoHabito(habito, delta: passo);
                  } else {
                    provedor.alternarConclusaoHabito(habito.id!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Botão de conclusão com checkmark
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: feito ? cor : cor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    feito ? cor : cor.withValues(alpha: 0.35),
                                width: feito ? 2 : 1.5,
                              ),
                              boxShadow: feito
                                  ? [
                                      BoxShadow(
                                        color: cor.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              feito ? Icons.check_rounded : habito.icone,
                              color: feito ? Colors.white : cor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        habito.titulo,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          decoration: feito
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: feito
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        habito.categoria,
                                        style: TextStyle(
                                          color: cor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      multiMeta
                                          ? '${habito.progressoHoje} / ${habito.metaValor} ${habito.metaUnidade}'
                                          : 'Meta: ${habito.metaValor} ${habito.metaUnidade}/dia',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: multiMeta
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: multiMeta &&
                                                habito.progressoHoje > 0
                                            ? cor
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Color(0xFFFF6D00),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${habito.ofensivaAtual}d',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6D00),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (multiMeta) ...[
                            if (habito.progressoHoje > 0)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip:
                                    'Diminuir $passo ${habito.metaUnidade}',
                                onPressed: () =>
                                    provedor.incrementarProgressoHabito(
                                  habito,
                                  delta: -passo,
                                ),
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                            if (!feito)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip:
                                    'Adicionar +$passo ${habito.metaUnidade}',
                                onPressed: () =>
                                    provedor.incrementarProgressoHabito(
                                  habito,
                                  delta: passo,
                                ),
                                icon: Icon(
                                  Icons.add_circle_rounded,
                                  color: cor,
                                  size: 24,
                                ),
                              ),
                          ],
                          // Indicador de conclusão total
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip:
                                feito ? 'Desmarcar' : 'Concluir meta inteira',
                            onPressed: () {
                              if (habito.id != null) {
                                provedor.alternarConclusaoHabito(habito.id!);
                              }
                            },
                            icon: Icon(
                              feito
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: feito ? cor : Colors.grey,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      if (multiMeta) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habito.percentualHoje,
                            minHeight: 5,
                            backgroundColor: cor.withValues(alpha: 0.14),
                            valueColor: AlwaysStoppedAnimation<Color>(cor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SecaoDeTarefasHoje extends StatelessWidget {
  const _SecaoDeTarefasHoje({required this.provedor});

  final ProvedorDeTreino provedor;

  @override
  Widget build(BuildContext context) {
    final tarefas = provedor.tarefas;
    final pendentes = provedor.tarefasPendentes;
    final concluidas = provedor.tarefasConcluidas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${pendentes.length} pendentes · ${concluidas.length} concluídas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: () async {
                final nova = await ModalEditarTarefa.exibir(context);
                if (nova != null && context.mounted) {
                  await provedor.salvarTarefaToDo(nova);
                }
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nova Tarefa'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tarefas.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma tarefa pendente!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione tarefas e pendências rápidas para organizar seu dia a dia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final nova = await ModalEditarTarefa.exibir(context);
                      if (nova != null && context.mounted) {
                        await provedor.salvarTarefaToDo(nova);
                      }
                    },
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Nova Tarefa'),
                  ),
                ],
              ),
            ),
          )
        else
          ...tarefas.map((tarefa) {
            Color corPrioridade;
            String textoPrioridade;
            switch (tarefa.prioridade) {
              case 'alta':
                corPrioridade = const Color(0xFFFF5252);
                textoPrioridade = 'Alta';
                break;
              case 'baixa':
                corPrioridade = const Color(0xFF00E676);
                textoPrioridade = 'Baixa';
                break;
              default:
                corPrioridade = const Color(0xFFFFAB00);
                textoPrioridade = 'Média';
                break;
            }

            DateTime? deadline;
            if (tarefa.dataLimiteISO != null) {
              deadline = DateTime.tryParse(tarefa.dataLimiteISO!);
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Checkbox(
                  value: tarefa.concluida,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (val) {
                    if (tarefa.id != null) {
                      provedor.alternarConclusaoTarefa(
                        tarefa.id!,
                        val ?? false,
                      );
                    }
                  },
                ),
                title: Text(
                  tarefa.titulo,
                  style: TextStyle(
                    decoration:
                        tarefa.concluida ? TextDecoration.lineThrough : null,
                    color: tarefa.concluida
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: corPrioridade.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        textoPrioridade,
                        style: TextStyle(
                          color: corPrioridade,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tarefa.categoria,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (deadline != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('dd/MM/yyyy').format(deadline),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD63031),
                  ),
                  onPressed: () {
                    if (tarefa.id != null) {
                      provedor.excluirTarefaToDo(tarefa.id!);
                    }
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ModalCalculadoraEAquecimento extends StatefulWidget {
  const _ModalCalculadoraEAquecimento({
    required this.provedor,
    required this.exercicio,
  });

  final ProvedorDeTreino provedor;
  final ExercicioPlanejado exercicio;

  @override
  State<_ModalCalculadoraEAquecimento> createState() =>
      _ModalCalculadoraEAquecimentoState();
}

class _ModalCalculadoraEAquecimentoState
    extends State<_ModalCalculadoraEAquecimento> {
  late double _cargaAlvo;
  late int _repsAlvo;

  @override
  void initState() {
    super.initState();
    _cargaAlvo = widget.provedor.cargaAtual(widget.exercicio, 0);
    if (_cargaAlvo <= 0) _cargaAlvo = widget.exercicio.carga;
    _repsAlvo = widget.provedor.repeticoesAtuais(widget.exercicio, 0);
    if (_repsAlvo <= 0) _repsAlvo = widget.exercicio.repeticoes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final temaEscuro = theme.brightness == Brightness.dark;

    final umRm = CalculadoraDeCargas.estimar1RM(
      carga: _cargaAlvo,
      repeticoes: _repsAlvo,
    );
    final aquecimento = CalculadoraDeCargas.calcularAquecimento(
      cargaAlvo: _cargaAlvo,
    );
    final anilhasPorLado = CatalogoDeExerciciosOffline.calcularAnilhasPorLado(
      _cargaAlvo,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: temaEscuro
                  ? const Color(0xFF444451)
                  : const Color(0xFFDFE2E7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculadora de Treino & Cargas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.exercicio.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                if (_cargaAlvo <= 0) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 34,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Carga de treino não definida',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Defina uma carga acima de 0 kg nas séries deste exercício para calcular com precisão a estimativa de 1RM, a pirâmide progressiva de aquecimento e a divisão de anilhas da barra.',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Card 1: 1RM Estimado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: temaEscuro
                            ? [
                                cs.surfaceContainerHighest,
                                Color.lerp(cs.surfaceContainerHighest,
                                    cs.primary, 0.08)!,
                              ]
                            : [
                                cs.primary.withValues(alpha: 0.08),
                                cs.primary.withValues(alpha: 0.03),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '1RM Estimado (1 Rep Máxima)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${umRm.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Baseado na carga de ${_cargaAlvo.toStringAsFixed(1)} kg para $_repsAlvo reps (Fórmulas combinadas de Epley & Brzycki).',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chipPercentual1RM(
                                context, '95% (~2 reps)', umRm * 0.95),
                            _chipPercentual1RM(
                                context, '85% (~6 reps)', umRm * 0.85),
                            _chipPercentual1RM(
                                context, '75% (~10 reps)', umRm * 0.75),
                            _chipPercentual1RM(
                                context, '65% (~15 reps)', umRm * 0.65),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Pirâmide de Aquecimento
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFA726).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFFA726),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pirâmide de Aquecimento Científica',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Séries preparatórias graduais para evitar lesões e maximizar a força sem gerar fadiga:',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (aquecimento.isEmpty)
                          const Text(
                            'Defina uma carga acima de 0 kg para calcular a pirâmide de aquecimento.',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          ...aquecimento.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFA726).withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.percentual}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: Color(0xFFFFA726),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${item.cargaKg} kg × ${item.repeticoes} reps',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.descricao,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        if (aquecimento.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA726),
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.bolt_rounded, size: 20),
                              label: const Text(
                                'Inserir Rampa de Aquecimento (1-Toque)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: () async {
                                final sucesso = await widget.provedor
                                    .inserirRampaDeAquecimento(
                                        widget.exercicio);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        sucesso
                                            ? '⚡ ${aquecimento.length} séries de aquecimento adicionadas a ${widget.exercicio.nome}!'
                                            : 'Defina uma carga válida para calcular o aquecimento.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Anilhas da Barra Olímpica (20 kg)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: temaEscuro
                          ? const Color(0xFF20232E)
                          : const Color(0xFFF2F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00B8D4).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              color: Color(0xFF00B8D4),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Calculadora de Anilhas (Barra 20 kg)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_cargaAlvo < 20.0)
                          Text(
                            'Carga menor que 20 kg: use halteres ou barra leve de peso menor.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        else if (anilhasPorLado.anilhasPorLado.isEmpty)
                          Text(
                            'Carga de 20 kg: utilize apenas a barra olímpica vazia.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        else ...[
                          Text(
                            'Anilhas para colocar em CADA lado da barra:',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                anilhasPorLado.anilhasPorLado.map((anilha) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B8D4).withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF00B8D4).withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$anilha kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: Color(0xFF00B8D4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Card 4: Ajustar RPE (Esforço Percebido) das Séries
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Classificar RPE / RIR por Série',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RPE 10 = Falha total (RIR 0) · RPE 9 = Sobrou 1 rep · RPE 8 = Sobraram 2 reps',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(widget.exercicio.series, (i) {
                        final rpeAtual = widget.provedor.rpeDaSerie(
                          widget.exercicio,
                          i,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'Série ${i + 1}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [10.0, 9.0, 8.5, 8.0, 7.0].map((
                                      val,
                                    ) {
                                      final selecionado = rpeAtual == val;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            val == 10.0
                                                ? '10 (Falha)'
                                                : '@${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: selecionado
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                          selected: selecionado,
                                          selectedColor: cs.primary
                                              .withValues(alpha: 0.25),
                                          onSelected: (selected) {
                                            ServicoDeSomDoAlarme.instance
                                                .vibrarClique();
                                            widget.provedor.definirRpeDaSerie(
                                              widget.exercicio,
                                              i,
                                              selected ? val : null,
                                            );
                                            setState(() {});
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (_cargaAlvo > 0) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      double? rpeMedio;
                      var somaRpe = 0.0;
                      var qtdRpe = 0;
                      for (var i = 0; i < widget.exercicio.series; i++) {
                        final rpe = widget.provedor
                            .rpeDaSerie(widget.exercicio, i);
                        if (rpe != null) {
                          somaRpe += rpe;
                          qtdRpe++;
                        }
                      }
                      if (qtdRpe > 0) {
                        rpeMedio = somaRpe / qtdRpe;
                      }

                      final progressao = RecursosAvancados.progressao(
                        cargaKg: _cargaAlvo,
                        repeticoes: _repsAlvo,
                        alvoRepeticoes: widget.exercicio.repeticoes,
                        rpe: rpeMedio,
                      );

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: Color(0xFF00E676),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sobrecarga Progressiva Sugerida',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${progressao.cargaSugeridaKg.toStringAsFixed(1)} kg × ${progressao.repeticoesSugeridas} reps',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF00E676),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    progressao.motivo,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Aplicar Carga Sugerida'),
                                onPressed: () async {
                                  await widget.provedor
                                      .atualizarDetalhesDoExercicio(
                                    widget.exercicio,
                                    carga: progressao.cargaSugeridaKg,
                                    repeticoes:
                                        progressao.repeticoesSugeridas,
                                  );
                                  setState(() {
                                    _cargaAlvo = progressao.cargaSugeridaKg;
                                    _repsAlvo =
                                        progressao.repeticoesSugeridas;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Nova meta aplicada: ${progressao.cargaSugeridaKg} kg × ${progressao.repeticoesSugeridas} reps!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipPercentual1RM(
      BuildContext context, String rotulo, double valorKg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$rotulo: ${valorKg.toStringAsFixed(1)} kg',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
