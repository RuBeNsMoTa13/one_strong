import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Substituir por dados reais do banco
  final Map<String, dynamic> _mockUser = {
    'name': 'João Silva',
    'email': 'joao.silva@email.com',
    'birthDate': '15/03/1990',
    'gender': 'Masculino',
    'height': 175,
    'weight': 78.2,
    'goal': 'Hipertrofia',
    'workoutsCompleted': 32,
    'daysStreak': 5,
    'joinedDate': '01/01/2024',
  };

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Implementar upload da imagem
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implementar tela de configurações
            },
          ),
        ],
      ),
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
              _mockUser['name'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _mockUser['email'],
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
                          _mockUser['workoutsCompleted'].toString(),
                          Icons.fitness_center,
                        ),
                        _buildStatCard(
                          context,
                          'Dias\nConsecutivos',
                          _mockUser['daysStreak'].toString(),
                          Icons.local_fire_department,
                        ),
                        _buildStatCard(
                          context,
                          'Membro\nDesde',
                          _mockUser['joinedDate'],
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
                    _mockUser['birthDate'],
                    Icons.cake,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Gênero',
                    _mockUser['gender'],
                    Icons.person_outline,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Altura',
                    '${_mockUser['height']} cm',
                    Icons.height,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Peso Atual',
                    '${_mockUser['weight']} kg',
                    Icons.monitor_weight_outlined,
                  ),
                  const Divider(),
                  _buildInfoTile(
                    'Objetivo',
                    _mockUser['goal'],
                    Icons.track_changes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
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

  Widget _buildInfoTile(String label, String value, IconData icon) {
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
    );
  }
} 