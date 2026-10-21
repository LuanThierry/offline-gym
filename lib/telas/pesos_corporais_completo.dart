import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provedores/estado_treino.dart';
import '../componentes/botao_de_perfil.dart';

class TelaDePesosCorporais extends StatelessWidget {
  const TelaDePesosCorporais({super.key});

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

    try {
      await provedor.excluirPesoCorporal(id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro de peso removido.')),
      );
    } catch (erro) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o registro: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os registros de peso'),
        actions: const [BotaoDePerfil()],
      ),
      body: Consumer<ProvedorDeTreino>(
        builder: (context, provedor, _) {
          if (provedor.pesosCorporais.isEmpty) {
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
            itemCount: provedor.pesosCorporais.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, indice) {
              final record = provedor.pesosCorporais[indice];

              final data = DateTime.tryParse(record.dataISO);

              return Card(
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
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
                    data == null
                        ? 'Data indisponível'
                        : (toBeginningOfSentenceCase(
                              DateFormat("MMMM 'de' yyyy", 'pt_BR')
                                  .format(data),
                            ) ??
                            DateFormat("MMMM 'de' yyyy", 'pt_BR').format(data)),
                  ),
                  trailing: IconButton(
                    tooltip: 'Excluir registro de peso',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFD63031),
                    ),
                    onPressed: () =>
                        _excluirPesoCorporal(context, provedor, record.id),
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
