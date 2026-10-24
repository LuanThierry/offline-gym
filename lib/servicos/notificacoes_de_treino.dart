import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../modelos/plano_de_treino.dart';

/// Estado de autorização das notificações do sistema.
enum StatusPermissaoNotificacao {
  concedida,
  negada,
  naoSolicitada,
}

/// Capacidade do aparelho de agendar alarmes com precisão exata.
enum CapacidadeAlarmeExato {
  disponivel,
  indisponivelOuNaoAutorizado,
}

/// Resultado detalhado da operação de agendamento do cronômetro de descanso.
enum ResultadoAgendamentoDescanso {
  agendadoExato,
  agendadoInexato,
  notificacaoNaoAutorizada,
  canalBloqueado,
  canalSemSom,
  falhaAoAgendar,
  descartadoPorConcorrencia,
}

/// Resultado de operações de cancelamento e limpeza de notificações.
enum ResultadoCancelamento {
  sucesso,
  falhaTecnica,
  descartadoPorConcorrencia,
}

/// Interface que padroniza o acesso aos recursos nativos de notificação,
/// garantindo que produção e testes percorram o mesmo fluxo de controle.
abstract class AdaptadorNotificacoesNativas {
  Future<bool?> inicializar(InitializationSettings settings);
  Future<List<AndroidNotificationChannel>?> obterCanaisDeNotificacao();
  Future<void> criarCanalDeNotificacao(AndroidNotificationChannel canal);
  Future<void> deletarCanalDeNotificacao(String canalId);
  Future<bool?> notificacoesEstaoAtivas();
  Future<bool?> solicitarPermissaoNotificacoes();
  Future<bool?> podeAgendarAlarmesExatos();
  Future<List<PendingNotificationRequest>> obterRequisicoesPendentes();
  Future<void> agendarZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  });
  Future<void> cancelar(int id);
}

/// Implementação padrão de produção delegando para o plugin FlutterLocalNotificationsPlugin.
class AdaptadorPadraoFlutterLocalNotifications
    implements AdaptadorNotificacoesNativas {
  AdaptadorPadraoFlutterLocalNotifications(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android {
    return _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
  }

  IOSFlutterLocalNotificationsPlugin? get _ios {
    return _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
  }

  @override
  Future<bool?> inicializar(InitializationSettings settings) async {
    return await _plugin.initialize(settings: settings);
  }

  @override
  Future<List<AndroidNotificationChannel>?> obterCanaisDeNotificacao() async {
    final android = _android;
    if (android == null) return null;
    return await android.getNotificationChannels();
  }

  @override
  Future<void> criarCanalDeNotificacao(AndroidNotificationChannel canal) async {
    final android = _android;
    if (android == null) return;
    await android.createNotificationChannel(canal);
  }

  @override
  Future<void> deletarCanalDeNotificacao(String canalId) async {
    final android = _android;
    if (android == null) return;
    await android.deleteNotificationChannel(channelId: canalId);
  }

  @override
  Future<bool?> notificacoesEstaoAtivas() async {
    final android = _android;
    if (android != null) return await android.areNotificationsEnabled();
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    throw UnsupportedError('Consulta de notificações indisponível nesta plataforma.');
  }

  @override
  Future<bool?> solicitarPermissaoNotificacoes() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission();
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    throw UnsupportedError('Permissão de notificações indisponível nesta plataforma.');
  }

  @override
  Future<bool?> podeAgendarAlarmesExatos() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications();
  }

  @override
  Future<List<PendingNotificationRequest>> obterRequisicoesPendentes() async {
    return await _plugin.pendingNotificationRequests();
  }

  @override
  Future<void> agendarZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> cancelar(int id) async {
    await _plugin.cancel(id: id);
  }
}

class ServicoDeNotificacoesDeTreino {
  ServicoDeNotificacoesDeTreino._() {
    _adaptador = AdaptadorPadraoFlutterLocalNotifications(_plugin);
  }

  static final ServicoDeNotificacoesDeTreino instance =
      ServicoDeNotificacoesDeTreino._();

  static const String _channelId = 'workout_reminders';
  static const int _firstReminderId = 2400;
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    'Lembretes de treino',
    description: 'Lembretes personalizados dos seus treinos.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const String _restTimerChannelId = 'offline_gym_rest_alarm_v3';
  static const int _restTimerNotificationId = 2501;
  static const AndroidNotificationChannel _restChannel =
      AndroidNotificationChannel(
    _restTimerChannelId,
    'Fim do Descanso',
    description: 'Avisa quando o tempo de descanso entre as séries terminar.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('offline_gym_alarm'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late AdaptadorNotificacoesNativas _adaptador;

  bool _initialized = false;
  Future<void>? _inicializacaoEmAndamento;

  // Controle de permissão com reuso de requisição pendente
  Future<bool>? _requisicaoPermissaoEmAndamento;
  bool _pedidoPermissaoRealizado = false;
  StatusPermissaoNotificacao _statusPermissaoNotificacao =
      StatusPermissaoNotificacao.naoSolicitada;

  // Fila serializada de operações para evitar corridas assíncronas no sistema
  Future<void> _filaOperacoes = Future<void>.value();
  int _idExecucaoAtiva = 0;
  int? _ultimoIdExecucaoAgendadoConhecido;
  int? _idExecucaoComFalhaDeCancelamento;
  bool _limpezaPendenteNoSistema = false;

  bool get inicializado => _initialized;
  StatusPermissaoNotificacao get statusPermissaoNotificacao =>
      _statusPermissaoNotificacao;
  int get idExecucaoAtiva => _idExecucaoAtiva;
  int? get ultimoIdExecucaoAgendadoConhecido =>
      _ultimoIdExecucaoAgendadoConhecido;
  int? get idExecucaoComFalhaDeCancelamento =>
      _idExecucaoComFalhaDeCancelamento;
  bool get temLimpezaPendente =>
      _limpezaPendenteNoSistema || _idExecucaoComFalhaDeCancelamento != null;

  @visibleForTesting
  DateTime Function()? relogioParaTestes;

  DateTime get _agora =>
      relogioParaTestes != null ? relogioParaTestes!() : DateTime.now();

  @visibleForTesting
  void definirAdaptadorParaTestes(AdaptadorNotificacoesNativas adaptador) {
    _adaptador = adaptador;
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _inicializacaoEmAndamento = null;
    _requisicaoPermissaoEmAndamento = null;
    _pedidoPermissaoRealizado = false;
    _statusPermissaoNotificacao = StatusPermissaoNotificacao.naoSolicitada;
    _idExecucaoAtiva = 0;
    _ultimoIdExecucaoAgendadoConhecido = null;
    _idExecucaoComFalhaDeCancelamento = null;
    _limpezaPendenteNoSistema = false;
    _filaOperacoes = Future<void>.value();
    relogioParaTestes = null;
    _adaptador = AdaptadorPadraoFlutterLocalNotifications(_plugin);
  }

  Future<void> inicializar() async {
    if (_initialized) return;
    if (_inicializacaoEmAndamento != null) {
      return await _inicializacaoEmAndamento!;
    }

    final completer = Completer<void>();
    _inicializacaoEmAndamento = completer.future;
    completer.future.ignore();

    try {
      tzdata.initializeTimeZones();
      try {
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      }

      final inicializou = await _adaptador.inicializar(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      if (inicializou != true) {
        throw StateError('O plugin não confirmou a inicialização.');
      }

      // Consulta os canais existentes no sistema antes de registrar os novos
      final canaisAntes = await _adaptador.obterCanaisDeNotificacao();
      final tinhaCanalV2 = canaisAntes != null &&
          canaisAntes.any((c) => c.id == 'offline_gym_rest_timer_v2');
      final tinhaCanalV3 = canaisAntes != null &&
          canaisAntes.any((c) => c.id == _restTimerChannelId);

      await _adaptador.criarCanalDeNotificacao(_channel);
      await _adaptador.criarCanalDeNotificacao(_restChannel);

      if (tinhaCanalV2) {
        final pendentes = await _adaptador.obterRequisicoesPendentes();
        final temAlertaDescansoPendente =
            pendentes.any((r) => r.id == _restTimerNotificationId);

        if (tinhaCanalV3 && temAlertaDescansoPendente) {
          // Coexistência v2+v3 com alerta no ID 2501 pendente:
          // Como as APIs locais não expõem o canal de origem do alerta agendado,
          // preserva o agendamento intacto e adia a exclusão do canal antigo v2
          // para não apagar indevidamente um descanso legítimo do v3.
        } else {
          // Migração v2 pura (sem v3 prévio no aparelho) OU sem alerta pendente:
          // Se houver alerta pendente exclusivo do canal antigo, cancela antes de remover o canal
          if (temAlertaDescansoPendente) {
            await _adaptador.cancelar(_restTimerNotificationId);
          }
          await _adaptador.deletarCanalDeNotificacao(
            'offline_gym_rest_timer_v2',
          );
        }
      }

      _initialized = true;
      completer.complete();
    } catch (e) {
      _initialized = false;
      completer.completeError(e);
      rethrow;
    } finally {
      _inicializacaoEmAndamento = null;
    }
  }

  /// Solicita autorização de notificação reutilizando requisição em andamento
  /// e preservando respostas anteriores para não incomodar o usuário a cada série.
  Future<bool> solicitarPermissao({bool forcar = false}) async {
    if (_requisicaoPermissaoEmAndamento != null) {
      return await _requisicaoPermissaoEmAndamento!;
    }
    if (!forcar &&
        (_statusPermissaoNotificacao == StatusPermissaoNotificacao.concedida ||
            _pedidoPermissaoRealizado)) {
      return _statusPermissaoNotificacao ==
          StatusPermissaoNotificacao.concedida;
    }

    final completer = Completer<bool>();
    _requisicaoPermissaoEmAndamento = completer.future;
    completer.future.ignore();

    try {
      await inicializar();
      final enabled = await _adaptador.notificacoesEstaoAtivas();
      final bool? resposta = enabled == true && !forcar
          ? true
          : await _adaptador.solicitarPermissaoNotificacoes();
      if (resposta == null) {
        throw StateError('Resposta de autorização inconclusiva.');
      }
      final concedida = resposta;
      _pedidoPermissaoRealizado = true;
      _statusPermissaoNotificacao = concedida
          ? StatusPermissaoNotificacao.concedida
          : StatusPermissaoNotificacao.negada;
      completer.complete(concedida);
      return concedida;
    } catch (erro, stack) {
      completer.completeError(erro, stack);
      rethrow;
    } finally {
      _requisicaoPermissaoEmAndamento = null;
    }
  }

  /// Atualiza o status interno de autorização silenciosamente ao retornar das configurações,
  /// sem repetir caixas de diálogo e sem converter falha técnica em negação.
  Future<void> atualizarStatusPermissaoSilenciosamente() async {
    try {
      final bool? enabled = await _adaptador.notificacoesEstaoAtivas();
      if (enabled != null) {
        _statusPermissaoNotificacao = enabled
            ? StatusPermissaoNotificacao.concedida
            : StatusPermissaoNotificacao.negada;
      }
    } catch (_) {
      // Falha técnica na consulta: não altera o status para negada
    }
  }

  /// Verifica o estado de autorização e silenciamento do canal de descanso,
  /// diferenciando app desautorizado, canal bloqueado ou canal sem som configurado.
  Future<ResultadoAgendamentoDescanso?> verificarEstadoDoCanalDescanso() async {
    try {
      await inicializar();
      final bool? enabled = await _adaptador.notificacoesEstaoAtivas();
      if (enabled == false) {
        return ResultadoAgendamentoDescanso.notificacaoNaoAutorizada;
      }

      final canais = await _adaptador.obterCanaisDeNotificacao();
      if (canais != null) {
        for (final canal in canais) {
          if (canal.id == _restTimerChannelId) {
            if (canal.importance == Importance.none) {
              return ResultadoAgendamentoDescanso.canalBloqueado;
            }
            if (canal.playSound == false) {
              return ResultadoAgendamentoDescanso.canalSemSom;
            }
            break;
          }
        }
      }
      return null;
    } catch (_) {
      // Falhas técnicas na consulta não devem ser diagnosticadas como permissão negada
      return ResultadoAgendamentoDescanso.falhaAoAgendar;
    }
  }

  /// Verifica se o sistema operacional autoriza o agendamento de alarmes com precisão exata.
  Future<CapacidadeAlarmeExato> verificarCapacidadeAlarmeExato() async {
    try {
      final canExact = await _adaptador.podeAgendarAlarmesExatos() ?? false;
      return canExact
          ? CapacidadeAlarmeExato.disponivel
          : CapacidadeAlarmeExato.indisponivelOuNaoAutorizado;
    } catch (_) {
      return CapacidadeAlarmeExato.indisponivelOuNaoAutorizado;
    }
  }

  Future<void> sincronizarLembretesSemanais({
    required PerfilDoUsuario? perfil,
    required Map<int, List<RotinaDeTreino>> rotinasPorDia,
  }) async {
    await inicializar();
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      await _adaptador.cancelar(_firstReminderId + diaSemana);
    }
    if (perfil == null || !perfil.lembretesAtivos) return;
    if (!await solicitarPermissao()) return;

    final now = tz.TZDateTime.now(tz.local);
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      final rotinas = (rotinasPorDia[diaSemana] ?? const <RotinaDeTreino>[])
          .where((rotina) => rotina.selecionado && rotina.exercicios.isNotEmpty)
          .toList(growable: false);
      if (rotinas.isEmpty) continue;

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        perfil.horaLembrete,
        perfil.minutoLembrete,
      );

      final daysUntilWeekday = (diaSemana - scheduled.weekday) % 7;
      scheduled = scheduled.add(Duration(days: daysUntilWeekday));
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      await _adaptador.agendarZoned(
        id: _firstReminderId + diaSemana,
        title: 'Bora treinar! 💪',
        body: 'Seu treino de hoje está pronto. Vamos nessa!',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Lembretes de treino',
            channelDescription: 'Lembretes personalizados dos seus treinos.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> mostrarMotivacaoDoTreino({
    required PerfilDoUsuario? perfil,
    required List<String> routineNames,
  }) async {
    if (perfil == null) return;
    await inicializar();
    final completedNames =
        routineNames.isEmpty ? 'seu treino' : routineNames.join(' e ');
    await _plugin.show(
      id: 2500,
      title: 'Mandou bem, ${perfil.nome}!',
      body: 'Você treinou $completedNames. Continue no seu ritmo!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Lembretes de treino',
          channelDescription: 'Lembretes personalizados dos seus treinos.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Encaminha a limpeza do alerta anterior na fila serializada caso a substituição atual
  /// não possa agendar (permissão negada, canal bloqueado, expiração ou falha).
  void _encaminharLimpezaPreviaSeNecessario(int idExecucao) {
    // Também limpa estado desconhecido após reinício. A fila é a autoridade
    // sobre a ordem; nunca limpa um agendamento mais novo já concluído.
    {
      _filaOperacoes = _filaOperacoes.then((_) async {
        if ((_ultimoIdExecucaoAgendadoConhecido ?? -1) >= idExecucao) return;
        try {
          await _adaptador.cancelar(_restTimerNotificationId);
          _ultimoIdExecucaoAgendadoConhecido = null;
          _limpezaPendenteNoSistema = false;
          _idExecucaoComFalhaDeCancelamento = null;
        } catch (_) {
          _limpezaPendenteNoSistema = true;
          _idExecucaoComFalhaDeCancelamento = idExecucao;
        }
      }).catchError((_) {
        _limpezaPendenteNoSistema = true;
        _idExecucaoComFalhaDeCancelamento = idExecucao;
      });
    }
  }

  Future<void> _tentarLimparOrfaoInterno(int idExecucao) async {
    try {
      await _adaptador.cancelar(_restTimerNotificationId);
      _ultimoIdExecucaoAgendadoConhecido = null;
      _limpezaPendenteNoSistema = false;
      _idExecucaoComFalhaDeCancelamento = null;
    } catch (_) {
      _limpezaPendenteNoSistema = true;
      _idExecucaoComFalhaDeCancelamento = idExecucao;
    }
  }

  /// Agenda uma notificação nativa para o cronômetro usando horário absoluto
  /// e garantindo concorrência segura com fila serializada.
  Future<ResultadoAgendamentoDescanso> agendarNotificacaoDescanso({
    required int idExecucao,
    required String nomeExercicio,
    required DateTime horarioTermino,
  }) async {
    if (idExecucao <= _idExecucaoAtiva) {
      return ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
    }
    _idExecucaoAtiva = idExecucao;
    _encaminharLimpezaPreviaSeNecessario(idExecucao);

    // Se o horário de término for igual ou anterior ao atual, descarta imediatamente
    final agoraInicio = _agora;
    if (!horarioTermino.isAfter(agoraInicio)) {
      return ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
    }

    bool permissaoConcedida;
    try {
      permissaoConcedida = await solicitarPermissao();
    } catch (_) {
      return idExecucao != _idExecucaoAtiva || !horarioTermino.isAfter(_agora)
          ? ResultadoAgendamentoDescanso.descartadoPorConcorrencia
          : ResultadoAgendamentoDescanso.falhaAoAgendar;
    }
    final agoraPosPermissao = _agora;
    if (idExecucao != _idExecucaoAtiva ||
        !horarioTermino.isAfter(agoraPosPermissao)) {
      return ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
    }
    if (!permissaoConcedida) {
      return ResultadoAgendamentoDescanso.notificacaoNaoAutorizada;
    }

    final estadoCanal = await verificarEstadoDoCanalDescanso();
    final agoraPosCanal = _agora;
    if (idExecucao != _idExecucaoAtiva ||
        !horarioTermino.isAfter(agoraPosCanal)) {
      return ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
    }
    if (estadoCanal == ResultadoAgendamentoDescanso.notificacaoNaoAutorizada) {
      _statusPermissaoNotificacao = StatusPermissaoNotificacao.negada;
      return ResultadoAgendamentoDescanso.notificacaoNaoAutorizada;
    }
    if (estadoCanal == ResultadoAgendamentoDescanso.canalBloqueado) {
      return ResultadoAgendamentoDescanso.canalBloqueado;
    }
    if (estadoCanal == ResultadoAgendamentoDescanso.falhaAoAgendar) {
      return ResultadoAgendamentoDescanso.falhaAoAgendar;
    }

    final capacidadeExata = await verificarCapacidadeAlarmeExato();
    final agoraPosCapacidade = _agora;
    if (idExecucao != _idExecucaoAtiva ||
        !horarioTermino.isAfter(agoraPosCapacidade)) {
      return ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
    }

    final scheduleMode = capacidadeExata == CapacidadeAlarmeExato.disponivel
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final completer = Completer<ResultadoAgendamentoDescanso>();

    _filaOperacoes = _filaOperacoes.then((_) async {
      final agoraPreNativo = _agora;
      if (idExecucao != _idExecucaoAtiva ||
          !horarioTermino.isAfter(agoraPreNativo)) {
        if (!completer.isCompleted) {
          completer.complete(
            ResultadoAgendamentoDescanso.descartadoPorConcorrencia,
          );
        }
        return;
      }

      ResultadoAgendamentoDescanso resultado =
          capacidadeExata == CapacidadeAlarmeExato.disponivel
              ? ResultadoAgendamentoDescanso.agendadoExato
              : ResultadoAgendamentoDescanso.agendadoInexato;

      try {
        await inicializar();
        if (idExecucao != _idExecucaoAtiva || !horarioTermino.isAfter(_agora)) {
          completer.complete(ResultadoAgendamentoDescanso.descartadoPorConcorrencia);
          return;
        }
        final scheduledDate = tz.TZDateTime.from(horarioTermino, tz.local);

        const androidDetails = AndroidNotificationDetails(
          _restTimerChannelId,
          'Fim do Descanso',
          channelDescription:
              'Avisa quando o tempo de descanso entre as séries terminar.',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('offline_gym_alarm'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          fullScreenIntent: false,
          visibility: NotificationVisibility.public,
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

        await _adaptador.agendarZoned(
          id: _restTimerNotificationId,
          title: 'Descanso finalizado! ⏱️',
          body: 'Hora da próxima série de $nomeExercicio.',
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: scheduleMode,
        );
        _ultimoIdExecucaoAgendadoConhecido = idExecucao;
        _limpezaPendenteNoSistema = false;
        _idExecucaoComFalhaDeCancelamento = null;
      } catch (_) {
        if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
          final agoraPreFallback = _agora;
          if (idExecucao != _idExecucaoAtiva ||
              !horarioTermino.isAfter(agoraPreFallback)) {
            await _tentarLimparOrfaoInterno(idExecucao);
            resultado = ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
          } else {
            try {
              final scheduledDate = tz.TZDateTime.from(
                horarioTermino,
                tz.local,
              );
              const androidDetails = AndroidNotificationDetails(
                _restTimerChannelId,
                'Fim do Descanso',
                channelDescription:
                    'Avisa quando o tempo de descanso entre as séries terminar.',
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.alarm,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('offline_gym_alarm'),
                audioAttributesUsage: AudioAttributesUsage.alarm,
                enableVibration: true,
                fullScreenIntent: false,
                visibility: NotificationVisibility.public,
              );
              const iosDetails = DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: false,
                presentSound: true,
                interruptionLevel: InterruptionLevel.timeSensitive,
              );

              await _adaptador.agendarZoned(
                id: _restTimerNotificationId,
                title: 'Descanso finalizado! ⏱️',
                body: 'Hora da próxima série de $nomeExercicio.',
                scheduledDate: scheduledDate,
                notificationDetails: const NotificationDetails(
                  android: androidDetails,
                  iOS: iosDetails,
                ),
                androidScheduleMode:
                    AndroidScheduleMode.inexactAllowWhileIdle,
              );
              _ultimoIdExecucaoAgendadoConhecido = idExecucao;
              _limpezaPendenteNoSistema = false;
              _idExecucaoComFalhaDeCancelamento = null;
              resultado = ResultadoAgendamentoDescanso.agendadoInexato;
            } catch (_) {
              await _tentarLimparOrfaoInterno(idExecucao);
              resultado = ResultadoAgendamentoDescanso.falhaAoAgendar;
            }
          }
        } else {
          await _tentarLimparOrfaoInterno(idExecucao);
          resultado = ResultadoAgendamentoDescanso.falhaAoAgendar;
        }
      }

      if (idExecucao != _idExecucaoAtiva) {
        await _tentarLimparOrfaoInterno(idExecucao);
        resultado = ResultadoAgendamentoDescanso.descartadoPorConcorrencia;
      } else if (estadoCanal == ResultadoAgendamentoDescanso.canalSemSom &&
          (resultado == ResultadoAgendamentoDescanso.agendadoExato ||
              resultado == ResultadoAgendamentoDescanso.agendadoInexato)) {
        resultado = ResultadoAgendamentoDescanso.canalSemSom;
      }

      if (!completer.isCompleted) {
        completer.complete(resultado);
      }
    }).catchError((_) {
      if (!completer.isCompleted) {
        completer.complete(ResultadoAgendamentoDescanso.falhaAoAgendar);
      }
    });

    return await completer.future;
  }

  /// Cancela o alarme de descanso agendado de forma serializada na fila.
  Future<ResultadoCancelamento> cancelarNotificacaoDescanso({
    required int idExecucao,
  }) async {
    if (idExecucao < _idExecucaoAtiva) {
      return ResultadoCancelamento.descartadoPorConcorrencia;
    }

    _idExecucaoAtiva = idExecucao;
    final completer = Completer<ResultadoCancelamento>();

    _filaOperacoes = _filaOperacoes.then((_) async {
      if (idExecucao < _idExecucaoAtiva) {
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.descartadoPorConcorrencia);
        }
        return;
      }

      try {
        await _adaptador.cancelar(_restTimerNotificationId);
        _ultimoIdExecucaoAgendadoConhecido = null;
        _limpezaPendenteNoSistema = false;
        _idExecucaoComFalhaDeCancelamento = null;
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.sucesso);
        }
      } catch (_) {
        _limpezaPendenteNoSistema = true;
        _idExecucaoComFalhaDeCancelamento = idExecucao;
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.falhaTecnica);
        }
      }
    }).catchError((_) {
      _limpezaPendenteNoSistema = true;
      _idExecucaoComFalhaDeCancelamento = idExecucao;
      if (!completer.isCompleted) {
        completer.complete(ResultadoCancelamento.falhaTecnica);
      }
    });

    return completer.future;
  }

  /// Tenta recuperar a limpeza pendente de uma notificação que falhou ao cancelar ou limpar,
  /// garantindo que um agendamento novo ativo nunca seja cancelado por uma recuperação antiga.
  Future<ResultadoCancelamento> tentarRecuperarCancelamentoPendente() async {
    if (!_limpezaPendenteNoSistema &&
        _idExecucaoComFalhaDeCancelamento == null) {
      return ResultadoCancelamento.sucesso;
    }

    final idParaRecuperar =
        _idExecucaoComFalhaDeCancelamento ?? _idExecucaoAtiva;
    final completer = Completer<ResultadoCancelamento>();

    _filaOperacoes = _filaOperacoes.then((_) async {
      // Se um alarme mais novo foi agendado com sucesso e assumiu a identificação ativa,
      // o ID 2501 já foi sobrescrito no sistema pelo novo agendamento; não podemos cancelá-lo!
      if (_ultimoIdExecucaoAgendadoConhecido != null &&
          _ultimoIdExecucaoAgendadoConhecido == _idExecucaoAtiva &&
          idParaRecuperar < _idExecucaoAtiva) {
        _limpezaPendenteNoSistema = false;
        _idExecucaoComFalhaDeCancelamento = null;
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.descartadoPorConcorrencia);
        }
        return;
      }

      try {
        await _adaptador.cancelar(_restTimerNotificationId);
        _ultimoIdExecucaoAgendadoConhecido = null;
        _limpezaPendenteNoSistema = false;
        _idExecucaoComFalhaDeCancelamento = null;
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.sucesso);
        }
      } catch (_) {
        _limpezaPendenteNoSistema = true;
        if (!completer.isCompleted) {
          completer.complete(ResultadoCancelamento.falhaTecnica);
        }
      }
    }).catchError((_) {
      _limpezaPendenteNoSistema = true;
      if (!completer.isCompleted) {
        completer.complete(ResultadoCancelamento.falhaTecnica);
      }
    });

    return completer.future;
  }
}
