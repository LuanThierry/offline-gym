import 'package:flutter/material.dart';
import '../dominio/coach_cientifico.dart';

class CardCoachFisiologico extends StatefulWidget {
  const CardCoachFisiologico({
    super.key,
    required this.diagnostico,
    this.aoTocarDeload,
  });

  final DiagnosticoDoCoach diagnostico;
  final VoidCallback? aoTocarDeload;

  @override
  State<CardCoachFisiologico> createState() => _EstadoDoCardCoachFisiologico();
}

class _EstadoDoCardCoachFisiologico extends State<CardCoachFisiologico> {
  bool _expandido = false;
  bool _expandirRecuperacao = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final diag = widget.diagnostico;

    final temAlertas = diag.pareceres.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: diag.semanaSugeridaDeload
              ? const Color(0xFFE67E22)
              : theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
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
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              diag.saudacaoPersonalizada,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OFFLINE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inteligência fisiológica e biomecânica em tempo real',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Resumo dinâmico
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                diag.resumoGeral,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF2D3436),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Barras de Simetria e Fadiga
            Row(
              children: [
                Expanded(
                  child: _IndicadorMetrico(
                    titulo: 'Simetria Muscular',
                    percentual: diag.indiceEquilibrioPercentual,
                    cor: diag.indiceEquilibrioPercentual >= 80
                        ? const Color(0xFF00B894)
                        : const Color(0xFFE67E22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IndicadorMetrico(
                    titulo: 'Fadiga Acumulada',
                    percentual: diag.indiceFadigaPercentual,
                    cor: diag.indiceFadigaPercentual >= 85
                        ? const Color(0xFFD63031)
                        : (diag.indiceFadigaPercentual >= 60
                            ? const Color(0xFFE67E22)
                            : const Color(0xFF00B894)),
                  ),
                ),
              ],
            ),

            // Seção de Fadiga & Recuperação Muscular Individual (Microciclo)
            if (diag.recuperacaoMuscular.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    setState(() => _expandirRecuperacao = !_expandirRecuperacao),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.battery_charging_full_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recuperação por Grupo Muscular',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _expandirRecuperacao
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandirRecuperacao) ...[
                const SizedBox(height: 4),
                ...diag.recuperacaoMuscular.map((m) => _BarraRecuperacaoMuscular(
                      recuperacao: m,
                    )),
              ] else ...[
                const SizedBox(height: 4),
                ...diag.recuperacaoMuscular
                    .where((m) => m.horasDesdeUltimoTreino != null)
                    .take(3)
                    .map((m) => _BarraRecuperacaoMuscular(
                          recuperacao: m,
                          compacto: true,
                        )),
              ],
            ],

            if (diag.semanaSugeridaDeload && widget.aoTocarDeload != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFE67E22).withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFFE67E22),
                  ),
                  onPressed: widget.aoTocarDeload,
                  icon:
                      const Icon(Icons.battery_charging_full_rounded, size: 18),
                  label: const Text(
                    'Programar Semana de Deload (-40% volume)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],

            if (temAlertas) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _expandido = !_expandido),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _expandido
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _expandido
                                ? 'Recolher recomendações'
                                : 'Ver ${diag.pareceres.length} pareceres biomecânicos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${diag.pareceres.length} análises',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandido) ...[
                const SizedBox(height: 8),
                ...diag.pareceres.map((p) => _ItemParecerCoach(parecer: p)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IndicadorMetrico extends StatelessWidget {
  const _IndicadorMetrico({
    required this.titulo,
    required this.percentual,
    required this.cor,
  });

  final String titulo;
  final int percentual;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              '$percentual%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentual / 100.0,
            minHeight: 6,
            backgroundColor: cor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }
}

class _ItemParecerCoach extends StatelessWidget {
  const _ItemParecerCoach({required this.parecer});

  final ParecerDoCoach parecer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color corBadge;
    IconData icone;
    switch (parecer.tipo) {
      case TipoDeParecer.alertaFisiologico:
        corBadge = const Color(0xFFE67E22);
        icone = Icons.warning_amber_rounded;
        break;
      case TipoDeParecer.otimizacao:
        corBadge = const Color(0xFF0984E3);
        icone = Icons.trending_up_rounded;
        break;
      case TipoDeParecer.destaque:
        corBadge = theme.colorScheme.primary;
        icone = Icons.auto_awesome_rounded;
        break;
      case TipoDeParecer.sucesso:
        corBadge = const Color(0xFF00B894);
        icone = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: corBadge.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corBadge.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: corBadge),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  parecer.titulo,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: corBadge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            parecer.mensagem,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (parecer.recomendacaoPratica != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: Color(0xFFF1C40F)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dica: ${parecer.recomendacaoPratica!}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarraRecuperacaoMuscular extends StatelessWidget {
  const _BarraRecuperacaoMuscular({
    required this.recuperacao,
    this.compacto = false,
  });

  final StatusRecuperacaoMuscular recuperacao;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = recuperacao.percentualRecuperado;

    Color cor;
    if (pct >= 85) {
      cor = const Color(0xFF00B894);
    } else if (pct >= 60) {
      cor = const Color(0xFF0984E3);
    } else if (pct >= 40) {
      cor = const Color(0xFFE67E22);
    } else {
      cor = const Color(0xFFD63031);
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE9ECEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recuperacao.grupoMuscular,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${recuperacao.percentualRecuperado}% recuperado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: recuperacao.percentualRecuperado / 100.0,
              minHeight: 6,
              backgroundColor: cor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
          if (!compacto) ...[
            const SizedBox(height: 4),
            Text(
              recuperacao.statusTexto,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
