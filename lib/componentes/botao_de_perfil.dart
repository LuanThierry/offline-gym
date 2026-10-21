import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/plano_de_treino.dart';
import '../provedores/estado_treino.dart';
import '../telas/perfil.dart';
import 'foto_de_perfil_com_ofensiva.dart';

class BotaoDePerfil extends StatelessWidget {
  const BotaoDePerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final perfil = context.select<ProvedorDeTreino, PerfilDoUsuario?>(
      (provedor) => provedor.perfil,
    );
    final streak = context.select<ProvedorDeTreino, int>(
      (provedor) => provedor.ofensivaAtual,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton(
        tooltip: 'Perfil',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const TelaDePerfil())),
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          maximumSize: const Size(42, 42),
          padding: EdgeInsets.zero,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: colorScheme.primary,
        ),
        icon: FotoDePerfilComOfensiva(
          caminhoFoto: perfil?.caminhoFoto,
          diasSeguidos: streak,
          diametro: 40,
        ),
      ),
    );
  }
}
