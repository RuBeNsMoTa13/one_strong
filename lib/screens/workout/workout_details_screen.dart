import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/database_service.dart';
import '../../models/workout_template.dart';
import '../../routes.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final WorkoutTemplate workout;
  
  const WorkoutDetailsScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _isWorkoutStarted = false;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _remainingRestTime = 0;
  Timer? _timer;
  final _weightController = TextEditingController();
  final _restTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    _weightController.text = exercise.weight?.toString() ?? '';
    _restTimeController.text = exercise.restTime.toString();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingRestTime = int.parse(_restTimeController.text);
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingRestTime > 0) {
          _remainingRestTime--;
        } else {
          timer.cancel();
          // Notificar usuário que o descanso acabou
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Descanso finalizado! Próxima série.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    });
  }

  void _nextSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    if (_currentSet < exercise.sets) {
      setState(() {
        _currentSet++;
        _startTimer();
      });
    } else {
      _nextExercise();
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _loadInitialData();
      });
    } else {
      // Treino finalizado
      setState(() {
        _isWorkoutStarted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parabéns! Treino finalizado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutStarted = true;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _loadInitialData();
    });
  }

  Future<void> _updateExerciseDetails(int index) async {
    final exercise = widget.workout.exercises[index];
    exercise.weight = double.tryParse(_weightController.text);
    exercise.restTime = int.parse(_restTimeController.text);
    
    await DatabaseService.updateWorkoutTemplate(widget.workout);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalhes do exercício atualizados!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weightController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          if (!_isWorkoutStarted)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.workoutEdit,
                  arguments: widget.workout,
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isWorkoutStarted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Text(
                    'Exercício ${_currentExerciseIndex + 1} de ${widget.workout.exercises.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Série $_currentSet de ${widget.workout.exercises[_currentExerciseIndex].sets}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_remainingRestTime > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Descanso: $_remainingRestTime s',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.workout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.workout.exercises[index];
                final isCurrentExercise = _isWorkoutStarted && index == _currentExerciseIndex;
                
                return Card(
                  color: isCurrentExercise
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exercise.imageUrl != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  exercise.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Erro ao carregar imagem: $error');
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey.shade400,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Erro ao carregar imagem',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCurrentExercise
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise.sets} séries x ${exercise.reps} reps',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (exercise.notes?.isNotEmpty == true) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              exercise.notes!,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: 'Peso (kg)',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: isCurrentExercise ? Colors.white : null,
                                ),
                                keyboardType: TextInputType.number,
                                enabled: !_isWorkoutStarted || isCurrentExercise,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _restTimeController,
                                decoration: InputDecoration(
                                  labelText: 'Descanso (s)',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: isCurrentExercise ? Colors.white : null,
                                ),
                                keyboardType: TextInputType.number,
                                enabled: !_isWorkoutStarted || isCurrentExercise,
                              ),
                            ),
                          ],
                        ),
                        if (!_isWorkoutStarted || isCurrentExercise) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _updateExerciseDetails(index),
                                  icon: const Icon(Icons.save),
                                  label: const Text('Salvar Alterações'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isWorkoutStarted
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _nextSet,
                        child: Text(_currentSet < widget.workout.exercises[_currentExerciseIndex].sets
                            ? 'Próxima Série'
                            : 'Próximo Exercício'),
                      ),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Treino'),
                ),
        ),
      ),
    );
  }

  Widget _buildExerciseDetails(WorkoutExerciseTemplate exercise) {
    return Column(
      children: [
        if (exercise.imageUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                exercise.imageUrl!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Text(
          exercise.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        // ... existing code ...
      ],
    );
  }
} 