import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dominio/coach_cientifico.dart';
import '../provedores/estado_tema.dart';

/// Calcula a cor neon estrita da escala fisiológica:
/// 100% = Verde Neon (#00E676 - totalmente recuperado / ótima simetria)
/// 50%  = Laranja Neon (#FF9100 - em regeneração / atenção)
/// 0%   = Vermelho Neon (#FF1744 - fadiga residual alta / desbalanceado)
/// Para Fadiga Acumulada, inverte a lógica (0% = descansado, 100% = exaustão).
Color obterCorFisiologica({
  required int percentual,
  required Color corSucesso,
  required Color corAlerta,
  required Color corPerigo,
  bool invertido = false,
}) {
  final pct = percentual.clamp(0, 100);
  if (invertido) {
    if (pct <= 35) return corSucesso;
    if (pct <= 70) return corAlerta;
    return corPerigo;
  } else {
    if (pct >= 75) return corSucesso;
    if (pct >= 40) return corAlerta;
    return corPerigo;
  }
}

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

    // Cores dinâmicas de identidade com base no tema ativo
    final provedorTema = context.watch<ProvedorDeTema>();
    final corDestaque = provedorTema.corInvertidaDestaque;
    final gradienteCoach = provedorTema.gradienteDualToneDestaque;
    final corSucesso = provedorTema.corSucessoNeon;
    final corAlerta = provedorTema.corAlertaNeon;
    final corPerigo = provedorTema.corPerigoNeon;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: diag.semanaSugeridaDeload
              ? corAlerta
              : corDestaque.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone do Coach com Gradiente Dual-Tone e Efeito Neon Glow
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradienteCoach,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: corDestaque.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 26,
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
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: corDestaque.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: corDestaque.withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'COACH OFFLINE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: corDestaque,
                                letterSpacing: 0.5,
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

            // Barras de Simetria e Fadiga com Contraste Fisiológico Neon (100% Verde, 50% Laranja, 0% Vermelho)
            Row(
              children: [
                Expanded(
                  child: _IndicadorMetrico(
                    titulo: 'Simetria Muscular',
                    percentual: diag.indiceEquilibrioPercentual,
                    cor: obterCorFisiologica(
                      percentual: diag.indiceEquilibrioPercentual,
                      corSucesso: corSucesso,
                      corAlerta: corAlerta,
                      corPerigo: corPerigo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IndicadorMetrico(
                    titulo: 'Fadiga Acumulada',
                    percentual: diag.indiceFadigaPercentual,
                    cor: obterCorFisiologica(
                      percentual: diag.indiceFadigaPercentual,
                      corSucesso: corSucesso,
                      corAlerta: corAlerta,
                      corPerigo: corPerigo,
                      invertido: true,
                    ),
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
                            color: corDestaque,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recuperação por Grupo Muscular',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: corDestaque,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _expandirRecuperacao
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: corDestaque,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandirRecuperacao) ...[
                const SizedBox(height: 4),
                ...diag.recuperacaoMuscular.map((m) => _BarraRecuperacaoMuscular(
                      recuperacao: m,
                      corSucesso: corSucesso,
                      corAlerta: corAlerta,
                      corDestaque: corDestaque,
                      corPerigo: corPerigo,
                    )),
              ] else ...[
                const SizedBox(height: 4),
                ...(diag.recuperacaoMuscular
                            .where((m) => m.horasDesdeUltimoTreino != null)
                            .isNotEmpty
                        ? diag.recuperacaoMuscular
                            .where((m) => m.horasDesdeUltimoTreino != null)
                            .take(4)
                        : diag.recuperacaoMuscular.take(3))
                    .map((m) => _BarraRecuperacaoMuscular(
                          recuperacao: m,
                          compacto: true,
                          corSucesso: corSucesso,
                          corAlerta: corAlerta,
                          corDestaque: corDestaque,
                          corPerigo: corPerigo,
                        )),
              ],
            ],

            if (diag.semanaSugeridaDeload && widget.aoTocarDeload != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: corAlerta.withValues(alpha: 0.18),
                    foregroundColor: corAlerta,
                    side: BorderSide(color: corAlerta.withValues(alpha: 0.45)),
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
                            color: corDestaque,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _expandido
                                ? 'Recolher recomendações'
                                : 'Ver ${diag.pareceres.length} pareceres biomecânicos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: corDestaque,
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
                ...diag.pareceres.map((p) => _ItemParecerCoach(
                      parecer: p,
                      corDestaque: corDestaque,
                      corSucesso: corSucesso,
                      corAlerta: corAlerta,
                      corPerigo: corPerigo,
                    )),
              ],
            ],
            const SizedBox(height: 10),
            Text(
              'Aviso: Estimativas informativas de treinamento físico que não substituem avaliação médica, fisioterapêutica ou de um profissional de educação física.',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
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
  const _ItemParecerCoach({
    required this.parecer,
    required this.corDestaque,
    required this.corSucesso,
    required this.corAlerta,
    required this.corPerigo,
  });

  final ParecerDoCoach parecer;
  final Color corDestaque;
  final Color corSucesso;
  final Color corAlerta;
  final Color corPerigo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color corBadge;
    IconData icone;
    String tag;
    switch (parecer.tipo) {
      case TipoDeParecer.alertaFisiologico:
        corBadge = corAlerta;
        icone = Icons.warning_amber_rounded;
        tag = 'ALERTA FISIOLÓGICO';
        break;
      case TipoDeParecer.otimizacao:
        corBadge = corDestaque;
        icone = Icons.trending_up_rounded;
        tag = 'OTIMIZAÇÃO DO PLANO';
        break;
      case TipoDeParecer.destaque:
        corBadge = corDestaque;
        icone = Icons.auto_awesome_rounded;
        tag = 'DESTAQUE BIOMECÂNICO';
        break;
      case TipoDeParecer.sucesso:
        corBadge = corSucesso;
        icone = Icons.verified_rounded;
        tag = 'PROGRESSO CONFIRMADO';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: corBadge.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: corBadge.withValues(alpha: isDark ? 0.40 : 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: corBadge.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              color: corBadge,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: corBadge.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icone, size: 16, color: corBadge),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parecer.titulo,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: corBadge.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: corBadge.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: corBadge,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      parecer.mensagem,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF333333),
                      ),
                    ),
                    if (parecer.recomendacaoPratica != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: corBadge.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_rounded, size: 15, color: corBadge),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dica prática: ${parecer.recomendacaoPratica!}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF222222),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraRecuperacaoMuscular extends StatelessWidget {
  const _BarraRecuperacaoMuscular({
    required this.recuperacao,
    required this.corSucesso,
    required this.corAlerta,
    required this.corDestaque,
    required this.corPerigo,
    this.compacto = false,
  });

  final StatusRecuperacaoMuscular recuperacao;
  final Color corSucesso;
  final Color corAlerta;
  final Color corDestaque;
  final Color corPerigo;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Escala fisiológica: 100% = Verde (#00E676), 50% = Laranja (#FF9100), 0% = Vermelho (#FF1744)
    final cor = obterCorFisiologica(
      percentual: recuperacao.percentualRecuperado,
      corSucesso: corSucesso,
      corAlerta: corAlerta,
      corPerigo: corPerigo,
    );

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
