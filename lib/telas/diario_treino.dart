import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../modelos/habito.dart';
import '../provedores/estado_treino.dart';

class TelaDeDiario extends StatefulWidget {
  const TelaDeDiario({super.key, required this.data});

  final DateTime data;

  @override
  State<TelaDeDiario> createState() => _EstadoDaTelaDeDiario();
}

class _EstadoDaTelaDeDiario extends State<TelaDeDiario> {
  final _ControladorDeTextoDoDiario _textController =
      _ControladorDeTextoDoDiario();
  final List<String> _imagePaths = <String>[];
  final List<FigurinhaDiario> _figurinhas = <FigurinhaDiario>[];
  bool _loading = true;
  bool _saving = false;
  bool _previewMode = true;

  @override
  void initState() {
    super.initState();
    _carregarRegistro();
  }

  Future<void> _carregarRegistro() async {
    final provedor = context.read<ProvedorDeTreino>();
    final entry = await provedor.obterDiarioNaData(widget.data);
    if (entry != null) {
      _textController.carregarConteudoSalvo(
        (entry['conteudo'] as String?) ?? '',
      );
      final rawImages = entry['caminhosImagens'];
      if (rawImages is String && rawImages.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawImages);
          if (decoded is List) {
            _imagePaths.addAll(decoded.map((e) => e.toString()));
          }
        } catch (_) {}
      }
      _figurinhas.clear();
      final rawFigurinhas = entry['figurinhas'];
      if (rawFigurinhas is String && rawFigurinhas.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawFigurinhas);
          if (decoded is List) {
            _figurinhas.addAll(
              decoded.whereType<Map<Object?, Object?>>().map(
                  (e) => FigurinhaDiario.deMapa(Map<String, Object?>.from(e))),
            );
          }
        } catch (_) {}
      }
      if (_figurinhas.isEmpty &&
          _textController.figurinhasCarregadas.isNotEmpty) {
        _figurinhas.addAll(_textController.figurinhasCarregadas);
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _escolherImagem(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final diaryDir = Directory(p.join(appDir.path, 'diary_images'));
      await diaryDir.create(recursive: true);

      final ext =
          p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
      final newFileName =
          'diary_${widget.data.year}${widget.data.month.toString().padLeft(2, '0')}${widget.data.day.toString().padLeft(2, '0')}_${DateTime.now().microsecondsSinceEpoch}$ext';
      final localTarget = File(p.join(diaryDir.path, newFileName));
      final savedFile = await File(picked.path).copy(localTarget.path);

      if (mounted) {
        setState(() {
          _imagePaths.add(savedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível adicionar a imagem: $e')),
        );
      }
    }
  }

  void _aplicarNegrito() {
    _textController.alternarNegritoNaSelecao();
    setState(() {});
  }

  void _aplicarTitulo() {
    _textController.alternarTituloNaSelecao();
    setState(() {});
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      final provedor = context.read<ProvedorDeTreino>();
      await provedor.salvarDiario(
        data: widget.data,
        conteudo: _textController.serializar(figurinhas: _figurinhas),
        caminhosImagens: _imagePaths,
        figurinhas: _figurinhas,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diário salvo com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _abrirSeletorDeFigurinhas() {
    final theme = Theme.of(context);
    final emojisPopulares = <String>[
      '🔥',
      '💪',
      '⚡',
      '🏆',
      '🎯',
      '👑',
      '🥗',
      '💧',
      '🧠',
      '🚀',
      '🥇',
      '⭐',
      '💥',
      '🏋️',
      '⏱️',
      '💯',
      '✨',
      '🧘',
      '🍎',
      '❤️',
      '😎',
      '🎉',
      '🥊',
      '🏅',
      '🥑',
      '🍗',
      '🥤',
      '💤',
      '👟',
      '📈',
    ];
    var emojiPersonalizado = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_reaction_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Figurinha / Emoji Arrastável',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha um emoji e arraste para qualquer lugar da sua folha!',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: emojisPopulares.map((emoji) {
                return InkWell(
                  onTap: () {
                    _adicionarFigurinha(emoji);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (valor) => emojiPersonalizado = valor,
                    onSubmitted: (valor) {
                      final text = valor.trim();
                      if (text.isNotEmpty) {
                        _adicionarFigurinha(text);
                        Navigator.of(ctx).pop();
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ou digite qualquer outro emoji...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final text = emojiPersonalizado.trim();
                    if (text.isNotEmpty) {
                      _adicionarFigurinha(text);
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarFigurinha(String emoji) {
    setState(() {
      _figurinhas.add(
        FigurinhaDiario(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          emoji: emoji,
          x: 0.5,
          y: 0.35,
          tamanho: 36.0,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Figurinha adicionada! Arraste-a pela tela.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(widget.data);

    return Scaffold(
      appBar: AppBar(
        title: Text('Diário · $dateFormatted'),
        actions: [
          IconButton.filledTonal(
            icon: Icon(
              _previewMode ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            tooltip: _previewMode ? 'Editar diário' : 'Visualizar diário',
            onPressed: () => setState(() => _previewMode = !_previewMode),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // BARRA DE FORMATAÇÃO (apenas Título e Bold) + Adicionar Imagem
                  if (!_previewMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Botão Título
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) =>
                                _textController.guardarSelecaoParaFormatacao(),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.10),
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: _aplicarTitulo,
                              icon: const Icon(Icons.title, size: 16),
                              label: const Text(
                                'Título',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botão Negrito
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) =>
                                _textController.guardarSelecaoParaFormatacao(),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.10),
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: _aplicarNegrito,
                              icon: const Icon(Icons.format_bold, size: 18),
                              label: const Text(
                                'Negrito',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botão Figurinha
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.10),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            onPressed: _abrirSeletorDeFigurinhas,
                            icon: const Icon(Icons.add_reaction_outlined,
                                size: 18),
                            label: const Text(
                              'Figurinha',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Botão Imagem
                          PopupMenuButton<ImageSource>(
                            tooltip: 'Adicionar foto',
                            icon: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            onSelected: _escolherImagem,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: ImageSource.gallery,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Galeria'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ImageSource.camera,
                                child: Row(
                                  children: [
                                    Icon(Icons.camera_alt_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Câmera'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // LISTA DE IMAGENS ANEXADAS
                  if (_imagePaths.isNotEmpty)
                    Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, indice) {
                          final imgPath = _imagePaths[indice];
                          final arquivo = File(imgPath);
                          final exists = arquivo.existsSync();

                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: exists
                                    ? Image.file(
                                        arquivo,
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        cacheWidth: 250,
                                        filterQuality: FilterQuality.medium,
                                      )
                                    : Container(
                                        width: 84,
                                        height: 84,
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                        child: const Icon(Icons.broken_image),
                                      ),
                              ),
                              if (!_previewMode)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _imagePaths.removeAt(indice),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                  // ÁREA DE TEXTO / VISUALIZADOR COM FIGURINHAS ARRASTÁVEIS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final viewInsets = MediaQuery.of(context).viewInsets;
                          // Altura de referência estável que não é reduzida quando o teclado virtual abre
                          final stableHeight = math.max(
                            constraints.maxHeight + viewInsets.bottom,
                            450.0,
                          );
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: _previewMode
                                    ? _construirPreviaFormatada(context)
                                    : TextField(
                                        controller: _textController,
                                        onChanged: _textController
                                            .sincronizarAlteracaoDeTexto,
                                        maxLines: null,
                                        expands: true,
                                        keyboardType: TextInputType.multiline,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Escreva suas anotações, sensações do treino, alimentação...',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          filled: false,
                                        ),
                                      ),
                              ),
                              for (var i = 0; i < _figurinhas.length; i++)
                                _construirFigurinha(i, width, stableHeight),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // BOTÃO DE SALVAR INFERIOR
                  if (!_previewMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _salvar,
                          icon: _saving
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Salvando...' : 'Salvar Diário',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _construirPreviaFormatada(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return Center(
        child: Text(
          'Nenhum texto escrito ainda.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView(
      children: <Widget>[
        Text.rich(
          _textController.buildTextSpan(
            context: context,
            style: Theme.of(context).textTheme.bodyLarge,
            withComposing: false,
          ),
        ),
      ],
    );
  }

  Widget _construirFigurinha(int idx, double width, double height) {
    final f = _figurinhas[idx];
    final effectiveWidth = math.max(width - f.tamanho, 1.0);
    final effectiveHeight = math.max(height - f.tamanho, 1.0);

    return _ItemFigurinhaArrastavel(
      key: ValueKey(f.id.isNotEmpty ? f.id : '$idx${f.emoji}'),
      figurinha: f,
      effectiveWidth: effectiveWidth,
      effectiveHeight: effectiveHeight,
      previewMode: _previewMode,
      aoMover: (atualizada) {
        _figurinhas[idx] = atualizada;
      },
      aoRemover: () {
        setState(() {
          _figurinhas.removeAt(idx);
        });
      },
    );
  }
}

class _ControladorDeTextoDoDiario extends TextEditingController {
  String _lastText = '';
  List<bool> _bold = <bool>[];
  List<bool> _title = <bool>[];
  bool _pendingBold = false;
  bool _pendingTitle = false;
  TextSelection? _savedFormattingSelection;

  void guardarSelecaoParaFormatacao() {
    if (selection.isValid) _savedFormattingSelection = selection;
  }

  void _restaurarSelecaoDeFormatacaoSalva() {
    final saved = _savedFormattingSelection;
    if (saved == null || !saved.isValid || saved.end > text.length) return;
    if (!selection.isValid || (selection.isCollapsed && !saved.isCollapsed)) {
      value = value.copyWith(selection: saved);
    }
  }

  List<FigurinhaDiario> figurinhasCarregadas = <FigurinhaDiario>[];

  void carregarConteudoSalvo(String storedContent) {
    try {
      final decoded = jsonDecode(storedContent);
      if (decoded is Map && decoded['type'] == 'offline_gym_diary_v1') {
        final text = decoded['text']?.toString() ?? '';
        final bold = List<bool>.filled(text.length, false);
        final title = List<bool>.filled(text.length, false);
        _aplicarIntervalosSalvos(bold, decoded['bold']);
        _aplicarIntervalosSalvos(title, decoded['title']);
        final rawStickers = decoded['figurinhas'];
        if (rawStickers is List) {
          figurinhasCarregadas = rawStickers
              .whereType<Map<Object?, Object?>>()
              .map((m) => FigurinhaDiario.deMapa(Map<String, Object?>.from(m)))
              .toList();
        }
        _definirDocumento(text, bold, title);
        return;
      }
    } catch (_) {}

    final parsed = _parseLegacyFormatting(storedContent);
    _definirDocumento(parsed.text, parsed.bold, parsed.title);
  }

  void _aplicarIntervalosSalvos(List<bool> flags, Object? rawRanges) {
    if (rawRanges is! List) return;
    for (final rawRange in rawRanges) {
      if (rawRange is! List || rawRange.length < 2) continue;
      final start = (rawRange[0] as num?)?.toInt();
      final end = (rawRange[1] as num?)?.toInt();
      if (start == null || end == null) continue;
      for (var indice = start.clamp(0, flags.length).toInt();
          indice < end.clamp(0, flags.length).toInt();
          indice++) {
        flags[indice] = true;
      }
    }
  }

  void _definirDocumento(String text, List<bool> bold, List<bool> title) {
    _lastText = text;
    _bold = bold.length == text.length
        ? bold
        : List<bool>.filled(text.length, false);
    _title = title.length == text.length
        ? title
        : List<bool>.filled(text.length, false);
    value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String serializar(
      {List<FigurinhaDiario> figurinhas = const <FigurinhaDiario>[]}) {
    return jsonEncode(<String, Object?>{
      'type': 'offline_gym_diary_v1',
      'text': text,
      'bold': _rangesFor(_bold),
      'title': _rangesFor(_title),
      'figurinhas': figurinhas.map((f) => f.paraMapa()).toList(),
    });
  }

  List<List<int>> _rangesFor(List<bool> flags) {
    final resultado = <List<int>>[];
    var start = -1;
    for (var indice = 0; indice < flags.length; indice++) {
      if (flags[indice] && start < 0) start = indice;
      if (!flags[indice] && start >= 0) {
        resultado.add(<int>[start, indice]);
        start = -1;
      }
    }
    if (start >= 0) resultado.add(<int>[start, flags.length]);
    return resultado;
  }

  void sincronizarAlteracaoDeTexto(String newText) {
    if (newText == _lastText) return;
    var prefix = 0;
    while (prefix < _lastText.length &&
        prefix < newText.length &&
        _lastText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < _lastText.length - prefix &&
        suffix < newText.length - prefix &&
        _lastText.codeUnitAt(_lastText.length - suffix - 1) ==
            newText.codeUnitAt(newText.length - suffix - 1)) {
      suffix++;
    }

    final insertedLength = newText.length - prefix - suffix;
    final inheritedIndex =
        prefix > 0 ? prefix - 1 : (prefix < _lastText.length ? prefix : -1);
    final inheritedBold =
        _pendingBold || (inheritedIndex >= 0 && _bold[inheritedIndex]);
    final inheritedTitle =
        _pendingTitle || (inheritedIndex >= 0 && _title[inheritedIndex]);
    final insertedText = newText.substring(prefix, prefix + insertedLength);

    final nextBold = <bool>[
      ..._bold.take(prefix),
      for (var indice = 0; indice < insertedLength; indice++) inheritedBold,
      ..._bold.skip(_lastText.length - suffix),
    ];
    final insertedTitle = <bool>[];
    var titleForInsertedText = inheritedTitle;
    for (var indice = 0; indice < insertedLength; indice++) {
      final isLineBreak = insertedText.codeUnitAt(indice) == 10;
      insertedTitle.add(isLineBreak ? false : titleForInsertedText);
      if (isLineBreak) titleForInsertedText = false;
    }
    final nextTitle = <bool>[
      ..._title.take(prefix),
      ...insertedTitle,
      ..._title.skip(_lastText.length - suffix),
    ];

    _lastText = newText;
    _bold = nextBold;
    _title = nextTitle;
    if (insertedText.contains('\n')) _pendingTitle = false;
    notifyListeners();
  }

  void alternarNegritoNaSelecao() {
    _restaurarSelecaoDeFormatacaoSalva();
    final range = _selectionOrWord();
    if (range == null) {
      _pendingBold = !_pendingBold;
      notifyListeners();
      return;
    }
    final enabled = !_bold.sublist(range.$1, range.$2).every((value) => value);
    for (var indice = range.$1; indice < range.$2; indice++) {
      _bold[indice] = enabled;
    }
    notifyListeners();
  }

  void alternarTituloNaSelecao() {
    _restaurarSelecaoDeFormatacaoSalva();
    final range = _selectedLineRange();
    if (range == null) {
      _pendingTitle = !_pendingTitle;
      notifyListeners();
      return;
    }
    final enabled = !_title.sublist(range.$1, range.$2).every((value) => value);
    for (var indice = range.$1; indice < range.$2; indice++) {
      _title[indice] = enabled;
    }
    notifyListeners();
  }

  (int, int)? _selectionOrWord() {
    final selected = selection;
    if (!selected.isValid) return null;
    if (!selected.isCollapsed) return (selected.start, selected.end);
    if (text.isEmpty) return null;

    var cursor = selected.extentOffset.clamp(0, text.length).toInt();
    if (cursor == text.length ||
        (cursor < text.length && text[cursor].trim().isEmpty)) {
      if (cursor == 0 || text[cursor - 1].trim().isEmpty) return null;
      cursor--;
    }
    var start = cursor;
    var end = cursor + 1;
    while (start > 0 && text[start - 1].trim().isNotEmpty) {
      start--;
    }
    while (end < text.length && text[end].trim().isNotEmpty) {
      end++;
    }
    return (start, end);
  }

  (int, int)? _selectedLineRange() {
    if (text.isEmpty) return null;
    final selected = selection;
    if (!selected.isValid) return null;
    final cursorStart =
        selected.isCollapsed ? selected.extentOffset : selected.start;
    final cursorEnd =
        selected.isCollapsed ? selected.extentOffset : selected.end;
    final start = text.lastIndexOf(
          '\n',
          (cursorStart - 1).clamp(0, text.length - 1).toInt(),
        ) +
        1;
    final lineBreak = text.indexOf(
      '\n',
      cursorEnd.clamp(0, text.length).toInt(),
    );
    final end = lineBreak < 0 ? text.length : lineBreak;
    if (start == end) return null;
    return (start, end);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      var end = start + 1;
      while (end < text.length &&
          _bold[end] == _bold[start] &&
          _title[end] == _title[start]) {
        end++;
      }
      final format = TextStyle(
        fontWeight:
            _title[start] || _bold[start] ? FontWeight.w900 : FontWeight.normal,
        fontSize: _title[start] ? 22 : null,
        color: _title[start] ? Theme.of(context).colorScheme.primary : null,
      );
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: style?.merge(format) ?? format,
        ),
      );
      start = end;
    }
    return TextSpan(style: style, children: spans);
  }

  _TextoDoDiarioInterpretado _parseLegacyFormatting(String source) {
    final textBuffer = StringBuffer();
    final bold = <bool>[];
    final title = <bool>[];
    final lines = source.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      if (lineIndex > 0) {
        textBuffer.write('\n');
        bold.add(false);
        title.add(false);
      }
      var line = lines[lineIndex];
      final titleMatch = RegExp(r'^\s*#+\s*').firstMatch(line);
      final isTitle = titleMatch != null;
      if (titleMatch != null) line = line.substring(titleMatch.end);

      var isBold = false;
      for (var indice = 0; indice < line.length;) {
        if (line.startsWith('**', indice)) {
          isBold = !isBold;
          indice += 2;
          continue;
        }
        textBuffer.write(line[indice]);
        bold.add(isBold);
        title.add(isTitle);
        indice++;
      }
    }
    return _TextoDoDiarioInterpretado(textBuffer.toString(), bold, title);
  }
}

class _TextoDoDiarioInterpretado {
  const _TextoDoDiarioInterpretado(this.text, this.bold, this.title);

  final String text;
  final List<bool> bold;
  final List<bool> title;
}

class _ItemFigurinhaArrastavel extends StatefulWidget {
  const _ItemFigurinhaArrastavel({
    super.key,
    required this.figurinha,
    required this.effectiveWidth,
    required this.effectiveHeight,
    required this.previewMode,
    required this.aoMover,
    required this.aoRemover,
  });

  final FigurinhaDiario figurinha;
  final double effectiveWidth;
  final double effectiveHeight;
  final bool previewMode;
  final ValueChanged<FigurinhaDiario> aoMover;
  final VoidCallback aoRemover;

  @override
  State<_ItemFigurinhaArrastavel> createState() =>
      _ItemFigurinhaArrastavelState();
}

class _ItemFigurinhaArrastavelState extends State<_ItemFigurinhaArrastavel> {
  late double _xFrac;
  late double _yFrac;

  @override
  void initState() {
    super.initState();
    _xFrac = widget.figurinha.x;
    _yFrac = widget.figurinha.y;
  }

  @override
  void didUpdateWidget(covariant _ItemFigurinhaArrastavel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.figurinha.x != widget.figurinha.x ||
        oldWidget.figurinha.y != widget.figurinha.y) {
      _xFrac = widget.figurinha.x;
      _yFrac = widget.figurinha.y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final posX =
        (_xFrac * widget.effectiveWidth).clamp(0.0, widget.effectiveWidth);
    final posY =
        (_yFrac * widget.effectiveHeight).clamp(0.0, widget.effectiveHeight);

    if (widget.previewMode) {
      return Positioned(
        left: posX,
        top: posY,
        child: Text(
          widget.figurinha.emoji,
          style: TextStyle(fontSize: widget.figurinha.tamanho),
        ),
      );
    }

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Movimento local suave a 120 FPS sem reconstruir todo o editor de texto
          setState(() {
            final curX = _xFrac * widget.effectiveWidth;
            final curY = _yFrac * widget.effectiveHeight;
            _xFrac = ((curX + details.delta.dx) / widget.effectiveWidth)
                .clamp(0.0, 1.0);
            _yFrac = ((curY + details.delta.dy) / widget.effectiveHeight)
                .clamp(0.0, 1.0);
          });
        },
        onPanEnd: (_) {
          widget.aoMover(widget.figurinha.copiarCom(x: _xFrac, y: _yFrac));
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                widget.figurinha.emoji,
                style: TextStyle(fontSize: widget.figurinha.tamanho),
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: GestureDetector(
                onTap: widget.aoRemover,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
