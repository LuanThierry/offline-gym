import 'package:flutter/material.dart';

import '../telas/configuracoes.dart';

class BotaoDeConfiguracoes extends StatelessWidget {
  const BotaoDeConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton.filledTonal(
        tooltip: 'Configurações',
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          maximumSize: const Size(42, 42),
          backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
          foregroundColor: colorScheme.primary,
        ),
        icon: const Icon(Icons.settings_outlined, size: 20),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TelaDeConfiguracoes()),
        ),
      ),
    );
  }
}
