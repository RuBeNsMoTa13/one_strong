import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../models/workout_template.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class WorkoutFormScreen extends StatefulWidget {
  final WorkoutTemplate? template;
  
  const WorkoutFormScreen({
    super.key,
    this.template,
  });

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  String _selectedDifficulty = 'Intermediário';
  final List<WorkoutExerciseTemplate> _exercises = [];
  bool _isLoading = false;

  final List<String> _difficulties = [
    'Iniciante',
    'Intermediário',
    'Avançado',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _categoryController.text = widget.template!.category;
      _selectedDifficulty = widget.template!.difficulty;
      _exercises.addAll(widget.template!.exercises);
    }
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExerciseFormSheet(
        onSave: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
        },
      ),
    );
  }

  void _editExercise(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExerciseFormSheet(
        exercise: _exercises[index],
        onSave: (exercise) {
          setState(() {
            _exercises[index] = exercise;
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um exercício'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final template = WorkoutTemplate(
        id: widget.template?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        difficulty: _selectedDifficulty,
        category: _categoryController.text,
        exercises: _exercises,
        isPreset: false,
        createdBy: userId,
      );

      if (widget.template != null) {
        await DatabaseService.updateWorkoutTemplate(template);
      } else {
        await DatabaseService.saveWorkoutTemplate(template);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar treino: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Nova Ficha' : 'Editar Ficha'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Ficha',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Dificuldade',
                              prefixIcon: Icon(Icons.speed),
                            ),
                            items: _difficulties
                                .map((difficulty) => DropdownMenuItem(
                                      value: difficulty,
                                      child: Text(difficulty),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDifficulty = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercícios',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        FilledButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_exercises.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum exercício adicionado',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Clique no botão acima para adicionar',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return Card(
                            key: ValueKey(exercise),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(exercise.name),
                              subtitle: Text(
                                '${exercise.sets} séries x ${exercise.reps} reps',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editExercise(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeExercise(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text('Salvar Treino'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseFormSheet extends StatefulWidget {
  final WorkoutExerciseTemplate? exercise;
  final Function(WorkoutExerciseTemplate) onSave;

  const _ExerciseFormSheet({
    this.exercise,
    required this.onSave,
  });

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _restTimeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _setsController.text = widget.exercise!.sets.toString();
      _repsController.text = widget.exercise!.reps;
      _weightController.text = widget.exercise!.weight?.toString() ?? '';
      _restTimeController.text = widget.exercise!.restTime.toString();
      _notesController.text = widget.exercise!.notes ?? '';
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = WorkoutExerciseTemplate(
      exerciseId: widget.exercise?.exerciseId ?? mongo.ObjectId(),
      name: _nameController.text,
      sets: int.parse(_setsController.text),
      reps: _repsController.text,
      weight: double.tryParse(_weightController.text),
      restTime: int.parse(_restTimeController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.exercise == null
                  ? 'Adicionar Exercício'
                  : 'Editar Exercício',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Exercício',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Séries',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      final sets = int.tryParse(value);
                      if (sets == null || sets <= 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Repetições',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _restTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Descanso (s)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      final time = int.tryParse(value);
                      if (time == null || time <= 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _handleSave,
              child: const Text('Salvar Exercício'),
            ),
          ],
        ),
      ),
    );
  }
} 