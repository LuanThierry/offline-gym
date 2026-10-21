/// Calculadora científica offline de Taxa Metabólica Basal (TMB / BMR),
/// Gasto Energético Total Diário (TDEE) e Metas de Macronutrientes (Mifflin-St Jeor).
class MetasNutricionais {
  const MetasNutricionais({
    required this.tmbKcal,
    required this.tdeeKcal,
    required this.caloriasAlvoKcal,
    required this.proteinaGramas,
    required this.carboidratoGramas,
    required this.gorduraGramas,
    required this.aguaLitros,
    required this.objetivo,
    required this.nivelAtividade,
  });

  /// Taxa Metabólica Basal (calorias em repouso absoluto)
  final double tmbKcal;

  /// Gasto Energético Total considerando nível de atividade física
  final double tdeeKcal;

  /// Calorias diárias recomendadas para atingir o objetivo
  final double caloriasAlvoKcal;

  /// Proteína diária recomendada em gramas (g)
  final double proteinaGramas;

  /// Carboidrato diário recomendado em gramas (g)
  final double carboidratoGramas;

  /// Gordura saudável recomendada em gramas (g)
  final double gorduraGramas;

  /// Ingestão hídrica diária recomendada em Litros (L)
  final double aguaLitros;

  final String objetivo;
  final String nivelAtividade;

  /// Calorias provenientes de proteínas
  double get caloriasProteina => proteinaGramas * 4;

  /// Calorias provenientes de carboidratos
  double get caloriasCarboidrato => carboidratoGramas * 4;

  /// Calorias provenientes de gorduras
  double get caloriasGordura => gorduraGramas * 9;

  /// Percentual de calorias de proteína
  double get percentualProteina =>
      caloriasAlvoKcal > 0 ? (caloriasProteina / caloriasAlvoKcal) * 100 : 0;

  /// Percentual de calorias de carboidrato
  double get percentualCarboidrato =>
      caloriasAlvoKcal > 0 ? (caloriasCarboidrato / caloriasAlvoKcal) * 100 : 0;

  /// Percentual de calorias de gordura
  double get percentualGordura =>
      caloriasAlvoKcal > 0 ? (caloriasGordura / caloriasAlvoKcal) * 100 : 0;
}

class CalculadoraNutricional {
  const CalculadoraNutricional._();

  /// Fatores de atividade física padrão (Physical Activity Level - PAL)
  static const Map<String, double> niveisDeAtividade = <String, double>{
    'Sedentário (pouco ou nenhum exercício)': 1.2,
    'Levemente Ativo (treino 1 a 3 dias/sem)': 1.375,
    'Moderadamente Ativo (treino 3 a 5 dias/sem)': 1.55,
    'Muito Ativo (treino intenso 6 a 7 dias/sem)': 1.725,
    'Extremamente Ativo (atleta ou trabalho pesado)': 1.9,
  };

  /// Estima a Taxa Metabólica Basal (TMB / BMR) usando a equação científica
  /// de Mifflin-St Jeor, padrão-ouro da nutrição esportiva moderna.
  ///
  /// Homens: (10 x peso em kg) + (6.25 x altura em cm) - (5 x idade) + 5
  /// Mulheres: (10 x peso em kg) + (6.25 x altura em cm) - (5 x idade) - 161
  static double calcularTMB({
    required double pesoKg,
    required double alturaCm,
    required int idade,
    required String sexo,
  }) {
    final pesoValido = pesoKg.clamp(20.0, 350.0);
    final alturaValida = alturaCm.clamp(80.0, 260.0);
    final idadeValida = idade.clamp(10, 110);

    final base =
        (10.0 * pesoValido) + (6.25 * alturaValida) - (5.0 * idadeValida);
    final isFeminino = sexo.trim().toLowerCase().startsWith('f');

    return isFeminino ? base - 161.0 : base + 5.0;
  }

  /// Calcula o plano completo de macros e calorias
  static MetasNutricionais calcularMetas({
    required double pesoKg,
    required double alturaCm,
    required int idade,
    required String sexo,
    required String objetivo,
    double fatorAtividade = 1.55,
  }) {
    final tmb = calcularTMB(
      pesoKg: pesoKg,
      alturaCm: alturaCm,
      idade: idade,
      sexo: sexo,
    );

    final fatorSeguro = fatorAtividade.clamp(1.1, 2.2);
    final tdee = tmb * fatorSeguro;

    final objNorm = objetivo.toLowerCase();
    double ajusteCalorico = 0;
    double proteinaPorKg = 2.0;

    if (objNorm.contains('emagrecimento') || objNorm.contains('defini')) {
      // Déficit moderado sustentável de ~400 kcal
      ajusteCalorico = -400;
      // Maior proteína para preservação de massa magra em déficit
      proteinaPorKg = 2.2;
    } else if (objNorm.contains('hipertrofia')) {
      // Superávit limpo de ~350 kcal
      ajusteCalorico = 350;
      proteinaPorKg = 2.0;
    } else if (objNorm.contains('força')) {
      // Superávit de suporte neuromuscular ~250 kcal
      ajusteCalorico = 250;
      proteinaPorKg = 2.0;
    } else {
      // Manutenção ou saúde
      ajusteCalorico = 0;
      proteinaPorKg = 1.8;
    }

    // Calorias diárias alvo mínimas seguras (1200 kcal)
    final caloriasAlvo = (tdee + ajusteCalorico).clamp(1200.0, 8000.0);

    // Proteína (4 kcal/g)
    final proteinaGramas = pesoKg * proteinaPorKg;
    final kcalProteina = proteinaGramas * 4;

    // Gorduras saudáveis (9 kcal/g) - 0.9 g/kg peso corporal
    final gorduraGramas = (pesoKg * 0.9).clamp(25.0, 180.0);
    final kcalGordura = gorduraGramas * 9;

    // Carboidratos (4 kcal/g) - calorias restantes
    final kcalRestante = caloriasAlvo - (kcalProteina + kcalGordura);
    final carboidratoGramas = (kcalRestante / 4.0).clamp(40.0, 900.0);

    // Hidratação científica: 35ml a 40ml por kg de peso corporal
    final aguaLitros = (pesoKg * 0.035).clamp(1.5, 6.0);

    String rotuloAtividade = 'Moderadamente Ativo (treino 3 a 5 dias/sem)';
    for (final entry in niveisDeAtividade.entries) {
      if ((entry.value - fatorSeguro).abs() < 0.05) {
        rotuloAtividade = entry.key;
        break;
      }
    }

    return MetasNutricionais(
      tmbKcal: tmb,
      tdeeKcal: tdee,
      caloriasAlvoKcal: caloriasAlvo,
      proteinaGramas: proteinaGramas,
      carboidratoGramas: carboidratoGramas,
      gorduraGramas: gorduraGramas,
      aguaLitros: aguaLitros,
      objetivo: objetivo,
      nivelAtividade: rotuloAtividade,
    );
  }
}
