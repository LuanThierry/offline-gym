import 'package:flutter/material.dart';

import '../dominio/catalogo_exercicios_offline.dart';

/// Modal interativo 100% offline para buscar e selecionar entre +1.100 exercícios
/// de Academia, Calistenia, Em Casa, CrossFit, Corrida e Mobilidade, ou escolher
/// um Modelo Pronto de treino completo.
class ModalCatalogoExercicios extends StatefulWidget {
  const ModalCatalogoExercicios({
    super.key,
    required this.multiplaEscolha,
  });

  final bool multiplaEscolha;

  /// Abre o catálogo para selecionar **um único** exercício (ex.: preencher um card).
  static Future<ItemCatalogoExercicio?> selecionarUnico(BuildContext context) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<ItemCatalogoExercicio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModalCatalogoExercicios(multiplaEscolha: false),
    );
  }

  /// Abre o catálogo para selecionar **um ou vários** exercícios de uma só vez.
  static Future<List<ItemCatalogoExercicio>?> selecionarMultiplos(
    BuildContext context,
  ) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<List<ItemCatalogoExercicio>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModalCatalogoExercicios(multiplaEscolha: true),
    );
  }

  /// Abre o seletor de **Modelos Prontos de Treino Completo** (100% offline).
  static Future<ModeloDeTreinoPronto?> selecionarModeloPronto(
    BuildContext context,
  ) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<ModeloDeTreinoPronto>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ModalModelosProntosDeTreino(),
    );
  }

  @override
  State<ModalCatalogoExercicios> createState() =>
      _EstadoDoModalCatalogoExercicios();
}

class _EstadoDoModalCatalogoExercicios extends State<ModalCatalogoExercicios> {
  final TextEditingController _buscaController = TextEditingController();
  String _modalidadeSelecionada = 'Todas';
  String _grupoSelecionado = 'Todos';
  final Set<String> _nomesSelecionados = <String>{};
  final List<ItemCatalogoExercicio> _itensSelecionados =
      <ItemCatalogoExercicio>[];

  late List<ItemCatalogoExercicio> _resultados;

  @override
  void initState() {
    super.initState();
    _resultados = CatalogoDeExerciciosOffline.todosOsExercicios;
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  int _idRequisicaoFiltro = 0;

  void _atualizarFiltro() async {
    final versao = ++_idRequisicaoFiltro;
    final termo = _buscaController.text;
    final modalidade = _modalidadeSelecionada;
    final grupo = _grupoSelecionado;

    final resultados = await CatalogoDeExerciciosOffline.filtrarAsync(
      busca: termo,
      modalidade: modalidade,
      grupoMuscular: grupo,
    );

    if (mounted && versao == _idRequisicaoFiltro) {
      setState(() {
        _resultados = resultados;
      });
    }
  }

  void _alternarSelecao(ItemCatalogoExercicio item) {
    if (!widget.multiplaEscolha) {
      Navigator.of(context).pop(item);
      return;
    }
    setState(() {
      if (_nomesSelecionados.contains(item.nome)) {
        _nomesSelecionados.remove(item.nome);
        _itensSelecionados.removeWhere((e) => e.nome == item.nome);
      } else {
        _nomesSelecionados.add(item.nome);
        _itensSelecionados.add(item);
      }
    });
  }

  IconData _iconeDaModalidade(String modalidade) {
    switch (modalidade) {
      case 'Academia':
        return Icons.fitness_center_rounded;
      case 'Calistenia':
        return Icons.sports_gymnastics_rounded;
      case 'Em Casa':
        return Icons.home_rounded;
      case 'CrossFit & Funcional':
        return Icons.bolt_rounded;
      case 'Corrida & Cardio':
        return Icons.directions_run_rounded;
      case 'Mobilidade & Core':
        return Icons.spa_rounded;
      case 'Artes Marciais & Boxe':
        return Icons.sports_kabaddi_rounded;
      case 'Pilates & Postura':
        return Icons.self_improvement_rounded;
      case 'Elásticos & Kettlebell':
        return Icons.sports_handball_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final temaEscuro = theme.brightness == Brightness.dark;
    final totalCatalogo = CatalogoDeExerciciosOffline.todosOsExercicios.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: temaEscuro
                  ? const Color(0xFF444451)
                  : const Color(0xFFDFE2E7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Biblioteca Offline ($totalCatalogo exercícios)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Academia • Calistenia • Casa • CrossFit • Corrida',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Campo de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _buscaController,
              onChanged: (_) => _atualizarFiltro(),
              decoration: InputDecoration(
                hintText:
                    'Buscar exercício (ex: Supino, Barra fixa, Kettlebell, Corrida...)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _buscaController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _buscaController.clear();
                          _atualizarFiltro();
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filtro de Modalidade
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: CatalogoDeExerciciosOffline.modalidades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final mod = CatalogoDeExerciciosOffline.modalidades[index];
                final selecionado = mod == _modalidadeSelecionada;
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  selected: selecionado,
                  avatar: Icon(
                    _iconeDaModalidade(mod),
                    size: 15,
                    color: selecionado ? cs.primary : cs.onSurfaceVariant,
                  ),
                  label: Text(
                    mod,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selecionado ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  onSelected: (_) {
                    _modalidadeSelecionada = mod;
                    _atualizarFiltro();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Filtro de Grupo Muscular
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: CatalogoDeExerciciosOffline.gruposMusculares.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final grupo =
                    CatalogoDeExerciciosOffline.gruposMusculares[index];
                final selecionado = grupo == _grupoSelecionado;
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  selected: selecionado,
                  label: Text(
                    grupo,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          selecionado ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  onSelected: (_) {
                    _grupoSelecionado = grupo;
                    _atualizarFiltro();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: <Widget>[
                Text(
                  '${_resultados.length} encontrados',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.multiplaEscolha)
                  Text(
                    'Toque nos exercícios para marcar vários',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: _resultados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.search_off_rounded,
                            size: 46,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Nenhum exercício encontrado com esses filtros.',
                            style: theme.textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          if (_buscaController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                final nomePersonalizado =
                                    _buscaController.text.trim();
                                final novoItem = ItemCatalogoExercicio(
                                  nome: nomePersonalizado,
                                  modalidade: _modalidadeSelecionada == 'Todas'
                                      ? 'Personalizado'
                                      : _modalidadeSelecionada,
                                  grupoMuscular: _grupoSelecionado == 'Todos'
                                      ? CatalogoDeExerciciosOffline
                                          .identificarGrupoMuscular(
                                              nomePersonalizado)
                                      : _grupoSelecionado,
                                  equipamento: 'Livre',
                                  cargaSugeridaKg: 0,
                                  seriesSugeridas: 3,
                                  repeticoesSugeridas: 10,
                                );
                                Navigator.of(context).pop(novoItem);
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  size: 18),
                              label: Text(
                                  'Usar "${_buscaController.text.trim()}"'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              _buscaController.clear();
                              _modalidadeSelecionada = 'Todas';
                              _grupoSelecionado = 'Todos';
                              _atualizarFiltro();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Limpar filtros'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    itemCount: _resultados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _resultados[index];
                      final marcado = _nomesSelecionados.contains(item.nome);
                      final cargaTxt = item.cargaSugeridaKg <= 0
                          ? 'Livre'
                          : '${item.cargaSugeridaKg.toStringAsFixed(0)} kg';

                      return Material(
                        color: marcado
                            ? cs.primary.withValues(alpha: 0.14)
                            : cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: marcado
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.5),
                            width: marcado ? 1.5 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _alternarSelecao(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    CatalogoDeExerciciosOffline.iconeDoItem(
                                        item),
                                    size: 19,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.nome,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.modalidade} • ${item.grupoMuscular} • ${item.equipamento} (${item.seriesSugeridas}x${item.repeticoesSugeridas} · $cargaTxt)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.multiplaEscolha)
                                  Icon(
                                    marcado
                                        ? Icons.check_circle_rounded
                                        : Icons.add_circle_outline_rounded,
                                    color: marcado
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: cs.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.multiplaEscolha)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _itensSelecionados.isEmpty
                          ? null
                          : () => Navigator.of(
                                context,
                              ).pop(_itensSelecionados),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _itensSelecionados.isEmpty
                            ? 'Selecione exercícios'
                            : 'Adicionar (${_itensSelecionados.length})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModalModelosProntosDeTreino extends StatelessWidget {
  const _ModalModelosProntosDeTreino();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final temaEscuro = theme.brightness == Brightness.dark;
    final modelos = CatalogoDeExerciciosOffline.modelosProntos;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: temaEscuro
                  ? const Color(0xFF444451)
                  : const Color(0xFFDFE2E7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Modelos Prontos de Treino',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Importe uma ficha completa 100% offline com 1 toque',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: modelos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final modelo = modelos[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(modelo),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(modelo.icone, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      modelo.nome,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      modelo.subtitulo,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.download_done_rounded,
                                color: cs.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: modelo.exercicios.map((ex) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${ex.nome} (${ex.seriesSugeridas}x${ex.repeticoesSugeridas})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
