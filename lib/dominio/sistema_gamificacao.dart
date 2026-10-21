import 'package:flutter/material.dart';

/// Define as classes e patamares da ofensiva do usuário.
class ClasseOfensiva {
  const ClasseOfensiva({
    required this.nome,
    required this.titulo,
    required this.diasMinimos,
    required this.cor,
    required this.corSecundaria,
    required this.icone,
    required this.descricaoObjetivo,
    required this.recompensa,
    required this.dicaDiaria,
    required this.motivacao,
  });

  final String nome;
  final String titulo;
  final int diasMinimos;
  final Color cor;
  final Color corSecundaria;
  final IconData icone;
  final String descricaoObjetivo;
  final String recompensa;
  final String dicaDiaria;
  final String motivacao;
}

/// Conquista ou marco gamificado dentro do app.
class ConquistaGamificada {
  const ConquistaGamificada({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.desbloqueada,
    required this.progresso,
    required this.textoProgresso,
  });

  final String id;
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool desbloqueada;
  final double progresso;
  final String textoProgresso;
}

/// Sistema de regras de gamificação, níveis, classes e recompensas.
class SistemaGamificacao {
  const SistemaGamificacao._();

  static const List<ClasseOfensiva> todasAsClasses = [
    ClasseOfensiva(
      nome: 'Iniciante',
      titulo: 'Primeiro Passo',
      diasMinimos: 0,
      cor: Color(0xFF7E8299),
      corSecundaria: Color(0xFF5E6278),
      icone: Icons.directions_walk_rounded,
      descricaoObjetivo: 'Complete seu primeiro treino para começar a jornada.',
      recompensa: 'Desbloqueia a borda de perfil e histórico pessoal.',
      dicaDiaria:
          'A consistência supera a intensidade no início. O treino mais importante é o de amanhã!',
      motivacao:
          'Todo campeão já foi um iniciante que não desistiu após o primeiro dia.',
    ),
    ClasseOfensiva(
      nome: 'Determinado',
      titulo: 'Ignição Roxa',
      diasMinimos: 1,
      cor: Color(0xFF7C4DFF),
      corSecundaria: Color(0xFF6C5CE7),
      icone: Icons.bolt_rounded,
      descricaoObjetivo: 'Complete 1 treino concluído com sucesso.',
      recompensa: 'Borda Ametista Neon + Dicas diárias de recuperação.',
      dicaDiaria:
          'Ao treinar, seu metabolismo e síntese proteica permanecem elevados por até 48 horas. Hidrate-se bem!',
      motivacao:
          'Você quebrou a inércia! O primeiro treino foi concluído e sua força começou a despertar.',
    ),
    ClasseOfensiva(
      nome: 'Focado',
      titulo: 'Ritmo Firme',
      diasMinimos: 3,
      cor: Color(0xFF00BFA5),
      corSecundaria: Color(0xFF009688),
      icone: Icons.track_changes_rounded,
      descricaoObjetivo: 'Mantenha 3 dias consecutivos em ofensiva.',
      recompensa: 'Borda Turquesa Elétrica + Dicas de descanso e sono.',
      dicaDiaria:
          'O sono profundo (7 a 8 horas) é quando seu corpo repara microlesões musculares e libera GH.',
      motivacao:
          '3 treinos seguidos provam que sua força de vontade está no comando.',
    ),
    ClasseOfensiva(
      nome: 'Constante',
      titulo: 'Semana de Ferro',
      diasMinimos: 7,
      cor: Color(0xFF00E676),
      corSecundaria: Color(0xFF10B981),
      icone: Icons.workspace_premium_rounded,
      descricaoObjetivo: 'Complete 7 dias consecutivos de compromisso.',
      recompensa: 'Borda Verde Esmeralda + Dicas de nutrição e proteínas.',
      dicaDiaria:
          'Consuma entre 1.6g a 2.2g de proteína por kg corporal para garantir hipertrofia e retenção de massa magra.',
      motivacao:
          'Uma semana inteira invicta! Poucas pessoas têm essa disciplina.',
    ),
    ClasseOfensiva(
      nome: 'Guerreiro',
      titulo: 'Chama Viva',
      diasMinimos: 14,
      cor: Color(0xFFFF6D00),
      corSecundaria: Color(0xFFFF9100),
      icone: Icons.local_fire_department_rounded,
      descricaoObjetivo: 'Mantenha 14 dias seguidos na ofensiva.',
      recompensa:
          'Borda Âmbar Flamejante + Estratégias de progressão de carga.',
      dicaDiaria:
          'Sobrecarga progressiva não é só aumentar peso: controlar o tempo sob tensão e amplitude multiplica seus ganhos.',
      motivacao: 'Duas semanas! A preguiça já não tem mais poder sobre você.',
    ),
    ClasseOfensiva(
      nome: 'Titã',
      titulo: 'Hábito Inquebrável',
      diasMinimos: 21,
      cor: Color(0xFFFF1744),
      corSecundaria: Color(0xFFF50057),
      icone: Icons.shield_rounded,
      descricaoObjetivo: 'Complete 21 dias seguidos de dedicação.',
      recompensa: 'Borda Rubi Radiante + Filosofia de mente inabalável.',
      dicaDiaria:
          'A ciência comprova: após 21 dias o treino se torna automático no cérebro. Você criou um estilo de vida!',
      motivacao:
          'Você cruzou a linha onde treinar não é mais obrigação, é a sua identidade.',
    ),
    ClasseOfensiva(
      nome: 'Mestre',
      titulo: 'Ouro Lendário',
      diasMinimos: 30,
      cor: Color(0xFFFFD700),
      corSecundaria: Color(0xFFFFB300),
      icone: Icons.military_tech_rounded,
      descricaoObjetivo: 'Alcance 30 dias na ofensiva.',
      recompensa: 'Borda Ouro Puro com brilho + Técnicas avançadas de treino.',
      dicaDiaria:
          'Foque no pico de contração em cada exercício. A conexão mente-músculo ativa até 25% mais fibras neuromotoras.',
      motivacao:
          '1 mês de consistência absoluta! Menos de 5% das pessoas chegam até aqui.',
    ),
    ClasseOfensiva(
      nome: 'Diamante',
      titulo: 'Pureza e Foco',
      diasMinimos: 60,
      cor: Color(0xFF00B0FF),
      corSecundaria: Color(0xFF0091EA),
      icone: Icons.diamond_rounded,
      descricaoObjetivo: 'Complete 60 dias de disciplina exemplar.',
      recompensa: 'Borda Safira Diamante + Guias de periodização.',
      dicaDiaria:
          'Monitore seus descansos e anote suas anotações no diário para bater seus recordes pessoais.',
      motivacao:
          'Dois meses sem vacilar. Seu corpo e sua mente estão forjados em diamante.',
    ),
    ClasseOfensiva(
      nome: 'Lenda',
      titulo: 'Força Cósmica',
      diasMinimos: 90,
      cor: Color(0xFFD500F9),
      corSecundaria: Color(0xFFAA00FF),
      icone: Icons.auto_awesome_rounded,
      descricaoObjetivo: 'Alcance 90 dias de consistência épica.',
      recompensa:
          'Borda Violeta Neon Cósmica + Status de Inspiração da Academia.',
      dicaDiaria:
          'Você atingiu um nível de maestria física. Pequenos detalhes em mobilidade e aquecimento evitam lesões e aceleram resultados.',
      motivacao:
          'Um trimestre inteiro! Você não apenas treina, você lidera pelo exemplo.',
    ),
    ClasseOfensiva(
      nome: 'Imortal',
      titulo: 'Legado Eterno',
      diasMinimos: 180,
      cor: Color(0xFFFFAB00),
      corSecundaria: Color(0xFFFF6F00),
      icone: Icons.star_rounded,
      descricaoObjetivo: '180 dias de dedicação ininterrupta.',
      recompensa: 'Borda Imortal Dourada com Aura Solar.',
      dicaDiaria:
          'A disciplina diária se transformou no seu maior legado. Nada pode parar quem conquistou a si mesmo.',
      motivacao:
          'Meio ano invicto! Você alcançou o topo supremo da disciplina física.',
    ),
  ];

  /// Retorna a classe atual conforme os dias seguidos de ofensiva.
  static ClasseOfensiva obterClasseAtual(int diasSeguidos) {
    ClasseOfensiva atual = todasAsClasses.first;
    for (final classe in todasAsClasses) {
      if (diasSeguidos >= classe.diasMinimos) {
        atual = classe;
      } else {
        break;
      }
    }
    return atual;
  }

  /// Retorna a próxima classe a ser alcançada, ou null se já está no topo.
  static ClasseOfensiva? obterProximaClasse(int diasSeguidos) {
    for (final classe in todasAsClasses) {
      if (diasSeguidos < classe.diasMinimos) {
        return classe;
      }
    }
    return null;
  }

  /// Retorna quantos dias faltam para a próxima classe.
  static int diasParaProximaClasse(int diasSeguidos) {
    final proxima = obterProximaClasse(diasSeguidos);
    if (proxima == null) return 0;
    return (proxima.diasMinimos - diasSeguidos).clamp(0, 9999);
  }

  /// Progresso percentual (0.0 a 1.0) entre a classe atual e a próxima.
  static double calcularProgresso(int diasSeguidos) {
    final atual = obterClasseAtual(diasSeguidos);
    final proxima = obterProximaClasse(diasSeguidos);
    if (proxima == null) return 1.0;

    final base = atual.diasMinimos;
    final meta = proxima.diasMinimos;
    final intervalo = meta - base;
    if (intervalo <= 0) return 1.0;

    final progresso = (diasSeguidos - base) / intervalo;
    return progresso.clamp(0.0, 1.0);
  }

  /// Retorna a lista de conquistas dinâmicas baseadas nos dados do usuário.
  static List<ConquistaGamificada> obterConquistas({
    required int diasSeguidos,
    required int totalTreinos,
    required int treinosNaSemana,
    int totalHabitosConcluidos = 0,
    bool metaPesoDefinida = false,
  }) {
    return [
      ConquistaGamificada(
        id: 'primeiro_treino',
        titulo: 'Primeiro Passo',
        descricao: 'Completar o primeiro treino no app.',
        icone: Icons.fitness_center_rounded,
        desbloqueada: totalTreinos >= 1,
        progresso: totalTreinos >= 1 ? 1.0 : 0.0,
        textoProgresso: totalTreinos >= 1 ? 'Concluído!' : '0/1 treino',
      ),
      ConquistaGamificada(
        id: 'trinca_de_ferro',
        titulo: 'Trinca de Ferro',
        descricao: 'Alcançar 3 dias consecutivos de treino.',
        icone: Icons.track_changes_rounded,
        desbloqueada: diasSeguidos >= 3,
        progresso: (diasSeguidos / 3).clamp(0.0, 1.0),
        textoProgresso:
            diasSeguidos >= 3 ? 'Concluído!' : '$diasSeguidos/3 dias',
      ),
      ConquistaGamificada(
        id: 'semana_campea',
        titulo: 'Semana Campeã',
        descricao: 'Treinar pelo menos 4 dias na mesma semana.',
        icone: Icons.date_range_rounded,
        desbloqueada: treinosNaSemana >= 4,
        progresso: (treinosNaSemana / 4).clamp(0.0, 1.0),
        textoProgresso:
            treinosNaSemana >= 4 ? 'Concluído!' : '$treinosNaSemana/4 dias',
      ),
      ConquistaGamificada(
        id: 'habito_de_aco',
        titulo: 'Hábito de Aço',
        descricao: 'Completar 14 dias seguidos na ofensiva.',
        icone: Icons.local_fire_department_rounded,
        desbloqueada: diasSeguidos >= 14,
        progresso: (diasSeguidos / 14).clamp(0.0, 1.0),
        textoProgresso:
            diasSeguidos >= 14 ? 'Concluído!' : '$diasSeguidos/14 dias',
      ),
      ConquistaGamificada(
        id: 'clube_dos_30',
        titulo: 'Mês Invicto',
        descricao: 'Atingir a marca lendária de 30 dias na ofensiva.',
        icone: Icons.military_tech_rounded,
        desbloqueada: diasSeguidos >= 30,
        progresso: (diasSeguidos / 30).clamp(0.0, 1.0),
        textoProgresso:
            diasSeguidos >= 30 ? 'Concluído!' : '$diasSeguidos/30 dias',
      ),
      ConquistaGamificada(
        id: 'centuriao',
        titulo: 'Centurião',
        descricao: 'Completar 100 treinos registrados no total.',
        icone: Icons.emoji_events_rounded,
        desbloqueada: totalTreinos >= 100,
        progresso: (totalTreinos / 100).clamp(0.0, 1.0),
        textoProgresso:
            totalTreinos >= 100 ? 'Concluído!' : '$totalTreinos/100 treinos',
      ),
      ConquistaGamificada(
        id: 'meta_definida',
        titulo: 'Foco na Balança',
        descricao: 'Definir uma meta de peso corporal e acompanhar a evolução.',
        icone: Icons.flag_rounded,
        desbloqueada: metaPesoDefinida,
        progresso: metaPesoDefinida ? 1.0 : 0.0,
        textoProgresso: metaPesoDefinida ? 'Concluído!' : 'Meta não definida',
      ),
      ConquistaGamificada(
        id: 'primeiro_habito',
        titulo: 'Construindo Hábitos',
        descricao: 'Cadastrar e concluir o primeiro hábito saudável.',
        icone: Icons.stars_rounded,
        desbloqueada: totalHabitosConcluidos >= 1,
        progresso: totalHabitosConcluidos >= 1 ? 1.0 : 0.0,
        textoProgresso:
            totalHabitosConcluidos >= 1 ? 'Concluído!' : '0/1 hábito',
      ),
      ConquistaGamificada(
        id: 'mestre_da_rotina',
        titulo: 'Mestre da Rotina',
        descricao: 'Completar pelo menos 10 hábitos no aplicativo.',
        icone: Icons.check_circle_outline_rounded,
        desbloqueada: totalHabitosConcluidos >= 10,
        progresso: (totalHabitosConcluidos / 10).clamp(0.0, 1.0),
        textoProgresso: totalHabitosConcluidos >= 10
            ? 'Concluído!'
            : '$totalHabitosConcluidos/10 hábitos',
      ),
    ];
  }
}
