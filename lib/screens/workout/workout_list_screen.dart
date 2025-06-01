import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../models/workout_template.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Em andamento', 'Concluídos', 'Favoritos'];
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;
  mongo.ObjectId? _userId;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      print('\n[WorkoutListScreen] Inicializando tela...');
      final userId = await AuthService.getCurrentUserId();
      
      if (userId == null) {
        print('[WorkoutListScreen] Usuário não autenticado');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      setState(() {
        _userId = userId;
      });

      await _loadTemplates();
    } catch (e) {
      print('[WorkoutListScreen] Erro na inicialização: $e');
      setState(() {
        _error = 'Erro ao inicializar a tela';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTemplates() async {
    if (_userId == null) {
      print('[WorkoutListScreen] Tentativa de carregar treinos sem usuário');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('\n[WorkoutListScreen] Carregando treinos do usuário: $_userId');
      
      // Primeiro carrega os treinos do usuário
      final userTemplates = await DatabaseService.getWorkoutTemplates(
        userId: _userId!,
        presetsOnly: false,
      );

      print('[WorkoutListScreen] Treinos do usuário carregados: ${userTemplates.length}');
      
      // Depois carrega os treinos predefinidos
      final presetTemplates = await DatabaseService.getWorkoutTemplates(
        presetsOnly: true,
      );

      print('[WorkoutListScreen] Treinos predefinidos carregados: ${presetTemplates.length}');

      // Combina os dois conjuntos de treinos
      final allTemplates = [...userTemplates, ...presetTemplates];
      print('[WorkoutListScreen] Total de treinos carregados: ${allTemplates.length}');

      if (mounted) {
        setState(() {
          _templates = allTemplates;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[WorkoutListScreen] Erro ao carregar treinos: $e');
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar seus treinos';
          _isLoading = false;
        });
      }
    }
  }

  List<WorkoutTemplate> get _filteredWorkouts {
    if (_templates.isEmpty) return [];

    switch (_selectedFilter) {
      case 'Em andamento':
        return _templates.where((template) => 
          template.lastWorkout != null && !template.lastWorkout!.isCompleted).toList();
      case 'Concluídos':
        return _templates.where((template) => 
          template.lastWorkout != null && template.lastWorkout!.isCompleted).toList();
      case 'Favoritos':
        return _templates.where((template) => template.isFavorite).toList();
      default:
        return _templates;
    }
  }

  Future<void> _toggleFavorite(WorkoutTemplate template) async {
    try {
      print('[WorkoutListScreen] Alternando favorito para treino: ${template.id}');
      final success = await DatabaseService.toggleWorkoutFavorite(template.id);
      
      if (success) {
        await _loadTemplates();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar favorito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[WorkoutListScreen] Erro ao alternar favorito: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar favorito'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteWorkoutTemplate(WorkoutTemplate template) async {
    try {
      // Mostra um diálogo de confirmação
      final bool? confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Tem certeza que deseja excluir este treino?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      print('[WorkoutListScreen] Deletando treino: ${template.id}');
      final success = await DatabaseService.deleteWorkoutTemplate(template.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino excluído com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadTemplates();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir o treino'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[WorkoutListScreen] Erro ao deletar treino: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir o treino'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar treinos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loadTemplates,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                      child: _filteredWorkouts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _templates.isEmpty
                                        ? 'Você ainda não tem nenhum treino'
                                        : 'Nenhum treino encontrado para o filtro selecionado',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, AppRoutes.workoutNew)
                                          .then((_) => _loadTemplates());
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Criar Novo Treino'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTemplates,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredWorkouts.length,
                                itemBuilder: (context, index) {
                                  final template = _filteredWorkouts[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.workoutDetails,
                                          arguments: template,
                                        ).then((_) => _loadTemplates());
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
                                                    template.name,
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    template.isFavorite
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: template.isFavorite
                                                        ? Colors.red
                                                        : null,
                                                  ),
                                                  onPressed: () => _toggleFavorite(template),
                                                ),                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes.workoutEdit,
                                                      arguments: template,
                                                    ).then((_) => _loadTemplates());
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline),
                                                  color: Colors.red,
                                                  onPressed: () => _deleteWorkoutTemplate(template),
                                                ),
                                              ],
                                            ),
                                            if (template.description.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(template.description),
                                            ],
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.fitness_center,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text('${template.exercises.length} exercícios'),
                                                const SizedBox(width: 16),
                                                Icon(
                                                  Icons.speed,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(template.difficulty),
                                                const SizedBox(width: 16),
                                                Icon(
                                                  Icons.category,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(template.category),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.workoutNew)
              .then((_) => _loadTemplates());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}