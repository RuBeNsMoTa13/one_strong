import 'package:flutter/material.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Em andamento', 'Concluídos', 'Favoritos'];

  // TODO: Substituir por dados reais do banco
  final List<Map<String, dynamic>> _mockWorkouts = [
    {
      'name': 'Treino A - Peito e Tríceps',
      'description': 'Foco em hipertrofia com exercícios compostos',
      'duration': 60,
      'difficulty': 'Intermediário',
      'exercises': 8,
      'isCompleted': false,
      'isFavorite': true,
    },
    {
      'name': 'Treino B - Costas e Bíceps',
      'description': 'Foco em força com exercícios básicos',
      'duration': 45,
      'difficulty': 'Avançado',
      'exercises': 6,
      'isCompleted': true,
      'isFavorite': false,
    },
    {
      'name': 'Treino C - Pernas',
      'description': 'Treino completo de membros inferiores',
      'duration': 75,
      'difficulty': 'Intermediário',
      'exercises': 10,
      'isCompleted': false,
      'isFavorite': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredWorkouts {
    if (_selectedFilter == 'Todos') return _mockWorkouts;
    if (_selectedFilter == 'Em andamento') {
      return _mockWorkouts.where((w) => !w['isCompleted']).toList();
    }
    if (_selectedFilter == 'Concluídos') {
      return _mockWorkouts.where((w) => w['isCompleted']).toList();
    }
    // Favoritos
    return _mockWorkouts.where((w) => w['isFavorite']).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredWorkouts.length,
              itemBuilder: (context, index) {
                final workout = _filteredWorkouts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/workout/details');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  workout['name'],
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  workout['isFavorite']
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: workout['isFavorite']
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () {
                                  // TODO: Implementar favoritar
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(workout['description']),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text('${workout['duration']} min'),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text('${workout['exercises']} exercícios'),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.speed,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(workout['difficulty']),
                            ],
                          ),
                          if (workout['isCompleted'])
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Concluído',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/workout/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 