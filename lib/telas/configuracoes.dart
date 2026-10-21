import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../banco_dados/banco_de_dados.dart';
import '../provedores/estado_tema.dart';
import '../provedores/estado_treino.dart';
import '../servicos/som_do_alarme.dart';
import '../servicos/backup.dart';
import '../servicos/exportacao_relatorio.dart';
import 'insights.dart';
import 'package:url_launcher/url_launcher.dart';

bool _licencaDoCriadorRegistrada = false;

void _garantirRegistroDaLicencaDoCriador() {
  if (_licencaDoCriadorRegistrada) return;
  _licencaDoCriadorRegistrada = true;
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['offline_gym (Criador & Autor Original: Luan Thierry)'],
      '''MIT License — Offline Gym

Criador, Idealizador e Desenvolvedor Original: Luan Thierry (@LuanThierry)
Repositório Oficial: https://github.com/LuanThierry/offline-gym

Copyright (c) 2026 Luan Thierry (LuanThierry)

Esta licença aplica-se ao código-fonte próprio do projeto. Ela NÃO concede direitos sobre o nome "Offline Gym", logotipos, ícone do aplicativo, capturas de tela ou artes promocionais, que pertencem exclusivamente ao criador Luan Thierry. Componentes de terceiros permanecem sob suas respectivas licenças.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.''',
    );
  });
}

class TelaDeConfiguracoes extends StatefulWidget {
  const TelaDeConfiguracoes({super.key});

  @override
  State<TelaDeConfiguracoes> createState() => _EstadoDaTelaDeConfiguracoes();
}

class _OpcoesDeImportacao {
  const _OpcoesDeImportacao({
    required this.apenasPlanosEExercicios,
    required this.salvarBackupAntes,
  });

  final bool apenasPlanosEExercicios;
  final bool salvarBackupAntes;
}

class _EstadoDaTelaDeConfiguracoes extends State<TelaDeConfiguracoes> {
  final ServicoDeBackup _backup = ServicoDeBackup(BancoDeDados.instance);
  final ServicoDeSomDoAlarme _alarmSound = ServicoDeSomDoAlarme.instance;
  bool _busy = false;
  List<BackupLocalSalvo> _backupsLocais = const <BackupLocalSalvo>[];
  bool _carregandoBackupsLocais = true;

  @override
  void initState() {
    super.initState();
    _garantirRegistroDaLicencaDoCriador();
    _atualizarListaDeBackupsLocais();
  }

  Future<void> _copiarTextoParaAreaDeTransferencia(
    String texto,
    String mensagemSucesso,
  ) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    _mostrarMensagem(mensagemSucesso);
  }

  Future<void> _abrirLinkNoNavegador(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _copiarTextoParaAreaDeTransferencia(
          url,
          'Link copiado para a área de transferência: $url',
        );
      }
    } catch (_) {
      await _copiarTextoParaAreaDeTransferencia(
        url,
        'Link copiado para a área de transferência: $url',
      );
    }
  }

  void _abrirModalSobreCriadorEApoio() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Criado por Luan Thierry',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Idealizador & Desenvolvedor Original (@LuanThierry)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O Offline Gym nasceu da necessidade real de planejar treinos, registrar séries, cargas e hábitos diários na academia sem depender de sinal de internet, sem anúncios invasivos e sem cobrar mensalidade.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF5252),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gostou do app? Apoie o criador!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Este projeto é mantido de forma 100% independente e gratuita por Luan Thierry. Se o aplicativo te ajuda nos treinos, você pode apoiar voluntariamente via LivePix (PIX seguro) ou deixar uma estrela (⭐) no GitHub:',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _abrirLinkNoNavegador(
                                  'https://livepix.gg/luanthierry');
                            },
                            icon: const Icon(Icons.volunteer_activism_rounded,
                                size: 18),
                            label: const Text(
                              'Apoiar via PIX (abrir livepix.gg/luanthierry)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _abrirLinkNoNavegador(
                                  'https://github.com/LuanThierry/offline-gym');
                            },
                            icon: const Icon(Icons.star_rounded,
                                size: 18, color: Colors.amber),
                            label: const Text(
                              'Deixar Estrela no GitHub (abrir repositório)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Por que existem as Licenças no aplicativo?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Autoria Oficial: Registra dentro do aplicativo que o código-fonte foi criado originalmente por Luan Thierry sob a Licença MIT, reservando exclusivamente ao autor o nome "Offline Gym", a marca e os logotipos.\n'
                    '2. Transparência Open Source: Cumpre a exigência legal de dar os devidos créditos às bibliotecas abertas utilizadas pelo Flutter (como SQLite, gráficos e criptografia).',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _atualizarListaDeBackupsLocais() async {
    try {
      final lista = await _backup.listarBackupsLocais();
      if (mounted) {
        setState(() {
          _backupsLocais = lista;
          _carregandoBackupsLocais = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoBackupsLocais = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  bool _bloqueadoPorSessao(ProvedorDeTreino provedor) {
    if (!provedor.sessaoAtiva) return false;
    _mostrarMensagem(
      'Finalize o treino em andamento antes de exportar ou importar um backup.',
    );
    return true;
  }

  Future<void> _salvarNoCelular() async {
    final provedor = context.read<ProvedorDeTreino>();
    if (_bloqueadoPorSessao(provedor)) return;

    setState(() => _busy = true);
    try {
      await _backup.salvarBackupNoCelular(automatico: false);
      await _atualizarListaDeBackupsLocais();
      _mostrarMensagem('Backup salvo diretamente no celular com sucesso!');
    } catch (erro) {
      _mostrarMensagem('Não foi possível salvar o backup no celular: $erro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportar() async {
    final provedor = context.read<ProvedorDeTreino>();
    if (_bloqueadoPorSessao(provedor)) return;
    final password = await _solicitarSenhaDoBackup(exportar: true);
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final resultado = await _backup.exportarECompartilhar(password: password);
      final warning = resultado.imagensAusentes == 0
          ? ''
          : ' ${resultado.imagensAusentes} imagem(ns) não foram encontradas e ficaram de fora.';
      _mostrarMensagem('Backup criptografado gerado.$warning');
    } catch (erro) {
      _mostrarMensagem('Não foi possível exportar o backup: $erro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importar() async {
    final provedor = context.read<ProvedorDeTreino>();
    if (_bloqueadoPorSessao(provedor)) return;

    // 1. Abre o seletor de arquivos PRIMEIRO (só pede senha depois se o arquivo for criptografado)
    ({String nome, Uint8List bytes})? arquivoEscolhido;
    try {
      arquivoEscolhido = await _backup.escolherBytesDeArquivoDeBackup();
    } catch (erro) {
      _mostrarMensagem('Não foi possível abrir o arquivo: $erro');
      return;
    }
    if (arquivoEscolhido == null || !mounted) return;

    // 2. Se o arquivo estiver criptografado (.ogb), solicita a senha para desbloqueá-lo
    String? password;
    if (_backup.bytesEstaoCriptografados(arquivoEscolhido.bytes)) {
      password = await _solicitarSenhaDoBackup(
        exportar: false,
        nomeArquivo: arquivoEscolhido.nome,
      );
      if (password == null || !mounted) return;
    }

    setState(() => _busy = true);
    DadosDoBackup? data;
    try {
      data = await _backup.decodificarBytesDeBackup(
        arquivoEscolhido.bytes,
        password: password,
      );
    } catch (erro) {
      _mostrarMensagem('$erro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    final picked = data;
    if (picked == null || !mounted) return;
    await _confirmarERestaurarBackup(picked, provedor: provedor);
  }

  Future<void> _restaurarDeBackupLocal(BackupLocalSalvo item) async {
    final provedor = context.read<ProvedorDeTreino>();
    if (_bloqueadoPorSessao(provedor)) return;

    String? password;
    if (await _backup.arquivoLocalEstaCriptografado(item.caminhoArquivo)) {
      if (!mounted) return;
      password = await _solicitarSenhaDoBackup(
        exportar: false,
        nomeArquivo: item.nomeArquivo,
      );
      if (password == null || !mounted) return;
    }

    setState(() => _busy = true);
    DadosDoBackup? data;
    try {
      data = await _backup.lerBackupDeArquivoLocal(
        item.caminhoArquivo,
        password: password,
      );
    } catch (erro) {
      _mostrarMensagem('Não foi possível ler o backup local: $erro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (data == null || !mounted) return;
    await _confirmarERestaurarBackup(
      data,
      provedor: provedor,
      salvarAntesPadrao: false,
    );
  }

  Future<void> _confirmarERestaurarBackup(
    DadosDoBackup picked, {
    required ProvedorDeTreino provedor,
    bool salvarAntesPadrao = true,
  }) async {
    var apenasPlanos = picked.contemApenasExercicios;
    var salvarAntes = salvarAntesPadrao;

    final exerciciosAtuais = provedor.planosPorDia.values.fold<int>(
      0,
      (acc, lista) => acc + lista.length,
    );
    final treinosAtuais = provedor.historico.length;
    final habitosAtuais = provedor.habitos.length;
    final tarefasAtuais = provedor.tarefas.length;
    final nomePerfilAtual = provedor.perfil?.nome ?? 'Configurado';
    final nomePerfilBackup = (picked.perfil?['nome'] as String?)?.trim();

    final opcoes = await showDialog<_OpcoesDeImportacao>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final cs = theme.colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Revisar antes de importar'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (picked.contemApenasExercicios)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Arquivo com apenas exercícios detectado! Seu perfil ($nomePerfilAtual), histórico e hábitos serão mantidos.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Conteúdo do arquivo vs. Seu celular hoje',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Exercícios no plano: ${picked.exerciseCount} (atual: $exerciciosAtuais)\n'
                            '• Treinos no histórico: ${picked.workoutCount} (atual: $treinosAtuais)\n'
                            '• Séries registradas: ${picked.seriesCount}\n'
                            '• Hábitos e tarefas: ${picked.habitCount} / ${picked.taskCount} (atual: $habitosAtuais / $tarefasAtuais)\n'
                            '• Pesos corporais: ${picked.bodyWeightCount}\n'
                            '• Anotações no diário: ${picked.diaryCount}\n'
                            '• Imagens / GIFs: ${picked.imageCount}\n'
                            '• Perfil no arquivo: ${nomePerfilBackup != null && nomePerfilBackup.isNotEmpty ? nomePerfilBackup : "Não incluído (mantém $nomePerfilAtual)"}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Como deseja importar?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setModalState(() => apenasPlanos = true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                apenasPlanos ? cs.primary : cs.outlineVariant,
                            width: apenasPlanos ? 1.8 : 1,
                          ),
                          color: apenasPlanos
                              ? cs.primary.withValues(alpha: 0.08)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              apenasPlanos
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 20,
                              color: apenasPlanos
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Apenas Planos e Exercícios',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Importa as fichas e GIFs de exercícios, mantendo sua conta, histórico, ofensiva, hábitos e tarefas atuais.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setModalState(() => apenasPlanos = false),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                !apenasPlanos ? cs.primary : cs.outlineVariant,
                            width: !apenasPlanos ? 1.8 : 1,
                          ),
                          color: !apenasPlanos
                              ? cs.primary.withValues(alpha: 0.08)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              !apenasPlanos
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 20,
                              color: !apenasPlanos
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Restaurar Backup Completo',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Restaura planos, histórico, hábitos e diário do arquivo (preserva seu perfil atual se o arquivo não tiver perfil).',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: salvarAntes,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: const Text(
                        'Salvar cópia do estado atual no celular antes de importar',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (val) =>
                          setModalState(() => salvarAntes = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _OpcoesDeImportacao(
                      apenasPlanosEExercicios: apenasPlanos,
                      salvarBackupAntes: salvarAntes,
                    ),
                  ),
                  child: const Text('Confirmar importação'),
                ),
              ],
            );
          },
        );
      },
    );
    if (opcoes == null || !mounted) return;

    setState(() => _busy = true);
    try {
      if (opcoes.salvarBackupAntes) {
        await _backup.salvarBackupNoCelular(automatico: true);
      }
      await _backup.restaurarBackup(
        picked,
        apenasPlanosEExercicios: opcoes.apenasPlanosEExercicios,
        manterPerfilSeAusente: true,
      );
      await provedor.recarregarTodosOsDados();
      await _atualizarListaDeBackupsLocais();
      _mostrarMensagem(
        opcoes.apenasPlanosEExercicios
            ? 'Planos e exercícios importados mantendo seu perfil e histórico!'
            : 'Backup restaurado com sucesso!',
      );
    } catch (erro) {
      _mostrarMensagem('Não foi possível importar o backup: $erro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatarDataHoraBackup(DateTime dt) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(dt.day)}/${dois(dt.month)}/${dt.year} às ${dois(dt.hour)}:${dois(dt.minute)}';
  }

  String _formatarTamanhoBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<String?> _solicitarSenhaDoBackup({
    required bool exportar,
    String? nomeArquivo,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _DialogoDeSenhaDoBackup(
        exportar: exportar,
        nomeArquivo: nomeArquivo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provedorDoTema = context.watch<ProvedorDeTema>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),

          // TEMA
          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.palette_outlined,
            title: 'Tema',
            subtitle: 'Use claro, escuro ou acompanhe o sistema.',
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android),
                label: Text('Sistema'),
              ),
            ],
            selected: <ThemeMode>{provedorDoTema.modoDoTema},
            onSelectionChanged: (selection) =>
                provedorDoTema.definirModoDoTema(selection.first),
          ),
          const SizedBox(height: 16),
          Text(
            'Cores de Treino & Acento',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProvedorDeTema.estilosDisponiveis.map((estilo) {
              final isSelected = provedorDoTema.estiloId == estilo.id;
              return ChoiceChip(
                avatar: CircleAvatar(
                  backgroundColor: estilo.primaria,
                  radius: 7,
                ),
                label: Text(estilo.nome),
                selected: isSelected,
                selectedColor: estilo.primaria.withValues(alpha: 0.18),
                side: BorderSide(
                  color: isSelected ? estilo.primaria : theme.dividerColor,
                  width: isSelected ? 1.6 : 1,
                ),
                onSelected: (selected) {
                  if (selected) {
                    provedorDoTema.definirEstiloDoTema(estilo.id);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: const Icon(
                  Icons.brightness_2_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Modo Preto Puro (AMOLED #000000)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Desliga 100% os pixels em telas OLED/AMOLED no tema escuro para economia máxima de bateria durante o treino.',
                style: TextStyle(fontSize: 12),
              ),
              value: provedorDoTema.modoAmoled,
              onChanged: (val) {
                provedorDoTema.definirModoAmoled(val);
              },
            ),
          ),

          const SizedBox(height: 26),

          // ALARME DO CRONÔMETRO
          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.notifications_active_outlined,
            title: 'Alarme do cronômetro',
            subtitle: 'Escolha o som e a vibração ao final do descanso.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                children: [
                  RadioGroup<String>(
                    groupValue: _alarmSound.currentSoundId,
                    onChanged: (value) async {
                      if (value != null) {
                        if (value == 'custom' &&
                            _alarmSound.customAudioPath == null) {
                          final picked =
                              await _alarmSound.selecionarAudioPersonalizado();
                          if (picked) {
                            await _alarmSound.tocarSom('custom');
                          }
                        } else {
                          await _alarmSound.definirSom(value);
                          await _alarmSound.tocarSom(value);
                        }
                        setState(() {});
                      }
                    },
                    child: Column(
                      children: ServicoDeSomDoAlarme.sonsDisponiveis.map((
                        sound,
                      ) {
                        final isSelected =
                            _alarmSound.currentSoundId == sound.id;
                        final isCustom = sound.id == 'custom';
                        final subtitleText =
                            isCustom && _alarmSound.customAudioName != null
                                ? 'Arquivo: ${_alarmSound.customAudioName}'
                                : sound.description;

                        return Column(
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              title: Text(
                                sound.title,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                subtitleText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCustom &&
                                          _alarmSound.customAudioName != null
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              leading: Radio<String>(value: sound.id),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.play_circle_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                    tooltip: 'Ouvir som',
                                    onPressed: () async {
                                      if (isCustom &&
                                          _alarmSound.customAudioPath == null) {
                                        final picked = await _alarmSound
                                            .selecionarAudioPersonalizado();
                                        if (picked) {
                                          await _alarmSound.tocarSom('custom');
                                          setState(() {});
                                        }
                                        return;
                                      }
                                      await _alarmSound.tocarSom(sound.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.stop_circle_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    tooltip: 'Parar áudio',
                                    onPressed: () async {
                                      await _alarmSound.pararAudio();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (isCustom)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(48, 0, 8, 8),
                                child: Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final picked = await _alarmSound
                                            .selecionarAudioPersonalizado();
                                        if (picked) {
                                          _mostrarMensagem(
                                            'Áudio selecionado: ${_alarmSound.customAudioName}',
                                          );
                                          await _alarmSound.tocarSom('custom');
                                        }
                                        setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.audio_file_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _alarmSound.customAudioName == null
                                            ? 'Escolher áudio do celular'
                                            : 'Trocar áudio',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (_alarmSound.customAudioName !=
                                        null) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () async {
                                          await _alarmSound
                                              .removerAudioPersonalizado();
                                          setState(() {});
                                        },
                                        child: const Text(
                                          'Remover',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Contagem regressiva 3-2-1'),
                    subtitle: const Text(
                      'Bip sonoro e tátil nos últimos 3 segundos antes do término',
                    ),
                    value: _alarmSound.countdownBeepEnabled,
                    activeThumbColor: theme.colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onChanged: (val) async {
                      await _alarmSound.definirBipContagemRegressiva(val);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Vibrar ao concluir'),
                    subtitle: const Text(
                      'Feedback tátil quando o descanso terminar',
                    ),
                    value: _alarmSound.vibrateEnabled,
                    activeThumbColor: theme.colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onChanged: (val) async {
                      await _alarmSound.definirVibracao(val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vibration_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Intensidade do Feedback Tátil',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vibração ao alternar séries, tocar botões e finalizar descanso.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<IntensidadeTatil>(
                            segments: const [
                              ButtonSegment<IntensidadeTatil>(
                                value: IntensidadeTatil.forte,
                                label: Text('Forte'),
                                icon: Icon(Icons.bolt_rounded, size: 16),
                              ),
                              ButtonSegment<IntensidadeTatil>(
                                value: IntensidadeTatil.media,
                                label: Text('Média'),
                                icon: Icon(Icons.sensors_rounded, size: 16),
                              ),
                              ButtonSegment<IntensidadeTatil>(
                                value: IntensidadeTatil.desativada,
                                label: Text('Desativada'),
                                icon: Icon(Icons.do_not_disturb_on_outlined,
                                    size: 16),
                              ),
                            ],
                            selected: {_alarmSound.intensidadeTatil},
                            onSelectionChanged: (novaSelecao) async {
                              final selecionado = novaSelecao.first;
                              await _alarmSound
                                  .definirIntensidadeTatil(selecionado);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.insights_outlined,
            title: 'Insights e progressão',
            subtitle:
                'PRs, 1RM, volume, streaks, deload e repetição da última sessão.',
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.query_stats),
              title: const Text('Abrir painel de evolução'),
              subtitle: const Text(
                  'Histórico calculado localmente, sem enviar dados.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TelaDeInsights()),
              ),
            ),
          ),

          const SizedBox(height: 26),

          // RELATÓRIO PARA PERSONAL TRAINER
          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.assessment_outlined,
            title: 'Relatório para Personal Trainer',
            subtitle:
                'Exporte o histórico de cargas, PRs e peso em PDF para impressão ou planilha CSV para seu treinador.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acompanhamento Profissional',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Gere arquivos prontos para compartilhar via WhatsApp ou e-mail com seu professor.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    final provedor =
                                        context.read<ProvedorDeTreino>();
                                    await ServicoDeExportacaoDeRelatorio
                                        .instance
                                        .exportarRelatorioPDFHtml(
                                            context, provedor);
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 18),
                          label: const Text('Relatório PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    final provedor =
                                        context.read<ProvedorDeTreino>();
                                    await ServicoDeExportacaoDeRelatorio
                                        .instance
                                        .exportarRelatorioCSV(
                                            context, provedor);
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          icon:
                              const Icon(Icons.table_chart_outlined, size: 18),
                          label: const Text('Planilha CSV'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          // BACKUP DOS DADOS
          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.backup_outlined,
            title: 'Backup e Armazenamento no Celular',
            subtitle:
                'Backups locais ficam no sandbox privado; para transportar dados, use a exportação protegida por senha.',
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _busy ? null : _salvarNoCelular,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Salvar backup no celular agora'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _exportar,
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Exportar (.ogb)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _importar,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Importar arquivo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ao importar um arquivo apenas com exercícios, seu perfil, histórico de treinos e hábitos são mantidos automaticamente.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (_carregandoBackupsLocais)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_backupsLocais.isNotEmpty) ...<Widget>[
            Text(
              'Backups salvos neste celular (${_backupsLocais.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ..._backupsLocais.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      item.automatico
                          ? Icons.history_rounded
                          : Icons.phone_android_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.automatico
                        ? 'Cópia automática pré-importação'
                        : 'Backup salvo no celular',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${_formatarDataHoraBackup(item.criadoEm)} • ${_formatarTamanhoBytes(item.tamanhoBytes)}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Revisar e restaurar',
                        icon: Icon(
                          Icons.settings_backup_restore_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed:
                            _busy ? null : () => _restaurarDeBackupLocal(item),
                      ),
                      IconButton(
                        tooltip: 'Compartilhar arquivo',
                        icon: const Icon(Icons.share_outlined, size: 20),
                        onPressed: _busy
                            ? null
                            : () async {
                                try {
                                  await _backup.compartilharBackupLocal(
                                    item.caminhoArquivo,
                                  );
                                } catch (e) {
                                  _mostrarMensagem('$e');
                                }
                              },
                      ),
                      IconButton(
                        tooltip: 'Excluir do celular',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: _busy
                            ? null
                            : () async {
                                await _backup.excluirBackupLocal(
                                  item.caminhoArquivo,
                                );
                                await _atualizarListaDeBackupsLocais();
                                _mostrarMensagem('Backup local removido.');
                              },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 26),

          // SOBRE O APLICATIVO, CRIADOR E APOIO
          const _TituloDaSecaoDeConfiguracoes(
            icon: Icons.verified_user_outlined,
            title: 'Sobre o Aplicativo, Autoria & Apoio',
            subtitle:
                'Idealizado e criado por Luan Thierry • 100% Offline, gratuito, sem anúncios e Open Source (MIT).',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.person_pin_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Criado por Luan Thierry (@LuanThierry)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Idealizador e autor original • Toque para conhecer a história e apoiar',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _abrirModalSobreCriadorEApoio,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.fitness_center_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Offline Gym — Treinos e Hábitos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Versão 1.4.1 (Build 8) • Coach Fisiológico, PDF Nativo, AMOLED e Catálogo +2.000 exercícios',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF00B894),
                  ),
                  title: Text(
                    'Privacidade Total no Dispositivo',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    'Nenhuma permissão de internet é solicitada. Todos os seus treinos, hábitos, fotos e backups permanecem exclusivamente no seu celular.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Licenças de Código Aberto & Registro de Autoria',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'Autoria de Luan Thierry (Licença MIT) e créditos legais das bibliotecas do Flutter',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Offline Gym (Criador: Luan Thierry)',
                      applicationVersion: '1.4.1+8',
                      applicationLegalese:
                          '© 2026 Luan Thierry (@LuanThierry) — Criador e Autor Original.\nDistribuído sob a Licença MIT (100% Offline & Open Source). O nome "Offline Gym", logotipos e ícones pertencem exclusivamente ao criador.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloDaSecaoDeConfiguracoes extends StatelessWidget {
  const _TituloDaSecaoDeConfiguracoes({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogoDeSenhaDoBackup extends StatefulWidget {
  const _DialogoDeSenhaDoBackup({
    required this.exportar,
    this.nomeArquivo,
  });

  final bool exportar;
  final String? nomeArquivo;

  @override
  State<_DialogoDeSenhaDoBackup> createState() =>
      _EstadoDoDialogoDeSenhaDoBackup();
}

class _EstadoDoDialogoDeSenhaDoBackup extends State<_DialogoDeSenhaDoBackup> {
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmacaoController = TextEditingController();
  bool _ocultarSenha = true;
  String? _erroSenha;
  String? _erroConfirmacao;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final textoSenha = _senhaController.text;
    if (widget.exportar) {
      if (textoSenha.trim().length < 8) {
        setState(() {
          _erroSenha = 'Use pelo menos 8 caracteres.';
          _erroConfirmacao = null;
        });
        return;
      }
      if (_confirmacaoController.text != textoSenha) {
        setState(() {
          _erroSenha = null;
          _erroConfirmacao = 'As senhas não correspondem.';
        });
        return;
      }
    } else {
      if (textoSenha.isEmpty) {
        setState(() {
          _erroSenha = 'Digite a senha deste backup para desbloqueá-lo.';
        });
        return;
      }
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(textoSenha);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.exportar ? 'Proteger backup (.ogb)' : 'Desbloquear backup',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!widget.exportar &&
                widget.nomeArquivo != null &&
                widget.nomeArquivo!.isNotEmpty) ...<Widget>[
              Text(
                'Arquivo selecionado: ${widget.nomeArquivo}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _senhaController,
              obscureText: _ocultarSenha,
              autofocus: true,
              onChanged: (_) {
                if (_erroSenha != null) {
                  setState(() => _erroSenha = null);
                }
              },
              onSubmitted: (_) {
                if (!widget.exportar) _confirmar();
              },
              decoration: InputDecoration(
                labelText: 'Senha do backup',
                hintText: widget.exportar ? 'Pelo menos 8 caracteres' : null,
                errorText: _erroSenha,
                suffixIcon: IconButton(
                  tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _ocultarSenha
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _ocultarSenha = !_ocultarSenha),
                ),
              ),
            ),
            if (widget.exportar) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmacaoController,
                obscureText: _ocultarSenha,
                onChanged: (_) {
                  if (_erroConfirmacao != null) {
                    setState(() => _erroConfirmacao = null);
                  }
                },
                onSubmitted: (_) => _confirmar(),
                decoration: InputDecoration(
                  labelText: 'Confirme a senha',
                  errorText: _erroConfirmacao,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A senha não fica salva no app. Guarde-a em um local seguro: sem ela, não será possível abrir esse backup.',
              ),
            ] else ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Este arquivo está protegido com criptografia Argon2id + AES-256. Digite a senha criada no momento da exportação.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: Text(widget.exportar ? 'Gerar backup' : 'Desbloquear'),
        ),
      ],
    );
  }
}
