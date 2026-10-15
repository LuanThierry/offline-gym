import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../providers/theme_provider.dart';
import '../providers/workout_provider.dart';
import '../services/backup_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final BackupService _backup = BackupService(DatabaseHelper.instance);
  bool _busy = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _blockedBySession(WorkoutProvider provider) {
    if (!provider.sessionActive) return false;
    _showMessage(
      'Finalize o treino em andamento antes de exportar ou importar um backup.',
    );
    return true;
  }

  Future<void> _export() async {
    final provider = context.read<WorkoutProvider>();
    if (_blockedBySession(provider)) return;

    setState(() => _busy = true);
    try {
      final result = await _backup.exportAndShare();
      final warning = result.missingImages == 0
          ? ''
          : ' ${result.missingImages} imagem(ns) não foram encontradas e ficaram de fora.';
      _showMessage('Backup gerado.$warning');
    } catch (error) {
      _showMessage('Não foi possível exportar o backup: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final provider = context.read<WorkoutProvider>();
    if (_blockedBySession(provider)) return;

    setState(() => _busy = true);
    BackupData? data;
    try {
      data = await _backup.pickBackup();
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    final picked = data;
    if (picked == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importar backup?'),
        content: Text(
          'Este backup contém:\n'
              '• ${picked.exerciseCount} exercício(s) no plano\n'
              '• ${picked.workoutCount} treino(s) no histórico\n'
              '• ${picked.seriesCount} série(s) registrada(s)\n'
              '• ${picked.bodyWeightCount} registro(s) de peso\n'
              '• ${picked.imageCount} imagem(ns)\n\n'
              'Os dados atuais deste celular serão substituídos. '
              'Se quiser guardar o que existe agora, exporte um backup antes.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _backup.restore(picked);
      await provider.reloadAllData();
      _showMessage('Backup restaurado com sucesso.');
    } catch (error) {
      _showMessage('Não foi possível importar o backup: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Tema', style: theme.textTheme.titleMedium),
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
            selected: <ThemeMode>{themeProvider.themeMode},
            onSelectionChanged: (selection) =>
                themeProvider.setThemeMode(selection.first),
          ),
          const SizedBox(height: 26),
          Text('Backup dos dados', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Exporte treinos, pesos e imagens para trocar de celular. Funciona '
                'totalmente offline: o arquivo é gerado no aparelho e você escolhe '
                'onde salvar (Drive, Arquivos, WhatsApp...).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Exportar backup'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Importar backup'),
          ),
          const SizedBox(height: 12),
          Text(
            'Importar substitui os dados deste celular pelos do arquivo escolhido.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}