import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provedores/estado_treino.dart';
import '../componentes/botao_de_perfil.dart';

class TelaCompletaDeSeriesECargas extends StatelessWidget {
  const TelaCompletaDeSeriesECargas({super.key, required this.nomeDoExercicio});

  final String nomeDoExercicio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séries e pesos por treino'),
        actions: const [BotaoDePerfil()],
      ),
      body: Consumer<ProvedorDeTreino>(
        builder: (context, provedor, _) {
          final details = provedor.detalhesDaEvolucao;
          if (details.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não há séries registradas para este exercício.',
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: details.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, indice) {
              final detail = details[indice];
              final data = DateTime.tryParse(detail.dataISO);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomeDoExercicio,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  data == null
                                      ? 'Data indisponível'
                                      : DateFormat(
                                          'dd/MM/yyyy · HH:mm',
                                        ).format(data),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Máx. ${_formatLoad(detail.cargaMaxima)} kg',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: detail.series.map((set) {
                          return Chip(
                            avatar: const Icon(
                              Icons.fitness_center,
                              size: 16,
                            ),
                            label: Text(
                              '${set.serieNumero}ª série · ${set.repeticoes} reps · ${_formatLoad(set.cargaUtilizada)} kg',
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatLoad(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
