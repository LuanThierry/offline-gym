import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Modal e gerador visual de cartão de treino estilo "Instagram Stories / Strava".
/// 100% offline — renderiza o cartão em alta resolução e aciona o compartilhamento nativo.
class ModalCompartilharTreino extends StatefulWidget {
  const ModalCompartilharTreino({
    super.key,
    required this.nomeTreino,
    required this.duracaoSegundos,
    required this.tonelagemKg,
    required this.totalSeries,
    required this.ofensivaDias,
    this.recordesBatidos = const <String>[],
  });

  final String nomeTreino;
  final int duracaoSegundos;
  final double tonelagemKg;
  final int totalSeries;
  final int ofensivaDias;
  final List<String> recordesBatidos;

  static Future<void> exibir(
    BuildContext context, {
    required String nomeTreino,
    required int duracaoSegundos,
    required double tonelagemKg,
    required int totalSeries,
    required int ofensivaDias,
    List<String> recordesBatidos = const <String>[],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalCompartilharTreino(
        nomeTreino: nomeTreino,
        duracaoSegundos: duracaoSegundos,
        tonelagemKg: tonelagemKg,
        totalSeries: totalSeries,
        ofensivaDias: ofensivaDias,
        recordesBatidos: recordesBatidos,
      ),
    );
  }

  @override
  State<ModalCompartilharTreino> createState() =>
      _ModalCompartilharTreinoState();
}

class _ModalCompartilharTreinoState extends State<ModalCompartilharTreino> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _gerandoImagem = false;

  Future<void> _compartilharImagem() async {
    setState(() => _gerandoImagem = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Não foi possível capturar o cartão de treino.');
      }

      // Renderiza em 3x para qualidade ultra-nítida nas redes sociais
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Falha ao codificar imagem PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/offline_gym_treino_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      final minutos = (widget.duracaoSegundos / 60).round();
      final toneladaTxt = widget.tonelagemKg >= 1000
          ? '${(widget.tonelagemKg / 1000).toStringAsFixed(1)} toneladas'
          : '${widget.tonelagemKg.toStringAsFixed(0)} kg';

      final textoCompartilhar =
          'Treino de hoje finalizado no Offline Gym! 💪🔥\n'
          '⏱️ $minutos min · 🏋️ $toneladaTxt levantados · 🔥 ${widget.ofensivaDias} dias seguidos\n'
          '#OfflineGym #Hipertrofia #Musculação';

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(filePath)],
          text: textoCompartilhar,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _gerandoImagem = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final minutos = (widget.duracaoSegundos / 60).round();
    final dataFormatada = DateFormat("d 'de' MMMM · EEEE", 'pt_BR').format(
      DateTime.now(),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compartilhar Treino (Story / WhatsApp)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Área capturável com RepaintBoundary (Card de Story)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    width: 330,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(const Color(0xFF0F0F14),
                              Theme.of(context).colorScheme.primary, 0.08)!,
                          Color.lerp(const Color(0xFF181822),
                              Theme.of(context).colorScheme.primary, 0.14)!,
                          Color.lerp(const Color(0xFF0F0F14),
                              Theme.of(context).colorScheme.primary, 0.06)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Marca d'água Offline Gym
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'OFFLINE GYM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CONCLUÍDO ✓',
                                style: TextStyle(
                                  color: Color(0xFF00B894),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Nome do Treino
                        Text(
                          widget.nomeTreino.isNotEmpty
                              ? widget.nomeTreino
                              : 'Treino de Força',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dataFormatada,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Grade com 4 estatísticas
                        Row(
                          children: [
                            Expanded(
                              child: _itemStat(
                                icone: Icons.timer_outlined,
                                cor: const Color(0xFF00B8D4),
                                valor: '$minutos min',
                                rotulo: 'Duração',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _itemStat(
                                icone: Icons.scale_rounded,
                                cor: Theme.of(context).colorScheme.primary,
                                valor: widget.tonelagemKg >= 1000
                                    ? '${(widget.tonelagemKg / 1000).toStringAsFixed(1)} ton'
                                    : '${widget.tonelagemKg.toStringAsFixed(0)} kg',
                                rotulo: 'Tonelagem',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _itemStat(
                                icone: Icons.repeat_rounded,
                                cor: const Color(0xFFFFA726),
                                valor: '${widget.totalSeries}',
                                rotulo: 'Séries Feitas',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _itemStat(
                                icone: Icons.local_fire_department_rounded,
                                cor: const Color(0xFFFF5252),
                                valor: '${widget.ofensivaDias} dias',
                                rotulo: 'Ofensiva 🔥',
                              ),
                            ),
                          ],
                        ),

                        // Recordes PR se houver
                        if (widget.recordesBatidos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFB300)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_rounded,
                                      size: 16,
                                      color: Color(0xFFFFB300),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'RECORDES PESSOAIS (PR) BATIDOS',
                                      style: TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...widget.recordesBatidos.map(
                                  (pr) => Text(
                                    '• $pr',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        // Rodapé
                        Center(
                          child: Text(
                            '100% Offline · Sem Anúncios · Foco Total',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão de Ação para Compartilhar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: _gerandoImagem ? null : _compartilharImagem,
              icon: _gerandoImagem
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_rounded),
              label: Text(
                _gerandoImagem
                    ? 'Preparando imagem...'
                    : 'Compartilhar no Instagram / WhatsApp',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemStat({
    required IconData icone,
    required Color cor,
    required String valor,
    required String rotulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            rotulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
