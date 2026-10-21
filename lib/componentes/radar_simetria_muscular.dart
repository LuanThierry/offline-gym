import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../dominio/volume_muscular.dart';

class RadarSimetriaMuscular extends StatelessWidget {
  const RadarSimetriaMuscular({
    super.key,
    required this.volumes,
    this.scoreSimetria = 85,
  });

  final List<MarcoDeVolumeMuscular> volumes;
  final int scoreSimetria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Agrupa dados para os 6 eixos principais do corpo humano
    final map = <String, int>{};
    for (final v in volumes) {
      map[v.grupoMuscular] = v.seriesCompletadas;
    }

    final eixos = <({String label, double valor, double maxRef})>[
      (label: 'Peito', valor: (map['Peito'] ?? 0).toDouble(), maxRef: 20.0),
      (label: 'Costas', valor: (map['Costas'] ?? 0).toDouble(), maxRef: 22.0),
      (label: 'Ombros', valor: (map['Ombros'] ?? 0).toDouble(), maxRef: 20.0),
      (
        label: 'Braços',
        valor: ((map['Bíceps'] ?? 0) + (map['Tríceps'] ?? 0)).toDouble() / 2.0,
        maxRef: 18.0,
      ),
      (
        label: 'Posterior',
        valor: (map['Posterior & Glúteos'] ?? 0).toDouble(),
        maxRef: 18.0,
      ),
      (
        label: 'Quadríceps',
        valor: (map['Quadríceps'] ?? 0).toDouble(),
        maxRef: 20.0,
      ),
    ];

    Color corScore;
    String statusSimetria;
    if (scoreSimetria >= 80) {
      corScore = const Color(0xFF00B894);
      statusSimetria = 'Ótima Simetria';
    } else if (scoreSimetria >= 65) {
      corScore = const Color(0xFFE67E22);
      statusSimetria = 'Atenção ao Equilíbrio';
    } else {
      corScore = const Color(0xFFD63031);
      statusSimetria = 'Desequilíbrio Notável';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simetria & Equilíbrio Muscular',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Radar biomecânico semanal (6 eixos)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: corScore.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: corScore.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$scoreSimetria%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: corScore,
                        ),
                      ),
                      Text(
                        statusSimetria,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: corScore,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RadarSimetriaPainter(
                    eixos: eixos,
                    corPrimaria: theme.colorScheme.primary,
                    isDark: isDark,
                    textColor: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Cada eixo representa a proporção de séries semanais em direção ao Volume Ótimo (MAV).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarSimetriaPainter extends CustomPainter {
  const _RadarSimetriaPainter({
    required this.eixos,
    required this.corPrimaria,
    required this.isDark,
    required this.textColor,
  });

  final List<({String label, double valor, double maxRef})> eixos;
  final Color corPrimaria;
  final bool isDark;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final totalEixos = eixos.length;
    if (totalEixos < 3) return;

    final stepAngle = (2 * math.pi) / totalEixos;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // 1. Desenha anéis poligonais concêntricos (25%, 50%, 75%, 100%)
    const niveis = [0.25, 0.50, 0.75, 1.0];
    for (final nivel in niveis) {
      final path = Path();
      for (var i = 0; i < totalEixos; i++) {
        final angle = (i * stepAngle) - (math.pi / 2);
        final r = radius * nivel;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Desenha os raios dos eixos e textos dos rótulos
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < totalEixos; i++) {
      final angle = (i * stepAngle) - (math.pi / 2);
      final spokeEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, axisPaint);

      // Posiciona o rótulo um pouco além do raio
      final labelDist = radius + 18.0;
      final labelPos = Offset(
        center.dx + labelDist * math.cos(angle),
        center.dy + labelDist * math.sin(angle),
      );

      final item = eixos[i];
      final labelText = '${item.label}\n${item.valor.toStringAsFixed(0)}s';
      textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelPos.dx - (textPainter.width / 2),
          labelPos.dy - (textPainter.height / 2),
        ),
      );
    }

    // 3. Desenha o polígono preenchido do atleta
    final polyPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < totalEixos; i++) {
      final item = eixos[i];
      final frac = (item.valor / item.maxRef).clamp(0.05, 1.05);
      final r = radius * frac;
      final angle = (i * stepAngle) - (math.pi / 2);
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      points.add(p);
      if (i == 0) {
        polyPath.moveTo(p.dx, p.dy);
      } else {
        polyPath.lineTo(p.dx, p.dy);
      }
    }
    polyPath.close();

    final fillPaint = Paint()
      ..color = corPrimaria.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final borderPaint = Paint()
      ..color = corPrimaria
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(polyPath, borderPaint);

    // Pontos nos vértices
    final dotPaint = Paint()..color = corPrimaria;
    final dotInner = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 2.0, dotInner);
    }
  }

  @override
  bool shouldRepaint(_RadarSimetriaPainter old) => true;
}
