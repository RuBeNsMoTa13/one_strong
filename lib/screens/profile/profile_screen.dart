import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('[ProfileScreen] Erro ao carregar dados do usuário: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Implementar upload da imagem
    }
  }

  Future<void> _updateWeight() async {
    final TextEditingController weightController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Peso'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
            ],
            decoration: const InputDecoration(
              labelText: 'Novo Peso (kg)',
              hintText: 'Ex: 75.5',
              suffixText: 'kg',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o peso';
              }
              final weight = double.tryParse(value);
              if (weight == null) {
                return 'Peso inválido';
              }
              if (weight < 30 || weight > 300) {
                return 'Peso deve estar entre 30 e 300 kg';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newWeight = double.parse(weightController.text);
                final success = await DatabaseService.updateUserWeight(_user!.email, newWeight);
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadUserData(); // Recarrega os dados do usuário
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Peso atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao atualizar peso. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar dados do usuário'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Voltar para o login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: _pickImage,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _user!.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          context,
                          'Treinos\nConcluídos',
                          _user!.workoutsCompleted.toString(),
                          Icons.fitness_center,
                        ),
                        _buildStatCard(
                          context,
                          'Dias\nConsecutivos',
                          _user!.daysStreak.toString(),
                          Icons.local_fire_department,
                        ),
                        _buildStatCard(
                          context,
                          'Membro\nDesde',
                          '${_user!.joinedDate.day}/${_user!.joinedDate.month}/${_user!.joinedDate.year}',
                          Icons.calendar_today,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildInfoTile(
                    'Data de Nascimento',
                    '${_user!.birthDate.day}/${_user!.birthDate.month}/${_user!.birthDate.year}',
                    Icons.cake,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Gênero',
                    _user!.gender,
                    Icons.person_outline,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Altura',
                    '${_user!.height} cm',
                    Icons.height,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Peso Atual',
                    '${_user!.weight} kg',
                    Icons.monitor_weight_outlined,
                    onTap: _updateWeight,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Objetivo',
                    _user!.goal,
                    Icons.track_changes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
} 