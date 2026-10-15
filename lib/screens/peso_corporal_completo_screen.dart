import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/workout_provider.dart';

class PesoCorporalCompletoScreen extends StatelessWidget {
  const PesoCorporalCompletoScreen({super.key});

  Future<void> _deleteBodyWeight(
      BuildContext context,
      WorkoutProvider provider,
      int id,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro de peso?'),
        content: const Text(
          'Este registro será removido permanentemente.',
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
      await provider.deleteBodyWeight(id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro de peso removido.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir o registro: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os registros de peso'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          if (provider.bodyWeights.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum peso corporal registrado ainda.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.bodyWeights.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = provider.bodyWeights[index];

              final date = DateTime.tryParse(record.dataISO);

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
                      Icons.monitor_weight_outlined,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  title: Text(
                    '${record.pesoKg.toStringAsFixed(1)} kg',
                  ),
                  subtitle: Text(
                    date == null
                        ? 'Data indisponível'
                        : DateFormat('dd/MM/yyyy').format(date),
                  ),
                  trailing: IconButton(
                    tooltip: 'Excluir registro de peso',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFD63031),
                    ),
                    onPressed: () => _deleteBodyWeight(
                      context,
                      provider,
                      record.id,
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