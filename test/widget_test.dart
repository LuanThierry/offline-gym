import 'package:flutter_test/flutter_test.dart';
import 'package:offline_gym/models/workout_plan_model.dart';

void main() {
  group('WorkoutPlanModel', () {
    test('mapeia corretamente os dias da semana', () {
      expect(WorkoutPlanModel.weekdayName(1), 'Segunda-feira');
      expect(WorkoutPlanModel.weekdayName(2), 'Terça-feira');
      expect(WorkoutPlanModel.weekdayName(3), 'Quarta-feira');
      expect(WorkoutPlanModel.weekdayName(4), 'Quinta-feira');
      expect(WorkoutPlanModel.weekdayName(5), 'Sexta-feira');
      expect(WorkoutPlanModel.weekdayName(6), 'Sábado');
      expect(WorkoutPlanModel.weekdayName(7), 'Domingo');
    });

    test('identifica um dia da semana inválido', () {
      expect(WorkoutPlanModel.weekdayName(0), 'Dia inválido');
      expect(WorkoutPlanModel.weekdayName(8), 'Dia inválido');
    });

    test('preserva os dados ao converter para mapa e retornar', () {
      const original = WorkoutPlanModel(
        id: 10,
        diaSemana: 5,
        nome: 'Supino reto',
        carga: 20,
        series: 3,
        repeticoes: 10,
      );

      final map = original.toMap();

      final restored = WorkoutPlanModel.fromMap(
        Map<String, Object?>.from(map),
      );

      expect(restored.id, original.id);
      expect(restored.diaSemana, original.diaSemana);
      expect(restored.nome, original.nome);
      expect(restored.carga, original.carga);
      expect(restored.series, original.series);
      expect(restored.repeticoes, original.repeticoes);
    });
  });
}