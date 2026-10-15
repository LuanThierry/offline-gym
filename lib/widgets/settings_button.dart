import 'package:flutter/material.dart';

import '../screens/configuracoes_screen.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Configurações',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConfiguracoesScreen()),
      ),
    );
  }
}