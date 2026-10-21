import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';

class TelaDeBoasVindasGamificada extends StatefulWidget {
  const TelaDeBoasVindasGamificada({super.key});

  @override
  State<TelaDeBoasVindasGamificada> createState() =>
      _EstadoDaTelaDeBoasVindasGamificada();
}

class _EstadoDaTelaDeBoasVindasGamificada
    extends State<TelaDeBoasVindasGamificada> {
  final PageController _pageController = PageController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoAtualController = TextEditingController();
  final TextEditingController _metaPesoController = TextEditingController();

  int _etapaAtual = 0;
  String _objetivoSelecionado = 'Hipertrofia';
  String _experienciaSelecionada = 'Iniciante';
  bool _salvando = false;

  final List<Map<String, dynamic>> _objetivos = const [
    {
      'id': 'Hipertrofia',
      'titulo': 'Hipertrofia & Massa',
      'descricao': 'Construir músculos, ganhar volume e força',
      'icone': Icons.fitness_center_rounded,
      'cor': Color(0xFF6C5CE7),
    },
    {
      'id': 'Emagrecimento',
      'titulo': 'Perda de Gordura',
      'descricao': 'Definição muscular, perda de gordura e resistência',
      'icone': Icons.local_fire_department_rounded,
      'cor': Color(0xFFFF6D00),
    },
    {
      'id': 'Força',
      'titulo': 'Força Pura',
      'descricao': 'Aumentar carga nos exercícios básicos e potência',
      'icone': Icons.bolt_rounded,
      'cor': Color(0xFFFFB300),
    },
    {
      'id': 'Saúde',
      'titulo': 'Saúde & Longevidade',
      'descricao': 'Qualidade de vida, postura e hábitos saudáveis',
      'icone': Icons.favorite_rounded,
      'cor': Color(0xFF00BFA5),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoAtualController.dispose();
    _metaPesoController.dispose();
    super.dispose();
  }

  void _avancar() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_etapaAtual == 1) {
      if (_nomeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, digite seu nome ou apelido.')),
        );
        return;
      }
    }
    if (_etapaAtual < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  void _voltar() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_etapaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _concluirOnboarding() async {
    setState(() => _salvando = true);
    try {
      final nome = _nomeController.text.trim().isEmpty
          ? 'Atleta'
          : _nomeController.text.trim();
      final idade = int.tryParse(_idadeController.text.trim());
      final pesoAtual = double.tryParse(
        _pesoAtualController.text.trim().replaceAll(',', '.'),
      );
      final metaPeso = double.tryParse(
        _metaPesoController.text.trim().replaceAll(',', '.'),
      );

      final novoPerfil = PerfilDoUsuario(
        nome: nome,
        idade: idade,
        metaPesoKg: metaPeso,
        objetivoPrincipal: _objetivoSelecionado,
        nivelExperiencia: _experienciaSelecionada,
        lembretesAtivos: true,
        onboardingConcluido: true,
      );

      final provedor = context.read<ProvedorDeTreino>();
      await provedor.salvarPerfil(novoPerfil, currentWeightKg: pesoAtual);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Progresso do Onboarding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (_etapaAtual > 0 && _etapaAtual < 4)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _voltar,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (_etapaAtual + 1) / 5,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Páginas do Onboarding
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _etapaAtual = page),
                children: [
                  _construirPaginaBoasVindas(),
                  _construirPaginaIdentidade(),
                  _construirPaginaPesoEMeta(),
                  _construirPaginaTutorial(),
                  _construirPaginaDesbloqueio(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ETAPA 1: Boas-vindas
  Widget _construirPaginaBoasVindas() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Offline Gym & Hábitos',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Seu centro de treinos e hábitos diários, 100% offline, gratuito e sem assinaturas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _itemDestaque(
            Icons.offline_bolt_rounded,
            'Totalmente Offline',
            'Seus treinos, notas e dados nunca saem do seu aparelho.',
            const Color(0xFF00BFA5),
          ),
          const SizedBox(height: 14),
          _itemDestaque(
            Icons.local_fire_department_rounded,
            'Ofensiva & Gamificação',
            'Desbloqueie classes, dicas diárias e conquistas a cada treino.',
            const Color(0xFFFF6D00),
          ),
          const SizedBox(height: 14),
          _itemDestaque(
            Icons.check_circle_rounded,
            'Hábitos & Metas',
            'Crie hábitos personalizados e acompanhe sua evolução.',
            theme.colorScheme.primary,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _avancar,
              child: const Text(
                'Começar Minha Jornada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _itemDestaque(
    IconData icone,
    String titulo,
    String subtitulo,
    Color cor,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: cor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ETAPA 2: Nome e Foco
  Widget _construirPaginaIdentidade() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual é o seu nome e foco?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Personalizaremos suas motivações e histórico.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Seu nome ou apelido *',
              hintText: 'Ex: Thierry, Lucas, Mari...',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _idadeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Idade (opcional)',
              suffixText: 'anos',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Seu objetivo principal:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._objetivos.map((obj) {
            final isSelected = _objetivoSelecionado == obj['id'];
            final cor = obj['id'] == 'Hipertrofia'
                ? theme.colorScheme.primary
                : (obj['cor'] as Color);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(
                  () => _objetivoSelecionado = obj['id'] as String,
                ),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cor.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? cor
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(obj['icone'] as IconData,
                            color: cor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              obj['titulo'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? cor
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              obj['descricao'] as String,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: cor),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _avancar,
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ETAPA 3: Ponto de Partida e Meta de Peso
  Widget _construirPaginaPesoEMeta() {
    final theme = Theme.of(context);
    final pesoAtual = double.tryParse(
      _pesoAtualController.text.trim().replaceAll(',', '.'),
    );
    final metaPeso = double.tryParse(
      _metaPesoController.text.trim().replaceAll(',', '.'),
    );

    String? resumoCalculo;
    if (pesoAtual != null && metaPeso != null) {
      final diff = metaPeso - pesoAtual;
      if (diff > 0) {
        resumoCalculo =
            'Meta: Ganhar +${diff.toStringAsFixed(1)} kg de massa muscular!';
      } else if (diff < 0) {
        resumoCalculo =
            'Meta: Queimar ${diff.abs().toStringAsFixed(1)} kg de gordura!';
      } else {
        resumoCalculo = 'Meta: Manter seu peso atual com máxima definição!';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu Ponto de Partida & Meta',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Esses valores guiarão seus gráficos de evolução no histórico.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pesoAtualController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Peso atual',
                    suffixText: 'kg',
                    hintText: 'Ex: 75.5',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _metaPesoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Meta de peso',
                    suffixText: 'kg',
                    hintText: 'Ex: 80.0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (resumoCalculo != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      resumoCalculo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Nível de experiência em treinos:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _nivelChip('Iniciante', 'Começando agora'),
              const SizedBox(width: 8),
              _nivelChip('Intermediário', 'Treino há 1 ano+'),
              const SizedBox(width: 8),
              _nivelChip('Avançado', 'Treino há 3 anos+'),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _avancar,
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _nivelChip(String valor, String sub) {
    final isSelected = _experienciaSelecionada == valor;
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _experienciaSelecionada = valor),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ETAPA 4: Mini-Tutorial
  Widget _construirPaginaTutorial() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '3 Abas. Tudo o que você precisa.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Um design limpo, rápido e focado nos seus resultados diários.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _cardTutorial(
                    Icons.fitness_center_rounded,
                    'Aba Hoje',
                    'Veja seus exercícios do dia e marque seus hábitos com um toque. Acompanhe a ofensiva no topo.',
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  _cardTutorial(
                    Icons.calendar_month_rounded,
                    'Aba Semana',
                    'Monte suas rotinas divididas de segunda a domingo. Adicione hábitos e gerencie sua lista To-Do.',
                    theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 14),
                  _cardTutorial(
                    Icons.insights_rounded,
                    'Aba Histórico',
                    'Gráficos de carga máxima por exercício, evolução de peso corporal e fotos mensais.',
                    const Color(0xFFE67E22),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _avancar,
                      child: const Text(
                        'Entendi, Vamos Lá!',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardTutorial(
    IconData icone,
    String titulo,
    String desc,
    Color cor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ETAPA 5: Desbloqueio e Celebração
  Widget _construirPaginaDesbloqueio() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFB300),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Jornada Desbloqueada! 🚀',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seu perfil e metas foram salvos no dispositivo. Você já tem acesso total a todos os recursos.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300)),
                        const SizedBox(width: 8),
                        Text(
                          '+50 XP de Boas-Vindas!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _concluirOnboarding,
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar no App',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
