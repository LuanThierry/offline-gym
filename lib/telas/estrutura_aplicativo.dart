import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provedores/estado_treino.dart';
import 'boas_vindas_gamificadas.dart';
import 'galeria.dart';
import 'historico.dart';
import 'hoje.dart';
import 'planos.dart';

class EstruturaDoAplicativo extends StatefulWidget {
  const EstruturaDoAplicativo({super.key});

  @override
  State<EstruturaDoAplicativo> createState() =>
      _EstadoDaEstruturaDoAplicativo();
}

class _EstadoDaEstruturaDoAplicativo extends State<EstruturaDoAplicativo> {
  int _selectedIndex = 0;
  final Set<int> _abasVisitadas = {0};
  ValueListenable<int>? _abrirHabitosListenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final novoListenable =
        context.read<ProvedorDeTreino>().abrirHabitosHojeListenable;
    if (_abrirHabitosListenable != novoListenable) {
      _abrirHabitosListenable?.removeListener(_aoSolicitarAbrirHabitosHoje);
      _abrirHabitosListenable = novoListenable;
      _abrirHabitosListenable!.addListener(_aoSolicitarAbrirHabitosHoje);
    }
  }

  @override
  void dispose() {
    _abrirHabitosListenable?.removeListener(_aoSolicitarAbrirHabitosHoje);
    super.dispose();
  }

  void _aoSolicitarAbrirHabitosHoje() {
    if (mounted && _selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
  }

  void _abrirPlanos() {
    setState(() {
      _selectedIndex = 1;
      _abasVisitadas.add(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ProvedorDeTreino,
        ({bool mostrarOnboarding, bool mostrarDesafioFoto})>(
      selector: (_, provedor) => (
        mostrarOnboarding: provedor.inicializado &&
            (provedor.perfil == null || !provedor.perfil!.onboardingConcluido),
        mostrarDesafioFoto: provedor.inicializado &&
            provedor.desafioFotoMensalAtivo(DateTime.now()),
      ),
      builder: (context, estadoRota, _) {
        if (estadoRota.mostrarOnboarding) {
          return const TelaDeBoasVindasGamificada();
        }
        if (estadoRota.mostrarDesafioFoto) {
          return const TelaDaGaleria(requiredForCurrentMonth: true);
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              TelaDeHoje(aoConfigurarPlano: _abrirPlanos),
              _abasVisitadas.contains(1)
                  ? const TelaDePlanos()
                  : const SizedBox.shrink(),
              _abasVisitadas.contains(2)
                  ? const TelaDeHistorico()
                  : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: NavigationBar(
              height: 72,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (indice) {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  _selectedIndex = indice;
                  _abasVisitadas.add(indice);
                });
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Hoje',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Semana',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: Icon(
                    Icons.insights,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Histórico',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
