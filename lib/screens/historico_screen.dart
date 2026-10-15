import 'dart:math' as math;

import 'historico_treinos_completo_screen.dart';
import 'peso_corporal_completo_screen.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/workout_plan_model.dart';
import '../providers/workout_provider.dart';

import '../widgets/theme_toggle_button.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showBodyWeightChart = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final hasPlannedExercises = provider.plannedExerciseNames.isNotEmpty;
        final hasCompletedWorkouts = provider.history.isNotEmpty;
        final selectedDate = _selectedDay ?? _focusedDay;
        final hasTrainingSelected = provider.hasCompletedWorkoutOn(
          selectedDate,
        );
        final visibleHistory = provider.history.take(3).toList(growable: false);

        final visibleBodyWeights = provider.bodyWeights
            .take(3)
            .toList(growable: false);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Histórico e evolução'),
            actions: const [ThemeToggleButton()],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              if (!hasPlannedExercises || !hasCompletedWorkouts) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E7EF)),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(
                        Icons.insights_outlined,
                        color: Color(0xFF6C5CE7),
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhum histórico de evolução disponível. Conclua seu primeiro treino!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text('Relatório!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar<String>(
                    locale: 'pt_BR',
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime(2100, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        _selectedDay != null && isSameDay(_selectedDay, day),
                    eventLoader: (day) => provider.hasCompletedWorkoutOn(day)
                        ? const <String>['Treino concluído']
                        : const <String>[],
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => _focusedDay = focused,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFF6C5CE7),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 12,
                      ),
                      weekendStyle: TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 12,
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Color(0x338C7AE6),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF6C5CE7),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                      markerSize: 6,
                      markersMaxCount: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: hasTrainingSelected
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF183629)
                            : const Color(0xFFEAF8F0))
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasTrainingSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF285B40)
                              : const Color(0xFFBDE8CD))
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      hasTrainingSelected
                          ? Icons.check_circle
                          : Icons.event_available,
                      color: hasTrainingSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF6FD39A)
                                : const Color(0xFF238754))
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasTrainingSelected
                            ? 'Treino concluído em ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                            : 'Nenhum treino concluído em ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Evolução', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Exercício'),
                    selected: !_showBodyWeightChart,
                    onSelected: (_) =>
                        setState(() => _showBodyWeightChart = false),
                  ),
                  ChoiceChip(
                    label: const Text('Peso corporal'),
                    selected: _showBodyWeightChart,
                    onSelected: (_) =>
                        setState(() => _showBodyWeightChart = true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _showBodyWeightChart
                      ? _buildBodyWeightChart(provider)
                      : _buildExerciseChart(
                          context,
                          provider,
                          hasPlannedExercises,
                          hasCompletedWorkouts,
                        ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Peso corporal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _registerBodyWeight(context, provider),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registrar meu peso'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (provider.bodyWeights.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum peso corporal registrado ainda.',
                      style: TextStyle(color: Color(0xFF636E72)),
                    ),
                  ),
                )
              else ...<Widget>[
                ...visibleBodyWeights.map((record) {
                  final date =
                      DateTime.tryParse(record.dataISO) ?? DateTime.now();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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
                        title: Text('${record.pesoKg.toStringAsFixed(1)} kg'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                        trailing: IconButton(
                          tooltip: 'Excluir registro de peso',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFD63031),
                          ),
                          onPressed: () =>
                              _deleteBodyWeight(context, provider, record.id),
                        ),
                      ),
                    ),
                  );
                }),
                if (provider.bodyWeights.length > 3)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PesoCorporalCompletoScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Ver todos (${provider.bodyWeights.length})'),
                    ),
                  ),
              ],

              const SizedBox(height: 18),

              Text(
                'Últimos treinos',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 10),

              if (provider.history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhum treino concluído foi registrado.'),
                  ),
                )
              else ...<Widget>[
                ...visibleHistory.map((workout) {
                  final date =
                      DateTime.tryParse(workout.dataISO) ?? DateTime.now();

                  final duration = Duration(
                    seconds: workout.tempoTotalSegundos,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        title: Text(
                          WorkoutPlanModel.weekdayName(workout.diaSemana),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy · HH:mm').format(date),
                        ),
                        trailing: SizedBox(
                          width: 115,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _durationText(duration),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Excluir treino do histórico',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFD63031),
                                ),
                                onPressed: () => _deleteWorkout(
                                  context,
                                  provider,
                                  workout.id,
                                  date,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (provider.history.length > 3)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const HistoricoTreinosCompletoScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Ver todos (${provider.history.length})'),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseChart(
    BuildContext context,
    WorkoutProvider provider,
    bool hasPlannedExercises,
    bool hasCompletedWorkouts,
  ) {
    if (!hasPlannedExercises || !hasCompletedWorkouts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          'Nenhum histórico de evolução disponível. Conclua seu primeiro treino!',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: provider.selectedEvolutionExercise,
          decoration: const InputDecoration(
            labelText: 'Exercício do seu plano',
            prefixIcon: Icon(Icons.fitness_center),
          ),
          items: provider.plannedExerciseNames
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) provider.selectEvolutionExercise(value);
          },
        ),
        const SizedBox(height: 18),
        if (provider.evolutionPoints.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Text(
              'Ainda não há séries concluídas para este exercício. Marque séries durante um treino e finalize a sessão para registrar a evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF636E72)),
            ),
          )
        else ...<Widget>[
          Text(
            'Carga máxima por dia (kg)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: _EvolutionLineChart(points: provider.evolutionPoints),
          ),
        ],
      ],
    );
  }

  Widget _buildBodyWeightChart(WorkoutProvider provider) {
    if (provider.bodyWeightPoints.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          'Registre seu peso corporal para acompanhar sua evolução.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF636E72)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Evolução do peso corporal (kg)'),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _EvolutionLineChart(points: provider.bodyWeightPoints),
        ),
      ],
    );
  }

  Future<void> _registerBodyWeight(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final input = await showDialog<_BodyWeightInput>(
      context: context,
      builder: (_) => const _BodyWeightDialog(),
    );
    if (input == null || !context.mounted) return;
    try {
      await provider.saveBodyWeight(date: input.date, weightKg: input.weightKg);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso corporal registrado.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar o peso: $error')),
      );
    }
  }

  Future<void> _deleteBodyWeight(
    BuildContext context,
    WorkoutProvider provider,
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
    await provider.deleteBodyWeight(id);
  }

  Future<void> _deleteWorkout(
    BuildContext context,
    WorkoutProvider provider,
    int id,
    DateTime date,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir treino do histórico?'),
        content: Text(
          'O treino de ${DateFormat('dd/MM/yyyy HH:mm').format(date)} e suas séries serão removidos.',
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
      await provider.deleteWorkoutSession(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino removido do histórico.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o treino: $error')),
      );
    }
  }
}

class _BodyWeightInput {
  const _BodyWeightInput({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

class _BodyWeightDialog extends StatefulWidget {
  const _BodyWeightDialog();

  @override
  State<_BodyWeightDialog> createState() => _BodyWeightDialogState();
}

class _BodyWeightDialogState extends State<_BodyWeightDialog> {
  final TextEditingController _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      locale: const Locale('pt', 'BR'),
    );
    if (selected != null && mounted) setState(() => _selectedDate = selected);
  }

  void _save() {
    final parsed = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed > 500) {
      setState(() => _error = 'Informe um peso válido em kg.');
      return;
    }
    Navigator.of(context).pop(
      _BodyWeightInput(
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        weightKg: parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar meu peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _chooseDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso corporal (kg)',
              hintText: 'Ex.: 68,5',
              suffixText: 'kg',
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD63031), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}

class _EvolutionLineChart extends StatelessWidget {
  const _EvolutionLineChart({required this.points});

  final List<EvolutionPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].loadKg),
    ];
    final loads = points.map((point) => point.loadKg).toList(growable: false);
    final minLoad = loads.reduce((a, b) => math.min(a, b).toDouble());
    final maxLoad = loads.reduce((a, b) => math.max(a, b).toDouble());
    final minY = math
        .max(0.0, minLoad - (minLoad > 0 ? minLoad * 0.12 : 0))
        .toDouble();
    final maxY = (maxLoad + (maxLoad > 0 ? maxLoad * 0.12 : 5)).toDouble();
    final maxX = points.length <= 1 ? 0.5 : (points.length - 1).toDouble();
    final interval = points.length > 6
        ? (points.length / 5).ceilToDouble()
        : 1.0;

    return LineChart(
      LineChartData(
        minX: points.length == 1 ? -0.5 : 0.0,
        maxX: maxX,
        minY: minY,
        maxY: maxY <= minY ? minY + 5 : maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('kg', style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if ((value - index).abs() > 0.15 ||
                    index < 0 ||
                    index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(points[index].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((spot) {
                  final index = spot.x
                      .round()
                      .clamp(0, points.length - 1)
                      .toInt();
                  final point = points[index];
                  return LineTooltipItem(
                    '${point.loadKg.toStringAsFixed(1)} kg\n${DateFormat('dd/MM/yyyy').format(point.date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF6C5CE7),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0x226C5CE7),
            ),
          ),
        ],
      ),
    );
  }
}

String _durationText(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m ${seconds}s';
}
