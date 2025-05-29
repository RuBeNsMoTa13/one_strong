import 'package:flutter/material.dart';
import '../../models/workout_template.dart';
import '../../services/database_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Pegar o userId do usuário logado
      final presets = await DatabaseService.getWorkoutTemplates(presetsOnly: true);
      final userTemplates = await DatabaseService.getWorkoutTemplates(
        presetsOnly: false,
        // userId: currentUser.id,
      );

      setState(() {
        _presetTemplates = presets;
        _userTemplates = userTemplates
            .where((template) => !template.isPreset)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // TODO: Mostrar erro ao usuário
      setState(() => _isLoading = false);
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplateList(_presetTemplates, isPredefined: true),
                _buildTemplateList(_userTemplates),
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
                  Navigator.pushNamed(context, '/workout/new');
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
              // TODO: Implementar visualização/edição do template
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
                            // TODO: Implementar ações de editar/excluir
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