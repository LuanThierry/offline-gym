import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../modelos/plano_de_treino.dart';

class ServicoDeNotificacoesDeTreino {
  ServicoDeNotificacoesDeTreino._();

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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> inicializar() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_channel);
    }

    _initialized = true;
  }

  Future<bool> solicitarPermissao() async {
    await inicializar();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }
    return !kIsWeb;
  }

  Future<void> sincronizarLembretesSemanais({
    required PerfilDoUsuario? perfil,
    required Map<int, List<RotinaDeTreino>> rotinasPorDia,
  }) async {
    await inicializar();
    for (var diaSemana = 1; diaSemana <= 7; diaSemana++) {
      await _plugin.cancel(id: _firstReminderId + diaSemana);
    }
    if (perfil == null || !perfil.lembretesAtivos) return;
    await solicitarPermissao();

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
      while (scheduled.weekday != diaSemana || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final routineNames = rotinas.map((rotina) => rotina.nome).join(' e ');
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Lembretes de treino',
          channelDescription: 'Lembretes personalizados dos seus treinos.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id: _firstReminderId + diaSemana,
        title: 'Oi, ${perfil.nome}!',
        body: 'Hoje é dia de $routineNames. Bora treinar? Você consegue!',
        scheduledDate: scheduled,
        notificationDetails: details,
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
}
