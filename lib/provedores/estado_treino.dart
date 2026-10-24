import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../banco_dados/banco_de_dados.dart';
import '../dominio/calculadora_de_cargas.dart';
import '../dominio/catalogo_exercicios_offline.dart';
import '../dominio/coach_cientifico.dart';
import '../dominio/regras_de_ofensiva.dart';
import '../dominio/volume_muscular.dart';
import '../modelos/habito.dart';
import '../modelos/plano_de_treino.dart';
import '../servicos/som_do_alarme.dart';
import '../servicos/notificacoes_de_treino.dart';

class ProvedorDeTreino extends ChangeNotifier with WidgetsBindingObserver {
  ProvedorDeTreino(this._bancoDeDados) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  final BancoDeDados _bancoDeDados;

  bool _estaInicializando = false;
  bool _inicializado = false;
  String? _ultimoErro;
  Map<int, List<ExercicioPlanejado>> _planosPorDia =
      <int, List<ExercicioPlanejado>>{};
  Map<int, List<RotinaDeTreino>> _rotinasPorDia = <int, List<RotinaDeTreino>>{};
  PerfilDoUsuario? _perfil;
  List<TreinoDoHistorico> _historico = <TreinoDoHistorico>[];
  Set<DateTime> _datasConcluidas = <DateTime>{};
  List<String> _nomesDosExerciciosPlanejados = <String>[];
  String? _exercicioSelecionadoNaEvolucao;
  List<PontoDeEvolucao> _pontosDeEvolucao = <PontoDeEvolucao>[];
  List<DetalheEvolucaoDoExercicio> _detalhesDaEvolucao =
      <DetalheEvolucaoDoExercicio>[];
  List<RegistroDePesoCorporal> _pesosCorporais = <RegistroDePesoCorporal>[];
  List<RegistroDeMedidasCorporais> _medidasCorporais =
      <RegistroDeMedidasCorporais>[];
  List<PontoDeEvolucao> _pontosDePesoCorporal = <PontoDeEvolucao>[];
  List<FotoMensalDeEvolucao> _fotosMensaisDeEvolucao = <FotoMensalDeEvolucao>[];
  String? _mesDaFotoMensalAdiado;
  List<Habito> _habitos = <Habito>[];
  List<TarefaToDo> _tarefas = <TarefaToDo>[];
  Map<String, double> _recordesDeCargaPorExercicio = <String, double>{};
  Map<String, List<SerieDoTreino>> _ultimasSeriesPorExercicio =
      <String, List<SerieDoTreino>>{};
  Map<String, int> _contagemHabitosPorData = <String, int>{};
  Set<DateTime> _datasProtegidasPorEscudo = <DateTime>{};

  bool _sessaoAtiva = false;
  int? _diaDaSessao;
  DateTime? _inicioDaSessao;
  Duration _tempoDecorridoDaSessao = Duration.zero;
  final ValueNotifier<Duration> _duracaoDaSessaoNotifier =
      ValueNotifier<Duration>(Duration.zero);
  List<ExercicioPlanejado> _exerciciosDaSessao = <ExercicioPlanejado>[];
  List<String> _nomesDasRotinasDaSessao = <String>[];
  Timer? _cronometroDaSessao;

  // Guarda a contagem e o exercício do descanso que está ativo.
  int? _idExercicioComCronometroAtivo;
  int _duracaoTotalDoCronometro = 0;
  int _tempoRestanteDoCronometro = 0;
  final ValueNotifier<int> _tempoRestanteDescansoNotifier =
      ValueNotifier<int>(0);
  bool _cronometroFinalizado = false;
  DateTime? _fimDoCronometro;
  Timer? _cronometroDeDescanso;
  int _idExecucaoDescansoAtual = 0;
  ResultadoAgendamentoDescanso? _ultimoResultadoAgendamento;

  @visibleForTesting
  bool? mockIsAppForeground;

  @visibleForTesting
  DateTime Function()? relogioParaTestes;

  @visibleForTesting
  Timer Function(Duration duration, void Function(Timer timer) callback)?
      criadorDeTimerParaTestes;

  DateTime get _agora =>
      relogioParaTestes != null ? relogioParaTestes!() : DateTime.now();

  final Set<String> _chavesDasSeriesConcluidas = <String>{};
  final Map<String, double> _cargasDasSeries = <String, double>{};
  final Map<String, int> _repeticoesDasSeries = <String, int>{};
  final Map<String, String> _tiposDasSeries = <String, String>{};
  final Map<String, double> _rpeDasSeries = <String, double>{};
  final ValueNotifier<int> _abrirHabitosHojeNotifier = ValueNotifier<int>(0);

  bool get inicializado => _inicializado;
  bool get estaInicializando => _estaInicializando;
  String? get ultimoErro => _ultimoErro;
  Map<int, List<ExercicioPlanejado>> get planosPorDia => _planosPorDia;
  PerfilDoUsuario? get perfil => _perfil;
  Map<int, List<RotinaDeTreino>> get rotinasPorDia => _rotinasPorDia;
  List<TreinoDoHistorico> get historico => _historico;
  Set<DateTime> get completedDates => _datasConcluidas;
  Set<DateTime> get datasProtegidasPorEscudo =>
      Set<DateTime>.unmodifiable(_datasProtegidasPorEscudo);
  Map<String, int> get contagemHabitosPorData =>
      Map<String, int>.unmodifiable(_contagemHabitosPorData);
  List<String> get nomesDosExerciciosPlanejados =>
      _nomesDosExerciciosPlanejados;
  String? get exercicioSelecionadoNaEvolucao => _exercicioSelecionadoNaEvolucao;
  List<PontoDeEvolucao> get pontosDeEvolucao => _pontosDeEvolucao;
  List<DetalheEvolucaoDoExercicio> get detalhesDaEvolucao =>
      _detalhesDaEvolucao;
  List<RegistroDePesoCorporal> get pesosCorporais => _pesosCorporais;
  List<RegistroDeMedidasCorporais> get medidasCorporais =>
      List<RegistroDeMedidasCorporais>.unmodifiable(_medidasCorporais);
  RegistroDeMedidasCorporais? get ultimasMedidasCorporais =>
      _medidasCorporais.isEmpty ? null : _medidasCorporais.first;
  List<PontoDeEvolucao> get pontosDePesoCorporal => _pontosDePesoCorporal;
  List<FotoMensalDeEvolucao> get fotosMensaisDeEvolucao =>
      List<FotoMensalDeEvolucao>.unmodifiable(_fotosMensaisDeEvolucao);
  List<Habito> get habitos => List<Habito>.unmodifiable(_habitos);
  List<Habito> habitosDoDia(int diaSemana) => _habitos
      .where((h) => h.ativo && h.seAplicaAoDia(diaSemana))
      .toList(growable: false);
  List<Habito> get habitosDeHoje => habitosDoDia(DateTime.now().weekday);
  int get totalHabitosDeHoje => habitosDeHoje.length;
  int get habitosConcluidosHoje =>
      habitosDeHoje.where((h) => h.concluidoHoje).length;
  double get taxaConclusaoHabitosHoje => totalHabitosDeHoje == 0
      ? 0.0
      : (habitosConcluidosHoje / totalHabitosDeHoje);
  bool get diaPerfeitoDeHabitosHoje =>
      totalHabitosDeHoje > 0 && habitosConcluidosHoje == totalHabitosDeHoje;

  List<TarefaToDo> get tarefas => List<TarefaToDo>.unmodifiable(_tarefas);
  List<TarefaToDo> get tarefasPendentes =>
      _tarefas.where((t) => !t.concluida).toList(growable: false);
  List<TarefaToDo> get tarefasConcluidas =>
      _tarefas.where((t) => t.concluida).toList(growable: false);
  bool get sessaoAtiva => _sessaoAtiva;
  int? get diaDaSessao => _diaDaSessao;
  DateTime? get inicioDaSessao => _inicioDaSessao;
  Duration get duracaoDaSessao => _tempoDecorridoDaSessao;
  ValueListenable<Duration> get duracaoDaSessaoListenable =>
      _duracaoDaSessaoNotifier;
  ValueListenable<int> get abrirHabitosHojeListenable =>
      _abrirHabitosHojeNotifier;

  void solicitarAbrirHabitosHoje() {
    _abrirHabitosHojeNotifier.value++;
  }

  List<ExercicioPlanejado> get exerciciosDaSessao =>
      List<ExercicioPlanejado>.unmodifiable(_exerciciosDaSessao);
  String get nomeDoTreinoDaSessao => _nomesDasRotinasDaSessao.join(' + ');
  double? get pesoCorporalAtualKg =>
      _pesosCorporais.isEmpty ? null : _pesosCorporais.first.pesoKg;

  /// Retorna a maior carga histórica registrada para o exercício (em kg).
  double recordePessoalDoExercicio(String nomeDoExercicio) =>
      _recordesDeCargaPorExercicio[nomeDoExercicio.trim().toLowerCase()] ?? 0.0;

  /// Preenche o plano selecionado com a última carga/repetições registradas,
  /// sem apagar séries ou exercícios que não possuem histórico.
  Future<void> repetirUltimaSessaoComCargas(int diaSemana) async {
    final atuais = planosDoDia(diaSemana);
    for (final exercicio in atuais) {
      final ultimas = ultimasSeriesDoExercicio(exercicio.nome);
      if (ultimas.isEmpty) continue;
      final melhor = ultimas.lastWhere(
        (serie) => serie.tipo != 'aquecimento',
        orElse: () => ultimas.last,
      );
      await atualizarDetalhesDoExercicio(
        exercicio,
        carga: melhor.cargaUtilizada,
        repeticoes: melhor.repeticoes,
      );
    }
    await _recarregarPlanos(notify: false);
    notifyListeners();
  }

  /// Retorna o volume total (tonelagem em kg) levantado na sessão ativa em tempo real.
  double get volumeTotalDaSessaoKg {
    if (!_sessaoAtiva) return 0.0;
    var total = 0.0;
    for (final exercicio in _exerciciosDaSessao) {
      for (var i = 0; i < exercicio.series; i++) {
        if (serieEstaConcluida(exercicio, i)) {
          final carga = cargaAtual(exercicio, i);
          final reps = repeticoesAtuais(exercicio, i);
          total += (carga * reps);
        }
      }
    }
    return total;
  }

  /// Retorna o volume de séries completadas nos últimos 7 dias classificado por marcos hipertróficos.
  Future<List<MarcoDeVolumeMuscular>> obterVolumeSemanalPorMusculo(
      {int dias = 7}) async {
    final series =
        await _bancoDeDados.obterSeriesConcluidasNosUltimosDias(dias);
    final contagemPorGrupo = <String, int>{};

    for (final s in series) {
      if (s.tipo == 'aquecimento') continue;
      final grupo =
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(s.nomeExercicio);
      contagemPorGrupo[grupo] = (contagemPorGrupo[grupo] ?? 0) + 1;
    }

    const gruposPadrao = <String>[
      'Peito',
      'Costas',
      'Quadríceps',
      'Posterior & Glúteos',
      'Ombros',
      'Bíceps',
      'Tríceps',
      'Panturrilhas',
      'Abdômen & Core',
    ];

    return gruposPadrao.map((grupo) {
      final total = contagemPorGrupo[grupo] ?? 0;
      return MarcoDeVolumeMuscular.criar(
        grupoMuscular: grupo,
        seriesCompletadas: total,
      );
    }).toList(growable: false);
  }

  DiagnosticoDoCoach? _diagnosticoDoCoachCache;

  /// Invalida o cache do diagnóstico do Coach Científico para forçar novo cálculo.
  void invalidarCacheCoach() {
    _diagnosticoDoCoachCache = null;
  }

  /// Retorna o diagnóstico fisiológico completo sintetizado pelo Coach Científico Offline.
  Future<DiagnosticoDoCoach> obterDiagnosticoDoCoach({
    int dias = 7,
    bool forcarRecalculo = false,
  }) async {
    if (!forcarRecalculo && _diagnosticoDoCoachCache != null && dias == 7) {
      return _diagnosticoDoCoachCache!;
    }
    final volumes = await obterVolumeSemanalPorMusculo(dias: dias);
    final ultimasSessoes =
        await _bancoDeDados.obterUltimaDataPorExercicioConcluido();
    final ultimosTreinosPorGrupo = <String, DateTime>{};
    for (final item in ultimasSessoes) {
      final nome = item['nomeExercicio'] ?? '';
      final dataStr = item['ultimaData'] ?? '';
      if (nome.isEmpty || dataStr.isEmpty) continue;
      final data = DateTime.tryParse(dataStr);
      if (data == null) continue;
      final grupo =
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(nome);
      final atual = ultimosTreinosPorGrupo[grupo];
      if (atual == null || data.isAfter(atual)) {
        ultimosTreinosPorGrupo[grupo] = data;
      }
    }

    final seriesRecentes =
        await _bancoDeDados.obterSeriesConcluidasNosUltimosDias(30);
    final platos = CoachCientificoOffline.detectarPlatos(seriesRecentes);

    final resultado = CoachCientificoOffline.analisarTreinamento(
      perfil: _perfil,
      volumeSemanal: volumes,
      historico: _historico,
      diasOfensiva: ofensivaAtual,
      pesoAtualKg: pesoCorporalAtualKg,
      ultimosTreinosPorGrupo: ultimosTreinosPorGrupo,
      exerciciosPlanejados: todosOsExerciciosPlanejadosNaSemana,
      prontidaoHoje: _prontidaoHoje,
      platosDetectados: platos,
    );

    if (dias == 7) {
      _diagnosticoDoCoachCache = resultado;
    }
    return resultado;
  }

  /// Quantidade de escudos de ofensiva disponíveis (ganha 1 a cada 4 dias de treino + 1 inicial).
  int get escudosDisponiveis {
    final ganhos = 1 + (_datasConcluidas.length ~/ 4);
    final restantes = ganhos - _datasProtegidasPorEscudo.length;
    return restantes.clamp(0, 5);
  }

  /// Verifica se hoje já está protegido por escudo de descanso.
  bool get hojeProtegidoPorEscudo {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return _datasProtegidasPorEscudo.contains(hoje);
  }

  /// Conta dias consecutivos com treino concluído (ou protegidos por escudo).
  int get ofensivaAtual => OfensivaTreino.calcularDiasConsecutivos(
        _datasConcluidas,
        DateTime.now(),
        datasProtegidas: _datasProtegidasPorEscudo,
      );

  /// Conta quantos dias diferentes tiveram treino na semana que contém a data.
  int treinosNaSemana(DateTime referencia) =>
      OfensivaTreino.contarDiasNaSemana(_datasConcluidas, referencia);

  // Consultas usadas pelos cartões para desenhar o cronômetro por exercício.
  int? get idExercicioComCronometroAtivo => _idExercicioComCronometroAtivo;
  int get duracaoTotalDoCronometro => _duracaoTotalDoCronometro;
  int get tempoRestanteDoCronometro => _tempoRestanteDoCronometro;
  ValueListenable<int> get tempoRestanteDescansoListenable =>
      _tempoRestanteDescansoNotifier;
  bool get cronometroConcluido => _cronometroFinalizado;
  int get idExecucaoDescansoAtual => _idExecucaoDescansoAtual;
  ResultadoAgendamentoDescanso? get ultimoResultadoAgendamento =>
      _ultimoResultadoAgendamento;
  StatusPermissaoNotificacao get statusPermissaoNotificacao =>
      ServicoDeNotificacoesDeTreino.instance.statusPermissaoNotificacao;
  Future<CapacidadeAlarmeExato> verificarCapacidadeAlarmeExato() =>
      ServicoDeNotificacoesDeTreino.instance.verificarCapacidadeAlarmeExato();

  bool get isAppForeground {
    if (mockIsAppForeground != null) return mockIsAppForeground!;
    try {
      final state = WidgetsBinding.instance.lifecycleState;
      return state == null || state == AppLifecycleState.resumed;
    } catch (_) {
      return true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(aoRetornarParaPrimeiroPlano());
    }
  }

  Future<void> aoRetornarParaPrimeiroPlano() async {
    final execucao = _idExecucaoDescansoAtual;
    // Antes de qualquer await, impede ticks de reproduzirem áudio retroativo.
    final endsAt = _fimDoCronometro;
    final now = _agora;
    if (endsAt != null && !endsAt.isAfter(now)) {
      // O descanso terminou enquanto o app estava em segundo plano / tela bloqueada.
      // Preserva o aviso nativo; não há confirmação de entrega pelo sistema.
      _cronometroDeDescanso?.cancel();
      _cronometroDeDescanso = null;
      _tempoRestanteDoCronometro = 0;
      _tempoRestanteDescansoNotifier.value = 0;
      _cronometroFinalizado = true;
      _fimDoCronometro = null;
      if (_sessaoAtiva) {
        unawaited(
          _bancoDeDados.atualizarDescansoDoTreinoEmAndamento(
            descansoSegundos: _duracaoTotalDoCronometro,
            descansoAteISO: null,
            idExercicioDescanso: _idExercicioComCronometroAtivo,
          ),
        );
      }
      notifyListeners();
    } else if (endsAt != null) {
      final diffMs = endsAt.difference(now).inMilliseconds;
      final remaining =
          (diffMs / 1000).ceil().clamp(0, _duracaoTotalDoCronometro).toInt();
      _tempoRestanteDoCronometro = remaining;
      _tempoRestanteDescansoNotifier.value = remaining;
      notifyListeners();
    }

    final notificacoes = ServicoDeNotificacoesDeTreino.instance;
    if (notificacoes.temLimpezaPendente) {
      await notificacoes.tentarRecuperarCancelamentoPendente();
      if (execucao != _idExecucaoDescansoAtual) return;
    }
    await notificacoes.atualizarStatusPermissaoSilenciosamente();
    if (execucao != _idExecucaoDescansoAtual) return;
    if (_idExercicioComCronometroAtivo == null || _cronometroFinalizado) return;
    final estadoCanal = await notificacoes.verificarEstadoDoCanalDescanso();
    if (execucao != _idExecucaoDescansoAtual || _cronometroFinalizado) return;
    if (estadoCanal != null) {
      _ultimoResultadoAgendamento = estadoCanal;
      notifyListeners();
    }
    // Autorização concedida não comprova que um descanso antes bloqueado foi
    // agendado. Não apaga o aviso técnico nem inventa sucesso de agendamento.
  }

  bool cronometroEstaAtivoPara(int idDoExercicio) =>
      _idExercicioComCronometroAtivo == idDoExercicio &&
      !_cronometroFinalizado &&
      _tempoRestanteDoCronometro > 0;

  bool cronometroTerminouPara(int idDoExercicio) =>
      _idExercicioComCronometroAtivo == idDoExercicio && _cronometroFinalizado;

  int tempoRestantePara(int idDoExercicio) =>
      _idExercicioComCronometroAtivo == idDoExercicio
          ? _tempoRestanteDoCronometro
          : 0;

  List<ExercicioPlanejado> planosDoDia(int diaSemana) =>
      List<ExercicioPlanejado>.unmodifiable(
        _planosPorDia[diaSemana] ?? const <ExercicioPlanejado>[],
      );

  List<RotinaDeTreino> rotinasDoDia(int diaSemana) =>
      List<RotinaDeTreino>.unmodifiable(
        _rotinasPorDia[diaSemana] ?? const <RotinaDeTreino>[],
      );

  List<RotinaDeTreino> rotinasSelecionadasDoDia(int diaSemana) =>
      rotinasDoDia(diaSemana)
          .where((rotina) => rotina.selecionado && rotina.exercicios.isNotEmpty)
          .toList(growable: false);

  List<ExercicioPlanejado> exerciciosSelecionadosDoDia(int diaSemana) =>
      rotinasSelecionadasDoDia(
        diaSemana,
      ).expand((rotina) => rotina.exercicios).toList(growable: false);

  /// Retorna todos os exercícios planejados ativos da semana (de segunda a domingo).
  List<ExercicioPlanejado> get todosOsExerciciosPlanejadosNaSemana {
    final todos = <ExercicioPlanejado>[];
    for (int dia = 1; dia <= 7; dia++) {
      final selecionados = exerciciosSelecionadosDoDia(dia);
      if (selecionados.isNotEmpty) {
        todos.addAll(selecionados);
      } else {
        todos.addAll(planosDoDia(dia));
      }
    }
    return List<ExercicioPlanejado>.unmodifiable(todos);
  }

  Future<void> inicializar() async {
    if (_inicializado || _estaInicializando) return;
    _estaInicializando = true;
    _ultimoErro = null;
    notifyListeners();
    try {
      await Future.wait(<Future<void>>[
        ServicoDeSomDoAlarme.instance.inicializar().catchError((_) {}),
        ServicoDeNotificacoesDeTreino.instance.inicializar().catchError((_) {}),
        _carregarDesafioFotoMensalAdiado(),
        _carregarEscudosDeOfensiva(),
        _carregarProntidaoDeHoje(),
      ]);
      _perfil = await _bancoDeDados.obterPerfilDoUsuario();
      await Future.wait(<Future<void>>[
        _recarregarPlanos(notify: false),
        _recarregarHistorico(notify: false, recarregarContagemHabitos: false),
        _recarregarHabitos(notify: false),
        _recarregarTarefas(notify: false),
      ]);
      await _sincronizarLembretesDeTreino();
      await _restaurarTreinoEmAndamento();
      _inicializado = true;
    } catch (erro) {
      _ultimoErro = 'Não foi possível carregar os dados locais: $erro';
    } finally {
      _estaInicializando = false;
      notifyListeners();
    }
  }

  RegistroDeProntidaoDiaria? _prontidaoHoje;
  RegistroDeProntidaoDiaria? get prontidaoHoje => _prontidaoHoje;

  Future<void> _carregarProntidaoDeHoje() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now();
      final chave = 'prontidao_${hoje.year}_${hoje.month}_${hoje.day}';
      final jsonStr = prefs.getString(chave);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, Object?>;
        _prontidaoHoje = RegistroDeProntidaoDiaria.deMapa(map);
      } else {
        _prontidaoHoje = null;
      }
    } catch (_) {
      _prontidaoHoje = null;
    }
  }

  Future<void> salvarProntidaoDeHoje({
    required int energia,
    required int sono,
    required int dorArticular,
    String? articulacaoComDor,
  }) async {
    final registro = RegistroDeProntidaoDiaria(
      energia: energia,
      sono: sono,
      dorArticular: dorArticular,
      articulacaoComDor: articulacaoComDor,
    );
    _prontidaoHoje = registro;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now();
      final chave = 'prontidao_${hoje.year}_${hoje.month}_${hoje.day}';
      await prefs.setString(chave, jsonEncode(registro.paraMapa()));
    } catch (_) {}
  }

  Future<void> _carregarEscudosDeOfensiva() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final salvos = preferencias.getStringList('datas_protegidas_escudo_v1') ??
          const <String>[];
      _datasProtegidasPorEscudo = salvos
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet();
    } catch (_) {
      _datasProtegidasPorEscudo = <DateTime>{};
    }
  }

  /// Ativa um Escudo de Descanso para proteger a ofensiva hoje (ou ontem, se ontem não houve treino).
  Future<bool> usarEscudoDeOfensiva({DateTime? data}) async {
    if (escudosDisponiveis <= 0) return false;
    final agora = data ?? DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));

    DateTime alvo = hoje;
    if (!_datasConcluidas.contains(ontem) &&
        !_datasProtegidasPorEscudo.contains(ontem) &&
        _datasConcluidas.any((d) => d.isBefore(ontem))) {
      alvo = ontem;
    }
    if (_datasProtegidasPorEscudo.contains(alvo)) {
      if (alvo != hoje && !_datasProtegidasPorEscudo.contains(hoje)) {
        alvo = hoje;
      } else {
        return false;
      }
    }

    _datasProtegidasPorEscudo = <DateTime>{
      ..._datasProtegidasPorEscudo,
      alvo,
    };
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setStringList(
        'datas_protegidas_escudo_v1',
        _datasProtegidasPorEscudo
            .map(
              (d) =>
                  '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            )
            .toList(growable: false),
      );
    } catch (_) {}
    notifyListeners();
    return true;
  }

  Future<void> tentarInicializacaoNovamente() async {
    _inicializado = false;
    await inicializar();
  }

  Future<void> _recarregarPlanos({bool notify = true}) async {
    final resultados = await Future.wait<Object>(<Future<Object>>[
      _bancoDeDados.obterPlanosDeTodosOsDias(),
      _bancoDeDados.obterRotinasDeTodosOsDias(),
    ]);
    _planosPorDia = resultados[0] as Map<int, List<ExercicioPlanejado>>;
    _rotinasPorDia = resultados[1] as Map<int, List<RotinaDeTreino>>;
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      _planosPorDia.putIfAbsent(diaSemana, () => <ExercicioPlanejado>[]);
    }
    if (notify) notifyListeners();
    _diagnosticoDoCoachCache = null;
  }

  Future<void> salvarRotinaDeTreino(RotinaDeTreino rotina) async {
    if (_sessaoAtiva && _diaDaSessao == rotina.diaSemana) {
      throw StateError(
        'Finalize o treino em andamento antes de editar este dia.',
      );
    }
    await _bancoDeDados.salvarRotinaDeTreino(rotina);
    await _recarregarPlanos(notify: false);
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> excluirRotinaDeTreino(int diaSemana, int idRotina) async {
    if (_sessaoAtiva && _diaDaSessao == diaSemana) {
      throw StateError(
        'Finalize o treino em andamento antes de editar este dia.',
      );
    }
    final remaining = rotinasDoDia(diaSemana)
        .where((rotina) => rotina.id != idRotina && rotina.selecionado)
        .toList(growable: false);
    if (remaining.isEmpty && rotinasDoDia(diaSemana).length > 1) {
      throw StateError('Mantenha pelo menos um treino selecionado neste dia.');
    }
    await _bancoDeDados.excluirRotinaDeTreino(diaSemana, idRotina);
    await _recarregarPlanos(notify: false);
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> definirRotinasSelecionadas(
    int diaSemana,
    Set<int> idsDasRotinas,
  ) async {
    if (_sessaoAtiva && _diaDaSessao == diaSemana) return;
    await _bancoDeDados.definirSelecaoDeRotinas(diaSemana, idsDasRotinas);
    await _recarregarPlanos(notify: false);
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> salvarPerfil(
    PerfilDoUsuario perfil, {
    double? currentWeightKg,
  }) async {
    await _bancoDeDados.salvarPerfilDoUsuario(
      perfil,
      currentWeightKg: currentWeightKg,
    );
    _perfil = perfil;
    if (currentWeightKg != null) {
      await _recarregarHistorico(notify: false);
    }
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> _sincronizarLembretesDeTreino() async {
    try {
      await ServicoDeNotificacoesDeTreino.instance.sincronizarLembretesSemanais(
        perfil: _perfil,
        rotinasPorDia: _rotinasPorDia,
      );
    } catch (_) {
      // O Android pode negar ou não oferecer notificações; isso não deve impedir
      // o uso dos planos e dos demais dados locais.
    }
  }

  Future<void> salvarExerciciosDoDia(
    int diaSemana,
    List<ExercicioPlanejado> exercicios,
  ) async {
    if (_sessaoAtiva && _diaDaSessao == diaSemana) {
      final currentPlans = planosDoDia(diaSemana);
      final onlyImagesChanged = currentPlans.length == exercicios.length &&
          List<bool>.generate(currentPlans.length, (indice) {
            final current = currentPlans[indice];
            final edited = exercicios[indice];
            return current.diaSemana == edited.diaSemana &&
                current.nome == edited.nome &&
                current.carga == edited.carga &&
                current.series == edited.series &&
                current.repeticoes == edited.repeticoes &&
                current.tempoDescansoSegundos == edited.tempoDescansoSegundos;
          }).every((same) => same);
      if (!onlyImagesChanged) {
        throw StateError(
          'Finalize o treino para editar os exercícios. Durante o treino, apenas a imagem pode ser alterada.',
        );
      }

      for (var indice = 0; indice < currentPlans.length; indice++) {
        final current = currentPlans[indice];
        final edited = exercicios[indice];
        if (current.caminhoLocalGif == edited.caminhoLocalGif) continue;
        final id = current.id;
        if (id == null) continue;
        await _bancoDeDados.atualizarImagemLocalDoExercicio(
          id,
          edited.caminhoLocalGif,
        );
        _exerciciosDaSessao = _exerciciosDaSessao.map((exercicio) {
          if (exercicio.id != id) return exercicio;
          return exercicio.copiarCom(
            caminhoLocalGif: edited.caminhoLocalGif,
            limparCaminhoLocalGif: edited.caminhoLocalGif == null,
          );
        }).toList(growable: false);
      }
      await _recarregarPlanos(notify: false);
      await _persistirTreinoEmAndamento();
      notifyListeners();
      return;
    }
    await _bancoDeDados.salvarExerciciosDoDia(diaSemana, exercicios);
    await _recarregarPlanos(notify: false);
    await _recarregarHistorico(notify: false);
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> _recarregarHistorico({
    bool notify = true,
    bool recarregarContagemHabitos = true,
  }) async {
    final resultados = await Future.wait<Object>(<Future<Object>>[
      _bancoDeDados.obterHistoricoDeTreinos(),
      _bancoDeDados.obterDatasDeTreinosConcluidos(),
      _bancoDeDados.obterNomesDeExerciciosPlanejados(),
      _bancoDeDados.obterPesosCorporais(),
      _bancoDeDados.obterEvolucaoDoPesoCorporal(),
      _bancoDeDados.obterFotosMensaisDeEvolucao(),
      _bancoDeDados.obterRecordesDeCargaPorExercicio(),
      _bancoDeDados.obterUltimasSeriesPorExercicio(),
      _bancoDeDados.obterMedidasCorporais(),
      if (recarregarContagemHabitos)
        _bancoDeDados.obterContagemDeHabitosPorData(),
    ]);
    _historico = resultados[0] as List<TreinoDoHistorico>;
    _datasConcluidas = resultados[1] as Set<DateTime>;
    _nomesDosExerciciosPlanejados = resultados[2] as List<String>;
    _pesosCorporais = resultados[3] as List<RegistroDePesoCorporal>;
    _pontosDePesoCorporal = resultados[4] as List<PontoDeEvolucao>;
    _fotosMensaisDeEvolucao = resultados[5] as List<FotoMensalDeEvolucao>;
    _recordesDeCargaPorExercicio = resultados[6] as Map<String, double>;
    _ultimasSeriesPorExercicio =
        resultados[7] as Map<String, List<SerieDoTreino>>;
    _medidasCorporais = resultados[8] as List<RegistroDeMedidasCorporais>;
    if (recarregarContagemHabitos) {
      _contagemHabitosPorData = resultados[9] as Map<String, int>;
    }

    if (_exercicioSelecionadoNaEvolucao == null ||
        !_nomesDosExerciciosPlanejados.contains(
          _exercicioSelecionadoNaEvolucao,
        )) {
      _exercicioSelecionadoNaEvolucao = _nomesDosExerciciosPlanejados.isEmpty
          ? null
          : _nomesDosExerciciosPlanejados.first;
    }
    final selected = _exercicioSelecionadoNaEvolucao;
    if (selected != null) {
      final evolucao = await Future.wait<Object>(<Future<Object>>[
        _bancoDeDados.obterPontosDeEvolucao(selected),
        _bancoDeDados.obterDetalhesDeEvolucaoDoExercicio(selected),
      ]);
      _pontosDeEvolucao = evolucao[0] as List<PontoDeEvolucao>;
      _detalhesDaEvolucao = evolucao[1] as List<DetalheEvolucaoDoExercicio>;
    } else {
      _pontosDeEvolucao = <PontoDeEvolucao>[];
      _detalhesDaEvolucao = <DetalheEvolucaoDoExercicio>[];
    }
    if (notify) notifyListeners();
    _diagnosticoDoCoachCache = null;
  }

  Future<List<SerieDoTreino>> obterSeriesDoTreino(int idDoTreino) =>
      _bancoDeDados.obterSeriesDoTreino(idDoTreino);

  /// Recarrega tudo depois de restaurar um backup.
  Future<void> recarregarTodosOsDados() async {
    if (_sessaoAtiva) {
      throw StateError(
        'Finalize o treino em andamento antes de restaurar um backup.',
      );
    }
    _exercicioSelecionadoNaEvolucao = null;
    _perfil = await _bancoDeDados.obterPerfilDoUsuario();
    await Future.wait(<Future<void>>[
      _recarregarPlanos(notify: false),
      _recarregarHistorico(notify: false, recarregarContagemHabitos: false),
      _recarregarHabitos(notify: false),
      _recarregarTarefas(notify: false),
    ]);
    await _sincronizarLembretesDeTreino();
    notifyListeners();
  }

  Future<void> selecionarExercicioDaEvolucao(String nomeDoExercicio) async {
    if (!_nomesDosExerciciosPlanejados.contains(nomeDoExercicio)) return;
    _exercicioSelecionadoNaEvolucao = nomeDoExercicio;
    _pontosDeEvolucao = <PontoDeEvolucao>[];
    _detalhesDaEvolucao = <DetalheEvolucaoDoExercicio>[];
    notifyListeners();
    try {
      final evolucao = await Future.wait<Object>(<Future<Object>>[
        _bancoDeDados.obterPontosDeEvolucao(nomeDoExercicio),
        _bancoDeDados.obterDetalhesDeEvolucaoDoExercicio(nomeDoExercicio),
      ]);
      final points = evolucao[0] as List<PontoDeEvolucao>;
      final details = evolucao[1] as List<DetalheEvolucaoDoExercicio>;
      if (_exercicioSelecionadoNaEvolucao == nomeDoExercicio) {
        _pontosDeEvolucao = points;
        _detalhesDaEvolucao = details;
        notifyListeners();
      }
    } catch (erro) {
      _ultimoErro = 'Não foi possível carregar a evolução: $erro';
      notifyListeners();
    }
  }

  Future<void> excluirSessaoDeTreino(int id) async {
    await _bancoDeDados.excluirSessaoDeTreino(id);
    await _recarregarHistorico(notify: false);
    notifyListeners();
  }

  Future<void> salvarPesoCorporal({
    required DateTime data,
    required double weightKg,
  }) async {
    await _bancoDeDados.inserirPesoCorporal(data: data, weightKg: weightKg);
    await _recarregarHistorico(notify: false);
    notifyListeners();
  }

  Future<void> excluirPesoCorporal(int id) async {
    await _bancoDeDados.excluirPesoCorporal(id);
    await _recarregarHistorico(notify: false);
    notifyListeners();
  }

  Future<void> salvarMedidasCorporais(
      RegistroDeMedidasCorporais medidas) async {
    await _bancoDeDados.salvarMedidasCorporais(medidas);
    await _recarregarHistorico(notify: false);
    notifyListeners();
  }

  Future<void> excluirMedidasCorporais(int id) async {
    await _bancoDeDados.excluirMedidasCorporais(id);
    await _recarregarHistorico(notify: false);
    notifyListeners();
  }

  bool treinoConcluidoNaData(DateTime data) {
    final normalized = DateTime(data.year, data.month, data.day);
    return _datasConcluidas.contains(normalized);
  }

  Future<Map<String, Object?>?> obterDiarioNaData(DateTime data) =>
      _bancoDeDados.obterDiarioNaData(data.toIso8601String());

  Future<void> salvarDiario({
    required DateTime data,
    required String conteudo,
    required List<String> caminhosImagens,
    List<FigurinhaDiario> figurinhas = const <FigurinhaDiario>[],
  }) async {
    await _bancoDeDados.salvarDiario(
      dataISO: data.toIso8601String(),
      conteudo: conteudo,
      caminhosImagens: caminhosImagens,
      figurinhas: figurinhas,
    );
    notifyListeners();
  }

  // ==================== HÁBITOS (Habit Now Gamificado) ====================

  Future<void> _recarregarHabitos({bool notify = true}) async {
    final resultados = await Future.wait<Object>(<Future<Object>>[
      _bancoDeDados.obterHabitos(apenasAtivos: false),
      _bancoDeDados.obterContagemDeHabitosPorData(),
    ]);
    _habitos = resultados[0] as List<Habito>;
    _contagemHabitosPorData = resultados[1] as Map<String, int>;
    if (notify) notifyListeners();
    _diagnosticoDoCoachCache = null;
  }

  Future<void> recarregarHabitos() => _recarregarHabitos();

  Future<void> salvarHabito(Habito habito) async {
    await _bancoDeDados.salvarHabito(habito);
    await _recarregarHabitos();
  }

  Future<void> excluirHabito(int id) async {
    await _bancoDeDados.excluirHabito(id);
    await _recarregarHabitos();
  }

  Future<bool> alternarConclusaoHabito(int idHabito, {DateTime? data}) async {
    final ref = data ?? DateTime.now();
    final result = await _bancoDeDados.alternarConclusaoHabito(
      idHabito: idHabito,
      dataISO: ref.toIso8601String(),
    );
    await _recarregarHabitos();
    return result;
  }

  Future<int> atualizarProgressoHabito(
    int idHabito,
    int novoProgresso, {
    DateTime? data,
  }) async {
    final ref = data ?? DateTime.now();
    final result = await _bancoDeDados.atualizarProgressoDoHabito(
      idHabito: idHabito,
      dataISO: ref.toIso8601String(),
      novoProgresso: novoProgresso.clamp(0, 100000),
    );
    await _recarregarHabitos();
    return result;
  }

  Future<int> incrementarProgressoHabito(
    Habito habito, {
    int? delta,
    DateTime? data,
  }) async {
    final id = habito.id;
    if (id == null) return habito.progressoHoje;
    final passo = delta ?? habito.passoIncremento;
    final novoValor = (habito.progressoHoje + passo).clamp(0, 100000);
    return atualizarProgressoHabito(id, novoValor, data: data);
  }

  Future<Set<String>> obterDatasDeConclusaoDoHabito(int idHabito) =>
      _bancoDeDados.obterDatasDeConclusaoDoHabito(idHabito);

  // ==================== TAREFAS (To-Do Offline) ====================

  Future<void> _recarregarTarefas({bool notify = true}) async {
    _tarefas = await _bancoDeDados.obterTarefasToDo();
    if (notify) notifyListeners();
    _diagnosticoDoCoachCache = null;
  }

  Future<void> recarregarTarefas() => _recarregarTarefas();

  Future<void> salvarTarefaToDo(TarefaToDo tarefa) async {
    await _bancoDeDados.salvarTarefaToDo(tarefa);
    await _recarregarTarefas();
  }

  Future<void> alternarConclusaoTarefa(int id, bool concluida) async {
    await _bancoDeDados.alternarConclusaoTarefa(id, concluida);
    await _recarregarTarefas();
  }

  Future<void> excluirTarefaToDo(int id) async {
    await _bancoDeDados.excluirTarefaToDo(id);
    await _recarregarTarefas();
  }

  static String chaveDoMes(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}';

  bool temFotoMensalDeEvolucao(DateTime data) {
    final key = chaveDoMes(data);
    return _fotosMensaisDeEvolucao.any((photo) => photo.mesISO == key);
  }

  /// Indica se o desafio mensal ainda bloqueia as abas nesta competência.
  bool desafioFotoMensalAtivo(DateTime data) =>
      !temFotoMensalDeEvolucao(data) &&
      _mesDaFotoMensalAdiado != chaveDoMes(data);

  /// Permite seguir sem foto até o próximo mês, mantendo o desafio disponível.
  Future<void> adiarDesafioFotoMensal(DateTime data) async {
    final mes = chaveDoMes(data);
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString('foto_mensal_adiada_ate', mes);
    _mesDaFotoMensalAdiado = mes;
    notifyListeners();
  }

  Future<void> _carregarDesafioFotoMensalAdiado() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      _mesDaFotoMensalAdiado = preferencias.getString('foto_mensal_adiada_ate');
    } catch (_) {
      _mesDaFotoMensalAdiado = null;
    }
  }

  Future<void> adicionarFotosMensaisDeEvolucao(
    DateTime month,
    List<String> localPaths,
  ) async {
    await _bancoDeDados.salvarFotosMensaisDeEvolucao(
      mesISO: chaveDoMes(month),
      caminhosLocais: localPaths,
    );
    if (_mesDaFotoMensalAdiado == chaveDoMes(month)) {
      _mesDaFotoMensalAdiado = null;
      try {
        final preferencias = await SharedPreferences.getInstance();
        await preferencias.remove('foto_mensal_adiada_ate');
      } catch (_) {}
    }
    _fotosMensaisDeEvolucao = await _bancoDeDados.obterFotosMensaisDeEvolucao();
    notifyListeners();
  }

  Future<void> excluirFotoMensalDeEvolucao(int id) async {
    await _bancoDeDados.excluirFotoMensalDeEvolucao(id);
    _fotosMensaisDeEvolucao = await _bancoDeDados.obterFotosMensaisDeEvolucao();
    notifyListeners();
  }

  /// Inicia o descanso do exercício e persiste o horário de término no banco.
  void iniciarCronometroDeDescanso(
    ExercicioPlanejado exercicio, {
    int? customSeconds,
    DateTime? endsAt,
  }) {
    _idExecucaoDescansoAtual++;
    final idExecucao = _idExecucaoDescansoAtual;

    _cronometroDeDescanso?.cancel();
    final total = customSeconds ??
        (exercicio.tempoDescansoSegundos > 0
            ? exercicio.tempoDescansoSegundos
            : 60);
    _idExercicioComCronometroAtivo = exercicio.id;
    _duracaoTotalDoCronometro = total;
    final now = _agora;
    final ends = endsAt ?? now.add(Duration(seconds: total));
    _fimDoCronometro = ends;

    // 1. Antes de qualquer agendamento, exija horarioTermino.isAfter(agora).
    // Prazo igual ou anterior ao atual deve ser descartado.
    if (!ends.isAfter(now)) {
      unawaited(ServicoDeNotificacoesDeTreino.instance
          .cancelarNotificacaoDescanso(idExecucao: idExecucao));
      _fimDoCronometro = null;
      _tempoRestanteDoCronometro = 0;
      _tempoRestanteDescansoNotifier.value = 0;
      _cronometroFinalizado = true;
      notifyListeners();
      return;
    }

    final diffMs = ends.difference(now).inMilliseconds;
    _tempoRestanteDoCronometro =
        (diffMs / 1000).ceil().clamp(0, total).toInt();
    _tempoRestanteDescansoNotifier.value = _tempoRestanteDoCronometro;
    _cronometroFinalizado = false;
    _ultimoResultadoAgendamento = null;

    if (_sessaoAtiva) {
      unawaited(
        _bancoDeDados.atualizarDescansoDoTreinoEmAndamento(
          descansoSegundos: total,
          descansoAteISO: _fimDoCronometro?.toIso8601String(),
          idExercicioDescanso: exercicio.id,
        ),
      );
    }

    unawaited(
      ServicoDeNotificacoesDeTreino.instance
          .agendarNotificacaoDescanso(
            idExecucao: idExecucao,
            nomeExercicio: exercicio.nome,
            horarioTermino: _fimDoCronometro!,
          )
          .then((resultado) {
        final now = _agora;
        final aindaValido = idExecucao == _idExecucaoDescansoAtual &&
            _idExercicioComCronometroAtivo != null &&
            !_cronometroFinalizado &&
            _fimDoCronometro != null &&
            _fimDoCronometro!.isAfter(now);
        if (aindaValido) {
          _ultimoResultadoAgendamento = resultado;
          notifyListeners();
        }
      }),
    );
    notifyListeners();

    var ultimoBipRestante = -1;
    final criador = criadorDeTimerParaTestes ?? Timer.periodic;
    _cronometroDeDescanso = criador(const Duration(seconds: 1), (timer) {
      final endsAt = _fimDoCronometro;
      if (endsAt == null) {
        timer.cancel();
        return;
      }
      final agora = _agora;
      final expirou = agora.isAfter(endsAt) || agora.isAtSameMomentAs(endsAt);
      final diffMs = endsAt.difference(agora).inMilliseconds;
      final remaining =
          (diffMs / 1000).ceil().clamp(0, _duracaoTotalDoCronometro + 1).toInt();
      _tempoRestanteDoCronometro = expirou ? 0 : remaining;
      _tempoRestanteDescansoNotifier.value = _tempoRestanteDoCronometro;

      // Bip sonoro e feedback tátil nos últimos 3 segundos (3, 2, 1) em primeiro plano
      if (!expirou &&
          remaining > 0 &&
          remaining <= 3 &&
          ultimoBipRestante != remaining) {
        ultimoBipRestante = remaining;
        if (isAppForeground) {
          ServicoDeSomDoAlarme.instance.tocarBipContagemRegressiva();
        }
      }

      if (expirou) {
        timer.cancel();
        _cronometroDeDescanso = null;
        _tempoRestanteDoCronometro = 0;
        _tempoRestanteDescansoNotifier.value = 0;
        _cronometroFinalizado = true;
        _fimDoCronometro = null;

        if (isAppForeground) {
          // Em primeiro plano:
          // 1. Invalida imediatamente a identificação da execução
          _idExecucaoDescansoAtual++;
          final idExecucaoConclusao = _idExecucaoDescansoAtual;
          // 2. Cancela o alarme nativo para não duplicar aviso
          unawaited(
            ServicoDeNotificacoesDeTreino.instance
                .cancelarNotificacaoDescanso(idExecucao: idExecucaoConclusao),
          );
          // 3. Toca áudio interno com ducking
          ServicoDeSomDoAlarme.instance.tocarAlarme();
        } else {
          // Em segundo plano / tela bloqueada: NÃO cancela o aviso nativo agendado!
          // Deixa o AlarmManager do sistema disparar o alerta sonoro pelo canal nativo.
        }

        if (_sessaoAtiva) {
          unawaited(
            _bancoDeDados.atualizarDescansoDoTreinoEmAndamento(
              descansoSegundos: _duracaoTotalDoCronometro,
              descansoAteISO: null,
              idExercicioDescanso: _idExercicioComCronometroAtivo,
            ),
          );
        }
        notifyListeners();
      }
    });
  }

  void cancelarCronometroDeDescanso() {
    _idExecucaoDescansoAtual++;
    final idExecucao = _idExecucaoDescansoAtual;

    _cronometroDeDescanso?.cancel();
    _cronometroDeDescanso = null;
    _idExercicioComCronometroAtivo = null;
    _tempoRestanteDoCronometro = 0;
    _tempoRestanteDescansoNotifier.value = 0;
    _cronometroFinalizado = false;
    _fimDoCronometro = null;
    _ultimoResultadoAgendamento = null;

    unawaited(
      ServicoDeNotificacoesDeTreino.instance
          .cancelarNotificacaoDescanso(idExecucao: idExecucao),
    );
    if (_sessaoAtiva) {
      unawaited(
        _bancoDeDados.atualizarDescansoDoTreinoEmAndamento(
          descansoSegundos: _duracaoTotalDoCronometro,
          descansoAteISO: null,
          idExercicioDescanso: null,
        ),
      );
    }
    notifyListeners();
  }

  /// Atualiza o tempo de descanso de um exercício específico e salva localmente no banco
  Future<void> atualizarDuracaoDoDescanso(
    int idDoExercicio,
    int segundos,
  ) async {
    if (segundos < 0 || segundos > 600) return;
    await _bancoDeDados.atualizarDuracaoDoDescanso(idDoExercicio, segundos);
    await _recarregarPlanos(notify: false);
    if (_sessaoAtiva) {
      final updatedSessionExercises = <ExercicioPlanejado>[];
      for (final ex in _exerciciosDaSessao) {
        if (ex.id == idDoExercicio) {
          updatedSessionExercises.add(
            ex.copiarCom(tempoDescansoSegundos: segundos),
          );
        } else {
          updatedSessionExercises.add(ex);
        }
      }
      _exerciciosDaSessao = updatedSessionExercises;
    }
    notifyListeners();
  }

  /// Atualiza detalhes do exercício (séries, repetições, carga, descanso) direto da tela Hoje
  Future<void> atualizarDetalhesDoExercicio(
    ExercicioPlanejado exercicio, {
    String? nome,
    double? carga,
    int? series,
    int? repeticoes,
    int? tempoDescansoSegundos,
  }) async {
    final id = exercicio.id;
    if (id == null) return;

    final quantidadeDeSeries = series ?? exercicio.series;
    final cargasPorSerie = List<double>.generate(
      quantidadeDeSeries,
      (indice) =>
          carga ??
          (indice < exercicio.series
              ? cargaAtual(exercicio, indice)
              : exercicio.carga),
    );
    final repeticoesPorSerie = List<int>.generate(
      quantidadeDeSeries,
      (indice) =>
          repeticoes ??
          (indice < exercicio.series
              ? repeticoesAtuais(exercicio, indice)
              : exercicio.repeticoes),
    );

    await _bancoDeDados.atualizarDetalhesDoExercicio(
      id,
      nome: nome,
      carga: carga,
      series: series,
      repeticoes: repeticoes,
      tempoDescansoSegundos: tempoDescansoSegundos,
    );
    if (series != null || carga != null || repeticoes != null) {
      await _bancoDeDados.atualizarValoresDasSeriesDoExercicio(
        id,
        cargas: cargasPorSerie,
        repeticoes: repeticoesPorSerie,
      );
    }
    await _recarregarPlanos(notify: false);

    if (_sessaoAtiva && _diaDaSessao == exercicio.diaSemana) {
      final updated = <ExercicioPlanejado>[];
      for (final ex in _exerciciosDaSessao) {
        if (ex.id == id) {
          final newModel = ex.copiarCom(
            nome: nome,
            carga: carga,
            series: series,
            repeticoes: repeticoes,
            tempoDescansoSegundos: tempoDescansoSegundos,
            cargasPorSerie: List<double>.unmodifiable(cargasPorSerie),
            repeticoesPorSerie: List<int>.unmodifiable(repeticoesPorSerie),
          );
          updated.add(newModel);
          if (series != null) {
            for (var i = 0; i < series; i++) {
              final key = _chaveDaSerie(newModel, i);
              _cargasDasSeries.putIfAbsent(key, () => carga ?? ex.carga);
              _repeticoesDasSeries.putIfAbsent(
                key,
                () => repeticoes ?? ex.repeticoes,
              );
            }
            for (var i = series; i < ex.series; i++) {
              _cargasDasSeries.remove(_chaveDaSerie(ex, i));
              _repeticoesDasSeries.remove(_chaveDaSerie(ex, i));
              _chavesDasSeriesConcluidas.remove(_chaveDaSerie(ex, i));
            }
          }
          if (carga != null && carga != ex.carga) {
            for (var i = 0; i < newModel.series; i++) {
              _cargasDasSeries[_chaveDaSerie(newModel, i)] = carga;
            }
          }
          if (repeticoes != null && repeticoes != ex.repeticoes) {
            for (var i = 0; i < newModel.series; i++) {
              _repeticoesDasSeries[_chaveDaSerie(newModel, i)] = repeticoes;
            }
          }
        } else {
          updated.add(ex);
        }
      }
      _exerciciosDaSessao = updated;
      await _persistirTreinoEmAndamento();
    }
    notifyListeners();
  }

  Future<void> adicionarSerieAoExercicio(ExercicioPlanejado exercicio) async {
    final newCount = exercicio.series + 1;
    await atualizarDetalhesDoExercicio(exercicio, series: newCount);
  }

  Future<void> removerSerieDoExercicio(ExercicioPlanejado exercicio) async {
    if (exercicio.series <= 1) return;
    final newCount = exercicio.series - 1;
    await atualizarDetalhesDoExercicio(exercicio, series: newCount);
  }

  /// Insere uma rampa de aquecimento neuromuscular gradual com 1-toque
  /// (40%, 60%, 80% da carga alvo) antes das séries de trabalho do exercício.
  Future<bool> inserirRampaDeAquecimento(ExercicioPlanejado exercicio) async {
    final id = exercicio.id;
    if (id == null) return false;

    final cargaBase = cargaAtual(exercicio, 0) > 0
        ? cargaAtual(exercicio, 0)
        : exercicio.carga;
    if (cargaBase <= 0) return false;

    final seriesAquecimento =
        CalculadoraDeCargas.calcularAquecimento(cargaAlvo: cargaBase);
    if (seriesAquecimento.isEmpty) return false;

    final novasCargas = <double>[];
    final novasReps = <int>[];

    for (final aq in seriesAquecimento) {
      novasCargas.add(aq.cargaKg);
      novasReps.add(aq.repeticoes);
    }

    for (var i = 0; i < exercicio.series; i++) {
      novasCargas.add(cargaAtual(exercicio, i));
      novasReps.add(repeticoesAtuais(exercicio, i));
    }

    final totalSeries = novasCargas.length;
    await atualizarDetalhesDoExercicio(exercicio, series: totalSeries);

    final exAtualizado = (_sessaoAtiva
            ? _exerciciosDaSessao.firstWhere((e) => e.id == id,
                orElse: () => exercicio)
            : exerciciosSelecionadosDoDia(exercicio.diaSemana)
                .firstWhere((e) => e.id == id, orElse: () => exercicio))
        .copiarCom(series: totalSeries);

    await _salvarValoresPersonalizadosDasSeries(
      exAtualizado,
      novasCargas,
      novasReps,
    );
    notifyListeners();
    return true;
  }

  /// Aplica a Semana Regenerativa (Deload) reduzindo cerca de 40% do volume de séries
  /// de todas as rotinas para permitir supercompensação e descarregar fadiga neuromuscular.
  Future<int> aplicarSemanaDeload({double reducaoVolume = 0.40}) async {
    int totalExerciciosAjustados = 0;
    for (final entry in _rotinasPorDia.entries) {
      final diaSemana = entry.key;
      final rotinas = entry.value;
      for (final rotina in rotinas) {
        bool rotinaModificada = false;
        final novosExercicios = <ExercicioPlanejado>[];
        for (final ex in rotina.exercicios) {
          if (ex.series > 1) {
            final novasSeries =
                math.max(1, (ex.series * (1.0 - reducaoVolume)).round());
            if (novasSeries != ex.series) {
              final novasCargas = ex.cargasPorSerie.take(novasSeries).toList();
              final novasReps =
                  ex.repeticoesPorSerie.take(novasSeries).toList();
              novosExercicios.add(
                ex.copiarCom(
                  series: novasSeries,
                  cargasPorSerie: novasCargas,
                  repeticoesPorSerie: novasReps,
                ),
              );
              rotinaModificada = true;
              totalExerciciosAjustados++;
              continue;
            }
          }
          novosExercicios.add(ex);
        }
        if (rotinaModificada) {
          final rotinaAtualizada = RotinaDeTreino(
            id: rotina.id,
            diaSemana: diaSemana,
            nome: rotina.nome,
            selecionado: rotina.selecionado,
            exercicios: novosExercicios,
          );
          await _bancoDeDados.salvarRotinaDeTreino(rotinaAtualizada);
        }
      }
    }

    await _recarregarPlanos();
    notifyListeners();
    return totalExerciciosAjustados;
  }

  Future<void> iniciarTreino(int diaSemana) async {
    if (_sessaoAtiva) return;
    final rotinas = rotinasSelecionadasDoDia(diaSemana);
    final exercicios = rotinas.expand((rotina) => rotina.exercicios).toList();
    if (exercicios.isEmpty) return;
    if (exercicios.any((exercicio) => exercicio.id == null)) {
      throw StateError('Um exercício do plano não tem ID local válido.');
    }

    _diaDaSessao = diaSemana;
    _inicioDaSessao = DateTime.now();
    _tempoDecorridoDaSessao = Duration.zero;
    _exerciciosDaSessao = List<ExercicioPlanejado>.of(exercicios);
    _nomesDasRotinasDaSessao = rotinas.map((rotina) => rotina.nome).toList();
    _sessaoAtiva = true;
    _chavesDasSeriesConcluidas.clear();
    _cargasDasSeries.clear();
    _repeticoesDasSeries.clear();
    for (final exercicio in _exerciciosDaSessao) {
      for (var indice = 0; indice < exercicio.series; indice++) {
        _cargasDasSeries[_chaveDaSerie(exercicio, indice)] =
            exercicio.cargaDaSerie(indice);
        _repeticoesDasSeries[_chaveDaSerie(exercicio, indice)] =
            exercicio.repeticoesDaSerie(indice);
      }
    }

    try {
      await _persistirTreinoEmAndamento();
      _iniciarCronometroDaSessao();
      notifyListeners();
    } catch (erro) {
      _sessaoAtiva = false;
      _diaDaSessao = null;
      _inicioDaSessao = null;
      _exerciciosDaSessao = <ExercicioPlanejado>[];
      _nomesDasRotinasDaSessao = <String>[];
      _cargasDasSeries.clear();
      _repeticoesDasSeries.clear();
      _chavesDasSeriesConcluidas.clear();
      notifyListeners();
      rethrow;
    }
  }

  bool serieEstaConcluida(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) =>
      _chavesDasSeriesConcluidas.contains(
        _chaveDaSerie(exercicio, zeroBasedSeriesIndex),
      );

  bool exercicioEstaConcluido(ExercicioPlanejado exercicio) {
    if (!_sessaoAtiva || exercicio.series <= 0) return false;
    for (var indice = 0; indice < exercicio.series; indice++) {
      if (!serieEstaConcluida(exercicio, indice)) return false;
    }
    return true;
  }

  bool ehUltimoExercicioPendente(ExercicioPlanejado exercicio) {
    if (!_sessaoAtiva || exercicio.id == null) return false;
    final incomplete = _exerciciosDaSessao
        .where((candidate) => !exercicioEstaConcluido(candidate))
        .toList(growable: false);
    return incomplete.length == 1 && incomplete.single.id == exercicio.id;
  }

  bool todasAsSeriesDoTreinoEstaoConcluidas() {
    return _sessaoAtiva &&
        _exerciciosDaSessao.isNotEmpty &&
        _exerciciosDaSessao.every(exercicioEstaConcluido);
  }

  /// Marca ou desmarca uma série e inicia o descanso se houver outra série.
  bool alternarConclusaoDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) {
    if (!_sessaoAtiva ||
        zeroBasedSeriesIndex < 0 ||
        zeroBasedSeriesIndex >= exercicio.series) {
      return false;
    }
    final key = _chaveDaSerie(exercicio, zeroBasedSeriesIndex);
    final completedNow = !_chavesDasSeriesConcluidas.contains(key);
    if (completedNow) {
      _chavesDasSeriesConcluidas.add(key);
      if (todasAsSeriesDoTreinoEstaoConcluidas()) {
        // A última série não tem outra série após o descanso; encerra o cronômetro.
        cancelarCronometroDeDescanso();
      } else {
        iniciarCronometroDeDescanso(exercicio);
      }
    } else {
      _chavesDasSeriesConcluidas.remove(key);
    }
    unawaited(_persistirEstadoDasSeries(exercicio, zeroBasedSeriesIndex));
    notifyListeners();
    return completedNow;
  }

  double cargaAtual(ExercicioPlanejado exercicio, int zeroBasedSeriesIndex) =>
      _cargasDasSeries[_chaveDaSerie(exercicio, zeroBasedSeriesIndex)] ??
      exercicio.cargaDaSerie(zeroBasedSeriesIndex);

  int repeticoesAtuais(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) =>
      _repeticoesDasSeries[_chaveDaSerie(exercicio, zeroBasedSeriesIndex)] ??
      exercicio.repeticoesDaSerie(zeroBasedSeriesIndex);

  /// Retorna o tipo marcador da série: 'normal', 'aquecimento', 'dropset' ou 'falha'.
  String tipoDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) =>
      _tiposDasSeries[_chaveDaSerie(exercicio, zeroBasedSeriesIndex)] ??
      'normal';

  /// Alterna o tipo marcador da série entre Normal -> Aquecimento (A) -> Drop-set (D) -> Falha (F).
  String alternarTipoDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) {
    const ordem = <String>['normal', 'aquecimento', 'dropset', 'falha'];
    final chave = _chaveDaSerie(exercicio, zeroBasedSeriesIndex);
    final atual = _tiposDasSeries[chave] ?? 'normal';
    final proximoIndice = (ordem.indexOf(atual) + 1) % ordem.length;
    final proximo = ordem[proximoIndice];
    _tiposDasSeries[chave] = proximo;
    notifyListeners();
    return proximo;
  }

  /// Retorna as séries executadas na última sessão histórica deste exercício (Ghost/Previous set).
  List<SerieDoTreino> ultimasSeriesDoExercicio(String nomeExercicio) {
    return _ultimasSeriesPorExercicio[nomeExercicio.trim().toLowerCase()] ??
        const <SerieDoTreino>[];
  }

  /// Retorna os dados da última execução correspondente para esta série (se houver histórico).
  SerieDoTreino? ultimaExecucaoDaSerie(
    String nomeExercicio,
    int zeroBasedSeriesIndex,
  ) {
    final series = ultimasSeriesDoExercicio(nomeExercicio);
    if (series.isEmpty) return null;
    if (zeroBasedSeriesIndex < series.length) {
      return series[zeroBasedSeriesIndex];
    }
    return series.last;
  }

  /// Retorna o RPE (Esforço Percebido) registrado para a série em andamento (se houver).
  double? rpeDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) =>
      _rpeDasSeries[_chaveDaSerie(exercicio, zeroBasedSeriesIndex)];

  /// Define o RPE (5.0 a 10.0) para a série especificada.
  void definirRpeDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
    double? rpe,
  ) {
    final chave = _chaveDaSerie(exercicio, zeroBasedSeriesIndex);
    if (rpe == null || rpe <= 0) {
      _rpeDasSeries.remove(chave);
    } else {
      _rpeDasSeries[chave] = rpe.clamp(5.0, 10.0);
    }
    notifyListeners();
  }

  /// Estima o 1RM para este exercício com base na série mais pesada registrada hoje ou planejada.
  double estimar1RMDoExercicio(ExercicioPlanejado exercicio) {
    var max1RM = 0.0;
    for (var i = 0; i < exercicio.series; i++) {
      final carga = cargaAtual(exercicio, i);
      final reps = repeticoesAtuais(exercicio, i);
      final est =
          CalculadoraDeCargas.estimar1RM(carga: carga, repeticoes: reps);
      if (est > max1RM) max1RM = est;
    }
    return max1RM;
  }

  Future<void> definirRepeticoesAtuais(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
    int value,
  ) async {
    if (value < 1 || value > 500 || zeroBasedSeriesIndex < 0) return;
    if (zeroBasedSeriesIndex >= exercicio.series) return;
    final cargas = List<double>.generate(
      exercicio.series,
      (indice) => cargaAtual(exercicio, indice),
    );
    final repeticoes = List<int>.generate(
      exercicio.series,
      (indice) => repeticoesAtuais(exercicio, indice),
    );
    repeticoes[zeroBasedSeriesIndex] = value;
    await _salvarValoresPersonalizadosDasSeries(
      exercicio,
      cargas,
      repeticoes,
      serieAlteradaIndex: zeroBasedSeriesIndex,
    );
  }

  Future<void> definirCargaAtual(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
    double value,
  ) async {
    if (!value.isFinite || value < 0 || zeroBasedSeriesIndex < 0) return;
    if (zeroBasedSeriesIndex >= exercicio.series) return;
    final cargas = List<double>.generate(
      exercicio.series,
      (indice) => cargaAtual(exercicio, indice),
    );
    final repeticoes = List<int>.generate(
      exercicio.series,
      (indice) => repeticoesAtuais(exercicio, indice),
    );
    cargas[zeroBasedSeriesIndex] = value;
    await _salvarValoresPersonalizadosDasSeries(
      exercicio,
      cargas,
      repeticoes,
      serieAlteradaIndex: zeroBasedSeriesIndex,
    );
  }

  Future<void> definirRepeticoesECargaDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex, {
    required int repeticoes,
    required double carga,
  }) async {
    if (repeticoes < 1 ||
        repeticoes > 500 ||
        !carga.isFinite ||
        carga < 0 ||
        zeroBasedSeriesIndex < 0 ||
        zeroBasedSeriesIndex >= exercicio.series) {
      return;
    }
    final cargas = List<double>.generate(
      exercicio.series,
      (indice) => cargaAtual(exercicio, indice),
    );
    final reps = List<int>.generate(
      exercicio.series,
      (indice) => repeticoesAtuais(exercicio, indice),
    );
    cargas[zeroBasedSeriesIndex] = carga;
    reps[zeroBasedSeriesIndex] = repeticoes;
    await _salvarValoresPersonalizadosDasSeries(
      exercicio,
      cargas,
      reps,
      serieAlteradaIndex: zeroBasedSeriesIndex,
    );
  }

  Future<void> _salvarValoresPersonalizadosDasSeries(
    ExercicioPlanejado exercicio,
    List<double> cargas,
    List<int> repeticoes, {
    int? serieAlteradaIndex,
  }) async {
    final id = exercicio.id;
    if (id == null) return;
    final atualizado = exercicio.copiarCom(
      cargasPorSerie: List<double>.unmodifiable(cargas),
      repeticoesPorSerie: List<int>.unmodifiable(repeticoes),
    );
    _substituirExercicioEmMemoria(atualizado);
    for (var indice = 0; indice < atualizado.series; indice++) {
      final chave = _chaveDaSerie(atualizado, indice);
      _cargasDasSeries[chave] = cargas[indice];
      _repeticoesDasSeries[chave] = repeticoes[indice];
    }
    notifyListeners();

    await _bancoDeDados.atualizarValoresDasSeriesDoExercicio(
      id,
      cargas: cargas,
      repeticoes: repeticoes,
    );
    if (_sessaoAtiva && _diaDaSessao == atualizado.diaSemana) {
      if (serieAlteradaIndex != null) {
        await _persistirEstadoDasSeries(atualizado, serieAlteradaIndex);
      } else {
        await _persistirTreinoEmAndamento();
      }
    }
  }

  void _substituirExercicioEmMemoria(ExercicioPlanejado atualizado) {
    final id = atualizado.id;
    if (id == null) return;
    final planos = _planosPorDia[atualizado.diaSemana];
    if (planos != null) {
      final indice = planos.indexWhere((item) => item.id == id);
      if (indice >= 0) planos[indice] = atualizado;
    }
    final rotinas = _rotinasPorDia[atualizado.diaSemana];
    if (rotinas != null) {
      for (var indiceRotina = 0;
          indiceRotina < rotinas.length;
          indiceRotina++) {
        final rotina = rotinas[indiceRotina];
        final indiceExercicio = rotina.exercicios.indexWhere(
          (item) => item.id == id,
        );
        if (indiceExercicio < 0) continue;
        final exercicios = List<ExercicioPlanejado>.of(rotina.exercicios);
        exercicios[indiceExercicio] = atualizado;
        rotinas[indiceRotina] = RotinaDeTreino(
          id: rotina.id,
          diaSemana: rotina.diaSemana,
          nome: rotina.nome,
          selecionado: rotina.selecionado,
          exercicios: List<ExercicioPlanejado>.unmodifiable(exercicios),
        );
      }
    }
    final indiceNaSessao = _exerciciosDaSessao.indexWhere(
      (item) => item.id == id,
    );
    if (indiceNaSessao >= 0) {
      final atualizados = List<ExercicioPlanejado>.of(_exerciciosDaSessao);
      atualizados[indiceNaSessao] = atualizado;
      _exerciciosDaSessao = atualizados;
    }
  }

  Future<void> _persistirEstadoDasSeries(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) async {
    final id = exercicio.id;
    if (id == null || !_sessaoAtiva) return;
    try {
      await _bancoDeDados.atualizarSeriesDoTreinoEmAndamento(
        exercisePlanId: id,
        serieNumero: zeroBasedSeriesIndex + 1,
        cargaAtual: cargaAtual(exercicio, zeroBasedSeriesIndex),
        repeticoesAtual: repeticoesAtuais(exercicio, zeroBasedSeriesIndex),
        concluido: serieEstaConcluida(exercicio, zeroBasedSeriesIndex),
      );
    } catch (erro) {
      _ultimoErro = 'Não foi possível salvar o progresso da série: $erro';
      notifyListeners();
    }
  }

  Future<void> _persistirTreinoEmAndamento() async {
    final startedAt = _inicioDaSessao;
    final diaSemana = _diaDaSessao;
    if (startedAt == null || diaSemana == null) return;
    final exerciseSnapshots = <ExercicioDoTreinoEmAndamento>[];
    for (final exercicio in _exerciciosDaSessao) {
      final progress = <SerieDoTreinoEmAndamento>[];
      for (var indice = 0; indice < exercicio.series; indice++) {
        progress.add(
          SerieDoTreinoEmAndamento(
            numeroSerie: indice + 1,
            cargaAtual: cargaAtual(exercicio, indice),
            repeticoesAtual: repeticoesAtuais(exercicio, indice),
            concluido: serieEstaConcluida(exercicio, indice),
          ),
        );
      }
      exerciseSnapshots.add(
        ExercicioDoTreinoEmAndamento(
          exercicio: exercicio,
          progressoDasSeries: progress,
        ),
      );
    }
    await _bancoDeDados.salvarTreinoEmAndamento(
      TreinoEmAndamento(
        dataInicioISO: startedAt.toIso8601String(),
        diaSemana: diaSemana,
        descansoSegundos: _duracaoTotalDoCronometro,
        descansoAteISO: _fimDoCronometro?.toIso8601String(),
        idExercicioDescanso: _idExercicioComCronometroAtivo,
        exercicios: exerciseSnapshots,
      ),
    );
  }

  Future<void> _restaurarTreinoEmAndamento() async {
    final estadoSalvo = await _bancoDeDados.obterTreinoEmAndamento();
    if (estadoSalvo == null) return;
    final startedAt = DateTime.tryParse(estadoSalvo.dataInicioISO);
    if (startedAt == null || estadoSalvo.exercicios.isEmpty) {
      await _bancoDeDados.excluirTreinoEmAndamento();
      return;
    }

    _inicioDaSessao = startedAt;
    _diaDaSessao = estadoSalvo.diaSemana;
    _exerciciosDaSessao = estadoSalvo.exercicios
        .map((item) => item.exercicio)
        .toList(growable: false);
    _nomesDasRotinasDaSessao = _exerciciosDaSessao
        .map((exercicio) => exercicio.nomeTreino)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);

    _sessaoAtiva = _exerciciosDaSessao.isNotEmpty;
    _tempoDecorridoDaSessao = DateTime.now().difference(startedAt);
    _duracaoDaSessaoNotifier.value = _tempoDecorridoDaSessao;
    _chavesDasSeriesConcluidas.clear();
    _cargasDasSeries.clear();
    _repeticoesDasSeries.clear();

    for (final estadoDoExercicio in estadoSalvo.exercicios) {
      final exercicio = estadoDoExercicio.exercicio;
      for (final progress in estadoDoExercicio.progressoDasSeries) {
        final indice = progress.numeroSerie - 1;
        _cargasDasSeries[_chaveDaSerie(exercicio, indice)] =
            progress.cargaAtual;
        _repeticoesDasSeries[_chaveDaSerie(exercicio, indice)] =
            progress.repeticoesAtual;
        if (progress.concluido) {
          _chavesDasSeriesConcluidas.add(_chaveDaSerie(exercicio, indice));
        }
      }
    }

    _iniciarCronometroDaSessao();
    final restEnd = estadoSalvo.descansoAteISO == null
        ? null
        : DateTime.tryParse(estadoSalvo.descansoAteISO!);
    ExercicioPlanejado? restExercise;
    final restExerciseId = estadoSalvo.idExercicioDescanso;
    if (restExerciseId != null) {
      for (final exercicio in _exerciciosDaSessao) {
        if (exercicio.id == restExerciseId) {
          restExercise = exercicio;
          break;
        }
      }
    }
    if (restExercise == null) {
      for (final estadoDoExercicio in estadoSalvo.exercicios.reversed) {
        if (estadoDoExercicio.progressoDasSeries.any(
          (series) => series.concluido,
        )) {
          restExercise = estadoDoExercicio.exercicio;
          break;
        }
      }
    }
    if (restEnd != null &&
        restEnd.isAfter(DateTime.now()) &&
        restExercise != null) {
      iniciarCronometroDeDescanso(
        restExercise,
        customSeconds: estadoSalvo.descansoSegundos,
        endsAt: restEnd,
      );
    } else {
      _idExercicioComCronometroAtivo = null;
      _tempoRestanteDoCronometro = 0;
      _tempoRestanteDescansoNotifier.value = 0;
      _cronometroFinalizado = false;
      _fimDoCronometro = null;
      await _bancoDeDados.atualizarDescansoDoTreinoEmAndamento(
        descansoSegundos: 60,
        descansoAteISO: null,
        idExercicioDescanso: null,
      );
    }
  }

  void _iniciarCronometroDaSessao() {
    _cronometroDaSessao?.cancel();
    _duracaoDaSessaoNotifier.value = _tempoDecorridoDaSessao;
    _cronometroDaSessao = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _inicioDaSessao;
      if (startedAt != null && _sessaoAtiva) {
        _tempoDecorridoDaSessao = DateTime.now().difference(startedAt);
        _duracaoDaSessaoNotifier.value = _tempoDecorridoDaSessao;
      }
    });
  }

  /// Finaliza a sessão, grava as séries concluídas e atualiza o histórico local.
  Future<int?> finalizarTreino() async {
    if (!_sessaoAtiva || _diaDaSessao == null) return null;
    final completedSets = <SerieDoTreino>[];
    for (final exercicio in _exerciciosDaSessao) {
      for (var indice = 0; indice < exercicio.series; indice++) {
        if (serieEstaConcluida(exercicio, indice)) {
          completedSets.add(
            SerieDoTreino(
              nomeExercicio: exercicio.nome,
              cargaUtilizada: cargaAtual(exercicio, indice),
              serieNumero: indice + 1,
              repeticoes: repeticoesAtuais(exercicio, indice),
              tipo: tipoDaSerie(exercicio, indice),
              rpe: rpeDaSerie(exercicio, indice),
            ),
          );
        }
      }
    }
    if (completedSets.isEmpty) return null;

    final startedAt = _inicioDaSessao ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final routineNames = List<String>.of(_nomesDasRotinasDaSessao);
    final historyId = await _bancoDeDados.salvarSessaoDeTreino(
      dataISO: startedAt.toIso8601String(),
      tempoTotalSegundos: elapsed.inSeconds,
      diaSemana: _diaDaSessao!,
      nomeTreino: routineNames.join(' + '),
      sets: completedSets,
    );

    _idExecucaoDescansoAtual++;
    final idExecucaoDescanso = _idExecucaoDescansoAtual;
    _cronometroDaSessao?.cancel();
    _cronometroDaSessao = null;
    _cronometroDeDescanso?.cancel();
    _cronometroDeDescanso = null;
    _idExercicioComCronometroAtivo = null;
    _tempoRestanteDoCronometro = 0;
    _tempoRestanteDescansoNotifier.value = 0;
    _cronometroFinalizado = false;
    _fimDoCronometro = null;
    _ultimoResultadoAgendamento = null;
    unawaited(
      ServicoDeNotificacoesDeTreino.instance
          .cancelarNotificacaoDescanso(idExecucao: idExecucaoDescanso),
    );
    _sessaoAtiva = false;
    _diaDaSessao = null;
    _inicioDaSessao = null;
    _tempoDecorridoDaSessao = Duration.zero;
    _duracaoDaSessaoNotifier.value = Duration.zero;
    _exerciciosDaSessao = <ExercicioPlanejado>[];
    _nomesDasRotinasDaSessao = <String>[];
    _chavesDasSeriesConcluidas.clear();
    _cargasDasSeries.clear();
    _repeticoesDasSeries.clear();
    _tiposDasSeries.clear();
    _rpeDasSeries.clear();

    await _recarregarPlanos(notify: false);
    await _recarregarHistorico(notify: false);
    try {
      await ServicoDeNotificacoesDeTreino.instance.mostrarMotivacaoDoTreino(
        perfil: _perfil,
        routineNames: routineNames,
      );
    } catch (_) {
      // O treino já foi salvo; falha no lembrete não pode desfazer o registro.
    }
    notifyListeners();
    return historyId;
  }

  String _chaveDaSerie(
    ExercicioPlanejado exercicio,
    int zeroBasedSeriesIndex,
  ) =>
      '${exercicio.id ?? exercicio.hashCode}:${zeroBasedSeriesIndex + 1}';

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _cronometroDaSessao?.cancel();
    _cronometroDeDescanso?.cancel();
    _duracaoDaSessaoNotifier.dispose();
    _tempoRestanteDescansoNotifier.dispose();
    _abrirHabitosHojeNotifier.dispose();
    super.dispose();
  }
}
