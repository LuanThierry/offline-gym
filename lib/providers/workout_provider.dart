import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/workout_plan_model.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._database);

  final DatabaseHelper _database;

  bool _isInitializing = false;
  bool _initialized = false;
  String? _lastError;
  Map<int, List<WorkoutPlanModel>> _plansByDay = <int, List<WorkoutPlanModel>>{};
  List<HistoryWorkoutModel> _history = <HistoryWorkoutModel>[];
  Set<DateTime> _completedDates = <DateTime>{};
  List<String> _plannedExerciseNames = <String>[];
  String? _selectedEvolutionExercise;
  List<EvolutionPoint> _evolutionPoints = <EvolutionPoint>[];
  List<BodyWeightRecord> _bodyWeights = <BodyWeightRecord>[];
  List<EvolutionPoint> _bodyWeightPoints = <EvolutionPoint>[];

  int _restDurationSeconds = 60;
  bool _sessionActive = false;
  int? _sessionWeekday;
  DateTime? _sessionStartedAt;
  Duration _sessionElapsed = Duration.zero;
  List<WorkoutPlanModel> _sessionExercises = <WorkoutPlanModel>[];
  Timer? _sessionTicker;
  Timer? _restTicker;
  bool _restTimerActive = false;
  int _restRemainingSeconds = 0;
  DateTime? _restEndsAt;
  final Set<String> _completedSetKeys = <String>{};
  final Map<String, double> _seriesLoads = <String, double>{};

  bool get initialized => _initialized;
  bool get isInitializing => _isInitializing;
  String? get lastError => _lastError;
  Map<int, List<WorkoutPlanModel>> get plansByDay => _plansByDay;
  List<HistoryWorkoutModel> get history => _history;
  Set<DateTime> get completedDates => _completedDates;
  List<String> get plannedExerciseNames => _plannedExerciseNames;
  String? get selectedEvolutionExercise => _selectedEvolutionExercise;
  List<EvolutionPoint> get evolutionPoints => _evolutionPoints;
  List<BodyWeightRecord> get bodyWeights => _bodyWeights;
  List<EvolutionPoint> get bodyWeightPoints => _bodyWeightPoints;
  int get restDurationSeconds => _restDurationSeconds;
  bool get sessionActive => _sessionActive;
  int? get sessionWeekday => _sessionWeekday;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  Duration get sessionElapsed => _sessionElapsed;
  List<WorkoutPlanModel> get sessionExercises => List<WorkoutPlanModel>.unmodifiable(_sessionExercises);
  bool get restTimerActive => _restTimerActive;
  int get restRemainingSeconds => _restRemainingSeconds;

  List<WorkoutPlanModel> plansForDay(int weekday) =>
      List<WorkoutPlanModel>.unmodifiable(
        _plansByDay[weekday] ?? const <WorkoutPlanModel>[],
      );

  Future<void> initialize() async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;
    _lastError = null;
    notifyListeners();
    try {
      await _reloadPlans(notify: false);
      await _reloadHistory(notify: false);
      await _restoreActiveWorkout();
      _initialized = true;
    } catch (error) {
      _lastError = 'Não foi possível carregar os dados locais: $error';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    _initialized = false;
    await initialize();
  }

  Future<void> _reloadPlans({bool notify = true}) async {
    _plansByDay = await _database.getAllDayPlans();
    for (var weekday = 1; weekday <= 7; weekday++) {
      _plansByDay.putIfAbsent(weekday, () => <WorkoutPlanModel>[]);
    }
    if (notify) notifyListeners();
  }

  Future<void> reloadPlans() => _reloadPlans();

  Future<void> saveDayExercises(
    int weekday,
    List<WorkoutPlanModel> exercises,
  ) async {
    if (_sessionActive && _sessionWeekday == weekday) {
      throw StateError('Finalize ou retome o treino em andamento antes de editar este dia.');
    }
    await _database.saveDayExercises(weekday, exercises);
    await _reloadPlans(notify: false);
    await _reloadHistory(notify: false);
    notifyListeners();
  }

  Future<void> _reloadHistory({bool notify = true}) async {
    _history = await _database.getWorkoutHistory();
    _completedDates = await _database.getCompletedWorkoutDates();
    _plannedExerciseNames = await _database.getDistinctPlannedExerciseNames();
    _bodyWeights = await _database.getBodyWeights();
    _bodyWeightPoints = await _database.getBodyWeightEvolution();

    if (_selectedEvolutionExercise == null ||
        !_plannedExerciseNames.contains(_selectedEvolutionExercise)) {
      _selectedEvolutionExercise = _plannedExerciseNames.isEmpty
          ? null
          : _plannedExerciseNames.first;
    }
    final selected = _selectedEvolutionExercise;
    _evolutionPoints = selected == null
        ? <EvolutionPoint>[]
        : await _database.getEvolutionPoints(selected);
    if (notify) notifyListeners();
  }

  Future<void> refreshHistory() => _reloadHistory();

  Future<void> selectEvolutionExercise(String exerciseName) async {
    if (!_plannedExerciseNames.contains(exerciseName)) return;
    _selectedEvolutionExercise = exerciseName;
    _evolutionPoints = <EvolutionPoint>[];
    notifyListeners();
    try {
      final points = await _database.getEvolutionPoints(exerciseName);
      if (_selectedEvolutionExercise == exerciseName) {
        _evolutionPoints = points;
        notifyListeners();
      }
    } catch (error) {
      _lastError = 'Não foi possível carregar a evolução: $error';
      notifyListeners();
    }
  }

  Future<void> deleteWorkoutSession(int id) async {
    await _database.deleteWorkoutSession(id);
    await _reloadHistory(notify: false);
    notifyListeners();
  }

  Future<void> saveBodyWeight({required DateTime date, required double weightKg}) async {
    await _database.insertBodyWeight(date: date, weightKg: weightKg);
    await _reloadHistory(notify: false);
    notifyListeners();
  }

  Future<void> deleteBodyWeight(int id) async {
    await _database.deleteBodyWeight(id);
    await _reloadHistory(notify: false);
    notifyListeners();
  }

  bool hasCompletedWorkoutOn(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _completedDates.contains(normalized);
  }

  void setRestDuration(int seconds) {
    if (![30, 60, 90].contains(seconds)) return;
    _restDurationSeconds = seconds;
    if (_sessionActive) {
      unawaited(_database.updateActiveWorkoutRest(
        descansoSegundos: seconds,
        descansoAteISO: _restEndsAt?.toIso8601String(),
      ));
    }
    notifyListeners();
  }

  Future<void> startWorkout(int weekday) async {
    if (_sessionActive) return;
    final exercises = plansForDay(weekday);
    if (exercises.isEmpty) return;
    if (exercises.any((exercise) => exercise.id == null)) {
      throw StateError('Um exercício do plano não tem ID local válido.');
    }

    _sessionWeekday = weekday;
    _sessionStartedAt = DateTime.now();
    _sessionElapsed = Duration.zero;
    _sessionExercises = List<WorkoutPlanModel>.of(exercises);
    _sessionActive = true;
    _completedSetKeys.clear();
    _seriesLoads.clear();
    for (final exercise in _sessionExercises) {
      for (var index = 0; index < exercise.series; index++) {
        _seriesLoads[_setKey(exercise, index)] = exercise.carga;
      }
    }

    try {
      await _persistActiveSnapshot();
      _startSessionTicker();
      notifyListeners();
    } catch (error) {
      _sessionActive = false;
      _sessionWeekday = null;
      _sessionStartedAt = null;
      _sessionExercises = <WorkoutPlanModel>[];
      _seriesLoads.clear();
      _completedSetKeys.clear();
      notifyListeners();
      rethrow;
    }
  }

  bool isSetCompleted(WorkoutPlanModel exercise, int zeroBasedSeriesIndex) =>
      _completedSetKeys.contains(_setKey(exercise, zeroBasedSeriesIndex));

  /// Alterna uma série e persiste o estado imediatamente para recuperar após
  /// um encerramento inesperado do processo Android.
  bool toggleSeries(WorkoutPlanModel exercise, int zeroBasedSeriesIndex) {
    if (!_sessionActive || zeroBasedSeriesIndex < 0 || zeroBasedSeriesIndex >= exercise.series) return false;
    final key = _setKey(exercise, zeroBasedSeriesIndex);
    final completedNow = !_completedSetKeys.contains(key);
    if (completedNow) {
      _completedSetKeys.add(key);
      startRestTimer();
    } else {
      _completedSetKeys.remove(key);
    }
    unawaited(_persistSeriesState(exercise, zeroBasedSeriesIndex));
    notifyListeners();
    return completedNow;
  }

  double currentLoad(WorkoutPlanModel exercise, int zeroBasedSeriesIndex) =>
      _seriesLoads[_setKey(exercise, zeroBasedSeriesIndex)] ?? exercise.carga;

  void setCurrentLoad(
    WorkoutPlanModel exercise,
    int zeroBasedSeriesIndex,
    double value,
  ) {
    if (!_sessionActive || !value.isFinite || value < 0 || zeroBasedSeriesIndex < 0 || zeroBasedSeriesIndex >= exercise.series) return;
    _seriesLoads[_setKey(exercise, zeroBasedSeriesIndex)] = value;
    unawaited(_persistSeriesState(exercise, zeroBasedSeriesIndex));
    notifyListeners();
  }

  Future<void> _persistSeriesState(WorkoutPlanModel exercise, int zeroBasedSeriesIndex) async {
    final id = exercise.id;
    if (id == null || !_sessionActive) return;
    try {
      await _database.updateActiveWorkoutSeries(
        exercisePlanId: id,
        serieNumero: zeroBasedSeriesIndex + 1,
        cargaAtual: currentLoad(exercise, zeroBasedSeriesIndex),
        concluido: isSetCompleted(exercise, zeroBasedSeriesIndex),
      );
    } catch (error) {
      _lastError = 'Não foi possível salvar o progresso da série: $error';
      notifyListeners();
    }
  }

  Future<void> _persistActiveSnapshot() async {
    final startedAt = _sessionStartedAt;
    final weekday = _sessionWeekday;
    if (startedAt == null || weekday == null) return;
    final exerciseSnapshots = <ActiveWorkoutExerciseModel>[];
    for (final exercise in _sessionExercises) {
      final progress = <ActiveWorkoutSeriesModel>[];
      for (var index = 0; index < exercise.series; index++) {
        progress.add(ActiveWorkoutSeriesModel(
          numeroSerie: index + 1,
          cargaAtual: currentLoad(exercise, index),
          concluido: isSetCompleted(exercise, index),
        ));
      }
      exerciseSnapshots.add(ActiveWorkoutExerciseModel(
        exercise: exercise,
        seriesProgress: progress,
      ));
    }
    await _database.saveActiveWorkoutSnapshot(ActiveWorkoutSnapshotModel(
      dataInicioISO: startedAt.toIso8601String(),
      diaSemana: weekday,
      descansoSegundos: _restDurationSeconds,
      descansoAteISO: _restEndsAt?.toIso8601String(),
      exercises: exerciseSnapshots,
    ));
  }

  Future<void> _restoreActiveWorkout() async {
    final snapshot = await _database.getActiveWorkoutSnapshot();
    if (snapshot == null) return;
    final startedAt = DateTime.tryParse(snapshot.dataInicioISO);
    if (startedAt == null) {
      await _database.deleteActiveWorkout();
      return;
    }

    _sessionStartedAt = startedAt;
    _sessionWeekday = snapshot.diaSemana;
    _sessionExercises = snapshot.exercises.map((item) => item.exercise).toList(growable: false);
    _restDurationSeconds = [30, 60, 90].contains(snapshot.descansoSegundos)
        ? snapshot.descansoSegundos
        : 60;
    _sessionActive = _sessionExercises.isNotEmpty;
    _sessionElapsed = DateTime.now().difference(startedAt);
    _completedSetKeys.clear();
    _seriesLoads.clear();

    for (final exerciseSnapshot in snapshot.exercises) {
      final exercise = exerciseSnapshot.exercise;
      for (final progress in exerciseSnapshot.seriesProgress) {
        final index = progress.numeroSerie - 1;
        _seriesLoads[_setKey(exercise, index)] = progress.cargaAtual;
        if (progress.concluido) _completedSetKeys.add(_setKey(exercise, index));
      }
    }

    _startSessionTicker();
    final restEnd = snapshot.descansoAteISO == null
        ? null
        : DateTime.tryParse(snapshot.descansoAteISO!);
    if (restEnd != null && restEnd.isAfter(DateTime.now())) {
      _startRestTimer(until: restEnd, persist: false);
    } else {
      _restTimerActive = false;
      _restRemainingSeconds = 0;
      _restEndsAt = null;
      await _database.updateActiveWorkoutRest(
        descansoSegundos: _restDurationSeconds,
        descansoAteISO: null,
      );
    }
  }

  void _startSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _sessionStartedAt;
      if (startedAt != null && _sessionActive) {
        _sessionElapsed = DateTime.now().difference(startedAt);
        notifyListeners();
      }
    });
  }

  void startRestTimer() => _startRestTimer();

  void _startRestTimer({DateTime? until, bool persist = true}) {
    _restTicker?.cancel();
    _restEndsAt = until ?? DateTime.now().add(Duration(seconds: _restDurationSeconds));
    _restRemainingSeconds = _restEndsAt!.difference(DateTime.now()).inSeconds.clamp(0, _restDurationSeconds + 1).toInt();
    _restTimerActive = _restRemainingSeconds > 0;
    if (persist && _sessionActive) {
      unawaited(_database.updateActiveWorkoutRest(
        descansoSegundos: _restDurationSeconds,
        descansoAteISO: _restEndsAt!.toIso8601String(),
      ));
    }
    notifyListeners();
    if (!_restTimerActive) {
      _restEndsAt = null;
      return;
    }
    _restTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final endAt = _restEndsAt;
      _restRemainingSeconds = endAt == null
          ? 0
          : endAt.difference(DateTime.now()).inSeconds.clamp(0, _restDurationSeconds + 1).toInt();
      if (_restRemainingSeconds <= 0) {
        timer.cancel();
        _restTicker = null;
        _restTimerActive = false;
        _restEndsAt = null;
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        if (_sessionActive) {
          unawaited(_database.updateActiveWorkoutRest(
            descansoSegundos: _restDurationSeconds,
            descansoAteISO: null,
          ));
        }
      }
      notifyListeners();
    });
  }

  void cancelRestTimer() {
    _restTicker?.cancel();
    _restTicker = null;
    _restTimerActive = false;
    _restRemainingSeconds = 0;
    _restEndsAt = null;
    if (_sessionActive) {
      unawaited(_database.updateActiveWorkoutRest(
        descansoSegundos: _restDurationSeconds,
        descansoAteISO: null,
      ));
    }
    notifyListeners();
  }

  /// Retorna null e mantém a sessão aberta se nenhuma série foi concluída.
  Future<int?> finishWorkout() async {
    if (!_sessionActive || _sessionWeekday == null) return null;
    final completedSets = <WorkoutSetModel>[];
    for (final exercise in _sessionExercises) {
      for (var index = 0; index < exercise.series; index++) {
        if (isSetCompleted(exercise, index)) {
          completedSets.add(WorkoutSetModel(
            nomeExercicio: exercise.nome,
            cargaUtilizada: currentLoad(exercise, index),
            serieNumero: index + 1,
          ));
        }
      }
    }
    if (completedSets.isEmpty) return null;

    final startedAt = _sessionStartedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final historyId = await _database.saveWorkoutSession(
      dataISO: startedAt.toIso8601String(),
      tempoTotalSegundos: elapsed.inSeconds,
      diaSemana: _sessionWeekday!,
      sets: completedSets,
    );

    _sessionTicker?.cancel();
    _sessionTicker = null;
    _restTicker?.cancel();
    _restTicker = null;
    _sessionActive = false;
    _sessionWeekday = null;
    _sessionStartedAt = null;
    _sessionElapsed = Duration.zero;
    _sessionExercises = <WorkoutPlanModel>[];
    _completedSetKeys.clear();
    _seriesLoads.clear();
    _restTimerActive = false;
    _restRemainingSeconds = 0;
    _restEndsAt = null;
    await _reloadHistory(notify: false);
    notifyListeners();
    return historyId;
  }

  String _setKey(WorkoutPlanModel exercise, int zeroBasedSeriesIndex) =>
      '${exercise.id ?? exercise.hashCode}:${zeroBasedSeriesIndex + 1}';

  @override
  void dispose() {
    _sessionTicker?.cancel();
    _restTicker?.cancel();
    super.dispose();
  }
}
