import 'package:flutter_test/flutter_test.dart';
import 'package:offline_gym/dominio/sistema_gamificacao.dart';

void main() {
  group('SistemaGamificacao', () {
    test('retorna classe correta com 0 dias', () {
      final classe = SistemaGamificacao.obterClasseAtual(0);
      expect(classe.nome, 'Iniciante');
      expect(classe.diasMinimos, 0);
    });

    test('retorna Determinado com 1 ou 2 dias', () {
      expect(SistemaGamificacao.obterClasseAtual(1).nome, 'Determinado');
      expect(SistemaGamificacao.obterClasseAtual(2).nome, 'Determinado');
    });

    test('retorna Focado com 3 a 6 dias', () {
      expect(SistemaGamificacao.obterClasseAtual(3).nome, 'Focado');
      expect(SistemaGamificacao.obterClasseAtual(6).nome, 'Focado');
    });

    test('retorna Constante com 7 a 13 dias', () {
      expect(SistemaGamificacao.obterClasseAtual(7).nome, 'Constante');
      expect(SistemaGamificacao.obterClasseAtual(13).nome, 'Constante');
    });

    test('retorna Guerreiro com 14 dias e Titã com 21 dias', () {
      expect(SistemaGamificacao.obterClasseAtual(14).nome, 'Guerreiro');
      expect(SistemaGamificacao.obterClasseAtual(21).nome, 'Titã');
    });

    test('retorna Mestre com 30 dias e Imortal com 180 dias', () {
      expect(SistemaGamificacao.obterClasseAtual(30).nome, 'Mestre');
      expect(SistemaGamificacao.obterClasseAtual(180).nome, 'Imortal');
    });

    test('calcula dias para proxima classe corretamente', () {
      expect(SistemaGamificacao.diasParaProximaClasse(0), 1);
      expect(SistemaGamificacao.diasParaProximaClasse(1), 2); // próxima é 3
      expect(SistemaGamificacao.diasParaProximaClasse(3), 4); // próxima é 7
      expect(SistemaGamificacao.diasParaProximaClasse(180), 0); // topo
    });

    test('calcula progresso percentual corretamente', () {
      expect(SistemaGamificacao.calcularProgresso(0), 0.0);
      expect(SistemaGamificacao.calcularProgresso(1),
          0.0); // começou Determinado (1 a 3)
      expect(SistemaGamificacao.calcularProgresso(2),
          0.5); // meio caminho de 1 a 3
      expect(SistemaGamificacao.calcularProgresso(180), 1.0);
    });

    test('gera conquistas corretas conforme métricas', () {
      final conquistasZero = SistemaGamificacao.obterConquistas(
        diasSeguidos: 0,
        totalTreinos: 0,
        treinosNaSemana: 0,
      );
      expect(conquistasZero.every((c) => !c.desbloqueada), isTrue);

      final conquistasPrimeiroTreino = SistemaGamificacao.obterConquistas(
        diasSeguidos: 1,
        totalTreinos: 1,
        treinosNaSemana: 1,
      );
      final primeiro = conquistasPrimeiroTreino.firstWhere(
        (c) => c.id == 'primeiro_treino',
      );
      expect(primeiro.desbloqueada, isTrue);
    });
  });
}
