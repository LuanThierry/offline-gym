import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../componentes/botao_de_perfil.dart';

class TelaDaGaleria extends StatefulWidget {
  const TelaDaGaleria({super.key, this.requiredForCurrentMonth = false});

  final bool requiredForCurrentMonth;

  @override
  State<TelaDaGaleria> createState() => _EstadoDaTelaDaGaleria();
}

class _EstadoDaTelaDaGaleria extends State<TelaDaGaleria> {
  bool _busy = false;

  Future<void> _mostrarOpcoesDaOrigemDaFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Adicionar foto mensal',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library_outlined),
                ),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Selecione uma ou mais fotos'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.camera_alt_outlined),
                ),
                title: const Text('Tirar uma foto'),
                subtitle: const Text('Usar a câmera do aparelho'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null && mounted) await _selecionarFotos(source);
  }

  Future<void> _selecionarFotos(ImageSource source) async {
    if (_busy) return;
    final workoutProvider = context.read<ProvedorDeTreino>();
    setState(() => _busy = true);
    final savedPaths = <String>[];
    try {
      final picker = ImagePicker();
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage(imageQuality: 95);
      } else {
        final imagem = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 95,
        );
        picked = imagem == null ? <XFile>[] : <XFile>[imagem];
      }
      if (picked.isEmpty) return;

      final now = DateTime.now();
      final chaveDoMes = ProvedorDeTreino.chaveDoMes(now);
      final documents = await getApplicationDocumentsDirectory();
      final photoDirectory = Directory(
        p.join(documents.path, 'monthly_progress_photos', chaveDoMes),
      );
      await photoDirectory.create(recursive: true);

      for (var indice = 0; indice < picked.length; indice++) {
        final photo = picked[indice];
        final extension = p.extension(photo.path).isEmpty
            ? '.jpg'
            : p.extension(photo.path).toLowerCase();
        final nomeDoArquivo =
            'evolucao_${chaveDoMes.replaceAll('-', '')}_${DateTime.now().microsecondsSinceEpoch}_$indice$extension';
        final target = File(p.join(photoDirectory.path, nomeDoArquivo));
        await File(photo.path).copy(target.path);
        savedPaths.add(target.path);
      }

      await workoutProvider.adicionarFotosMensaisDeEvolucao(now, savedPaths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${savedPaths.length} foto(s) salva(s) para ${_rotuloDoMes(chaveDoMes)}.',
            ),
          ),
        );
      }
    } catch (erro) {
      for (final caminho in savedPaths) {
        try {
          await File(caminho).delete();
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar as fotos: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _excluirFoto(
    BuildContext context,
    ProvedorDeTreino provedor,
    FotoMensalDeEvolucao photo,
  ) async {
    final currentMonth = ProvedorDeTreino.chaveDoMes(DateTime.now());
    final currentMonthPhotos = provedor.fotosMensaisDeEvolucao
        .where((item) => item.mesISO == currentMonth)
        .length;
    if (photo.mesISO == currentMonth && currentMonthPhotos <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione outra foto antes de remover a última foto deste mês.',
          ),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover foto?'),
        content: const Text(
          'Esta foto será removida permanentemente da sua galeria de evolução.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      await provedor.excluirFotoMensalDeEvolucao(photo.id);
      try {
        await File(photo.caminhoLocal).delete();
      } catch (_) {}
    } catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover a foto: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = ProvedorDeTreino.chaveDoMes(now);

    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final hasCurrentPhoto = provedor.temFotoMensalDeEvolucao(now);
        final grouped = <String, List<FotoMensalDeEvolucao>>{};
        for (final photo in provedor.fotosMensaisDeEvolucao) {
          grouped
              .putIfAbsent(photo.mesISO, () => <FotoMensalDeEvolucao>[])
              .add(photo);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Galeria'),
            actions: widget.requiredForCurrentMonth
                ? null
                : [
                    if (provedor.fotosMensaisDeEvolucao.length >= 2)
                      IconButton(
                        tooltip: 'Comparador Antes & Depois',
                        icon: const Icon(Icons.compare_arrows_rounded),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const TelaDeComparacaoAntesDepois(),
                            ),
                          );
                        },
                      ),
                    const BotaoDePerfil(),
                  ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.requiredForCurrentMonth && !hasCurrentPhoto
                        ? const Color(0xFFB7791F)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      widget.requiredForCurrentMonth && !hasCurrentPhoto
                          ? Icons.lock_outline
                          : Icons.photo_camera_back_outlined,
                      color: widget.requiredForCurrentMonth && !hasCurrentPhoto
                          ? const Color(0xFFB7791F)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${widget.requiredForCurrentMonth ? 'Desafio da foto mensal' : 'Foto mensal'} · ${_rotuloDoMes(currentMonth)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fotos feitas em condições parecidas ajudam a comparar mudanças ao longo do tempo. Elas ficam salvas neste aparelho. ${widget.requiredForCurrentMonth && !hasCurrentPhoto ? 'É um desafio opcional: registre uma foto para acompanhar sua evolução ou pule por enquanto e continue usando o app.' : hasCurrentPhoto ? 'A foto deste mês já foi registrada; você também pode guardar outras.' : 'Registre uma ou mais fotos neste mês.'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (widget.requiredForCurrentMonth) ...<Widget>[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: hasCurrentPhoto ? 1 : 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasCurrentPhoto
                                  ? 'Desafio concluído'
                                  : '0 de 1 foto registrada',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _mostrarOpcoesDaOrigemDaFoto,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_busy ? 'Salvando...' : 'Adicionar foto(s)'),
                ),
              ),
              if (provedor.fotosMensaisDeEvolucao.length >= 2) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TelaDeComparacaoAntesDepois(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: const Text('Comparador Antes & Depois'),
                  ),
                ),
              ],
              if (widget.requiredForCurrentMonth &&
                  !hasCurrentPhoto) ...<Widget>[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          try {
                            await provedor.adiarDesafioFotoMensal(now);
                          } catch (erro) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Não foi possível adiar o desafio: $erro',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Pular por enquanto'),
                ),
              ],
              if (grouped.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Text(
                    'As fotos salvas da sua evolução aparecerão aqui, organizadas por mês.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _rotuloDoMes(entry.key),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entry.value.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, indice) {
                            final photo = entry.value[indice];
                            final imagem = File(photo.caminhoLocal);
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  imagem.existsSync()
                                      ? Image.file(
                                          imagem,
                                          fit: BoxFit.cover,
                                          cacheWidth: 600,
                                          filterQuality: FilterQuality.medium,
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                  if (!(photo.mesISO == currentMonth &&
                                      entry.value.length <= 1))
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: IconButton.filledTonal(
                                        tooltip: 'Remover foto',
                                        onPressed: () => _excluirFoto(
                                          context,
                                          provedor,
                                          photo,
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

String _rotuloDoMes(String chaveDoMes) {
  final data = DateTime.tryParse('$chaveDoMes-01');
  if (data == null) return chaveDoMes;
  final label = DateFormat('MMMM yyyy', 'pt_BR').format(data);
  return label[0].toUpperCase() + label.substring(1);
}

class TelaDeComparacaoAntesDepois extends StatefulWidget {
  const TelaDeComparacaoAntesDepois({super.key});

  @override
  State<TelaDeComparacaoAntesDepois> createState() =>
      _EstadoDaTelaDeComparacaoAntesDepois();
}

class _EstadoDaTelaDeComparacaoAntesDepois
    extends State<TelaDeComparacaoAntesDepois> {
  int? _idFotoAntes;
  int? _idFotoDepois;
  double _posicaoDivisor = 0.5; // 0.0 a 1.0
  bool _modoSlider = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ProvedorDeTreino>(
      builder: (context, provedor, _) {
        final fotos = List<FotoMensalDeEvolucao>.from(
          provedor.fotosMensaisDeEvolucao,
        )..sort((a, b) => a.dataCriacaoISO.compareTo(b.dataCriacaoISO));

        if (fotos.length < 2) {
          return Scaffold(
            appBar: AppBar(title: const Text('Antes & Depois')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'É necessário ter ao menos 2 fotos registradas na galeria para comparar a evolução.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Voltar para a Galeria'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Inicializa defaults caso não tenham sido setados
        final fotoMaisAntiga = fotos.first;
        final fotoMaisRecente = fotos.last;

        final fotoAntes = fotos.firstWhere(
          (f) => f.id == _idFotoAntes,
          orElse: () => fotoMaisAntiga,
        );
        final fotoDepois = fotos.firstWhere(
          (f) => f.id == _idFotoDepois,
          orElse: () => fotoMaisRecente,
        );

        final dataA = DateTime.tryParse(fotoAntes.dataCriacaoISO);
        final dataD = DateTime.tryParse(fotoDepois.dataCriacaoISO);
        int mesesDiff = 0;
        if (dataA != null && dataD != null) {
          mesesDiff =
              ((dataD.year - dataA.year) * 12) + (dataD.month - dataA.month);
          if (mesesDiff < 0) mesesDiff = -mesesDiff;
        }

        final arquivoAntes = File(fotoAntes.caminhoLocal);
        final arquivoDepois = File(fotoDepois.caminhoLocal);
        final fotosExistem =
            arquivoAntes.existsSync() && arquivoDepois.existsSync();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Comparador Antes & Depois'),
            actions: [
              IconButton(
                tooltip: 'Inverter Fotos',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  setState(() {
                    final temp = _idFotoAntes ?? fotoMaisAntiga.id;
                    _idFotoAntes = _idFotoDepois ?? fotoMaisRecente.id;
                    _idFotoDepois = temp;
                  });
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              // Alternador de Modo: Divisor ou Lado a Lado
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.splitscreen_rounded),
                      label: Text('Divisor Interativo'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.view_column_rounded),
                      label: Text('Lado a Lado'),
                    ),
                  ],
                  selected: {_modoSlider},
                  onSelectionChanged: (set) {
                    setState(() => _modoSlider = set.first);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Controles para selecionar Foto Antes e Foto Depois
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Antes (Início)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          key: ValueKey<int>(fotoAntes.id),
                          isExpanded: true,
                          initialValue: fotoAntes.id,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: fotos.map((f) {
                            return DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(
                                _rotuloDoMes(f.mesISO),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) => setState(() => _idFotoAntes = id),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Depois (Atual)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          key: ValueKey<int>(fotoDepois.id),
                          isExpanded: true,
                          initialValue: fotoDepois.id,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: fotos.map((f) {
                            return DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(
                                _rotuloDoMes(f.mesISO),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) => setState(() => _idFotoDepois = id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Badge de tempo decorrido
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    mesesDiff == 0
                        ? 'Comparando fotos do mesmo mês'
                        : '$mesesDiff ${mesesDiff == 1 ? "mês" : "meses"} de evolução e dedicação! 🔥',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!fotosExistem)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                        'Uma das fotos selecionadas não foi encontrada no aparelho.'),
                  ),
                )
              else if (_modoSlider)
                // MODO SLIDER DIVISOR INTERATIVO
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final width = constraints.maxWidth;
                        final divisorX =
                            (width * _posicaoDivisor).clamp(0.0, width);

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _posicaoDivisor =
                                  (details.localPosition.dx / width)
                                      .clamp(0.01, 0.99);
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Foto DEPOIS (embaixo)
                              Image.file(
                                arquivoDepois,
                                fit: BoxFit.cover,
                              ),

                              // Foto ANTES (em cima, cortada pela posição do divisor)
                              ClipRect(
                                clipper: _HorizontalClipper(divisorX),
                                child: Image.file(
                                  arquivoAntes,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Linha divisória
                              Positioned(
                                left: divisorX - 1.5,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 3,
                                  color: Colors.white,
                                ),
                              ),

                              // Handle circular central do divisor
                              Positioned(
                                left: divisorX - 18,
                                top: (constraints.maxHeight / 2) - 18,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.compare_arrows_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                              ),

                              // Tag "ANTES"
                              Positioned(
                                top: 12,
                                left: 12,
                                child: _TagFotoComparacao(
                                  rotulo: 'ANTES',
                                  mes: _rotuloDoMes(fotoAntes.mesISO),
                                  corFundo:
                                      Colors.black.withValues(alpha: 0.65),
                                ),
                              ),

                              // Tag "DEPOIS"
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _TagFotoComparacao(
                                  rotulo: 'DEPOIS',
                                  mes: _rotuloDoMes(fotoDepois.mesISO),
                                  corFundo: theme.colorScheme.primary
                                      .withValues(alpha: 0.85),
                                ),
                              ),

                              // Dica na parte inferior
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '↔ Arraste o divisor para comparar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                // MODO LADO A LADO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Antes: ${_rotuloDoMes(fotoAntes.mesISO)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: InteractiveViewer(
                                clipBehavior: Clip.none,
                                child:
                                    Image.file(arquivoAntes, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Depois: ${_rotuloDoMes(fotoDepois.mesISO)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: InteractiveViewer(
                                clipBehavior: Clip.none,
                                child: Image.file(arquivoDepois,
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HorizontalClipper extends CustomClipper<Rect> {
  const _HorizontalClipper(this.splitX);

  final double splitX;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(_HorizontalClipper oldClipper) =>
      oldClipper.splitX != splitX;
}

class _TagFotoComparacao extends StatelessWidget {
  const _TagFotoComparacao({
    required this.rotulo,
    required this.mes,
    required this.corFundo,
  });

  final String rotulo;
  final String mes;
  final Color corFundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            mes,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
