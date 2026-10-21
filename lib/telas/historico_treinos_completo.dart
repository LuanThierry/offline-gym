import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../componentes/botao_de_perfil.dart';

class TelaDeHistoricoCompletoDeTreinos extends StatelessWidget {
  const TelaDeHistoricoCompletoDeTreinos({super.key});

  Future<void> _excluirTreino(
    BuildContext context,
    ProvedorDeTreino provedor,
    TreinoDoHistorico treino,
  ) async {
    final data = DateTime.tryParse(treino.dataISO);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir treino do histórico?'),
        content: Text(
          data == null
              ? 'Este treino será removido permanentemente.'
              : 'O treino de ${DateFormat('dd/MM/yyyy HH:mm').format(data)} '
                  'e suas séries serão removidos.',
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
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provedor.excluirSessaoDeTreino(treino.id);

      messenger.showSnackBar(
        const SnackBar(content: Text('Treino removido do histórico.')),
      );
    } catch (erro) {
      messenger.showSnackBar(
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
                    const SizedBox(width: 12),
                    Text(
                      _textoDaDuracao(
                        Duration(seconds: treino.tempoTotalSegundos),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('EEEE', 'pt_BR').format(data),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
                                  final loadStr = s.cargaUtilizada ==
                                          s.cargaUtilizada.roundToDouble()
                                      ? s.cargaUtilizada.toStringAsFixed(0)
                                      : s.cargaUtilizada.toStringAsFixed(1);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: temaEscuro
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${s.serieNumero}ª · ${s.repeticoes} reps · $loadStr kg',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os treinos'),
        actions: const [BotaoDePerfil()],
      ),
      body: Consumer<ProvedorDeTreino>(
        builder: (context, provedor, _) {
          if (provedor.historico.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum treino concluído foi registrado.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provedor.historico.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, indice) {
              final treino = provedor.historico[indice];

              final data = DateTime.tryParse(treino.dataISO);
              final duracao = Duration(seconds: treino.tempoTotalSegundos);

              return Card(
                child: ListTile(
                  isThreeLine: true,
                  onTap: () =>
                      _mostrarDetalhesDoTreino(context, provedor, treino),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    treino.nomeTreino.isEmpty ? 'Treino' : treino.nomeTreino,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: data == null
                      ? const Text('Data indisponível')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(height: 3),
                            Text(
                              '${toBeginningOfSentenceCase(DateFormat('EEEE', 'pt_BR').format(data))} · ${DateFormat('dd/MM/yyyy').format(data)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
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
                    width: 125,
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
                          tooltip: 'Excluir treino',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFD63031),
                          ),
                          onPressed: () =>
                              _excluirTreino(context, provedor, treino),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _textoDaDuracao(Duration duracao) {
  final hours = duracao.inHours;
  final minutes = duracao.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = duracao.inSeconds.remainder(60).toString().padLeft(2, '0');

  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m ${segundos}s';
}
