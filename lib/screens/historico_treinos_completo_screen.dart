import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan_model.dart';
import '../providers/workout_provider.dart';

class HistoricoTreinosCompletoScreen extends StatelessWidget {
  const HistoricoTreinosCompletoScreen({super.key});

  Future<void> _deleteWorkout(
      BuildContext context,
      WorkoutProvider provider,
      HistoryWorkoutModel workout,
      ) async {
    final date = DateTime.tryParse(workout.dataISO);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir treino do histórico?'),
        content: Text(
          date == null
              ? 'Este treino será removido permanentemente.'
              : 'O treino de ${DateFormat('dd/MM/yyyy HH:mm').format(date)} '
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

    try {
      await provider.deleteWorkoutSession(workout.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino removido do histórico.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir o treino: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os treinos'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          if (provider.history.isEmpty) {
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
            itemCount: provider.history.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final workout = provider.history[index];

              final date = DateTime.tryParse(workout.dataISO);
              final duration = Duration(
                seconds: workout.tempoTotalSegundos,
              );

              return Card(
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  title: Text(
                    WorkoutPlanModel.weekdayName(
                      workout.diaSemana,
                    ),
                  ),
                  subtitle: Text(
                    date == null
                        ? 'Data indisponível'
                        : DateFormat('dd/MM/yyyy · HH:mm')
                        .format(date),
                  ),
                  trailing: SizedBox(
                    width: 125,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _durationText(duration),
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
                          onPressed: () => _deleteWorkout(
                            context,
                            provider,
                            workout,
                          ),
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

String _durationText(Duration duration) {
  final hours = duration.inHours;
  final minutes =
  duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds =
  duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  return hours > 0
      ? '${hours}h ${minutes}m'
      : '${minutes}m ${seconds}s';
}