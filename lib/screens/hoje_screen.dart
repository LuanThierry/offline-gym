import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan_model.dart';
import '../providers/workout_provider.dart';

import '../widgets/theme_toggle_button.dart';
import '../widgets/settings_button.dart';

class HojeScreen extends StatefulWidget {
  const HojeScreen({super.key, required this.onConfigurePlan});

  final VoidCallback onConfigurePlan;

  @override
  State<HojeScreen> createState() => _HojeScreenState();
}

class _HojeScreenState extends State<HojeScreen> {
  bool _restSheetOpen = false;
  void _openRestDurationPicker(WorkoutProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _RestDurationPickerSheet(
        initialSeconds: provider.restDurationSeconds,
        onConfirm: provider.setRestDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final todayWeekday = DateTime.now().weekday;
        final weekday =
            provider.sessionActive && provider.sessionWeekday != null
            ? provider.sessionWeekday!
            : todayWeekday;
        final dayName = WorkoutPlanModel.weekdayName(weekday);
        final exercises = provider.sessionActive
            ? provider.sessionExercises
            : provider.plansForDay(weekday);

        if (!provider.initialized && provider.lastError != null) {
          return _LoadError(
            error: provider.lastError!,
            onRetry: provider.retryInitialization,
          );
        }
        if (!provider.initialized) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: Text('Carregando seus dados locais...')),
            ),
          );
        }

        if (exercises.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hoje'),
              actions: const [SettingsButton(), ThemeToggleButton()],
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 38,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Você não adicionou exercícios para $dayName.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Configure seu treino para deixar tudo pronto antes de ir à academia.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF636E72),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onConfigurePlan,
                          icon: const Icon(Icons.add),
                          label: const Text('Configurar Treino'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hoje'),
            actions: <Widget>[
              if (provider.sessionActive)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: _TimerPill(
                      text: _formatDuration(provider.sessionElapsed),
                    ),
                  ),
                ),
              const SettingsButton(),
              const ThemeToggleButton(),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        dayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          const Expanded(child: Text('Descanso entre séries')),
                          OutlinedButton.icon(
                            onPressed: provider.sessionActive
                                ? null
                                : () => _openRestDurationPicker(provider),
                            icon: const Icon(Icons.timer_outlined),
                            label: Text(
                              _formatRestDuration(provider.restDurationSeconds),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.sessionActive
                              ? null
                              : () => _startWorkout(provider, weekday),
                          icon: Icon(
                            provider.sessionActive
                                ? Icons.timer
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            provider.sessionActive
                                ? 'Treino em andamento'
                                : 'Iniciar Treino',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return _WorkoutExerciseCard(
                        exercise: exercise,
                        enabled:
                            provider.sessionActive &&
                            provider.sessionWeekday == weekday,
                        onToggleSet: (seriesIndex, checked) {
                          final marked = provider.toggleSeries(
                            exercise,
                            seriesIndex,
                          );
                          if (marked && checked) {
                            _showRestSheet(provider);
                          }
                        },
                        isSetCompleted: provider.isSetCompleted,
                        currentLoad: (seriesIndex) =>
                            provider.currentLoad(exercise, seriesIndex),
                        onLoadChanged: (seriesIndex, value) => provider
                            .setCurrentLoad(exercise, seriesIndex, value),
                      );
                    },
                  ),
                ),
                if (provider.sessionActive &&
                    provider.sessionWeekday == weekday)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3436),
                        ),
                        onPressed: () => _finishWorkout(context, provider),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Finalizar Treino'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startWorkout(WorkoutProvider provider, int weekday) async {
    try {
      await provider.startWorkout(weekday);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível iniciar o treino: $error')),
      );
    }
  }

  void _showRestSheet(WorkoutProvider provider) {
    if (_restSheetOpen || !mounted) return;
    _restSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestTimerSheet(provider: provider),
    ).whenComplete(() {
      _restSheetOpen = false;
    });
  }

  Future<void> _finishWorkout(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar treino?'),
        content: const Text(
          'A sessão será salva no histórico. Apenas as séries marcadas serão usadas na evolução de carga.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar treinando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (shouldFinish != true || !context.mounted) return;
    try {
      final historyId = await provider.finishWorkout();
      if (!context.mounted) return;
      if (historyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Marque pelo menos uma série concluída para salvar o treino.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino concluído e salvo no histórico.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o treino: $error')),
      );
    }
  }
}

class _WorkoutExerciseCard extends StatelessWidget {
  const _WorkoutExerciseCard({
    required this.exercise,
    required this.enabled,
    required this.onToggleSet,
    required this.isSetCompleted,
    required this.currentLoad,
    required this.onLoadChanged,
  });

  final WorkoutPlanModel exercise;
  final bool enabled;
  final void Function(int seriesIndex, bool checked) onToggleSet;
  final bool Function(WorkoutPlanModel exercise, int seriesIndex)
  isSetCompleted;
  final double Function(int seriesIndex) currentLoad;
  final void Function(int seriesIndex, double value) onLoadChanged;

  @override
  Widget build(BuildContext context) {
    final localPath = exercise.caminhoLocalGif;
    final hasLocalFile =
        localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (hasLocalFile) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Image.file(
                        File(localPath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const _ImageFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...<Widget>[
                  const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF6C5CE7),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exercise.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${exercise.series} séries × ${exercise.repeticoes} repetições',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (!hasLocalFile &&
                          localPath != null &&
                          localPath.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        const Text(
                          'Imagem não encontrada; exercício disponível normalmente.',
                          style: TextStyle(
                            color: Color(0xFF636E72),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            ...List<Widget>.generate(exercise.series, (seriesIndex) {
              final completed = isSetCompleted(exercise, seriesIndex);
              final load = currentLoad(seriesIndex);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      value: completed,
                      activeColor: const Color(0xFF6C5CE7),
                      onChanged: enabled
                          ? (value) => onToggleSet(seriesIndex, value ?? false)
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Série ${seriesIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${exercise.repeticoes} repetições',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: TextFormField(
                        key: ValueKey<String>(
                          'load-${exercise.id}-$seriesIndex',
                        ),
                        initialValue: _formatLoad(load),
                        enabled: enabled,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Carga (kg)',
                          suffixText: 'kg',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 11,
                          ),
                        ),
                        onChanged: (text) {
                          final parsed = double.tryParse(
                            text.trim().replaceAll(',', '.'),
                          );
                          if (parsed != null && parsed >= 0) {
                            onLoadChanged(seriesIndex, parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Inicie o treino para marcar as séries e editar as cargas.',
                  style: TextStyle(color: Color(0xFF636E72), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatLoad(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fitness_center,
        color: Color(0xFF6C5CE7),
        size: 30,
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6C5CE7)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestDurationPickerSheet extends StatefulWidget {
  const _RestDurationPickerSheet({
    required this.initialSeconds,
    required this.onConfirm,
  });

  final int initialSeconds;
  final ValueChanged<int> onConfirm;

  @override
  State<_RestDurationPickerSheet> createState() =>
      _RestDurationPickerSheetState();
}

class _RestDurationPickerSheetState extends State<_RestDurationPickerSheet> {
  static const int _maxSeconds = 600;
  static const double _dialSize = 260;

  late int _seconds;

  @override
  void initState() {
    super.initState();

    _seconds = widget.initialSeconds.clamp(0, _maxSeconds);
  }

  void _updateFromPosition(Offset position) {
    final center = Offset(_dialSize / 2, _dialSize / 2);

    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Evita alterar o tempo ao tocar perto do centro.
    if (math.sqrt(dx * dx + dy * dy) < 55) {
      return;
    }

    final angle = math.atan2(dy, dx);

    // O topo representa 00:00.
    // O tempo aumenta no sentido horário.
    final fraction = ((angle + math.pi / 2) / (2 * math.pi)) % 1.0;

    final newSeconds = (fraction * _maxSeconds).round().clamp(0, _maxSeconds);

    if (newSeconds != _seconds) {
      setState(() {
        _seconds = newSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Tempo de descanso',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deslize o dedo ao redor do círculo para escolher.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => _updateFromPosition(details.localPosition),
            onPanUpdate: (details) =>
                _updateFromPosition(details.localPosition),
            onTapDown: (details) => _updateFromPosition(details.localPosition),
            child: SizedBox(
              width: _dialSize,
              height: _dialSize,
              child: CustomPaint(
                painter: _RestDialPainter(seconds: _seconds, isDark: isDark),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.timer_outlined,
                        size: 28,
                        color: Color(0xFF6C5CE7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRestDuration(_seconds),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MIN : SEG',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_seconds);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestDialPainter extends CustomPainter {
  const _RestDialPainter({required this.seconds, required this.isDark});

  final int seconds;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const maxSeconds = 600;

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 16;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF343044) : const Color(0xFFEDE9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progress = seconds / maxSeconds;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // O marcador indica a posição selecionada no relógio.
    final angle = -math.pi / 2 + 2 * math.pi * progress;

    final markerCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    canvas.drawCircle(
      markerCenter,
      10,
      Paint()..color = const Color(0xFF6C5CE7),
    );

    canvas.drawCircle(markerCenter, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RestDialPainter oldDelegate) {
    return oldDelegate.seconds != seconds || oldDelegate.isDark != isDark;
  }
}

class _RestTimerSheet extends StatelessWidget {
  const _RestTimerSheet({required this.provider});
  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Consumer<WorkoutProvider>(
        builder: (context, state, _) {
          final remaining = state.restRemainingSeconds;
          final total = state.restDurationSeconds;
          final progress = total == 0
              ? 0.0
              : (remaining / total).clamp(0.0, 1.0).toDouble();
          final finished = !state.restTimerActive && remaining == 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF444451)
                      : const Color(0xFFDFE2E7),
                ),
              ),
              const SizedBox(height: 22),
              Icon(
                finished ? Icons.check_circle : Icons.hourglass_bottom_rounded,
                size: 38,
                color: const Color(0xFF6C5CE7),
              ),
              const SizedBox(height: 10),
              Text(
                finished ? 'Descanso concluído!' : 'Hora de descansar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: isDark
                            ? const Color(0xFF343044)
                            : const Color(0xFFEDE9FF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${remaining}s',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                finished
                    ? 'O descanso terminou. Você pode voltar à próxima série.'
                    : 'Respire, recupere-se e prepare-se para a próxima série.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    state.cancelRestTimer();
                    Navigator.of(context).pop();
                  },
                  child: Text(finished ? 'Continuar treino' : 'Pular descanso'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Color(0xFF6C5CE7),
              ),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

String _formatRestDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainingSeconds.toString().padLeft(2, '0')}';
}
