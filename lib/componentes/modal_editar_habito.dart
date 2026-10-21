import 'package:flutter/material.dart';
import '../modelos/habito.dart';

/// Modal para criar ou editar um hábito diário com meta intuitiva,
/// unidades selecionáveis, atalhos de frequência e catálogo rico de ícones.
class ModalEditarHabito extends StatefulWidget {
  const ModalEditarHabito({super.key, this.habito});

  final Habito? habito;

  static Future<Habito?> exibir(BuildContext context, {Habito? habito}) {
    return showModalBottomSheet<Habito>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ModalEditarHabito(habito: habito),
      ),
    );
  }

  @override
  State<ModalEditarHabito> createState() => _EstadoDoModalEditarHabito();
}

class _EstadoDoModalEditarHabito extends State<ModalEditarHabito> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _metaValorController = TextEditingController();
  final _metaUnidadePersonalizadaController = TextEditingController();

  static const List<String> _unidadesPadrao = <String>[
    'vezes',
    'copos',
    'ml',
    'litros',
    'minutos',
    'horas',
    'km',
    'páginas',
    'doses',
    'porções',
  ];

  late String _categoriaSelecionada;
  late int _corValor;
  late int _iconeCodePoint;
  late Set<int> _diasSelecionados;
  late int _metaValor;
  late String _metaUnidade;
  bool _unidadePersonalizada = false;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final h = widget.habito;
    if (h != null) {
      _tituloController.text = h.titulo;
      _descricaoController.text = h.descricao;
      _categoriaSelecionada = h.categoria;
      _corValor = h.corValor;
      _iconeCodePoint = h.iconeCodePoint;
      _diasSelecionados = h.diasSemana.toSet();
      _metaValor = h.metaValor > 0 ? h.metaValor : 1;
      _metaValorController.text = _metaValor.toString();
      _metaUnidade =
          h.metaUnidade.trim().isEmpty ? 'vezes' : h.metaUnidade.trim();
      _ativo = h.ativo;

      if (_unidadesPadrao.contains(_metaUnidade.toLowerCase())) {
        _unidadePersonalizada = false;
      } else {
        _unidadePersonalizada = true;
        _metaUnidadePersonalizadaController.text = _metaUnidade;
      }
    } else {
      _categoriaSelecionada = PaletaCoresHabito.categoriasPadrao.first;
      _corValor = PaletaCoresHabito.cores.first.toARGB32();
      _iconeCodePoint = CatalogoIconesHabito.iconesDisponiveis.first.codePoint;
      _diasSelecionados = <int>{1, 2, 3, 4, 5, 6, 7};
      _metaValor = 1;
      _metaValorController.text = '1';
      _metaUnidade = 'vezes';
      _unidadePersonalizada = false;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _metaValorController.dispose();
    _metaUnidadePersonalizadaController.dispose();
    super.dispose();
  }

  List<int> _obterSugestoesDeMeta(String unidade) {
    switch (unidade.toLowerCase()) {
      case 'copos':
        return const [4, 6, 8, 10, 12];
      case 'ml':
        return const [500, 1000, 1500, 2000, 2500, 3000];
      case 'litros':
        return const [1, 2, 3, 4, 5];
      case 'minutos':
        return const [10, 15, 20, 30, 45, 60];
      case 'horas':
        return const [1, 2, 4, 6, 8];
      case 'km':
        return const [1, 2, 3, 5, 10];
      case 'páginas':
      case 'paginas':
        return const [5, 10, 15, 20, 30];
      case 'doses':
        return const [1, 2, 3, 4];
      case 'porções':
      case 'porcoes':
        return const [1, 2, 3, 5];
      case 'vez':
      case 'vezes':
      default:
        return const [1, 2, 3, 4, 5];
    }
  }

  int _obterPassoDeIncremento(String unidade) {
    final u = unidade.toLowerCase();
    if (u == 'ml') return 250;
    if (u == 'minutos') return 5;
    return 1;
  }

  void _alterarMeta(int delta) {
    setState(() {
      final novo = (_metaValor + delta).clamp(1, 100000);
      _metaValor = novo;
      _metaValorController.text = novo.toString();
    });
  }

  void _definirMeta(int valor) {
    setState(() {
      _metaValor = valor.clamp(1, 100000);
      _metaValorController.text = _metaValor.toString();
    });
  }

  void _selecionarUnidade(String unidade) {
    setState(() {
      _metaUnidade = unidade;
      _unidadePersonalizada = false;
      // Adapta meta diária inicial para o tipo de unidade
      final u = unidade.toLowerCase();
      if (u == 'ml' && _metaValor < 500) {
        _metaValor = 2000;
      } else if (u == 'copos' && (_metaValor < 2 || _metaValor > 20)) {
        _metaValor = 8;
      } else if (u == 'minutos' && _metaValor < 10) {
        _metaValor = 30;
      } else if (u == 'litros' && _metaValor > 10) {
        _metaValor = 2;
      } else if (u == 'vezes' && _metaValor > 20) {
        _metaValor = 1;
      }
      _metaValorController.text = _metaValor.toString();
    });
  }

  void _salvar() {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o hábito.')),
      );
      return;
    }
    if (_diasSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia da semana.')),
      );
      return;
    }

    final parsedValor =
        int.tryParse(_metaValorController.text.trim()) ?? _metaValor;
    final metaFinal = parsedValor > 0 ? parsedValor : 1;

    String unidadeFinal;
    if (_unidadePersonalizada) {
      final personalizada = _metaUnidadePersonalizadaController.text.trim();
      unidadeFinal = personalizada.isEmpty ? 'vezes' : personalizada;
    } else {
      unidadeFinal = _metaUnidade;
    }

    final novoOuAtualizado = (widget.habito ??
            Habito(
              titulo: titulo,
              dataCriacaoISO: DateTime.now().toIso8601String(),
            ))
        .copiarCom(
      titulo: titulo,
      descricao: _descricaoController.text.trim(),
      categoria: _categoriaSelecionada,
      corValor: _corValor,
      iconeCodePoint: _iconeCodePoint,
      diasSemana: _diasSelecionados.toList()..sort(),
      metaValor: metaFinal,
      metaUnidade: unidadeFinal,
      ativo: _ativo,
    );

    Navigator.of(context).pop(novoOuAtualizado);
  }

  bool get _isTodosOsDias => _diasSelecionados.length == 7;
  bool get _isDiasUteis =>
      _diasSelecionados.length == 5 &&
      _diasSelecionados.containsAll(const [1, 2, 3, 4, 5]);
  bool get _isFimDeSemana =>
      _diasSelecionados.length == 2 &&
      _diasSelecionados.containsAll(const [6, 7]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corAtual = Color(_corValor);
    final sugestoes = _obterSugestoesDeMeta(
      _unidadePersonalizada
          ? _metaUnidadePersonalizadaController.text
          : _metaUnidade,
    );
    final passo = _obterPassoDeIncremento(
      _unidadePersonalizada
          ? _metaUnidadePersonalizadaController.text
          : _metaUnidade,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior com ícone ativo e título
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: corAtual.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: corAtual.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Icon(
                  CatalogoIconesHabito.obterIcone(_iconeCodePoint),
                  color: corAtual,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.habito == null ? 'Novo Hábito' : 'Editar Hábito',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Título do Hábito
          TextField(
            controller: _tituloController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nome do hábito *',
              hintText: 'Ex: Beber 2L de água, Alongamento, Leitura...',
              prefixIcon: Icon(Icons.edit_outlined, color: corAtual),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),

          // Descrição ou Motivação
          TextField(
            controller: _descricaoController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Motivação ou detalhes (opcional)',
              hintText: 'Ex: Logo após acordar para ter mais foco no dia',
              prefixIcon: const Icon(Icons.lightbulb_outline_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 18),

          // Categoria
          Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: corAtual),
              const SizedBox(width: 8),
              Text(
                'Categoria',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PaletaCoresHabito.categoriasPadrao.map((cat) {
                final isSelected = _categoriaSelecionada == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: corAtual.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? corAtual
                          : theme.colorScheme.outlineVariant,
                    ),
                    onSelected: (_) =>
                        setState(() => _categoriaSelecionada = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Ícones disponíveis (2 linhas com rolagem fluida)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, size: 18, color: corAtual),
                  const SizedBox(width: 8),
                  Text(
                    'Ícone representativo',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${CatalogoIconesHabito.iconesDisponiveis.length} ícones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: CatalogoIconesHabito.iconesDisponiveis.length,
              itemBuilder: (context, idx) {
                final icon = CatalogoIconesHabito.iconesDisponiveis[idx];
                final isSelected = _iconeCodePoint == icon.codePoint;
                return InkWell(
                  onTap: () => setState(() => _iconeCodePoint = icon.codePoint),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? corAtual.withValues(alpha: 0.22)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? corAtual : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? corAtual
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Cor do marcador
          Row(
            children: [
              Icon(Icons.color_lens_outlined, size: 18, color: corAtual),
              const SizedBox(width: 8),
              Text(
                'Cor do hábito',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PaletaCoresHabito.cores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final cor = PaletaCoresHabito.cores[idx];
                final isSelected = _corValor == cor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _corValor = cor.toARGB32()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cor.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Frequência semanal com atalhos inteligentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_repeat_rounded, size: 18, color: corAtual),
                  const SizedBox(width: 8),
                  Text(
                    'Frequência semanal',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                _isTodosOsDias
                    ? 'Todos os dias'
                    : _isDiasUteis
                        ? 'Dias úteis (5d)'
                        : _isFimDeSemana
                            ? 'Fins de semana (2d)'
                            : '${_diasSelecionados.length} dias na semana',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: corAtual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Atalhos rápidos: Todos os dias, Dias úteis, Fins de semana
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: Icon(
                    Icons.all_inclusive_rounded,
                    size: 16,
                    color: _isTodosOsDias ? corAtual : null,
                  ),
                  label: const Text('Todos os dias'),
                  backgroundColor:
                      _isTodosOsDias ? corAtual.withValues(alpha: 0.16) : null,
                  side: BorderSide(
                    color: _isTodosOsDias
                        ? corAtual
                        : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: () {
                    setState(() => _diasSelecionados = {1, 2, 3, 4, 5, 6, 7});
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    Icons.work_outline_rounded,
                    size: 16,
                    color: _isDiasUteis ? corAtual : null,
                  ),
                  label: const Text('Dias úteis'),
                  backgroundColor:
                      _isDiasUteis ? corAtual.withValues(alpha: 0.16) : null,
                  side: BorderSide(
                    color: _isDiasUteis
                        ? corAtual
                        : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: () {
                    setState(() => _diasSelecionados = {1, 2, 3, 4, 5});
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    Icons.weekend_outlined,
                    size: 16,
                    color: _isFimDeSemana ? corAtual : null,
                  ),
                  label: const Text('Fim de semana'),
                  backgroundColor:
                      _isFimDeSemana ? corAtual.withValues(alpha: 0.16) : null,
                  side: BorderSide(
                    color: _isFimDeSemana
                        ? corAtual
                        : theme.colorScheme.outlineVariant,
                  ),
                  onPressed: () {
                    setState(() => _diasSelecionados = {6, 7});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Círculos dos 7 dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDiaChip(1, 'Seg'),
              _buildDiaChip(2, 'Ter'),
              _buildDiaChip(3, 'Qua'),
              _buildDiaChip(4, 'Qui'),
              _buildDiaChip(5, 'Sex'),
              _buildDiaChip(6, 'Sáb'),
              _buildDiaChip(7, 'Dom'),
            ],
          ),
          const SizedBox(height: 22),

          // Unidade de medida selecionável
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: corAtual),
              const SizedBox(width: 8),
              Text(
                'Unidade de registro',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._unidadesPadrao.map((unidade) {
                  final isSelected = !_unidadePersonalizada &&
                      _metaUnidade.toLowerCase() == unidade.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(unidade),
                      selected: isSelected,
                      selectedColor: corAtual.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected
                            ? corAtual
                            : theme.colorScheme.outlineVariant,
                      ),
                      onSelected: (_) => _selecionarUnidade(unidade),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Outra...'),
                    selected: _unidadePersonalizada,
                    selectedColor: corAtual.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: _unidadePersonalizada
                          ? corAtual
                          : theme.colorScheme.outlineVariant,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _unidadePersonalizada = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_unidadePersonalizada) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _metaUnidadePersonalizadaController,
              decoration: InputDecoration(
                labelText: 'Nome da sua unidade',
                hintText: 'Ex: páginas, capítulos, flexões, cápsulas...',
                prefixIcon:
                    Icon(Icons.bookmark_border_rounded, color: corAtual),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 20),

          // Meta Diária Intuitiva com Stepper e Atalhos Numéricos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes_rounded, size: 18, color: corAtual),
                  const SizedBox(width: 8),
                  Text(
                    'Meta diária',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '$_metaValor ${_unidadePersonalizada ? (_metaUnidadePersonalizadaController.text.trim().isEmpty ? 'vezes' : _metaUnidadePersonalizadaController.text.trim()) : _metaUnidade}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: corAtual,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Card de controle de meta com Stepper [-] [ Valor ] [+]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Diminuir meta',
                      icon: const Icon(Icons.remove_rounded),
                      onPressed:
                          _metaValor > 1 ? () => _alterarMeta(-passo) : null,
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _exibirDialogoEdicaoManual(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_metaValor',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: corAtual,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _unidadePersonalizada
                                  ? (_metaUnidadePersonalizadaController.text
                                          .trim()
                                          .isEmpty
                                      ? 'vezes'
                                      : _metaUnidadePersonalizadaController.text
                                          .trim())
                                  : _metaUnidade,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton.filledTonal(
                      tooltip: 'Aumentar meta',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _alterarMeta(passo),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Sugestões rápidas de valores
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: sugestoes.map((sugestao) {
                    final isAtivo = _metaValor == sugestao;
                    final rotulo =
                        '$sugestao ${_unidadePersonalizada ? '' : _metaUnidade}';
                    return ActionChip(
                      label: Text(rotulo.trim()),
                      backgroundColor:
                          isAtivo ? corAtual.withValues(alpha: 0.2) : null,
                      side: BorderSide(
                        color: isAtivo
                            ? corAtual
                            : theme.colorScheme.outlineVariant,
                      ),
                      onPressed: () => _definirMeta(sugestao),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Switch de Hábito Ativo
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile.adaptive(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Hábito ativo'),
              subtitle:
                  const Text('Aparece na sua rotina diária e gera ofensiva'),
              value: _ativo,
              activeTrackColor: corAtual,
              onChanged: (val) => setState(() => _ativo = val),
            ),
          ),
          const SizedBox(height: 24),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: corAtual,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _salvar,
              icon: const Icon(Icons.check_rounded, size: 22),
              label: Text(
                widget.habito == null ? 'Criar Hábito' : 'Salvar Alterações',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exibirDialogoEdicaoManual(BuildContext context) async {
    final sufixo = _unidadePersonalizada
        ? _metaUnidadePersonalizadaController.text
        : _metaUnidade;
    final valor = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoMetaDiariaManual(
        valorInicial: _metaValor,
        sufixoUnidade: sufixo,
      ),
    );
    if (valor != null && valor > 0 && mounted) {
      _definirMeta(valor);
    }
  }

  Widget _buildDiaChip(int dia, String rotulo) {
    final isSelected = _diasSelecionados.contains(dia);
    final cor = Color(_corValor);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_diasSelecionados.length > 1) {
              _diasSelecionados.remove(dia);
            }
          } else {
            _diasSelecionados.add(dia);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? cor
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DialogoMetaDiariaManual extends StatefulWidget {
  const _DialogoMetaDiariaManual({
    required this.valorInicial,
    required this.sufixoUnidade,
  });

  final int valorInicial;
  final String sufixoUnidade;

  @override
  State<_DialogoMetaDiariaManual> createState() =>
      _EstadoDoDialogoMetaDiariaManual();
}

class _EstadoDoDialogoMetaDiariaManual extends State<_DialogoMetaDiariaManual> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.valorInicial}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final valor = int.tryParse(_controller.text.trim());
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(valor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Definir Meta Diária'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        onSubmitted: (_) => _confirmar(),
        decoration: InputDecoration(
          labelText: 'Quantidade',
          suffixText: widget.sufixoUnidade,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
