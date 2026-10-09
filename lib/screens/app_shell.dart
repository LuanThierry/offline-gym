import 'package:flutter/material.dart';

import 'historico_screen.dart';
import 'hoje_screen.dart';
import 'planos_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _openPlans() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          HojeScreen(onConfigurePlan: _openPlans),
          const PlanosScreen(),
          const HistoricoScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: const Color(0xFFB2BEC3),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Hoje',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Planos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.analytics),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
