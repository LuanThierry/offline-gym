import 'package:offline_gym/dominio/volume_muscular.dart';
import 'package:offline_gym/dominio/calculadora_de_cargas.dart';
import 'package:offline_gym/dominio/calculadora_nutricional.dart';
import 'package:offline_gym/dominio/coach_cientifico.dart';
import 'package:offline_gym/provedores/estado_tema.dart';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_gym/dominio/catalogo_exercicios_offline.dart';
import 'package:offline_gym/dominio/regras_de_ofensiva.dart';
import 'package:offline_gym/dominio/sistema_gamificacao.dart';
import 'package:offline_gym/modelos/habito.dart';
import 'package:offline_gym/modelos/plano_de_treino.dart';
import 'package:offline_gym/servicos/backup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_gym/servicos/som_do_alarme.dart';
import 'package:offline_gym/servicos/criptografia_de_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('ExercicioPlanejado', () {
    test('mapeia corretamente os dias da semana', () {
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(1), 'Segunda-feira');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(2), 'Terça-feira');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(3), 'Quarta-feira');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(4), 'Quinta-feira');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(5), 'Sexta-feira');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(6), 'Sábado');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(7), 'Domingo');
    });

    test('identifica um dia da semana inválido', () {
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(0), 'Dia inválido');
      expect(ExercicioPlanejado.nomeDoDiaDaSemana(8), 'Dia inválido');
    });

    test(
      'preserva os dados e tempoDescansoSegundos ao converter para mapa e retornar',
      () {
        const original = ExercicioPlanejado(
          id: 10,
          diaSemana: 5,
          nome: 'Supino reto',
          carga: 20,
          series: 3,
          repeticoes: 10,
          tempoDescansoSegundos: 90,
        );

        final map = original.paraMapa();

        final restored = ExercicioPlanejado.deMapa(
          Map<String, Object?>.from(map),
        );

        expect(restored.id, original.id);
        expect(restored.diaSemana, original.diaSemana);
        expect(restored.nome, original.nome);
        expect(restored.carga, original.carga);
        expect(restored.series, original.series);
        expect(restored.repeticoes, original.repeticoes);
        expect(restored.tempoDescansoSegundos, 90);
      },
    );

    test('mantém carga e repetições diferentes para cada série', () {
      const original = ExercicioPlanejado(
        id: 21,
        diaSemana: 3,
        nome: 'Remada',
        carga: 20,
        series: 3,
        repeticoes: 10,
        cargasPorSerie: <double>[20, 22.5, 25],
        repeticoesPorSerie: <int>[12, 10, 8],
      );

      final recuperado = ExercicioPlanejado.deMapa(
        Map<String, Object?>.from(original.paraMapa()),
      );

      expect(List<double>.generate(3, recuperado.cargaDaSerie), <double>[
        20,
        22.5,
        25,
      ]);
      expect(List<int>.generate(3, recuperado.repeticoesDaSerie), <int>[
        12,
        10,
        8,
      ]);
    });

    test('permite atualizar uma única série sem alterar as demais', () {
      const original = ExercicioPlanejado(
        id: 30,
        diaSemana: 1,
        nome: 'Desenvolvimento',
        carga: 15,
        series: 3,
        repeticoes: 10,
        cargasPorSerie: <double>[15, 15, 15],
        repeticoesPorSerie: <int>[10, 10, 10],
      );

      final novasCargas = List<double>.from(original.cargasPorSerie);
      final novasReps = List<int>.from(original.repeticoesPorSerie);
      novasCargas[1] = 18.0; // Apenas a 2ª série é modificada
      novasReps[1] = 12;

      final atualizado = original.copiarCom(
        cargasPorSerie: novasCargas,
        repeticoesPorSerie: novasReps,
      );

      expect(atualizado.cargaDaSerie(0), 15.0);
      expect(atualizado.cargaDaSerie(1), 18.0);
      expect(atualizado.cargaDaSerie(2), 15.0);
      expect(atualizado.repeticoesDaSerie(0), 10);
      expect(atualizado.repeticoesDaSerie(1), 12);
      expect(atualizado.repeticoesDaSerie(2), 10);
    });

    test('SerieDoTreino mapeia carga e série corretamente', () {
      const set = SerieDoTreino(
        nomeExercicio: 'Agachamento',
        cargaUtilizada: 60.5,
        serieNumero: 2,
      );

      final map = set.paraMapa(idHistoricoTreino: 1);
      final deMapa = SerieDoTreino.deMapa(map);

      expect(deMapa.nomeExercicio, 'Agachamento');
      expect(deMapa.cargaUtilizada, 60.5);
      expect(deMapa.serieNumero, 2);
    });

    test('DetalheEvolucaoDoExercicio agrupa séries do histórico', () {
      const detail = DetalheEvolucaoDoExercicio(
        idDoTreino: 1,
        dataISO: '2026-10-16T10:00:00.000',
        series: [
          SerieDoTreino(
            nomeExercicio: 'Supino',
            cargaUtilizada: 30,
            serieNumero: 1,
          ),
          SerieDoTreino(
            nomeExercicio: 'Supino',
            cargaUtilizada: 35,
            serieNumero: 2,
          ),
        ],
        cargaMaxima: 35,
      );

      expect(detail.idDoTreino, 1);
      expect(detail.series.length, 2);
      expect(detail.cargaMaxima, 35);
    });
  });

  group('ServicoDeSomDoAlarme', () {
    test('possui opções de som cadastradas', () {
      expect(ServicoDeSomDoAlarme.sonsDisponiveis.isNotEmpty, isTrue);
      expect(
        ServicoDeSomDoAlarme.sonsDisponiveis.any((s) => s.id == 'digital'),
        isTrue,
      );
      expect(
        ServicoDeSomDoAlarme.sonsDisponiveis.any((s) => s.id == 'classic'),
        isTrue,
      );
      expect(
        ServicoDeSomDoAlarme.sonsDisponiveis.any((s) => s.id == 'bell'),
        isTrue,
      );
    });

    test('possui todos os 10 sons incluindo os novos esportivos sintetizados',
        () {
      final ids =
          ServicoDeSomDoAlarme.sonsDisponiveis.map((s) => s.id).toList();
      expect(ids.contains('digital'), isTrue);
      expect(ids.contains('classic'), isTrue);
      expect(ids.contains('bell'), isTrue);
      expect(ids.contains('soft'), isTrue);
      expect(ids.contains('boxing_gong'), isTrue);
      expect(ids.contains('whistle'), isTrue);
      expect(ids.contains('countdown'), isTrue);
      expect(ids.contains('pulse'), isTrue);
      expect(ids.contains('system'), isTrue);
      expect(ids.contains('custom'), isTrue);
      expect(ServicoDeSomDoAlarme.sonsDisponiveis.length,
          greaterThanOrEqualTo(10));
    });

    test('possui opção de música/áudio do celular cadastrada', () {
      expect(
        ServicoDeSomDoAlarme.sonsDisponiveis.any((s) => s.id == 'custom'),
        isTrue,
      );
    });
  });

  group('OfensivaTreino', () {
    final hoje = DateTime(2026, 10, 18, 15, 30);

    test('conta dias consecutivos e mantém a ofensiva durante o dia atual', () {
      final dias = <DateTime>[
        DateTime(2026, 10, 18, 8),
        DateTime(2026, 10, 17, 20),
        DateTime(2026, 10, 16),
      ];

      expect(OfensivaTreino.calcularDiasConsecutivos(dias, hoje), 3);
      expect(
        OfensivaTreino.calcularDiasConsecutivos(
          dias.skip(1),
          DateTime(2026, 10, 18),
        ),
        2,
      );
    });

    test('não conta sequência interrompida nem dias futuros', () {
      final dias = <DateTime>[
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 16),
        DateTime(2026, 10, 20),
      ];

      expect(OfensivaTreino.calcularDiasConsecutivos(dias, hoje), 1);
    });

    test('conta dias diferentes na semana de segunda a domingo', () {
      final datas = <DateTime>[
        DateTime(2026, 10, 12, 8),
        DateTime(2026, 10, 12, 19),
        DateTime(2026, 10, 17),
        DateTime(2026, 10, 19),
      ];

      expect(OfensivaTreino.contarDiasNaSemana(datas, hoje), 2);
    });
  });

  group('CriptografiaBackup', () {
    test('criptografa e recupera o conteúdo com a senha correta', () async {
      final original = Uint8List.fromList('treinos e fotos'.codeUnits);
      final arquivo = await CriptografiaBackup.criptografar(
        original,
        'minha-senha-segura',
      );

      expect(CriptografiaBackup.ehBackupCriptografado(arquivo), isTrue);
      expect(
        await CriptografiaBackup.descriptografar(arquivo, 'minha-senha-segura'),
        orderedEquals(original),
      );
    });

    test('recusa senha incorreta e conteúdo adulterado', () async {
      final original = Uint8List.fromList('meus dados locais'.codeUnits);
      final arquivo = await CriptografiaBackup.criptografar(
        original,
        'outra-senha-forte',
      );

      await expectLater(
        CriptografiaBackup.descriptografar(arquivo, 'senha-errada'),
        throwsA(isA<FormatException>()),
      );

      arquivo[arquivo.length - 1] ^= 1;
      await expectLater(
        CriptografiaBackup.descriptografar(arquivo, 'outra-senha-forte'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Habito e Tarefas', () {
    test('Habito seAplicaAoDia e serializacao funcionam', () {
      final habito = Habito(
        id: 1,
        titulo: 'Beber 2L de Água',
        descricao: 'Hidratação constante',
        categoria: 'Saúde',
        iconeCodePoint: CatalogoIconesHabito.iconesDisponiveis.first.codePoint,
        corValor: PaletaCoresHabito.cores.first.toARGB32(),
        diasSemana: const [1, 3, 5],
        metaValor: 2,
        metaUnidade: 'L',
        ordem: 0,
        ativo: true,
        dataCriacaoISO: DateTime(2026, 1, 1).toIso8601String(),
        concluidoHoje: true,
        ofensivaAtual: 5,
        totalConclusoes: 15,
      );

      expect(habito.seAplicaAoDia(1), isTrue);
      expect(habito.seAplicaAoDia(2), isFalse);
      expect(habito.seAplicaAoDia(3), isTrue);

      final mapa = habito.paraMapa();
      expect(mapa['titulo'], 'Beber 2L de Água');
      expect(mapa['ativo'], 1);

      final recuperado = Habito.deMapa(mapa);
      expect(recuperado.titulo, habito.titulo);
      expect(recuperado.diasSemana, [1, 3, 5]);
    });

    test('TarefaToDo serializacao e alternancia de conclusao', () {
      const tarefa = TarefaToDo(
        id: 10,
        titulo: 'Comprar creatina',
        prioridade: 'alta',
        categoria: 'Suplementação',
        concluida: false,
        dataCriacaoISO: '2026-10-19T00:00:00.000',
      );

      expect(tarefa.concluida, isFalse);
      final mapa = tarefa.paraMapa();
      expect(mapa['concluida'], 0);
      expect(mapa['prioridade'], 'alta');

      final recuperada = TarefaToDo.deMapa(mapa);
      expect(recuperada.titulo, 'Comprar creatina');
      expect(recuperada.prioridade, 'alta');

      final concluida = tarefa.copiarCom(
        concluida: true,
        dataLimiteISO: '2026-10-25T00:00:00.000',
      );
      expect(concluida.concluida, isTrue);
      expect(concluida.dataLimiteISO, isNotNull);

      final semPrazo = concluida.copiarCom(limparDataLimite: true);
      expect(semPrazo.dataLimiteISO, isNull);
    });

    test('Habito calcula percentualHoje e passoIncremento corretamente', () {
      const habitoMl = Habito(
        titulo: 'Água',
        metaValor: 2000,
        metaUnidade: 'ml',
        progressoHoje: 500,
        dataCriacaoISO: '2026-10-19T00:00:00.000',
      );
      expect(habitoMl.passoIncremento, 250);
      expect(habitoMl.percentualHoje, 0.25);

      const habitoCopos = Habito(
        titulo: 'Água em copos',
        metaValor: 8,
        metaUnidade: 'copos',
        progressoHoje: 4,
        dataCriacaoISO: '2026-10-19T00:00:00.000',
      );
      expect(habitoCopos.passoIncremento, 1);
      expect(habitoCopos.percentualHoje, 0.5);
    });

    test('FigurinhaDiario serializa coordenadas relativas X e Y', () {
      const figurinha = FigurinhaDiario(
        id: 'fig-1',
        emoji: '🔥',
        x: 0.25,
        y: 0.75,
        tamanho: 36,
      );

      final mapa = figurinha.paraMapa();
      expect(mapa['emoji'], '🔥');
      expect(mapa['x'], 0.25);
      expect(mapa['y'], 0.75);

      final recuperada = FigurinhaDiario.deMapa(mapa);
      expect(recuperada.emoji, '🔥');
      expect(recuperada.x, 0.25);
      expect(recuperada.y, 0.75);
    });
  });

  group('SistemaGamificacao', () {
    test('calcula classes e conquistas com habitos e meta de peso', () {
      final classeIniciante = SistemaGamificacao.obterClasseAtual(0);
      expect(classeIniciante.nome, 'Iniciante');

      final classeTita = SistemaGamificacao.obterClasseAtual(21);
      expect(classeTita.nome, 'Titã');

      final conquistas = SistemaGamificacao.obterConquistas(
        diasSeguidos: 7,
        totalTreinos: 10,
        treinosNaSemana: 4,
        totalHabitosConcluidos: 12,
        metaPesoDefinida: true,
      );

      final metaConquista =
          conquistas.firstWhere((c) => c.id == 'meta_definida');
      expect(metaConquista.desbloqueada, isTrue);

      final mestreHabitos =
          conquistas.firstWhere((c) => c.id == 'mestre_da_rotina');
      expect(mestreHabitos.desbloqueada, isTrue);
    });
  });

  group('DadosDoBackup', () {
    test('detecta quando o backup contem apenas planos e exercicios', () {
      const apenasExercicios = DadosDoBackup(
        exercicios: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'diaSemana': 1,
            'nome': 'Supino',
            'carga': 40.0,
            'series': 3,
            'repeticoes': 10,
          },
        ],
        treinos: <Map<String, Object?>>[],
        series: <Map<String, Object?>>[],
        pesosCorporais: <Map<String, Object?>>[],
        imagens: <String, Uint8List>{},
      );
      expect(apenasExercicios.contemApenasExercicios, isTrue);
      expect(apenasExercicios.temPerfil, isFalse);

      const backupCompleto = DadosDoBackup(
        exercicios: <Map<String, Object?>>[],
        treinos: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'dataISO': '2026-10-19T10:00:00.000',
            'tempoTotalSegundos': 1800,
            'diaSemana': 1,
          },
        ],
        series: <Map<String, Object?>>[],
        pesosCorporais: <Map<String, Object?>>[],
        perfil: <String, Object?>{'nome': 'Thierry', 'onboardingConcluido': 1},
        imagens: <String, Uint8List>{},
      );
      expect(backupCompleto.contemApenasExercicios, isFalse);
      expect(backupCompleto.temPerfil, isTrue);
    });
  });

  group('CatalogoDeExerciciosOffline e Novidades v1.1.1', () {
    test('possui mais de 2000 exercicios offline em todas as modalidades', () {
      final todos = CatalogoDeExerciciosOffline.todosOsExercicios;
      expect(todos.length, greaterThan(2000));

      for (final modalidade in <String>[
        'Academia',
        'Calistenia',
        'Em Casa',
        'CrossFit & Funcional',
        'Corrida & Cardio',
        'Mobilidade & Core',
        'Artes Marciais & Boxe',
        'Pilates & Postura',
        'Elásticos & Kettlebell',
      ]) {
        final filtrados = CatalogoDeExerciciosOffline.filtrar(
          modalidade: modalidade,
        );
        expect(
          filtrados,
          isNotEmpty,
          reason: 'Modalidade $modalidade deve possuir exercícios',
        );
      }

      final buscaSupino = CatalogoDeExerciciosOffline.filtrar(busca: 'supino');
      expect(buscaSupino, isNotEmpty);
      expect(
        CatalogoDeExerciciosOffline.modelosProntos.length,
        greaterThanOrEqualTo(15),
      );
    });

    test('calcula anilhas por lado da barra olimpica (20 kg) corretamente', () {
      expect(
        CatalogoDeExerciciosOffline.calcularAnilhasPorLado(20).anilhasPorLado,
        isEmpty,
      );
      expect(
        CatalogoDeExerciciosOffline.calcularAnilhasPorLado(60).anilhasPorLado,
        equals(<double>[20]),
      );
      expect(
        CatalogoDeExerciciosOffline.calcularAnilhasPorLado(100).anilhasPorLado,
        equals(<double>[25, 15]),
      );
    });

    test('Escudo de Ofensiva protege dia sem treino na sequencia', () {
      final hoje = DateTime(2026, 10, 19);
      final concluidos = <DateTime>[
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 17),
        DateTime(2026, 10, 16),
      ];
      final protegidos = <DateTime>[DateTime(2026, 10, 18)];

      expect(
        OfensivaTreino.calcularDiasConsecutivos(concluidos, hoje),
        equals(1),
      );
      expect(
        OfensivaTreino.calcularDiasConsecutivos(
          concluidos,
          hoje,
          datasProtegidas: protegidos,
        ),
        equals(3),
      );
    });
    test('ProvedorDeTema possui paletas de estilos esportivos validas', () {
      expect(ProvedorDeTema.estilosDisponiveis.length, greaterThanOrEqualTo(6));
      final ids = ProvedorDeTema.estilosDisponiveis.map((e) => e.id).toList();
      expect(ids.contains('roxo'), isTrue);
      expect(ids.contains('esmeralda'), isTrue);
      expect(ids.contains('ferro'), isTrue);
      expect(ids.contains('ouro'), isTrue);
      expect(ids.contains('ciano'), isTrue);
      expect(ids.contains('obsidiana'), isTrue);

      final provedor = ProvedorDeTema();
      expect(provedor.estiloAtual.id, equals('roxo'));
    });
  });

  group('Novidades v1.2.0 - Calculadora de Cargas, 1RM, RPE e Bi-sets', () {
    test('CalculadoraDeCargas estima 1RM corretamente via Epley e Brzycki', () {
      // 1 repetição = a própria carga
      expect(
          CalculadoraDeCargas.estimar1RM(carga: 100.0, repeticoes: 1), 100.0);

      // 100 kg para 10 repetições:
      // Epley: 100 * (1 + 10/30) = 133.33 kg
      // Brzycki: 100 / (1.0278 - 0.278) = 133.36 kg
      // Média ~133.5 kg
      final umRm = CalculadoraDeCargas.estimar1RM(carga: 100.0, repeticoes: 10);
      expect(umRm, greaterThan(130.0));
      expect(umRm, lessThan(136.0));

      // Casos de contorno
      expect(CalculadoraDeCargas.estimar1RM(carga: 0, repeticoes: 10), 0.0);
      expect(CalculadoraDeCargas.estimar1RM(carga: 100, repeticoes: 0), 0.0);
    });

    test(
        'CalculadoraDeCargas gera pirâmide gradual de aquecimento neuromuscular',
        () {
      final aquecimento =
          CalculadoraDeCargas.calcularAquecimento(cargaAlvo: 100.0);
      expect(aquecimento.length, equals(4)); // 40%, 60%, 80%, 90%
      expect(aquecimento[0].percentual, equals(40));
      expect(aquecimento[0].cargaKg, equals(40.0));
      expect(aquecimento[0].repeticoes, equals(10));

      expect(aquecimento[1].percentual, equals(60));
      expect(aquecimento[1].cargaKg, equals(60.0));
      expect(aquecimento[1].repeticoes, equals(6));

      expect(aquecimento[2].percentual, equals(80));
      expect(aquecimento[2].cargaKg, equals(80.0));
      expect(aquecimento[2].repeticoes, equals(3));

      expect(aquecimento[3].percentual, equals(90));
      expect(aquecimento[3].cargaKg, equals(90.0));
      expect(aquecimento[3].repeticoes, equals(1));
    });

    test('CalculadoraDeCargas converte RIR e RPE com precisão', () {
      expect(CalculadoraDeCargas.rirParaRpe(0), equals(10.0));
      expect(CalculadoraDeCargas.rirParaRpe(2), equals(8.0));
      expect(CalculadoraDeCargas.rpeParaRir(10.0), equals(0));
      expect(CalculadoraDeCargas.rpeParaRir(8.0), equals(2));
    });

    test(
        'ExercicioPlanejado serializa e desserializa grupoSuperSerie para Bi-sets',
        () {
      const original = ExercicioPlanejado(
        id: 42,
        diaSemana: 1,
        nome: 'Supino Reto + Crucifixo',
        carga: 80.0,
        series: 3,
        repeticoes: 10,
        grupoSuperSerie: 'A',
      );

      final mapa = original.paraMapa();
      expect(mapa['grupoSuperSerie'], equals('A'));

      final reconstituido = ExercicioPlanejado.deMapa(mapa);
      expect(reconstituido.grupoSuperSerie, equals('A'));

      final copiado = original.copiarCom(grupoSuperSerie: 'B');
      expect(copiado.grupoSuperSerie, equals('B'));

      final semBiSet = original.copiarCom(limparGrupoSuperSerie: true);
      expect(semBiSet.grupoSuperSerie, isNull);
    });

    test(
        'SerieDoTreino suporta tipos marcadores (aquecimento, dropset, falha) e RPE',
        () {
      const serie = SerieDoTreino(
        nomeExercicio: 'Agachamento Livre',
        cargaUtilizada: 120.0,
        serieNumero: 1,
        repeticoes: 8,
        tipo: 'aquecimento',
        rpe: 8.5,
      );

      final mapa = serie.paraMapa(idHistoricoTreino: 1);
      expect(mapa['tipo'], equals('aquecimento'));
      expect(mapa['rpe'], equals(8.5));

      final reconstituida = SerieDoTreino.deMapa(mapa);
      expect(reconstituida.tipo, equals('aquecimento'));
      expect(reconstituida.rpe, equals(8.5));
    });
  });

  group('Novidades v1.2.0 - Volume Muscular Semanal e Tonelagem', () {
    test(
        'MarcoDeVolumeMuscular classifica corretamente os volumes hipertróficos',
        () {
      final peitoZero = MarcoDeVolumeMuscular.criar(
          grupoMuscular: 'Peito', seriesCompletadas: 0);
      expect(peitoZero.status, equals('Sem estímulo'));

      final peitoManutencao = MarcoDeVolumeMuscular.criar(
          grupoMuscular: 'Peito', seriesCompletadas: 6);
      expect(peitoManutencao.status, equals('Manutenção'));

      final peitoOtimo = MarcoDeVolumeMuscular.criar(
          grupoMuscular: 'Peito', seriesCompletadas: 16);
      expect(peitoOtimo.status, equals('Volume Ótimo 🔥'));

      final peitoAlto = MarcoDeVolumeMuscular.criar(
          grupoMuscular: 'Peito', seriesCompletadas: 22);
      expect(peitoAlto.status, equals('Volume Alto'));

      final peitoSobrecarga = MarcoDeVolumeMuscular.criar(
          grupoMuscular: 'Peito', seriesCompletadas: 26);
      expect(peitoSobrecarga.status, equals('Sobrecarga (MRV)'));
    });

    test(
        'CatalogoDeExerciciosOffline identifica grupo muscular de exercícios oficiais e customizados',
        () {
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Supino Reto com Barra'),
          equals('Peito'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Puxada Frontal Aberta'),
          equals('Costas'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Agachamento Livre com Barra'),
          equals('Quadríceps'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Rosca Direta na Barra W'),
          equals('Bíceps'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Tríceps Corda na Polia'),
          equals('Tríceps'));

      // Exercícios personalizados com palavras-chave semânticas
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Meu Supino Inclinado Caseiro'),
          equals('Peito'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Remada Curvada com Halter'),
          equals('Costas'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Elevação Lateral com Elástico'),
          equals('Ombros'));
      expect(
          CatalogoDeExerciciosOffline.identificarGrupoMuscular(
              'Prancha Abdominal Isométrica'),
          equals('Abdômen & Core'));
    });
  });

  group('Novidades v1.3.0 - Nutrição TMB/TDEE, Medidas e Timer 3-2-1', () {
    test(
        'CalculadoraNutricional estima TMB masculina e feminina cientificamente (Mifflin-St Jeor)',
        () {
      // Homem: 80kg, 180cm, 25 anos -> 10*80 + 6.25*180 - 5*25 + 5 = 800 + 1125 - 125 + 5 = 1805 kcal
      final tmbHomem = CalculadoraNutricional.calcularTMB(
        pesoKg: 80,
        alturaCm: 180,
        idade: 25,
        sexo: 'Masculino',
      );
      expect(tmbHomem, closeTo(1805.0, 0.1));

      // Mulher: 60kg, 165cm, 30 anos -> 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25 kcal
      final tmbMulher = CalculadoraNutricional.calcularTMB(
        pesoKg: 60,
        alturaCm: 165,
        idade: 30,
        sexo: 'Feminino',
      );
      expect(tmbMulher, closeTo(1320.25, 0.1));
    });

    test(
        'CalculadoraNutricional calcula TDEE, déficit para emagrecimento e macros',
        () {
      final metas = CalculadoraNutricional.calcularMetas(
        pesoKg: 80,
        alturaCm: 180,
        idade: 25,
        sexo: 'Masculino',
        objetivo: 'Emagrecimento / Definição',
        fatorAtividade: 1.55,
      );

      // TMB = 1805, TDEE = 1805 * 1.55 = 2797.75 kcal
      expect(metas.tdeeKcal, closeTo(2797.75, 1.0));
      // Déficit de 400 kcal -> ~2397.75 kcal
      expect(metas.caloriasAlvoKcal, closeTo(2397.75, 1.0));
      // Proteína emagrecimento: 2.2g/kg -> 80 * 2.2 = 176g
      expect(metas.proteinaGramas, closeTo(176.0, 0.1));
      // Gordura: 0.9g/kg -> 80 * 0.9 = 72g
      expect(metas.gorduraGramas, closeTo(72.0, 0.1));
      // Hidratação: 80 * 0.035 = 2.8 L
      expect(metas.aguaLitros, closeTo(2.8, 0.01));
    });

    test(
        'RegistroDeMedidasCorporais serializa, desserializa e preserva todas as circunferências',
        () {
      const original = RegistroDeMedidasCorporais(
        id: 42,
        dataISO: '2026-10-20T10:00:00.000Z',
        bracoDireitoCm: 41.5,
        bracoEsquerdoCm: 41.0,
        peitoralCm: 108.0,
        cinturaCm: 82.0,
        abdomenCm: 84.5,
        coxaDireitaCm: 62.0,
        coxaEsquerdaCm: 61.5,
        panturrilhaDireitaCm: 40.0,
        panturrilhaEsquerdaCm: 39.8,
        observacoes: 'Medido em jejum',
      );

      final map = original.paraMapa(incluirId: true);
      final restaurado = RegistroDeMedidasCorporais.deMapa(map);

      expect(restaurado.id, equals(42));
      expect(restaurado.dataISO, equals('2026-10-20T10:00:00.000Z'));
      expect(restaurado.bracoDireitoCm, equals(41.5));
      expect(restaurado.bracoEsquerdoCm, equals(41.0));
      expect(restaurado.peitoralCm, equals(108.0));
      expect(restaurado.cinturaCm, equals(82.0));
      expect(restaurado.abdomenCm, equals(84.5));
      expect(restaurado.coxaDireitaCm, equals(62.0));
      expect(restaurado.coxaEsquerdaCm, equals(61.5));
      expect(restaurado.panturrilhaDireitaCm, equals(40.0));
      expect(restaurado.panturrilhaEsquerdaCm, equals(39.8));
      expect(restaurado.observacoes, equals('Medido em jejum'));
    });

    test('PerfilDoUsuario preserva alturaCm, sexo e fatorAtividade', () {
      const perfil = PerfilDoUsuario(
        nome: 'Luan Thierry',
        idade: 26,
        alturaCm: 178.5,
        sexo: 'Masculino',
        fatorAtividade: 1.725,
        objetivoPrincipal: 'Hipertrofia',
      );

      final map = perfil.paraMapa();
      final recuperado = PerfilDoUsuario.deMapa(map);

      expect(recuperado.nome, equals('Luan Thierry'));
      expect(recuperado.alturaCm, equals(178.5));
      expect(recuperado.sexo, equals('Masculino'));
      expect(recuperado.fatorAtividade, equals(1.725));
    });

    test('ServicoDeSomDoAlarme expõe opção de contagem regressiva 3-2-1', () {
      final servico = ServicoDeSomDoAlarme.instance;
      expect(servico.countdownBeepEnabled, isA<bool>());
    });
  });

  group(
      'Novidades v1.4.0 - Coach Científico Offline, Simetria, Deload e AMOLED',
      () {
    test(
        'CoachCientificoOffline detecta assimetria Peitoral vs Costas e emite alerta fisiológico',
        () {
      const perfil = PerfilDoUsuario(
        nome: 'Thierry Dev',
        objetivoPrincipal: 'Hipertrofia',
        nivelExperiencia: 'Intermediário',
      );

      final volumes = <MarcoDeVolumeMuscular>[
        MarcoDeVolumeMuscular.criar(
            grupoMuscular: 'Peito', seriesCompletadas: 18),
        MarcoDeVolumeMuscular.criar(
            grupoMuscular: 'Costas', seriesCompletadas: 6),
      ];

      final diag = CoachCientificoOffline.analisarTreinamento(
        perfil: perfil,
        volumeSemanal: volumes,
        historico: const <TreinoDoHistorico>[],
        diasOfensiva: 5,
      );

      expect(diag.saudacaoPersonalizada, contains('Thierry'));
      expect(diag.indiceEquilibrioPercentual, lessThan(100));
      expect(
        diag.pareceres.any((p) => p.titulo.contains('Dominância de Peitoral')),
        isTrue,
      );
    });

    test(
        'CoachCientificoOffline detecta desbalanço na relação I:Q de membros inferiores',
        () {
      const perfil = PerfilDoUsuario(
        nome: 'Carlos Atleta',
        objetivoPrincipal: 'Força e Explosão',
      );

      final volumes = <MarcoDeVolumeMuscular>[
        MarcoDeVolumeMuscular.criar(
            grupoMuscular: 'Quadríceps', seriesCompletadas: 20),
        MarcoDeVolumeMuscular.criar(
            grupoMuscular: 'Posterior & Glúteos', seriesCompletadas: 6),
      ];

      final diag = CoachCientificoOffline.analisarTreinamento(
        perfil: perfil,
        volumeSemanal: volumes,
        historico: const <TreinoDoHistorico>[],
        diasOfensiva: 4,
      );

      expect(
        diag.pareceres.any((p) => p.titulo.contains('Relação I:Q')),
        isTrue,
      );
    });

    test(
        'CoachCientificoOffline alerta sobre sobrecarga (MRV) durante déficit calórico',
        () {
      const perfil = PerfilDoUsuario(
        nome: 'Marina',
        objetivoPrincipal: 'Emagrecimento / Definição',
      );

      final volumes = <MarcoDeVolumeMuscular>[
        MarcoDeVolumeMuscular.criar(
            grupoMuscular: 'Peito', seriesCompletadas: 25), // > MRV (22)
      ];

      final diag = CoachCientificoOffline.analisarTreinamento(
        perfil: perfil,
        volumeSemanal: volumes,
        historico: const <TreinoDoHistorico>[],
        diasOfensiva: 6,
      );

      expect(
        diag.pareceres.any((p) => p.titulo.contains('Déficit Calórico')),
        isTrue,
      );
    });

    test(
        'CoachCientificoOffline recomenda Semana de Deload com histórico de alta fadiga',
        () {
      const perfil = PerfilDoUsuario(
        nome: 'Lucas Pro',
        objetivoPrincipal: 'Hipertrofia Máxima',
        nivelExperiencia: 'Avançado',
      );

      // Simula 22 treinos pesados recentes (> 45 min)
      final historico = List.generate(
        22,
        (i) => TreinoDoHistorico(
          id: i + 1,
          dataISO: DateTime.now().subtract(Duration(days: i)).toIso8601String(),
          nomeTreino: 'Treino Intenso',
          tempoTotalSegundos: 3600, // 60 min
          diaSemana: (i % 7) + 1,
        ),
      );

      final diag = CoachCientificoOffline.analisarTreinamento(
        perfil: perfil,
        volumeSemanal: const <MarcoDeVolumeMuscular>[],
        historico: historico,
        diasOfensiva: 14,
      );

      expect(diag.semanaSugeridaDeload, isTrue);
      expect(diag.indiceFadigaPercentual, greaterThanOrEqualTo(85));
      expect(
        diag.pareceres.any((p) => p.titulo.contains('Hora do Deload')),
        isTrue,
      );
    });

    test('ProvedorDeTema armazena e alterna o Modo Preto Puro AMOLED',
        () async {
      final provedor = ProvedorDeTema();
      expect(provedor.modoAmoled, isFalse);

      await provedor.definirModoAmoled(true);
      expect(provedor.modoAmoled, isTrue);

      await provedor.definirModoAmoled(false);
      expect(provedor.modoAmoled, isFalse);
    });

    test(
        'CatalogoDeExerciciosOffline mapeia exercicios importados pelo nome mais próximo via regex',
        () {
      final supino =
          CatalogoDeExerciciosOffline.encontrarMaisProximo('Supino Reto Barra');
      expect(supino, isNotNull);
      expect(supino!.nome.toLowerCase().contains('supino'), isTrue);

      final agachamento =
          CatalogoDeExerciciosOffline.encontrarMaisProximo('Agachamento');
      expect(agachamento, isNotNull);
      expect(agachamento!.nome.toLowerCase().contains('agachamento'), isTrue);

      final rosca =
          CatalogoDeExerciciosOffline.encontrarMaisProximo('Rosca direta');
      expect(rosca, isNotNull);
      expect(rosca!.nome.toLowerCase().contains('rosca'), isTrue);
    });

    test(
        'CatalogoDeExerciciosOffline fornece ícones distintos para cada grupo muscular',
        () {
      final iconePeito = CatalogoDeExerciciosOffline.iconeDoGrupo('Peito');
      final iconeCostas = CatalogoDeExerciciosOffline.iconeDoGrupo('Costas');
      final iconePernas =
          CatalogoDeExerciciosOffline.iconeDoGrupo('Quadríceps');
      final iconeCardio =
          CatalogoDeExerciciosOffline.iconeDoGrupo('Cardio & Corrida');

      expect(iconePeito, isNot(equals(iconeCostas)));
      expect(iconeCostas, isNot(equals(iconePernas)));
      expect(iconePernas, isNot(equals(iconeCardio)));
    });
  });

  group(
      'Novidades v1.4.1 - Exportação PDF Nativa, Fadiga por Músculo, Isolate e Hápticos',
      () {
    test(
        'CoachCientificoOffline estima recuperação e fadiga em horas por grupo muscular',
        () {
      final agora = DateTime(2026, 10, 20, 18, 0);
      final ultimosTreinos = <String, DateTime>{
        'Peito': agora.subtract(const Duration(hours: 24)), // 24h atrás (base 60h -> 40%)
        'Quadríceps': agora.subtract(const Duration(hours: 36)), // 36h atrás (base 72h -> 50%)
        'Ombros': agora.subtract(const Duration(hours: 48)), // 48h atrás (base 48h -> 100%)
      };

      final recuperacoes = CoachCientificoOffline.estimarRecuperacaoMuscular(
        ultimosTreinosPorGrupo: ultimosTreinos,
        agora: agora,
      );

      final peito = recuperacoes.firstWhere((r) => r.grupoMuscular == 'Peito');
      expect(peito.percentualRecuperado, equals(40));
      expect(peito.horasDesdeUltimoTreino, equals(24));
      expect(peito.prontoParaTreinar, isFalse);

      final pernas =
          recuperacoes.firstWhere((r) => r.grupoMuscular == 'Quadríceps');
      expect(pernas.percentualRecuperado, equals(50));
      expect(pernas.horasDesdeUltimoTreino, equals(36));

      final ombros =
          recuperacoes.firstWhere((r) => r.grupoMuscular == 'Ombros');
      expect(ombros.percentualRecuperado, equals(100));
      expect(ombros.prontoParaTreinar, isTrue);

      final costas =
          recuperacoes.firstWhere((r) => r.grupoMuscular == 'Costas');
      expect(costas.percentualRecuperado, equals(100));
      expect(costas.horasDesdeUltimoTreino, isNull);
      expect(costas.prontoParaTreinar, isTrue);

      // Verifica inclusão no DiagnosticoDoCoach
      final diag = CoachCientificoOffline.analisarTreinamento(
        perfil: const PerfilDoUsuario(nome: 'Atleta'),
        volumeSemanal: const <MarcoDeVolumeMuscular>[],
        historico: const <TreinoDoHistorico>[],
        diasOfensiva: 3,
        ultimosTreinosPorGrupo: ultimosTreinos,
        dataReferencia: agora,
      );

      expect(diag.recuperacaoMuscular.isNotEmpty, isTrue);
      expect(diag.recuperacaoMuscular.any((m) => m.grupoMuscular == 'Peito'), isTrue);
    });

    test(
        'CatalogoDeExerciciosOffline.filtrarAsync filtra exercicios em background com compute()',
        () async {
      final resultadoSupino =
          await CatalogoDeExerciciosOffline.filtrarAsync(busca: 'supino');
      expect(resultadoSupino.isNotEmpty, isTrue);
      expect(
        resultadoSupino.every((e) =>
            e.nome.toLowerCase().contains('supino') ||
            e.grupoMuscular.toLowerCase().contains('peito')),
        isTrue,
      );

      final resultadoCalistenia =
          await CatalogoDeExerciciosOffline.filtrarAsync(
        modalidade: 'Calistenia',
      );
      expect(resultadoCalistenia.isNotEmpty, isTrue);
      expect(
        resultadoCalistenia.every((e) => e.modalidade == 'Calistenia'),
        isTrue,
      );
    });

    test(
        'ServicoDeSomDoAlarme permite configurar e persistir IntensidadeTatil (Forte, Média, Desativada)',
        () async {
      final servico = ServicoDeSomDoAlarme.instance;

      await servico.definirIntensidadeTatil(IntensidadeTatil.forte);
      expect(servico.intensidadeTatil, equals(IntensidadeTatil.forte));
      expect(servico.vibrateEnabled, isTrue);

      await servico.definirIntensidadeTatil(IntensidadeTatil.media);
      expect(servico.intensidadeTatil, equals(IntensidadeTatil.media));
      expect(servico.vibrateEnabled, isTrue);

      await servico.definirIntensidadeTatil(IntensidadeTatil.desativada);
      expect(servico.intensidadeTatil, equals(IntensidadeTatil.desativada));
      expect(servico.vibrateEnabled, isFalse);

      // Chamadas seguras sem exceção
      servico.vibrarClique();
      servico.vibrarImpacto();

      // Restaura para forte
      await servico.definirIntensidadeTatil(IntensidadeTatil.forte);
      expect(servico.intensidadeTatil, equals(IntensidadeTatil.forte));
    });

    test(
        'ExercicioPlanejado suporta ajuste unificado de repeticoes e carga por serie e em lote',
        () {
      const exercicio = ExercicioPlanejado(
        id: 99,
        diaSemana: 1,
        nome: 'Supino Reto',
        series: 3,
        repeticoes: 10,
        carga: 80.0,
      );

      // Valores iniciais calculados por série
      expect(exercicio.repeticoesDaSerie(0), 10);
      expect(exercicio.cargaDaSerie(0), 80.0);

      // Ajusta repeticoes e carga unificados para a série 0
      final seriesCargas = List<double>.generate(3, exercicio.cargaDaSerie);
      final seriesReps = List<int>.generate(3, exercicio.repeticoesDaSerie);
      seriesCargas[0] = 85.5;
      seriesReps[0] = 12;

      final serie0Atualizada = exercicio.copiarCom(
        cargasPorSerie: seriesCargas,
        repeticoesPorSerie: seriesReps,
      );

      expect(serie0Atualizada.repeticoesDaSerie(0), 12);
      expect(serie0Atualizada.cargaDaSerie(0), 85.5);
      expect(serie0Atualizada.repeticoesDaSerie(1), 10);
      expect(serie0Atualizada.cargaDaSerie(1), 80.0);

      // Aplica em lote para todas as séries (modo "Aplicar em todas as séries" do modal)
      final todasAtualizadas = exercicio.copiarCom(
        carga: 90.0,
        repeticoes: 8,
        cargasPorSerie: List<double>.filled(3, 90.0),
        repeticoesPorSerie: List<int>.filled(3, 8),
      );

      for (var i = 0; i < todasAtualizadas.series; i++) {
        expect(todasAtualizadas.repeticoesDaSerie(i), 8);
        expect(todasAtualizadas.cargaDaSerie(i), 90.0);
      }
    });
  });
}
