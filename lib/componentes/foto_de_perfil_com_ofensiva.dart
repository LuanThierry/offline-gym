import 'dart:io';

import 'package:flutter/material.dart';

import '../dominio/sistema_gamificacao.dart';

/// Exibe a foto do perfil com uma borda que evolui conforme a ofensiva de treino.
/// Renderiza a imagem e a borda sem distorções nem cortes indesejados.
class FotoDePerfilComOfensiva extends StatelessWidget {
  const FotoDePerfilComOfensiva({
    super.key,
    required this.caminhoFoto,
    required this.diasSeguidos,
    required this.diametro,
    this.permiteEditar = false,
    this.aoEditar,
  });

  final String? caminhoFoto;
  final int diasSeguidos;
  final double diametro;
  final bool permiteEditar;
  final VoidCallback? aoEditar;

  Widget _iconePadrao(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: diametro * 0.52,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classe = SistemaGamificacao.obterClasseAtual(diasSeguidos);
    final cor = diasSeguidos == 0
        ? Theme.of(context).colorScheme.outlineVariant
        : classe.cor;
    final arquivo = caminhoFoto;
    final existe = arquivo != null && File(arquivo).existsSync();
    final espessuraBorda = (diametro * 0.045).clamp(2.5, 4.5);

    return Tooltip(
      message: diasSeguidos == 0
          ? 'Ofensiva: comece hoje!'
          : '${classe.nome}: $diasSeguidos ${diasSeguidos == 1 ? 'dia' : 'dias'} em sequência',
      child: InkWell(
        onTap: permiteEditar ? aoEditar : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: diametro,
          height: diametro,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              // Avatar com borda da ofensiva
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: diametro,
                height: diametro,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cor, width: espessuraBorda),
                  boxShadow: diasSeguidos == 0
                      ? const <BoxShadow>[]
                      : <BoxShadow>[
                          BoxShadow(
                            color: cor.withValues(alpha: 0.28),
                            blurRadius: diametro * 0.14,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: ClipOval(
                  child: existe
                      ? Image.file(
                          File(arquivo),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _iconePadrao(context),
                        )
                      : _iconePadrao(context),
                ),
              ),

              // Botão de alterar foto (posicionado fora do ClipOval para não cortar)
              if (permiteEditar)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: diametro * 0.32,
                    height: diametro * 0.32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: diametro * 0.17,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
