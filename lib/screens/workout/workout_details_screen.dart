import 'package:flutter/material.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  const WorkoutDetailsScreen({super.key});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  // TODO: Substituir por dados reais do banco
  final Map<String, dynamic> _mockWorkout = {
    'name': 'Treino A - Peito e Tríceps',
    'description': 'Foco em hipertrofia com exercícios compostos',
    'duration': 60,
    'difficulty': 'Intermediário',
    'exercises': [
      {
        'name': 'Supino Reto',
        'sets': 4,
        'reps': '12',
        'weight': 60,
        'restTime': 90,
        'notes': 'Manter escapulas retraídas',
        'isCompleted': false,
      },
      {
        'name': 'Supino Inclinado',
        'sets': 3,
        'reps': '12',
        'weight': 50,
        'restTime': 90,
        'notes': 'Ângulo do banco em 30°',
        'isCompleted': false,
      },
      {
        'name': 'Crucifixo na Polia',
        'sets': 3,
        'reps': '15',
        'weight': 15,
        'restTime': 60,
        'notes': 'Manter cotovelos levemente flexionados',
        'isCompleted': false,
      },
      {
        'name': 'Extensão de Tríceps na Polia',
        'sets': 4,
        'reps': '12-15',
        'weight': 25,
        'restTime': 60,
        'notes': 'Manter cotovelos junto ao corpo',
        'isCompleted': false,
      },
    ],
    'isCompleted': false,
    'isFavorite': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mockWorkout['name']),
        actions: [
          IconButton(
            icon: Icon(
              _mockWorkout['isFavorite'] ? Icons.favorite : Icons.favorite_border,
              color: _mockWorkout['isFavorite'] ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _mockWorkout['isFavorite'] = !_mockWorkout['isFavorite'];
              });
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Excluir'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              // TODO: Implementar ações
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descrição',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_mockWorkout['description']),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text('${_mockWorkout['duration']} min'),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text('${_mockWorkout['exercises'].length} exercícios'),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.speed,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(_mockWorkout['difficulty']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Exercícios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            ..._mockWorkout['exercises'].asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: exercise['isCompleted']
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(exercise['name']),
                    subtitle: Text(
                      '${exercise['sets']} séries x ${exercise['reps']} reps',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${exercise['weight']}kg',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          exercise['isCompleted']
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color:
                              exercise['isCompleted'] ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Descanso: ${exercise['restTime']}s',
                                ),
                              ],
                            ),
                            if (exercise['notes'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Observações:',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(exercise['notes']),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // TODO: Implementar edição do exercício
                                    },
                                    child: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      setState(() {
                                        exercise['isCompleted'] =
                                            !exercise['isCompleted'];
                                      });
                                    },
                                    child: Text(
                                      exercise['isCompleted']
                                          ? 'Desmarcar'
                                          : 'Concluir',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              // TODO: Implementar início do treino
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Treino'),
          ),
        ),
      ),
    );
  }
} 