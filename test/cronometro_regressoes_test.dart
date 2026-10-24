import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_gym/servicos/notificacoes_de_treino.dart';

import 'aplicativo_test.dart' show AdaptadorSimuladoNotificacoes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final servico = ServicoDeNotificacoesDeTreino.instance;
  late AdaptadorSimuladoNotificacoes adaptador;
  final agora = DateTime(2026, 10, 24, 12);
  Future<ResultadoAgendamentoDescanso> agendar(int id) =>
      servico.agendarNotificacaoDescanso(
        idExecucao: id, nomeExercicio: 'Supino',
        horarioTermino: agora.add(const Duration(seconds: 60)),
      );

  setUp(() {
    servico.resetForTesting();
    adaptador = AdaptadorSimuladoNotificacoes();
    servico.definirAdaptadorParaTestes(adaptador);
    servico.relogioParaTestes = () => agora;
  });
  tearDown(() => servico.resetForTesting());

  test('primeiro pedido continua possível após consulta silenciosa negativa', () async {
    adaptador.notificacoesAtivas = false;
    await servico.atualizarStatusPermissaoSilenciosamente();
    expect(await servico.solicitarPermissao(), isTrue);
    expect(adaptador.chamadasSolicitarPermissao, 1);
  });

  test('erro de consulta não vira recusa e permite nova tentativa', () async {
    adaptador.erroConsultaStatus = Exception('IPC');
    expect(await agendar(1), ResultadoAgendamentoDescanso.falhaAoAgendar);
    expect(servico.statusPermissaoNotificacao, StatusPermissaoNotificacao.naoSolicitada);
    adaptador.erroConsultaStatus = null;
    expect(await agendar(2), ResultadoAgendamentoDescanso.agendadoExato);
  });

  test('recusa não repete diálogo na série seguinte', () async {
    adaptador.notificacoesAtivas = false;
    adaptador.permissaoNotificacoesConcedida = false;
    expect(await servico.solicitarPermissao(), isFalse);
    expect(await servico.solicitarPermissao(), isFalse);
    expect(adaptador.chamadasSolicitarPermissao, 1);
  });

  test('cancelamento real falho permanece pendente até recuperação', () async {
    adaptador.erroAoCancelar = Exception('IPC');
    expect(await servico.cancelarNotificacaoDescanso(idExecucao: 1),
        ResultadoCancelamento.falhaTecnica);
    expect(servico.temLimpezaPendente, isTrue);
    adaptador.erroAoCancelar = null;
    expect(await servico.tentarRecuperarCancelamentoPendente(),
        ResultadoCancelamento.sucesso);
    expect(servico.temLimpezaPendente, isFalse);
  });

  test('inicialização false não é sucesso', () async {
    adaptador.retornoInicializar = false;
    await expectLater(servico.inicializar(), throwsA(isA<StateError>()));
    expect(servico.inicializado, isFalse);
    adaptador.retornoInicializar = true;
    await servico.inicializar();
    expect(servico.inicializado, isTrue);
  });

  test('identificação antiga não retrocede execução ativa', () async {
    await agendar(10);
    expect(await agendar(9), ResultadoAgendamentoDescanso.descartadoPorConcorrencia);
    expect(servico.idExecucaoAtiva, 10);
  });

  group('adaptador real preserva erros da plataforma', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final binding = TestDefaultBinaryMessengerBinding.instance;
    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'falha_simulada');
      });
    });
    tearDown(() => binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    for (final operacao in ['inicializar', 'pendentes', 'cancelar']) {
      test(operacao, () async {
        final real = AdaptadorPadraoFlutterLocalNotifications(FlutterLocalNotificationsPlugin());
        final Future<dynamic> resultado = switch (operacao) {
          'inicializar' => real.inicializar(const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'))),
          'pendentes' => real.obterRequisicoesPendentes(),
          _ => real.cancelar(2501),
        };
        await expectLater(resultado, throwsA(isA<PlatformException>()));
      });
    }
  });
}
