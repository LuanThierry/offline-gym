import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../componentes/botao_de_perfil.dart';
import '../componentes/modal_catalogo_exercicios.dart';
import '../componentes/modal_editar_habito.dart';
import '../componentes/modal_editar_tarefa.dart';
import '../dominio/catalogo_exercicios_offline.dart';
import '../modelos/habito.dart';
import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../servicos/exportacao_relatorio.dart';
import '../servicos/som_do_alarme.dart';

enum _AbaSemana { treinos, habitos, tarefas }

class TelaDePlanos extends StatefulWidget {
  const TelaDePlanos({super.key});

  @override
  State<TelaDePlanos> createState() => _EstadoDaTelaDePlanos();
}

class _EstadoDaTelaDePlanos extends State<TelaDePlanos> {
  _AbaSemana _abaAtual = _AbaSemana.treinos;
  String _filtroCategoriaHabito = 'Todas';
  String _filtroStatusTarefa = 'todas';

  void _abrirModalExportacaoFicha(
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
                        Icons.description_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exportar Ficha de Treino',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Envie para o personal, médico ou imprima sua rotina.',
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
                  title: const Text('Ficha Semanal em PDF',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Documento nativo em PDF pronto para imprimir ou WhatsApp.'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ServicoDeExportacaoDeRelatorio.instance
                        .exportarFichaTreinoPDF(context, provedor);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined,
                      color: Colors.green),
                  title: const Text('Planilha de Treinos (CSV / Excel)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Tabela estruturada com séries, repetições e cargas.'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ServicoDeExportacaoDeRelatorio.instance
                        .exportarFichaTreinoCSV(context, provedor);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provedor = context.watch<ProvedorDeTreino>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _abaAtual == _AbaSemana.treinos
              ? 'Planos da semana'
              : _abaAtual == _AbaSemana.habitos
                  ? 'Hábitos & Rotina'
                  : 'Tarefas (To-Do)',
        ),
        actions: [
          if (_abaAtual == _AbaSemana.treinos)
            IconButton(
              tooltip: 'Exportar Ficha de Treinos (PDF / CSV)',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _abrirModalExportacaoFicha(context, provedor),
            ),
          const BotaoDePerfil(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  _ItemSegmentoSemana(
                    titulo: 'Treinos',
                    icone: Icons.fitness_center_rounded,
                    selecionado: _abaAtual == _AbaSemana.treinos,
                    onTap: () => setState(() => _abaAtual = _AbaSemana.treinos),
                  ),
                  _ItemSegmentoSemana(
                    titulo: 'Hábitos',
                    icone: Icons.stars_rounded,
                    selecionado: _abaAtual == _AbaSemana.habitos,
                    badge: provedor.habitos.isEmpty
                        ? null
                        : '${provedor.habitos.length}',
                    onTap: () => setState(() => _abaAtual = _AbaSemana.habitos),
                  ),
                  _ItemSegmentoSemana(
                    titulo: 'Tarefas',
                    icone: Icons.checklist_rounded,
                    selecionado: _abaAtual == _AbaSemana.tarefas,
                    badge: provedor.tarefasPendentes.isEmpty
                        ? null
                        : '${provedor.tarefasPendentes.length}',
                    onTap: () => setState(() => _abaAtual = _AbaSemana.tarefas),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _abaAtual == _AbaSemana.habitos
          ? FloatingActionButton.extended(
              heroTag: 'fab_novo_habito',
              onPressed: () => _adicionarHabito(context, provedor),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Hábito'),
            )
          : _abaAtual == _AbaSemana.tarefas
              ? FloatingActionButton.extended(
                  heroTag: 'fab_nova_tarefa',
                  onPressed: () => _adicionarTarefa(context, provedor),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Nova Tarefa'),
                )
              : null,
      body: Builder(
        builder: (context) {
          if (!provedor.inicializado && provedor.ultimoErro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(provedor.ultimoErro!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provedor.tentarInicializacaoNovamente,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          switch (_abaAtual) {
            case _AbaSemana.treinos:
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, indice) {
                  final diaSemana = indice + 1;
                  final rotinas = provedor.rotinasDoDia(diaSemana);
                  return _CartaoDoPlanoDoDia(
                    diaSemana: diaSemana,
                    rotinas: rotinas,
                    onPressed: () => _gerenciarDia(context, diaSemana),
                  );
                },
              );
            case _AbaSemana.habitos:
              return _SecaoDeHabitosSemana(
                provedor: provedor,
                categoriaSelecionada: _filtroCategoriaHabito,
                aoMudarCategoria: (cat) =>
                    setState(() => _filtroCategoriaHabito = cat),
                aoCriarHabito: () => _adicionarHabito(context, provedor),
                aoEditarHabito: (h) => _editarHabito(context, provedor, h),
                aoExcluirHabito: (h) => _excluirHabito(context, provedor, h),
              );
            case _AbaSemana.tarefas:
              return _SecaoDeTarefasSemana(
                provedor: provedor,
                filtroStatus: _filtroStatusTarefa,
                aoMudarFiltro: (status) =>
                    setState(() => _filtroStatusTarefa = status),
                aoCriarTarefa: () => _adicionarTarefa(context, provedor),
                aoEditarTarefa: (t) => _editarTarefa(context, provedor, t),
                aoExcluirTarefa: (t) => _excluirTarefa(context, provedor, t),
              );
          }
        },
      ),
    );
  }

  Future<void> _adicionarHabito(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    final novo = await ModalEditarHabito.exibir(context);
    if (novo != null && context.mounted) {
      await provedor.salvarHabito(novo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hábito "${novo.titulo}" criado!')),
        );
      }
    }
  }

  Future<void> _editarHabito(
    BuildContext context,
    ProvedorDeTreino provedor,
    Habito habito,
  ) async {
    final editado = await ModalEditarHabito.exibir(context, habito: habito);
    if (editado != null && context.mounted) {
      await provedor.salvarHabito(editado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hábito "${editado.titulo}" atualizado!')),
        );
      }
    }
  }

  Future<void> _excluirHabito(
    BuildContext context,
    ProvedorDeTreino provedor,
    Habito habito,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir hábito?'),
        content: Text(
          'Deseja realmente excluir "${habito.titulo}"? O histórico deste hábito será apagado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD63031),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && habito.id != null) {
      await provedor.excluirHabito(habito.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábito excluído.')),
        );
      }
    }
  }

  Future<void> _adicionarTarefa(
    BuildContext context,
    ProvedorDeTreino provedor,
  ) async {
    final nova = await ModalEditarTarefa.exibir(context);
    if (nova != null && context.mounted) {
      await provedor.salvarTarefaToDo(nova);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarefa "${nova.titulo}" criada!')),
        );
      }
    }
  }

  Future<void> _editarTarefa(
    BuildContext context,
    ProvedorDeTreino provedor,
    TarefaToDo tarefa,
  ) async {
    final editada = await ModalEditarTarefa.exibir(context, tarefa: tarefa);
    if (editada != null && context.mounted) {
      await provedor.salvarTarefaToDo(editada);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarefa "${editada.titulo}" atualizada!')),
        );
      }
    }
  }

  Future<void> _excluirTarefa(
    BuildContext context,
    ProvedorDeTreino provedor,
    TarefaToDo tarefa,
  ) async {
    if (tarefa.id == null) return;
    await provedor.excluirTarefaToDo(tarefa.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa removida.')),
      );
    }
  }

  Future<void> _gerenciarDia(BuildContext context, int diaSemana) async {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: PainelDeRotinasDoDia(diaSemana: diaSemana),
      ),
    );
    if (context.mounted) {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }
  }
}

class _ItemSegmentoSemana extends StatelessWidget {
  const _ItemSegmentoSemana({
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

class _SecaoDeHabitosSemana extends StatelessWidget {
  const _SecaoDeHabitosSemana({
    required this.provedor,
    required this.categoriaSelecionada,
    required this.aoMudarCategoria,
    required this.aoCriarHabito,
    required this.aoEditarHabito,
    required this.aoExcluirHabito,
  });

  final ProvedorDeTreino provedor;
  final String categoriaSelecionada;
  final ValueChanged<String> aoMudarCategoria;
  final VoidCallback aoCriarHabito;
  final ValueChanged<Habito> aoEditarHabito;
  final ValueChanged<Habito> aoExcluirHabito;

  @override
  Widget build(BuildContext context) {
    final todosHabitos = provedor.habitos;
    final habitosFiltrados = categoriaSelecionada == 'Todas'
        ? todosHabitos
        : todosHabitos
            .where((h) => h.categoria == categoriaSelecionada)
            .toList(growable: false);
    final categorias = ['Todas', ...PaletaCoresHabito.categoriasPadrao];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Estatísticas Rápidas de Hábitos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hábitos Ativos (${todosHabitos.where((h) => h.ativo).length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Hoje: ${provedor.habitosConcluidosHoje}/${provedor.totalHabitosDeHoje} concluídos · ${(provedor.taxaConclusaoHabitosHoje * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                  value: provedor.taxaConclusaoHabitosHoje,
                  minHeight: 7,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filtro de Categorias
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categorias.map((cat) {
              final selected = cat == categoriaSelecionada;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => aoMudarCategoria(cat),
                ),
              );
            }).toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),

        if (habitosFiltrados.isEmpty)
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
                      Icons.stars_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    todosHabitos.isEmpty
                        ? 'Comece sua jornada de hábitos!'
                        : 'Nenhum hábito nesta categoria.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todosHabitos.isEmpty
                        ? 'Crie hábitos saudáveis como beber água, tomar creatina, leitura ou mobilidade para manter sua sequência diária.'
                        : 'Altere o filtro acima ou crie um novo hábito nesta categoria.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: aoCriarHabito,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Novo Hábito'),
                  ),
                ],
              ),
            ),
          )
        else
          ...habitosFiltrados.map((habito) {
            final cor = Color(habito.corValor);
            final diasNomes = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => aoEditarHabito(habito),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(habito.icone, color: cor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        habito.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        habito.categoria,
                                        style: TextStyle(
                                          color: cor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (habito.descricao.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    habito.descricao,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções do hábito',
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (val) {
                              if (val == 'editar') {
                                aoEditarHabito(habito);
                              } else if (val == 'pausar') {
                                provedor.salvarHabito(
                                  habito.copiarCom(ativo: !habito.ativo),
                                );
                              } else if (val == 'excluir') {
                                aoExcluirHabito(habito);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'pausar',
                                child: Row(
                                  children: [
                                    Icon(
                                      habito.ativo
                                          ? Icons.pause_circle_outline
                                          : Icons.play_circle_outline,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      habito.ativo ? 'Pausar' : 'Reativar',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFD63031),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(
                                        color: Color(0xFFD63031),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dias da semana
                          Row(
                            children: List.generate(7, (i) {
                              final diaSemana = i + 1;
                              final aplica = habito.seAplicaAoDia(diaSemana);
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: aplica
                                      ? cor.withValues(alpha: 0.18)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: aplica
                                        ? cor
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  diasNomes[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: aplica
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: aplica
                                        ? cor
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                              );
                            }),
                          ),
                          // Meta diária + Streak badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${habito.metaValor} ${habito.metaUnidade}/dia',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFFF6D00),
                                size: 18,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${habito.ofensivaAtual}d',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFFFF6D00),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _SecaoDeTarefasSemana extends StatelessWidget {
  const _SecaoDeTarefasSemana({
    required this.provedor,
    required this.filtroStatus,
    required this.aoMudarFiltro,
    required this.aoCriarTarefa,
    required this.aoEditarTarefa,
    required this.aoExcluirTarefa,
  });

  final ProvedorDeTreino provedor;
  final String filtroStatus;
  final ValueChanged<String> aoMudarFiltro;
  final VoidCallback aoCriarTarefa;
  final ValueChanged<TarefaToDo> aoEditarTarefa;
  final ValueChanged<TarefaToDo> aoExcluirTarefa;

  @override
  Widget build(BuildContext context) {
    final todasTarefas = provedor.tarefas;
    final pendentes = provedor.tarefasPendentes;
    final concluidas = provedor.tarefasConcluidas;

    final tarefasExibidas = filtroStatus == 'pendentes'
        ? pendentes
        : filtroStatus == 'concluidas'
            ? concluidas
            : todasTarefas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Filtro de status sem overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text('Todas (${todasTarefas.length})'),
                selected: filtroStatus == 'todas',
                onSelected: (_) => aoMudarFiltro('todas'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text('Pendentes (${pendentes.length})'),
                selected: filtroStatus == 'pendentes',
                onSelected: (_) => aoMudarFiltro('pendentes'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text('Concluídas (${concluidas.length})'),
                selected: filtroStatus == 'concluidas',
                onSelected: (_) => aoMudarFiltro('concluidas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (tarefasExibidas.isEmpty)
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
                  Text(
                    filtroStatus == 'pendentes'
                        ? 'Tudo feito por aqui! 🎉'
                        : 'Nenhuma tarefa encontrada.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione tarefas rápidas, metas de suplementação ou lembretes diários para manter o foco total.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: aoCriarTarefa,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Nova Tarefa'),
                  ),
                ],
              ),
            ),
          )
        else
          ...tarefasExibidas.map((tarefa) {
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
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
                ),
                title: Text(
                  tarefa.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration:
                        tarefa.concluida ? TextDecoration.lineThrough : null,
                    color: tarefa.concluida
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
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
                trailing: PopupMenuButton<String>(
                  tooltip: 'Opções',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'editar') {
                      aoEditarTarefa(tarefa);
                    } else if (val == 'excluir') {
                      aoExcluirTarefa(tarefa);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Color(0xFFD63031),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Excluir',
                            style: TextStyle(color: Color(0xFFD63031)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CartaoDoPlanoDoDia extends StatelessWidget {
  const _CartaoDoPlanoDoDia({
    required this.diaSemana,
    required this.rotinas,
    required this.onPressed,
  });

  final int diaSemana;
  final List<RotinaDeTreino> rotinas;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasRoutines = rotinas.isNotEmpty;
    final exerciseCount = rotinas.fold<int>(
      0,
      (total, rotina) => total + rotina.exercicios.length,
    );
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      ExercicioPlanejado.nomeDoDiaDaSemana(
                        diaSemana,
                      ).substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ExercicioPlanejado.nomeDoDiaDaSemana(diaSemana),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: hasRoutines
                          ? colorScheme.primary.withValues(
                              alpha: temaEscuro ? 0.14 : 0.08,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasRoutines
                            ? colorScheme.primary.withValues(alpha: 0.45)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      hasRoutines
                          ? '${rotinas.length} ${rotinas.length == 1 ? 'treino' : 'treinos'}'
                          : 'Dia de descanso 🧘',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasRoutines)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Descanso / Recuperação ativa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    ...rotinas.take(3).map((rotina) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${rotina.nome} · ${rotina.exercicios.length} ex.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                    if (rotinas.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '+${rotinas.length - 3}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    hasRoutines ? Icons.tune_rounded : Icons.add_circle_outline,
                    size: 17,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    hasRoutines
                        ? 'Gerenciar treinos · $exerciseCount exercícios'
                        : 'Criar treino para este dia',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PainelDeRotinasDoDia extends StatelessWidget {
  const PainelDeRotinasDoDia({super.key, required this.diaSemana});

  final int diaSemana;

  Future<void> _editarRotina(
    BuildContext context,
    RotinaDeTreino? rotina,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: PainelDeEdicaoDoPlanoDoDia(
          diaSemana: diaSemana,
          rotinaInicial: rotina,
        ),
      ),
    );
    if (context.mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  Future<void> _excluirRotina(
    BuildContext context,
    ProvedorDeTreino provedor,
    RotinaDeTreino rotina,
  ) async {
    final id = rotina.id;
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: Text('“${rotina.nome}” e seus exercícios serão removidos.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      await provedor.excluirRotinaDeTreino(diaSemana, id);
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeDoDia = ExercicioPlanejado.nomeDoDiaDaSemana(diaSemana);
    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final rotinas = provedor.rotinasDoDia(diaSemana);
        return SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            nomeDoDia,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Marque os treinos que quer fazer neste dia.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: rotinas.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.self_improvement_rounded,
                                  size: 34,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Dia de Descanso & Recuperação 🧘',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'O descanso é parte fundamental do ganho muscular e prevenção de lesões. Não é obrigatório treinar todos os dias!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Boas práticas para o descanso:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '💧 Beba água suficiente para hidratar seus tecidos musculares',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '🧘 Faça alongamentos suaves ou caminhada leve',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '🥗 Mantenha sua ingestão proteica e tenha uma boa noite de sono',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Caso queira treinar neste dia, toque no botão abaixo:',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: rotinas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, indice) {
                          final rotina = rotinas[indice];
                          final id = rotina.id;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Checkbox.adaptive(
                                    value: rotina.selecionado,
                                    onChanged: id == null ||
                                            (provedor.sessaoAtiva &&
                                                provedor.diaDaSessao ==
                                                    diaSemana)
                                        ? null
                                        : (selected) async {
                                            final ids = rotinas
                                                .where(
                                                  (item) => item.selecionado,
                                                )
                                                .map((item) => item.id!)
                                                .toSet();
                                            if (selected == true) {
                                              ids.add(id);
                                            } else {
                                              ids.remove(id);
                                            }
                                            try {
                                              await provedor
                                                  .definirRotinasSelecionadas(
                                                diaSemana,
                                                ids,
                                              );
                                            } catch (erro) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Não foi possível atualizar a seleção: $erro',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _editarRotina(context, rotina),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              rotina.nome,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${rotina.exercicios.length} exercícios',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () =>
                                        _editarRotina(context, rotina),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir',
                                    onPressed: () => _excluirRotina(
                                      context,
                                      provedor,
                                      rotina,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final modelo = await ModalCatalogoExercicios
                              .selecionarModeloPronto(
                            context,
                          );
                          if (modelo == null || !context.mounted) return;
                          try {
                            await provedor.salvarRotinaDeTreino(
                              RotinaDeTreino(
                                diaSemana: diaSemana,
                                nome: modelo.nome,
                                selecionado: true,
                                exercicios: modelo.exercicios
                                    .map(
                                      (e) =>
                                          e.paraExercicioPlanejado(diaSemana),
                                    )
                                    .toList(growable: false),
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Modelo “${modelo.nome}” adicionado!',
                                  ),
                                ),
                              );
                            }
                          } catch (erro) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Não foi possível importar o modelo: $erro',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text(
                          'Importar Modelo Pronto (Academia / Casa / Calistenia)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _editarRotina(context, null),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar treino personalizado'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PainelDeEdicaoDoPlanoDoDia extends StatefulWidget {
  const PainelDeEdicaoDoPlanoDoDia({
    super.key,
    required this.diaSemana,
    this.rotinaInicial,
  });

  final int diaSemana;
  final RotinaDeTreino? rotinaInicial;

  @override
  State<PainelDeEdicaoDoPlanoDoDia> createState() =>
      _EstadoDoPainelDeEdicaoDoPlano();
}

class _EstadoDoPainelDeEdicaoDoPlano extends State<PainelDeEdicaoDoPlanoDoDia>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _routineNameController = TextEditingController();
  late final AnimationController _draftMoveController;
  _RascunhoDeExercicio? _movingDraft;
  Animation<Offset>? _draftMoveAnimation;
  late List<_RascunhoDeExercicio> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draftMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _movingDraft = null;
            _draftMoveAnimation = null;
          });
        }
      });
    _routineNameController.text = widget.rotinaInicial?.nome ?? '';
    _drafts = (widget.rotinaInicial?.exercicios ?? const <ExercicioPlanejado>[])
        .map(_RascunhoDeExercicio.fromPlan)
        .toList();
    if (_drafts.isEmpty) _drafts.add(_RascunhoDeExercicio.empty());
  }

  @override
  void dispose() {
    _draftMoveController.dispose();
    _routineNameController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _adicionarRascunho() =>
      setState(() => _drafts.add(_RascunhoDeExercicio.empty()));

  Future<void> _escolherVariosDoCatalogo() async {
    if (_saving) return;
    final escolhidos = await ModalCatalogoExercicios.selecionarMultiplos(
      context,
    );
    if (escolhidos == null || escolhidos.isEmpty || !mounted) return;
    setState(() {
      if (_drafts.length == 1 &&
          _drafts.first.nameController.text.trim().isEmpty) {
        final antigo = _drafts.removeAt(0);
        WidgetsBinding.instance.addPostFrameCallback((_) => antigo.dispose());
      }
      for (final item in escolhidos) {
        _drafts.add(
          _RascunhoDeExercicio.fromPlan(
            item.paraExercicioPlanejado(widget.diaSemana),
          ),
        );
      }
    });
  }

  Future<void> _escolherUnicoDoCatalogo(int indice) async {
    if (_saving || indice < 0 || indice >= _drafts.length) return;
    final item = await ModalCatalogoExercicios.selecionarUnico(context);
    if (item == null || !mounted) return;
    final draft = _drafts[indice];
    setState(() {
      draft.nameController.text = item.nome;
      draft.loadController.text = _RascunhoDeExercicio._textoNumerico(
        item.cargaSugeridaKg,
      );
      draft.seriesController.text = item.seriesSugeridas.toString();
      draft.repetitionsController.text = item.repeticoesSugeridas.toString();
      draft.tempoDescansoSegundos = item.descansoSugeridoSegundos;
    });
  }

  Future<void> _aplicarModeloPronto() async {
    if (_saving) return;
    final modelo = await ModalCatalogoExercicios.selecionarModeloPronto(
      context,
    );
    if (modelo == null || !mounted) return;
    setState(() {
      if (_routineNameController.text.trim().isEmpty) {
        _routineNameController.text = modelo.nome;
      }
      if (_drafts.length == 1 &&
          _drafts.first.nameController.text.trim().isEmpty) {
        final antigo = _drafts.removeAt(0);
        WidgetsBinding.instance.addPostFrameCallback((_) => antigo.dispose());
      }
      for (final ex in modelo.exercicios) {
        _drafts.add(
          _RascunhoDeExercicio.fromPlan(
            ex.paraExercicioPlanejado(widget.diaSemana),
          ),
        );
      }
    });
  }

  void _removerRascunho(int indice) {
    late final _RascunhoDeExercicio removed;
    setState(() => removed = _drafts.removeAt(indice));
    // Aguarda os campos saírem da árvore antes de descartar seus controladores.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _moverRascunho(int indice, int deslocamento) {
    final destination = indice + deslocamento;
    if (_saving || indice < 0 || indice >= _drafts.length) return;
    if (destination < 0 || destination >= _drafts.length) return;
    final movedDraft = _drafts[indice];
    final reduzirAnimacoes = MediaQuery.of(context).disableAnimations;
    _draftMoveController.stop();
    setState(() {
      _drafts.removeAt(indice);
      _drafts.insert(destination, movedDraft);
      _movingDraft = reduzirAnimacoes ? null : movedDraft;
      _draftMoveAnimation = reduzirAnimacoes
          ? null
          : Tween<Offset>(
              begin: Offset(0, deslocamento < 0 ? 1.04 : -1.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _draftMoveController,
                curve: Curves.easeOutCubic,
              ),
            );
    });
    if (!reduzirAnimacoes) _draftMoveController.forward(from: 0);
  }

  Future<void> _escolherImagem(int indice) async {
    final draft = _drafts[indice];
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      const imageType = XTypeGroup(
        label: 'Imagem do exercício',
        extensions: <String>['gif', 'png', 'jpg', 'jpeg', 'webp'],
        mimeTypes: <String>[
          'image/gif',
          'image/png',
          'image/jpeg',
          'image/webp',
        ],
      );
      final picked = await openFile(
        acceptedTypeGroups: <XTypeGroup>[imageType],
      );
      if (picked == null || !mounted) return;

      final extension = p
          .extension(picked.name.isNotEmpty ? picked.name : picked.path)
          .toLowerCase();
      const allowedExtensions = <String>{
        '.gif',
        '.png',
        '.jpg',
        '.jpeg',
        '.webp',
      };
      if (!allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escolha um arquivo GIF, PNG, JPG, JPEG ou WEBP.'),
          ),
        );
        return;
      }

      final fileSize = await picked.length();
      if (!mounted) return;
      const maxBytes = 15 * 1024 * 1024;
      if (fileSize > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O arquivo deve ter no máximo 15 MB.')),
        );
        return;
      }
      if (fileSize == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O arquivo selecionado está vazio.')),
        );
        return;
      }

      final documents = await getApplicationDocumentsDirectory();
      final mediaDirectory = Directory(p.join(documents.path, 'exercise_gifs'));
      await mediaDirectory.create(recursive: true);
      final nomeDoArquivo =
          'exercise_${DateTime.now().microsecondsSinceEpoch}$extension';
      final destination = File(p.join(mediaDirectory.path, nomeDoArquivo));
      await destination.writeAsBytes(await picked.readAsBytes(), flush: true);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();

      setState(() {
        draft.caminhoLocalGif = destination.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem salva no celular para uso offline.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a imagem: $erro')),
      );
    }
  }

  Future<void> _salvar() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final exercicioVazio = _drafts.indexWhere(
      (d) => d.nameController.text.trim().isEmpty,
    );
    if (exercicioVazio >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione o exercício #${exercicioVazio + 1} na biblioteca antes de salvar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final exercicios = _drafts.map((draft) {
      final parsedLoad = double.tryParse(
            draft.loadController.text.trim().replaceAll(',', '.'),
          ) ??
          0;
      final quantidadeDeSeries =
          int.tryParse(draft.seriesController.text.trim()) ?? 3;
      final original = draft.modeloOriginal;
      final parsedReps =
          int.tryParse(draft.repetitionsController.text.trim()) ?? 10;
      final mudouCarga =
          original != null && (original.carga - parsedLoad).abs() > 0.001;
      final mudouReps = original != null && original.repeticoes != parsedReps;
      return ExercicioPlanejado(
        id: original?.id,
        diaSemana: widget.diaSemana,
        nome: draft.nameController.text.trim(),
        carga: parsedLoad,
        series: quantidadeDeSeries,
        repeticoes: parsedReps,
        tempoDescansoSegundos: draft.tempoDescansoSegundos,
        cargasPorSerie:
            original == null || original.cargasPorSerie.isEmpty || mudouCarga
                ? const <double>[]
                : List<double>.generate(
                    quantidadeDeSeries,
                    (indice) => indice < original.series
                        ? original.cargaDaSerie(indice)
                        : parsedLoad,
                  ),
        repeticoesPorSerie:
            original == null || original.repeticoesPorSerie.isEmpty || mudouReps
                ? const <int>[]
                : List<int>.generate(
                    quantidadeDeSeries,
                    (indice) => indice < original.series
                        ? original.repeticoesDaSerie(indice)
                        : parsedReps,
                  ),
        // Mantém o exercício offline e não reaproveita URLs antigas de GIF.
        urlGif: null,
        caminhoLocalGif: draft.caminhoLocalGif,
        grupoSuperSerie: draft.grupoSuperSerie,
      );
    }).toList(growable: false);

    try {
      await context.read<ProvedorDeTreino>().salvarRotinaDeTreino(
            RotinaDeTreino(
              id: widget.rotinaInicial?.id,
              diaSemana: widget.diaSemana,
              nome: _routineNameController.text.trim(),
              selecionado: widget.rotinaInicial?.selecionado ?? true,
              exercicios: exercicios,
            ),
          );
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.of(context).pop(true);
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o treino: $erro')),
      );
    }
  }

  Widget _construirSeletorDeNome(
    int itemIndex,
    _RascunhoDeExercicio draft,
    ColorScheme cs,
  ) {
    final nome = draft.nameController.text.trim();
    final vazio = nome.isEmpty;
    final grupo =
        vazio ? '' : CatalogoDeExerciciosOffline.identificarGrupoMuscular(nome);
    final icone = vazio
        ? Icons.search_rounded
        : CatalogoDeExerciciosOffline.iconeDoExercicio(nome);

    return InkWell(
      onTap: _saving ? null : () => _escolherUnicoDoCatalogo(itemIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: vazio
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: vazio
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: vazio ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    vazio ? 'Selecione o exercício...' : nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: vazio ? FontWeight.w600 : FontWeight.w800,
                      color: vazio ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vazio
                        ? 'Toque para escolher da biblioteca (+2.000)'
                        : grupo,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    vazio
                        ? Icons.library_books_rounded
                        : Icons.swap_horiz_rounded,
                    size: 14,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vazio ? 'Catálogo' : 'Trocar',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirRodapeExercicio(
    int itemIndex,
    _RascunhoDeExercicio draft,
    bool hasSavedImage,
    ColorScheme cs,
  ) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#${itemIndex + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Mover exercício para cima',
          onPressed: _saving || itemIndex == 0
              ? null
              : () => _moverRascunho(itemIndex, -1),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_upward_rounded, size: 19),
        ),
        IconButton(
          tooltip: 'Mover exercício para baixo',
          onPressed: _saving || itemIndex == _drafts.length - 1
              ? null
              : () => _moverRascunho(itemIndex, 1),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_downward_rounded, size: 19),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _saving
              ? null
              : () {
                  ServicoDeSomDoAlarme.instance.vibrarClique();
                  setState(() {
                    final atual = draft.grupoSuperSerie;
                    if (atual == null) {
                      draft.grupoSuperSerie = 'A';
                    } else if (atual == 'A') {
                      draft.grupoSuperSerie = 'B';
                    } else if (atual == 'B') {
                      draft.grupoSuperSerie = 'C';
                    } else {
                      draft.grupoSuperSerie = null;
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: draft.grupoSuperSerie != null
                  ? cs.primary.withValues(alpha: 0.16)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: draft.grupoSuperSerie != null
                    ? cs.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 15,
                  color: draft.grupoSuperSerie != null
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  draft.grupoSuperSerie != null
                      ? 'Bi-set ${draft.grupoSuperSerie}'
                      : 'Bi-set',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: draft.grupoSuperSerie != null
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          tooltip:
              hasSavedImage ? 'Trocar foto ou GIF' : 'Adicionar foto ou GIF',
          onPressed: _saving ? null : () => _escolherImagem(itemIndex),
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          icon: Icon(
            hasSavedImage
                ? Icons.image_rounded
                : Icons.add_photo_alternate_outlined,
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remover exercício',
          onPressed: _saving ? null : () => _removerRascunho(itemIndex),
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFE74C3C),
            size: 20,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeDoDia = ExercicioPlanejado.nomeDoDiaDaSemana(widget.diaSemana);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        nomeDoDia,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deslize ou toque em Carga, Séries e Reps para ajustar.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(context).pop(false);
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextFormField(
                      controller: _routineNameController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome deste treino',
                        hintText: 'Ex.: Peito e tríceps',
                        prefixIcon: Icon(Icons.fitness_center_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Digite um nome para o treino.'
                              : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed:
                                _saving ? null : _escolherVariosDoCatalogo,
                            icon:
                                const Icon(Icons.library_add_rounded, size: 18),
                            label: Text(
                              '+ Vários do Catálogo (+${CatalogoDeExerciciosOffline.todosOsExercicios.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _aplicarModeloPronto,
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              '15 Modelos Prontos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: _drafts.length,
                      findChildIndexCallback: (key) {
                        if (key is ObjectKey) {
                          final indice = _drafts.indexWhere(
                            (draft) => identical(draft, key.value),
                          );
                          return indice < 0 ? null : indice;
                        }
                        return null;
                      },
                      itemBuilder: (context, itemIndex) {
                        final draft = _drafts[itemIndex];
                        final hasSavedImage = draft.caminhoLocalGif != null &&
                            File(draft.caminhoLocalGif!).existsSync();
                        return Padding(
                          key: ObjectKey(draft),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedBuilder(
                            animation: _draftMoveController,
                            child: Card(
                              elevation:
                                  identical(_movingDraft, draft) ? 8 : null,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // 1. Seletor do Exercício da Biblioteca Offline (+2.000)
                                    _construirSeletorDeNome(
                                      itemIndex,
                                      draft,
                                      Theme.of(context).colorScheme,
                                    ),
                                    const SizedBox(height: 10),
                                    _LinhaMedidasDeslizaveisExercicioPlano(
                                      draft: draft,
                                      indiceExercicio: itemIndex + 1,
                                      habilitado: !_saving,
                                      aoAlterar: () => setState(() {}),
                                    ),
                                    if (hasSavedImage) ...<Widget>[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: <Widget>[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: SizedBox(
                                              width: 58,
                                              height: 58,
                                              child: Image.file(
                                                File(draft.caminhoLocalGif!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    ColoredBox(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Imagem salva no celular',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _saving
                                                ? null
                                                : () => setState(() {
                                                      draft.caminhoLocalGif =
                                                          null;
                                                    }),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    _construirRodapeExercicio(
                                      itemIndex,
                                      draft,
                                      hasSavedImage,
                                      Theme.of(context).colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            builder: (context, child) {
                              final moveAnimation =
                                  identical(_movingDraft, draft)
                                      ? _draftMoveAnimation
                                      : null;
                              if (moveAnimation == null) return child!;
                              return FractionalTranslation(
                                translation: moveAnimation.value,
                                transformHitTests: false,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _adicionarRascunho,
                    child: const Text('Adicionar Mais'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _salvar,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Salvando...' : 'Concluído'),
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

class _LinhaMedidasDeslizaveisExercicioPlano extends StatelessWidget {
  const _LinhaMedidasDeslizaveisExercicioPlano({
    required this.draft,
    required this.indiceExercicio,
    required this.habilitado,
    required this.aoAlterar,
  });

  final _RascunhoDeExercicio draft;
  final int indiceExercicio;
  final bool habilitado;
  final VoidCallback aoAlterar;

  double get _cargaAtual =>
      double.tryParse(
        draft.loadController.text.trim().replaceAll(',', '.'),
      ) ??
      0;

  int get _seriesAtuais =>
      (int.tryParse(draft.seriesController.text.trim()) ?? 3).clamp(1, 30);

  int get _repsAtuais =>
      (int.tryParse(draft.repetitionsController.text.trim()) ?? 10)
          .clamp(1, 100);

  static String _formatarCarga(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);

  Future<void> _abrirModalRoleta(BuildContext context) async {
    if (!habilitado) return;
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    final resultado = await _ModalSeletorDeslizanteExercicioPlano.exibir(
      context,
      nomeExercicio: draft.nameController.text.trim().isEmpty
          ? 'Exercício $indiceExercicio'
          : draft.nameController.text.trim(),
      cargaInicialKg: _cargaAtual,
      seriesIniciais: _seriesAtuais,
      repeticoesIniciais: _repsAtuais,
    );
    if (resultado != null) {
      draft.loadController.text = _formatarCarga(resultado.cargaKg);
      draft.seriesController.text = resultado.series.toString();
      draft.repetitionsController.text = resultado.repeticoes.toString();
      aoAlterar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cargaTxt =
        _cargaAtual <= 0 ? 'Livre' : '${_formatarCarga(_cargaAtual)} kg';

    return InkWell(
      onTap: habilitado ? () => _abrirModalRoleta(context) : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.tune_rounded, size: 19, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '$_seriesAtuais ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: 'séries   •   ',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    TextSpan(
                      text: '$_repsAtuais ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: 'reps   •   ',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ajustar',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 14,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoMedidasPlano {
  const _ResultadoMedidasPlano({
    required this.cargaKg,
    required this.series,
    required this.repeticoes,
  });

  final double cargaKg;
  final int series;
  final int repeticoes;
}

class _ModalSeletorDeslizanteExercicioPlano extends StatefulWidget {
  const _ModalSeletorDeslizanteExercicioPlano({
    required this.nomeExercicio,
    required this.cargaInicialKg,
    required this.seriesIniciais,
    required this.repeticoesIniciais,
  });

  final String nomeExercicio;
  final double cargaInicialKg;
  final int seriesIniciais;
  final int repeticoesIniciais;

  static Future<_ResultadoMedidasPlano?> exibir(
    BuildContext context, {
    required String nomeExercicio,
    required double cargaInicialKg,
    required int seriesIniciais,
    required int repeticoesIniciais,
  }) {
    return showModalBottomSheet<_ResultadoMedidasPlano>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalSeletorDeslizanteExercicioPlano(
        nomeExercicio: nomeExercicio,
        cargaInicialKg: cargaInicialKg,
        seriesIniciais: seriesIniciais,
        repeticoesIniciais: repeticoesIniciais,
      ),
    );
  }

  @override
  State<_ModalSeletorDeslizanteExercicioPlano> createState() =>
      _EstadoDoModalSeletorDeslizanteExercicioPlano();
}

class _EstadoDoModalSeletorDeslizanteExercicioPlano
    extends State<_ModalSeletorDeslizanteExercicioPlano> {
  static final List<int> _opcoesCargaKg = <int>[
    0,
    for (int kg = 5; kg <= 900; kg += 5) kg,
  ];

  late int _indiceCargaSelecionada;
  late int _seriesSelecionadas;
  late int _repeticoesSelecionadas;

  late FixedExtentScrollController _cargaScrollController;
  late FixedExtentScrollController _seriesScrollController;
  late FixedExtentScrollController _repsScrollController;

  @override
  void initState() {
    super.initState();
    if (widget.cargaInicialKg <= 0) {
      _indiceCargaSelecionada = 0;
    } else {
      final kgArredondado =
          ((widget.cargaInicialKg / 5).round() * 5).clamp(5, 900);
      _indiceCargaSelecionada = (kgArredondado ~/ 5).clamp(
        1,
        _opcoesCargaKg.length - 1,
      );
    }
    _seriesSelecionadas = widget.seriesIniciais.clamp(1, 30);
    _repeticoesSelecionadas = widget.repeticoesIniciais.clamp(1, 100);

    _cargaScrollController = FixedExtentScrollController(
      initialItem: _indiceCargaSelecionada,
    );
    _seriesScrollController = FixedExtentScrollController(
      initialItem: _seriesSelecionadas - 1,
    );
    _repsScrollController = FixedExtentScrollController(
      initialItem: _repeticoesSelecionadas - 1,
    );
  }

  @override
  void dispose() {
    _cargaScrollController.dispose();
    _seriesScrollController.dispose();
    _repsScrollController.dispose();
    super.dispose();
  }

  int get _cargaSelecionadaKg => _opcoesCargaKg[_indiceCargaSelecionada];

  void _irParaIndiceCarga(int novoIndice) {
    final clamped = novoIndice.clamp(0, _opcoesCargaKg.length - 1);
    if (clamped == _indiceCargaSelecionada) return;
    _cargaScrollController.animateToItem(
      clamped,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
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
            widget.nomeExercicio,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Deslize as roletas de Carga (5 em 5 kg), Séries (1–30) e Reps (1–100)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              // Coluna Carga (0 kg ou 5 em 5 kg até 900 kg)
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      'CARGA (KG)',
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
                          setState(() => _indiceCargaSelecionada = index);
                        },
                        itemBuilder: (context, index) {
                          final kg = _opcoesCargaKg[index];
                          final selecionado = index == _indiceCargaSelecionada;
                          return Center(
                            child: Text(
                              kg == 0 ? '0 kg (Livre)' : '$kg kg',
                              style: TextStyle(
                                fontSize: selecionado ? 16 : 14,
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
              const SizedBox(width: 8),
              // Coluna Séries (1 a 30)
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      'SÉRIES (1–30)',
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
                        scrollController: _seriesScrollController,
                        itemExtent: 40,
                        magnification: 1.12,
                        useMagnifier: true,
                        childCount: 30,
                        onSelectedItemChanged: (index) {
                          ServicoDeSomDoAlarme.instance.vibrarClique();
                          setState(() => _seriesSelecionadas = index + 1);
                        },
                        itemBuilder: (context, index) {
                          final valor = index + 1;
                          final selecionado = valor == _seriesSelecionadas;
                          return Center(
                            child: Text(
                              '$valor ${valor == 1 ? 'série' : 'séries'}',
                              style: TextStyle(
                                fontSize: selecionado ? 16 : 14,
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
              const SizedBox(width: 8),
              // Coluna Repetições (1 a 100)
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      'REPS (1–100)',
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
                                fontSize: selecionado ? 16 : 14,
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
          // Atalhos rápidos de carga
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
                      final idx = _opcoesCargaKg.indexOf(kgAtalho);
                      if (idx >= 0) _irParaIndiceCarga(idx);
                    },
                  ),
                );
              }).toList(growable: false),
            ),
          ),
          if (_cargaSelecionadaKg > 20) ...<Widget>[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final calc = CatalogoDeExerciciosOffline.calcularAnilhasPorLado(
                  _cargaSelecionadaKg.toDouble(),
                );
                if (calc.anilhasPorLado.isEmpty) return const SizedBox.shrink();
                final textoAnilhas = calc.anilhasPorLado
                    .map(
                      (a) =>
                          a == a.roundToDouble() ? '${a.toInt()}kg' : '${a}kg',
                    )
                    .join(' + ');
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🏋️ Barra 20kg → Por lado: $textoAnilhas',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 14),
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
                  onPressed: () => Navigator.of(context).pop(
                    _ResultadoMedidasPlano(
                      cargaKg: _cargaSelecionadaKg.toDouble(),
                      series: _seriesSelecionadas,
                      repeticoes: _repeticoesSelecionadas,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RascunhoDeExercicio {
  _RascunhoDeExercicio({
    required this.nameController,
    required this.loadController,
    required this.seriesController,
    required this.repetitionsController,
    this.modeloOriginal,
    this.tempoDescansoSegundos = 60,
    this.caminhoLocalGif,
    this.grupoSuperSerie,
  });

  final TextEditingController nameController;
  final TextEditingController loadController;
  final TextEditingController seriesController;
  final TextEditingController repetitionsController;
  final ExercicioPlanejado? modeloOriginal;
  int tempoDescansoSegundos;
  String? caminhoLocalGif;
  String? grupoSuperSerie;

  factory _RascunhoDeExercicio.empty() => _RascunhoDeExercicio(
        nameController: TextEditingController(),
        loadController: TextEditingController(text: '0'),
        seriesController: TextEditingController(text: '3'),
        repetitionsController: TextEditingController(text: '10'),
        tempoDescansoSegundos: 60,
      );

  factory _RascunhoDeExercicio.fromPlan(ExercicioPlanejado plan) {
    var nomeFinal = plan.nome;
    var descansoFinal = plan.tempoDescansoSegundos;
    var cargaFinal = plan.carga;
    final seriesFinal = plan.series;
    final repsFinal = plan.repeticoes;

    final correspondente =
        CatalogoDeExerciciosOffline.encontrarMaisProximo(plan.nome);
    if (correspondente != null) {
      nomeFinal = correspondente.nome;
      if (cargaFinal <= 0 && correspondente.cargaSugeridaKg > 0) {
        cargaFinal = correspondente.cargaSugeridaKg;
      }
      if (descansoFinal <= 0) {
        descansoFinal = correspondente.descansoSugeridoSegundos;
      }
    }

    return _RascunhoDeExercicio(
      nameController: TextEditingController(text: nomeFinal),
      loadController: TextEditingController(text: _textoNumerico(cargaFinal)),
      seriesController: TextEditingController(text: seriesFinal.toString()),
      repetitionsController: TextEditingController(
        text: repsFinal.toString(),
      ),
      modeloOriginal: plan,
      tempoDescansoSegundos: descansoFinal,
      caminhoLocalGif: plan.caminhoLocalGif,
      grupoSuperSerie: plan.grupoSuperSerie,
    );
  }

  void dispose() {
    nameController.dispose();
    loadController.dispose();
    seriesController.dispose();
    repetitionsController.dispose();
  }

  static String _textoNumerico(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
