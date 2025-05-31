import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/database_service.dart';
import '../../models/workout_template.dart';
import '../../models/user.dart';
import '../../routes.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/auth_service.dart';

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
  Timer? _restTimer;
  Timer? _workoutTimer;
  Timer? _exerciseTimer;
  int _totalWorkoutTime = 0;
  int _currentExerciseTime = 0;
  final _weightController = TextEditingController();
  final _restTimeController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<WorkoutExerciseProgress> _exerciseProgress = [];
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioPlayer.setSource(AssetSource('sounds/timer-end.wav'));
    await _audioPlayer.setVolume(1.0);
  }

  void _loadInitialData() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    _weightController.text = exercise.weight?.toString() ?? '';
    _restTimeController.text = exercise.restTime.toString();
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _totalWorkoutTime = 0;
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalWorkoutTime++;
      });
    });
  }

  void _startExerciseTimer() {
    _exerciseTimer?.cancel();
    _currentExerciseTime = 0;
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentExerciseTime++;
      });
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _exerciseTimer?.cancel();
    
    if (_restTimeController.text.isNotEmpty) {
      setState(() {
        _remainingRestTime = int.parse(_restTimeController.text);
      });
    
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingRestTime > 0) {
            _remainingRestTime--;
          } else {
            timer.cancel();
            _startExerciseTimer(); // Reinicia o timer do exercício após o descanso
            _playTimerEndSound();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.timer_off_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text('Descanso finalizado! Próxima série.'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(8),
              ),
            );
          }
        });
      });
    }
  }

  Future<void> _playTimerEndSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.resume();
    } catch (e) {
      print('Erro ao reproduzir o som: $e');
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutStarted = true;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _workoutStartTime = DateTime.now();
      _loadInitialData();
      _startWorkoutTimer();
      _startExerciseTimer();
      _exerciseProgress.clear();
    });
  }

  void _nextSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    
    // Registra o progresso da série atual
    _recordSetProgress();
    
    if (_currentSet < exercise.sets) {
      setState(() {
        _currentSet++;
        _startRestTimer();
      });
    } else {
      // Marca o exercício como completo
      exercise.isCompleted = true;
      _nextExercise();
    }
  }

  void _recordSetProgress() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    
    // Procura o progresso do exercício atual ou cria um novo
    WorkoutExerciseProgress? progress = _exerciseProgress.firstWhere(
      (p) => p.exerciseId == exercise.exerciseId,
      orElse: () {
        final newProgress = WorkoutExerciseProgress(
          exerciseId: exercise.exerciseId,
          timestamp: DateTime.now(),
        );
        _exerciseProgress.add(newProgress);
        return newProgress;
      },
    );

    // Adiciona o progresso da série atual
    progress.sets.add(SetProgress(
      reps: int.tryParse(exercise.reps) ?? 0,
      weight: weight,
      isCompleted: true,
    ));

    // Atualiza o histórico de progresso do exercício
    exercise.progressHistory.add(ExerciseProgress(
      date: DateTime.now(),
      weight: weight,
      completedSets: _currentSet,
      completedReps: int.tryParse(exercise.reps) ?? 0,
    ));
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _loadInitialData();
        _startExerciseTimer(); // Inicia o timer do novo exercício
      });
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() async {
    final endTime = DateTime.now();
    setState(() {
      _isWorkoutStarted = false;
      _restTimer?.cancel();
      _exerciseTimer?.cancel();
      _workoutTimer?.cancel();
    });
    
    // Cria um novo template com a sessão atualizada
    final updatedWorkout = WorkoutTemplate(
      id: widget.workout.id,
      name: widget.workout.name,
      description: widget.workout.description,
      difficulty: widget.workout.difficulty,
      category: widget.workout.category,
      exercises: widget.workout.exercises,
      isPreset: widget.workout.isPreset,
      createdBy: widget.workout.createdBy,
      isFavorite: widget.workout.isFavorite,
      lastWorkout: WorkoutSession(
        startTime: _workoutStartTime ?? endTime.subtract(Duration(seconds: _totalWorkoutTime)),
        endTime: endTime,
        isCompleted: true,
        exerciseProgress: _exerciseProgress,
      ),
    );
    
    // Atualiza o template do treino
    await DatabaseService.updateWorkoutTemplate(updatedWorkout);

    // Atualiza as métricas do usuário
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      final today = DateTime(endTime.year, endTime.month, endTime.day);
      
      // Verifica se já houve treino hoje
      final hasWorkoutToday = user.workoutHistory.any((w) {
        final workoutDate = DateTime(w.date.year, w.date.month, w.date.day);
        return workoutDate.isAtSameMomentAs(today);
      });

      // Cria o registro do treino
      final workoutRecord = WorkoutHistory(
        date: endTime,
        workoutName: widget.workout.name,
        durationSeconds: _totalWorkoutTime,  // Salvando em segundos
        exercises: widget.workout.exercises.map((e) {
          final progress = _exerciseProgress.firstWhere(
            (p) => p.exerciseId == e.exerciseId,
            orElse: () => WorkoutExerciseProgress(
              exerciseId: e.exerciseId,
              timestamp: endTime,
            ),
          );
          
          return ExerciseRecord(
            name: e.name,
            sets: progress.sets.length,
            reps: int.tryParse(e.reps) ?? 0,
            weight: e.weight ?? 0.0,
          );
        }).toList(),
      );

      if (!hasWorkoutToday) {
        // Atualiza as estatísticas do usuário
        user.workoutsCompleted++;
        user.totalWorkoutMinutes += (_totalWorkoutTime / 60).ceil();  // Convertendo segundos para minutos
        user.workoutHistory.add(workoutRecord);

        // Atualiza a sequência de dias
        if (user.lastWorkoutDate != null) {
          final lastWorkoutDay = DateTime(
            user.lastWorkoutDate!.year,
            user.lastWorkoutDate!.month,
            user.lastWorkoutDate!.day,
          );
          
          final difference = today.difference(lastWorkoutDay).inDays;
          
          if (difference == 1) {
            // Treinou em dias consecutivos
            user.daysStreak++;
          } else if (difference > 1) {
            // Quebrou a sequência
            user.daysStreak = 1;
          }
        } else {
          // Primeiro treino
          user.daysStreak = 1;
        }

        user.lastWorkoutDate = endTime;
        
        // Salva as atualizações do usuário
        await DatabaseService.updateUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Parabéns! Treino finalizado em ${_formatDuration(_totalWorkoutTime)}!',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      } else {
        // Atualiza apenas o histórico e o tempo total
        user.workoutHistory.add(workoutRecord);
        user.totalWorkoutMinutes += (_totalWorkoutTime / 60).ceil();  // Convertendo segundos para minutos
        await DatabaseService.updateUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Você já completou um treino hoje! A sequência será atualizada apenas no próximo dia.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
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
    _restTimer?.cancel();
    _exerciseTimer?.cancel();
    _workoutTimer?.cancel();
    _weightController.dispose();
    _restTimeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isWorkoutStarted)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
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
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
        children: [
          if (_isWorkoutStarted) ...[
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tempo Total',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_totalWorkoutTime),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_remainingRestTime == 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Tempo do Exercício',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_run,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(_currentExerciseTime),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                  ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                    'Série $_currentSet de ${widget.workout.exercises[_currentExerciseIndex].sets}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                  ),
                  if (_remainingRestTime > 0) ...[
                    const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                    Text(
                                '$_remainingRestTime s',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ],
                  ),
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
                
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isCurrentExercise
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                  color: isCurrentExercise
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                            : Theme.of(context).colorScheme.surface,
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (exercise.imageUrl != null)
                              Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Image.asset(
                                      exercise.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Erro ao carregar imagem: $error');
                                        return Container(
                                          color: Colors.grey.shade50,
                                          padding: const EdgeInsets.all(32),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.grey.shade300,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Não foi possível carregar a imagem',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                              backgroundColor: isCurrentExercise
                                  ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                      radius: 20,
                              child: Text(
                                '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${exercise.sets} séries × ${exercise.reps} repetições',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (exercise.notes?.isNotEmpty == true) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              exercise.notes!,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                          decoration: InputDecoration(
                                  labelText: 'Peso (kg)',
                                            labelStyle: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber,
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber.shade400,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber.shade600,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            enabled: !_isWorkoutStarted || isCurrentExercise,
                                            prefixIcon: Icon(
                                              Icons.fitness_center,
                                              color: Colors.amber.shade600,
                                              size: 24,
                                            ),
                                ),
                                keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _restTimeController,
                                          decoration: InputDecoration(
                                  labelText: 'Descanso (s)',
                                            labelStyle: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber,
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber.shade400,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.amber.shade600,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            enabled: !_isWorkoutStarted || isCurrentExercise,
                                            prefixIcon: Icon(
                                              Icons.timer_outlined,
                                              color: Colors.amber.shade600,
                                              size: 24,
                                            ),
                                ),
                                keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!_isWorkoutStarted || isCurrentExercise) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () => _updateExerciseDetails(index),
                                        icon: const Icon(Icons.save_outlined),
                                        label: const Text('Salvar Alterações'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _isWorkoutStarted
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _nextSet,
                        icon: Icon(_currentSet < widget.workout.exercises[_currentExerciseIndex].sets
                            ? Icons.arrow_forward
                            : Icons.skip_next),
                        label: Text(
                          _currentSet < widget.workout.exercises[_currentExerciseIndex].sets
                            ? 'Próxima Série'
                              : 'Próximo Exercício',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'Iniciar Treino',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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