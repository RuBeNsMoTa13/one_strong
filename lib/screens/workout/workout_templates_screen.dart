import 'package:flutter/material.dart';
import '../../models/workout_template.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';

class WorkoutTemplatesScreen extends StatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WorkoutTemplate> _presetTemplates = [];
  List<WorkoutTemplate> _userTemplates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final presets = await DatabaseService.getWorkoutTemplates(presetsOnly: true);
      final userTemplates = await DatabaseService.getWorkoutTemplates(
        presetsOnly: false,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _presetTemplates = presets;
          _userTemplates = userTemplates.where((t) => !t.isPreset).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichas de Treino'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pré-definidas'),
            Tab(text: 'Minhas Fichas'),
          ],
        ),
      ),
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
                        'Erro ao carregar fichas',
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTemplateList(_presetTemplates, isPredefined: true),
                    _buildTemplateList(_userTemplates),
                  ],
                ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.workoutNew).then((_) {
                  _loadTemplates();
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTemplateList(List<WorkoutTemplate> templates,
      {bool isPredefined = false}) {
    if (templates.isEmpty) {
      return Center(
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
              isPredefined
                  ? 'Nenhuma ficha pré-definida disponível'
                  : 'Você ainda não criou nenhuma ficha',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (!isPredefined) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.workoutNew).then((_) {
                    _loadTemplates();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar Nova Ficha'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.workoutDetails,
                arguments: template,
              ).then((_) {
                if (!isPredefined) {
                  _loadTemplates();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (template.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isPredefined)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.workoutEdit,
                              arguments: template,
                            ).then((_) {
                              _loadTemplates();
                            });
                          },
                        ),
                    ],
                  ),
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
    );
  }
} 