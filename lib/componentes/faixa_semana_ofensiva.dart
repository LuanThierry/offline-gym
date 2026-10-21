import 'package:flutter/material.dart';

import '../componentes/modal_conquista_ofensiva.dart';
import '../dominio/sistema_gamificacao.dart';
import '../provedores/estado_treino.dart';

/// Faixa da semana de treinos com indicador de ofensiva e dias concluídos.
class FaixaSemanaDeOfensiva extends StatelessWidget {
  const FaixaSemanaDeOfensiva({super.key, required this.provedor});

  final ProvedorDeTreino provedor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final semanaInicio = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final diasSiglas = <String>[
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb',
      'Dom',
    ];
    final ofensiva = provedor.ofensivaAtual;
    final classe = SistemaGamificacao.obterClasseAtual(ofensiva);
    final temaEscuro = Theme.of(context).brightness == Brightness.dark;
    final treinosSemana = provedor.treinosNaSemana(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Material(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: temaEscuro ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => ModalConquistaOfensiva.exibir(
            context,
            diasSeguidos: ofensiva,
            totalTreinos: provedor.historico.length,
            treinosNaSemana: treinosSemana,
            acabouDeConcluir: false,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: temaEscuro
                    ? classe.cor.withValues(alpha: 0.35)
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            classe.cor,
                            classe.corSecundaria,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: classe.cor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ofensiva == 0
                                    ? 'Comece sua ofensiva!'
                                    : '$ofensiva ${ofensiva == 1 ? 'dia' : 'dias'} de ofensiva',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: classe.cor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  classe.nome,
                                  style: TextStyle(
                                    color: classe.cor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            classe.dicaDiaria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List<Widget>.generate(7, (indice) {
                    final dia = semanaInicio.add(Duration(days: indice));
                    final temTreino = provedor.treinoConcluidoNaData(dia);
                    final ehHoje = DateUtils.isSameDay(dia, now);

                    final corTreino = temaEscuro
                        ? const Color(0xFF6FD39A)
                        : const Color(0xFF238754);
                    final fundo = temTreino
                        ? corTreino
                        : (ehHoje
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest);
                    final corTexto = temTreino
                        ? Colors.white
                        : (ehHoje
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Text(
                              diasSiglas[indice],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    ehHoje ? FontWeight.w800 : FontWeight.w600,
                                color: ehHoje
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: fundo,
                                shape: BoxShape.circle,
                                border: ehHoje
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 1.8,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: temTreino
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${dia.day}',
                                      style: TextStyle(
                                        color: corTexto,
                                        fontWeight: ehHoje
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
