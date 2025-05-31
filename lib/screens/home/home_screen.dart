import 'package:flutter/material.dart';
import '../workout/workout_list_screen.dart';
import '../profile/profile_screen.dart';
import '../metrics/metrics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WorkoutListScreen(),
    const MetricsScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: 'Treinos',
    ),
    NavigationDestination(
      icon: Icon(Icons.insert_chart_outlined),
      selectedIcon: Icon(Icons.insert_chart),
      label: 'Métricas',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  String get _screenTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Meus Treinos';
      case 1:
        return 'Métricas';
      case 2:
        return 'Perfil';
      default:
        return '';
    }
  }

  List<Widget>? get _actions {
    switch (_selectedIndex) {
      case 0:
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar busca
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar mais filtros
            },
          ),
        ];
      case 2:
        return [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implementar tela de configurações
            },
          ),
        ];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_screenTitle),
          actions: _actions,
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _destinations,
        ),
      ),
    );
  }
} 