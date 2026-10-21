import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/catalogo_exercicios_offline.dart';
import '../dominio/recursos_avancados.dart';
import '../provedores/estado_treino.dart';

class TelaDeInsights extends StatefulWidget {
  const TelaDeInsights({super.key});

  @override
  State<TelaDeInsights> createState() => _EstadoDaTelaDeInsights();
}

class _EstadoDaTelaDeInsights extends State<TelaDeInsights> {
  late Future<List<SerieHistorica>> _dados;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<List<SerieHistorica>> _carregar() async {
    final provedor = context.read<ProvedorDeTreino>();
    final resultado = <SerieHistorica>[];
    for (final treino in provedor.historico) {
      final data = DateTime.tryParse(treino.dataISO);
      if (data == null) continue;
      final series = await provedor.obterSeriesDoTreino(treino.id);
      resultado.addAll(
          series.map((serie) => SerieHistorica(data: data, serie: serie)));
    }
    return resultado;
  }

  Future<void> _repetir(BuildContext context) async {
    final dia = DateTime.now().weekday;
    await context.read<ProvedorDeTreino>().repetirUltimaSessaoComCargas(dia);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Últimas cargas aplicadas ao treino de hoje.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provedor = context.watch<ProvedorDeTreino>();
    return Scaffold(
      appBar: AppBar(title: const Text('Insights do treino')),
      body: FutureBuilder<List<SerieHistorica>>(
        future: _dados,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final series = snapshot.data!;
          final prs = RecursosAvancados.recordes(series);
          final volume = RecursosAvancados.volumePorGrupo(
            series
                .where(
                    (item) => DateTime.now().difference(item.data).inDays <= 7)
                .toList(growable: false),
            grupoDoExercicio:
                CatalogoDeExerciciosOffline.identificarGrupoMuscular,
          );
          final deload =
              RecursosAvancados.detectarDeload(series, DateTime.now());
          final medidas = provedor.medidasCorporais;
          final comparacao = medidas.length >= 2
              ? RecursosAvancados.comparar(
                  medidas[medidas.length - 1], medidas.first)
              : null;
          final streaks = RecursosAvancados.streaks(
            treinos: provedor.completedDates,
            habitos: provedor.contagemHabitosPorData.entries
                .where((item) => item.value > 0)
                .map((item) => DateTime.tryParse(item.key))
                .whereType<DateTime>()
                .toSet(),
            hoje: DateTime.now(),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => _repetir(context),
                icon: const Icon(Icons.replay),
                label: const Text('Repetir última sessão com cargas'),
              ),
              const SizedBox(height: 12),
              _Cartao(
                titulo: 'Streaks separados',
                child: Text(
                    'Treino: ${streaks.treino} dias  •  Hábitos: ${streaks.habitos} dias  •  Descanso: ${streaks.descanso} dias'),
              ),
              _Cartao(
                titulo: 'Recordes pessoais e 1RM estimado',
                child: prs.isEmpty
                    ? const Text('Conclua séries para começar o histórico.')
                    : Column(
                        children: prs
                            .take(12)
                            .map((item) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.exercicio),
                                  subtitle: Text(
                                      '${item.cargaKg.toStringAsFixed(1)} kg × ${item.repeticoes} reps'),
                                  trailing: Text(
                                      '1RM ${item.estimativa1RM.toStringAsFixed(1)} kg'),
                                ))
                            .toList()),
              ),
              _Cartao(
                titulo: 'Volume semanal por grupo muscular',
                child: volume.isEmpty
                    ? const Text('Sem volume registrado nos últimos 7 dias.')
                    : Column(
                        children: volume.entries
                            .map((item) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.key),
                                  trailing: Text(
                                      '${item.value.toStringAsFixed(0)} kg'),
                                ))
                            .toList()),
              ),
              _Cartao(
                titulo: 'Detecção de deload',
                child: Text(deload.recomendado
                    ? 'Recomendado: ${deload.motivo}'
                    : deload.motivo),
              ),
              if (comparacao != null)
                _Cartao(
                  titulo: 'Comparação de medidas',
                  child: Column(
                      children: comparacao.valores.entries
                          .map((item) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.key),
                                trailing: Text(
                                    '${item.value >= 0 ? '+' : ''}${item.value.toStringAsFixed(1)} cm'),
                              ))
                          .toList()),
                ),
              const _Cartao(
                titulo: 'Gráficos, widget e modo academia',
                child: Text(
                    'A base histórica está pronta. O widget de tela inicial e o modo sempre ativo dependem da integração nativa Android e ficam separados para não aumentar consumo em segundo plano.'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titulo,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                child,
              ]),
        ),
      );
}
