import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool _isEditing = false;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para os campos editáveis
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _goalController;
  String _selectedGender = '';
  DateTime? _birthDate;

  final List<String> _goals = [
    'Hipertrofia',
    'Emagrecimento',
    'Força',
    'Resistência',
    'Saúde',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadUserData();
    _loadProfileImage();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _goalController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _user = user;
        _nameController.text = user?.name ?? '';
        _heightController.text = user?.height.toString() ?? '';
        _weightController.text = user?.weight.toString() ?? '';
        _goalController.text = user?.goal ?? '';
        _selectedGender = user?.gender ?? '';
        _birthDate = user?.birthDate;
        _isLoading = false;
      });
    } catch (e) {
      print('[ProfileScreen] Erro ao carregar dados do usuário: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profile_image.jpg');
      if (await file.exists()) {
        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      print('[ProfileScreen] Erro ao carregar imagem de perfil: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/profile_image.jpg');
        
        // Copia a imagem selecionada para o diretório do app
        await File(image.path).copy(file.path);
        
        setState(() {
          _imageFile = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('[ProfileScreen] Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar foto de perfil. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      locale: const Locale('pt', 'BR'),
    );

    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione sua data de nascimento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final updatedUser = User(
        id: _user!.id,
        name: _nameController.text,
        email: _user!.email,
        password: _user!.password,
        birthDate: _birthDate!,
        gender: _selectedGender,
        height: double.parse(_heightController.text.replaceAll(',', '.')),
        weight: double.parse(_weightController.text.replaceAll(',', '.')),
        goal: _goalController.text,
        joinedDate: _user!.joinedDate,
        weightHistory: _user!.weightHistory,
        workoutsCompleted: _user!.workoutsCompleted,
        daysStreak: _user!.daysStreak,
      );

      final success = await DatabaseService.updateUser(updatedUser);

      setState(() {
        _isLoading = false;
        if (success) {
          _user = updatedUser;
          _isEditing = false;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Perfil atualizado com sucesso!' : 'Erro ao atualizar perfil. Tente novamente.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar perfil. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeightChart() {
    if (_user == null || _user!.weightHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final weightData = _user!.weightHistory
      ..sort((a, b) => a.date.compareTo(b.date));

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < weightData.length) {
                    final date = weightData[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weightData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.weight);
              }).toList(),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
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
              const Text('Erro ao carregar dados'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Voltar para o login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _isEditing ? AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isEditing = false;
              _loadUserData();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ) : null,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.black54,
                                  )
                                : null,
                          ),
                          if (!_isEditing)
                            FloatingActionButton.small(
                              onPressed: _pickImage,
                              child: const Icon(Icons.camera_alt),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing) ...[
                      Text(
                        _user!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _user!.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu nome';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Informações Pessoais',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isEditing ? Icons.save : Icons.settings),
                          onPressed: () {
                            if (_isEditing) {
                              _saveProfile();
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_isEditing) ...[
                              InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Data de Nascimento',
                                    prefixIcon: Icon(Icons.cake),
                                  ),
                                  child: Text(
                                    _birthDate == null
                                        ? 'Selecione sua data de nascimento'
                                        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                                    style: _birthDate == null 
                                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor)
                                        : Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Gênero',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Masculino',
                                    child: Text('Masculino'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Feminino',
                                    child: Text('Feminino'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Outro',
                                    child: Text('Outro'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedGender = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Altura (cm)',
                                        prefixIcon: Icon(Icons.height),
                                        hintText: 'Ex: 175.5',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Insira sua altura';
                                        }
                                        final height = double.tryParse(value.replaceAll(',', '.'));
                                        if (height == null || height < 30 || height > 250) {
                                          return 'Altura inválida';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (value.contains(',')) {
                                          _heightController.text = value.replaceAll(',', '.');
                                          _heightController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: _heightController.text.length),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Peso (kg)',
                                        prefixIcon: Icon(Icons.monitor_weight),
                                        hintText: 'Ex: 75.5',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Insira seu peso';
                                        }
                                        final weight = double.tryParse(value.replaceAll(',', '.'));
                                        if (weight == null || weight < 30 || weight > 300) {
                                          return 'Peso inválido';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (value.contains(',')) {
                                          _weightController.text = value.replaceAll(',', '.');
                                          _weightController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: _weightController.text.length),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _goalController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Objetivo',
                                  prefixIcon: Icon(Icons.track_changes),
                                ),
                                items: _goals.map((goal) {
                                  return DropdownMenuItem(
                                    value: goal,
                                    child: Text(goal),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _goalController.text = value);
                                  }
                                },
                              ),
                            ] else ...[
                              _buildInfoTile('Data de Nascimento', 
                                '${_user!.birthDate.day.toString().padLeft(2, '0')}/${_user!.birthDate.month.toString().padLeft(2, '0')}/${_user!.birthDate.year}',
                                Icons.cake),
                              const Divider(),
                              _buildInfoTile('Gênero', _user!.gender, Icons.person_outline),
                              const Divider(),
                              _buildInfoTile('Altura', '${_user!.height} cm', Icons.height),
                              const Divider(),
                              _buildInfoTile('Peso', '${_user!.weight} kg', Icons.monitor_weight_outlined),
                              const Divider(),
                              _buildInfoTile('Objetivo', _user!.goal, Icons.track_changes),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Estatísticas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            if (_user!.weightHistory.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Histórico de Peso',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 16),
                              _buildWeightChart(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await AuthService.logout();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, AppRoutes.login);
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sair'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
                fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }
} 