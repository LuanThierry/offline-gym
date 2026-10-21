import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../dominio/sistema_gamificacao.dart';
import '../provedores/estado_treino.dart';

/// Modal bottom sheet que não ocupa a tela inteira, exibindo a comemoração
/// do treino, ofensiva, níveis, classes, dicas e recompensas desbloqueadas.
class ModalConquistaOfensiva extends StatefulWidget {
  const ModalConquistaOfensiva({
    super.key,
    required this.diasSeguidos,
    required this.totalTreinos,
    required this.treinosNaSemana,
    this.acabouDeConcluir = false,
  });

  final int diasSeguidos;
  final int totalTreinos;
  final int treinosNaSemana;
  final bool acabouDeConcluir;

  static Future<void> exibir(
    BuildContext context, {
    required int diasSeguidos,
    required int totalTreinos,
    required int treinosNaSemana,
    bool acabouDeConcluir = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalConquistaOfensiva(
        diasSeguidos: diasSeguidos,
        totalTreinos: totalTreinos,
        treinosNaSemana: treinosNaSemana,
        acabouDeConcluir: acabouDeConcluir,
      ),
    );
  }

  @override
  State<ModalConquistaOfensiva> createState() =>
      _EstadoDoModalConquistaOfensiva();
}

class _EstadoDoModalConquistaOfensiva extends State<ModalConquistaOfensiva> {
  int _abaSelecionada =
      0; // 0 = Visão Geral & Recompensas, 1 = Classes, 2 = Conquistas
  final GlobalKey _chaveCardCompartilhavel = GlobalKey();
  bool _compartilhando = false;

  Future<void> _compartilharCardImagem(ClasseOfensiva classeAtual) async {
    if (_compartilhando) return;
    setState(() => _compartilhando = true);
    try {
      final boundary = _chaveCardCompartilhavel.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final imagem = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await imagem.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final arquivo = File(
        '${tempDir.path}/conquista_ofensiva_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await arquivo.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(arquivo.path, mimeType: 'image/png')],
          text:
              '🔥 ${widget.diasSeguidos} dias de ofensiva no Offline Gym (Nível ${classeAtual.nome})!',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar a imagem para compartilhar.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _compartilhando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provedor = context.watch<ProvedorDeTreino>();
    final diasExibidos = provedor.ofensivaAtual > widget.diasSeguidos
        ? provedor.ofensivaAtual
        : widget.diasSeguidos;
    final classeAtual = SistemaGamificacao.obterClasseAtual(diasExibidos);
    final proximaClasse = SistemaGamificacao.obterProximaClasse(diasExibidos);
    final progresso = SistemaGamificacao.calcularProgresso(diasExibidos);
    final diasFaltantes =
        SistemaGamificacao.diasParaProximaClasse(diasExibidos);
    final conquistas = SistemaGamificacao.obterConquistas(
      diasSeguidos: diasExibidos,
      totalTreinos: widget.totalTreinos,
      treinosNaSemana: widget.treinosNaSemana,
      totalHabitosConcluidos: provedor.habitos.fold<int>(
        0,
        (sum, h) => sum + h.totalConclusoes,
      ),
      metaPesoDefinida: provedor.perfil?.metaPesoKg != null,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de arrasto
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // Cabeçalho
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: classeAtual.cor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.acabouDeConcluir
                            ? Icons.celebration_rounded
                            : Icons.military_tech_rounded,
                        color: classeAtual.cor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.acabouDeConcluir
                                ? 'Treino Registrado!'
                                : 'Ofensiva & Recompensas',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            widget.acabouDeConcluir
                                ? 'Você acumulou novos ganhos e consistência!'
                                : 'Veja seu patamar, dicas e metas alcançadas',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Segmented / Tab selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Meu Nível'),
                      icon: Icon(Icons.star_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Classes'),
                      icon: Icon(Icons.shield_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Metas'),
                      icon: Icon(Icons.emoji_events_outlined, size: 18),
                    ),
                  ],
                  selected: {_abaSelecionada},
                  onSelectionChanged: (novaSelecao) {
                    setState(() => _abaSelecionada = novaSelecao.first);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Conteúdo rolável
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    if (_abaSelecionada == 0) ...[
                      RepaintBoundary(
                        key: _chaveCardCompartilhavel,
                        child: Container(
                          color: colorScheme.surface,
                          child: Column(
                            children: [
                              // Cartão da Classe Atual
                              _construirCartaoClasseAtual(
                                context,
                                classeAtual,
                                proximaClasse,
                                progresso,
                                diasFaltantes,
                              ),
                              const SizedBox(height: 14),

                              // Métricas Rápidas
                              _construirGridMetricas(context, classeAtual),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Escudo de Descanso / Proteção de Ofensiva
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00B8D4).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                const Color(0xFF00B8D4).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B8D4)
                                    .withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Color(0xFF00B8D4),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Escudos de Ofensiva: ${provedor.escudosDisponiveis} disponíveis',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    provedor.hojeProtegidoPorEscudo
                                        ? 'Ofensiva protegida hoje por escudo de descanso!'
                                        : 'Ganha 1 escudo a cada 4 treinos para proteger dias de descanso.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!provedor.hojeProtegidoPorEscudo &&
                                provedor.escudosDisponiveis > 0)
                              OutlinedButton(
                                onPressed: () async {
                                  final usado =
                                      await provedor.usarEscudoDeOfensiva();
                                  if (context.mounted && usado) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '🛡️ Escudo de Ofensiva ativado com sucesso!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Usar 🛡️'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Recompensa e Dica Desbloqueada
                      _construirCartaoRecompensaEDica(context, classeAtual),
                      const SizedBox(height: 14),

                      // Botões de ação (Compartilhar Card + Fechar)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _compartilhando
                                  ? null
                                  : () => _compartilharCardImagem(classeAtual),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: Text(
                                _compartilhando
                                    ? 'Gerando...'
                                    : 'Compartilhar Card',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                widget.acabouDeConcluir
                                    ? 'Continuar Focado'
                                    : 'Fechar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_abaSelecionada == 1) ...[
                      // Lista de todas as 10 classes
                      _construirListaTodasClasses(context, classeAtual),
                    ] else ...[
                      // Lista de conquistas / metas
                      _construirListaConquistas(context, conquistas),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirCartaoClasseAtual(
    BuildContext context,
    ClasseOfensiva classe,
    ClasseOfensiva? proxima,
    double progresso,
    int diasFaltantes,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            classe.cor.withValues(alpha: 0.18),
            classe.corSecundaria.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: classe.cor.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: classe.cor,
                  boxShadow: [
                    BoxShadow(
                      color: classe.cor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(classe.icone, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CLASSE ${classe.nome.toUpperCase()}',
                          style: TextStyle(
                            color: classe.cor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: classe.cor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nível ${SistemaGamificacao.todasAsClasses.indexOf(classe) + 1}',
                            style: TextStyle(
                              color: classe.cor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      classe.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.diasSeguidos == 0
                          ? 'Complete o treino de hoje para avançar!'
                          : '${widget.diasSeguidos} ${widget.diasSeguidos == 1 ? 'dia' : 'dias'} consecutivos de consistência',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progresso para próxima classe
          if (proxima != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximo nível: ${proxima.nome}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$diasFaltantes ${diasFaltantes == 1 ? 'dia restante' : 'dias restantes'}',
                  style: TextStyle(
                    color: proxima.cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(classe.cor),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Você atingiu a classe máxima do app! Uma verdadeira lenda.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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

  Widget _construirGridMetricas(BuildContext context, ClasseOfensiva classe) {
    return Row(
      children: [
        Expanded(
          child: _ItemMetrica(
            icone: Icons.local_fire_department_rounded,
            corIcone: classe.cor,
            valor: '${widget.diasSeguidos}',
            rotulo: 'Dias Ofensiva',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ItemMetrica(
            icone: Icons.fitness_center_rounded,
            corIcone: Theme.of(context).colorScheme.primary,
            valor: '${widget.totalTreinos}',
            rotulo: 'Treinos Totais',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ItemMetrica(
            icone: Icons.calendar_today_rounded,
            corIcone: const Color(0xFF00BFA5),
            valor: '${widget.treinosNaSemana}/7',
            rotulo: 'Nesta Semana',
          ),
        ),
      ],
    );
  }

  Widget _construirCartaoRecompensaEDica(
    BuildContext context,
    ClasseOfensiva classe,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'O QUE VOCÊ GANHA:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            classe.recompensa,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'DICA DIÁRIA DO SEU NÍVEL:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            classe.dicaDiaria,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: classe.cor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, color: classe.cor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    classe.motivacao,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaTodasClasses(
    BuildContext context,
    ClasseOfensiva classeAtual,
  ) {
    final todas = SistemaGamificacao.todasAsClasses;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolução de Classes & Bordas',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Cada patamar desbloqueia uma cor vibrante para a borda do seu perfil, novos objetivos e orientações exclusivas:',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...todas.map((classe) {
          final desbloqueada = widget.diasSeguidos >= classe.diasMinimos;
          final isAtual = classe.nome == classeAtual.nome;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAtual
                  ? classe.cor.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAtual
                    ? classe.cor
                    : (desbloqueada
                        ? classe.cor.withValues(alpha: 0.4)
                        : theme.colorScheme.outlineVariant),
                width: isAtual ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: desbloqueada
                        ? classe.cor
                        : theme.colorScheme.outlineVariant,
                  ),
                  child: Icon(
                    classe.icone,
                    color: desbloqueada ? Colors.white : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            classe.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: desbloqueada
                                  ? classe.cor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isAtual)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: classe.cor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'VOCÊ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${classe.diasMinimos == 0 ? 'Início' : '${classe.diasMinimos} dias'} · ${classe.titulo}',
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classe.recompensa,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: desbloqueada
                              ? theme.colorScheme.onSurface
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  desbloqueada
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  color: desbloqueada ? classe.cor : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _construirListaConquistas(
    BuildContext context,
    List<ConquistaGamificada> conquistas,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objetivos & Metas Gamificadas',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Conquiste marcos ao longo da semana e dos meses para solidificar seus resultados:',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...conquistas.map((conquista) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: conquista.desbloqueada
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: conquista.desbloqueada
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conquista.desbloqueada
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                  child: Icon(
                    conquista.icone,
                    color: conquista.desbloqueada
                        ? Colors.white
                        : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conquista.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: conquista.desbloqueada
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        conquista.descricao,
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: conquista.progresso,
                          minHeight: 5,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  conquista.textoProgresso,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: conquista.desbloqueada
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ItemMetrica extends StatelessWidget {
  const _ItemMetrica({
    required this.icone,
    required this.corIcone,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final Color corIcone;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icone, color: corIcone, size: 20),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          Text(
            rotulo,
            style: TextStyle(
                fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
