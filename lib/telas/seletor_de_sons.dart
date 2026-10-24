import 'package:flutter/material.dart';
import '../servicos/som_do_alarme.dart';

/// Tela dedicada para ouvir, testar e selecionar o som do alarme de descanso
/// com agrupamento por categorias, prévia em tempo real e suporte a arquivo próprio.
class TelaSeletorDeSons extends StatefulWidget {
  const TelaSeletorDeSons({super.key});

  @override
  State<TelaSeletorDeSons> createState() => _TelaSeletorDeSonsState();
}

class _TelaSeletorDeSonsState extends State<TelaSeletorDeSons> {
  final ServicoDeSomDoAlarme _somService = ServicoDeSomDoAlarme.instance;
  String? _somTocandoId;

  @override
  void dispose() {
    _somService.pararAudio();
    super.dispose();
  }

  Future<void> _ouvirOuParar(String soundId) async {
    if (_somTocandoId == soundId && _somService.isPlaying) {
      await _somService.pararAudio();
      setState(() => _somTocandoId = null);
      return;
    }

    if (soundId == 'custom' && _somService.customAudioPath == null) {
      final escolheu = await _somService.selecionarAudioPersonalizado();
      if (!escolheu) return;
    }

    setState(() => _somTocandoId = soundId);
    await _somService.tocarSom(soundId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selecionarSom(String soundId) async {
    if (soundId == 'custom' && _somService.customAudioPath == null) {
      final escolheu = await _somService.selecionarAudioPersonalizado();
      if (!escolheu) return;
    }

    await _somService.definirSom(soundId);
    setState(() => _somTocandoId = soundId);
    await _somService.tocarSom(soundId);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Som "${ServicoDeSomDoAlarme.sonsDisponiveis.firstWhere((s) => s.id == soundId).title}" definido como alarme!',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Agrupa os sons por categoria
    final categorias = <String, List<OpcaoDeAlarme>>{};
    for (final s in ServicoDeSomDoAlarme.sonsDisponiveis) {
      categorias.putIfAbsent(s.categoria, () => <OpcaoDeAlarme>[]).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sons do Alarme'),
        actions: [
          if (_somService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded),
              tooltip: 'Parar Áudio',
              color: primary,
              onPressed: () async {
                await _somService.pararAudio();
                setState(() => _somTocandoId = null);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Banner informativo sobre ducking nativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161622) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.music_note_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Áudio Inteligente & Ducking',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seus bipes tocam suavemente por cima do Spotify e YouTube Music atenuando o volume momentaneamente sem pausar suas músicas de treino.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seções de Categorias de Sons
          ...categorias.entries.map((entry) {
            final categoriaNome = entry.key;
            final sonsDaCategoria = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8, top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoriaNome.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...sonsDaCategoria.map((sound) {
                  final isSelected = _somService.currentSoundId == sound.id;
                  final isPlayingThis =
                      _somTocandoId == sound.id && _somService.isPlaying;
                  final isCustom = sound.id == 'custom';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? primary
                            : (isDark
                                ? const Color(0xFF282836)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    color: isSelected
                        ? (isDark
                            ? primary.withValues(alpha: 0.12)
                            : primary.withValues(alpha: 0.06))
                        : (isDark ? const Color(0xFF1A1A24) : Colors.white),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _selecionarSom(sound.id),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Ícone em container neon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary.withValues(alpha: 0.22)
                                    : (isDark
                                        ? const Color(0xFF262634)
                                        : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                sound.icone,
                                color: isSelected
                                    ? primary
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black54),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Título e Descrição
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          sound.title,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 14.5,
                                            color: isSelected ? primary : null,
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primary
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'ATIVO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isCustom &&
                                            _somService.customAudioName != null
                                        ? 'Arquivo: ${_somService.customAudioName}'
                                        : sound.description,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isCustom &&
                                              _somService.customAudioName != null
                                          ? primary
                                          : theme
                                              .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isCustom) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (_somService.customAudioPath == null)
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.file_upload_outlined,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Escolher do Aparelho',
                                            ),
                                            onPressed: () async {
                                              final escolheu = await _somService
                                                  .selecionarAudioPersonalizado();
                                              if (escolheu && mounted) {
                                                setState(() {
                                                  _somTocandoId = 'custom';
                                                });
                                                await _somService
                                                    .tocarSom('custom');
                                              }
                                            },
                                          )
                                        else ...[
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.swap_horiz_rounded,
                                              size: 15,
                                            ),
                                            label: const Text('Trocar áudio'),
                                            onPressed: () async {
                                              final escolheu = await _somService
                                                  .selecionarAudioPersonalizado();
                                              if (escolheu && mounted) {
                                                setState(() {
                                                  _somTocandoId = 'custom';
                                                });
                                                await _somService
                                                    .tocarSom('custom');
                                              }
                                            },
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              foregroundColor: Colors.redAccent,
                                              textStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 15,
                                            ),
                                            label: const Text('Remover'),
                                            onPressed: () async {
                                              await _somService
                                                  .removerAudioPersonalizado();
                                              if (mounted) setState(() {});
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Botão Ouvir / Parar
                            IconButton(
                              icon: Icon(
                                isPlayingThis
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isPlayingThis
                                    ? Colors.redAccent
                                    : primary,
                                size: 34,
                              ),
                              tooltip: isPlayingThis
                                  ? 'Parar áudio'
                                  : 'Ouvir demonstração',
                              onPressed: () => _ouvirOuParar(sound.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
