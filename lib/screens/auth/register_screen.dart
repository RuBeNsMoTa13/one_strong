import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Masculino';
  String _goal = 'Hipertrofia';
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final List<String> _goals = [
    'Hipertrofia',
    'Emagrecimento',
    'Força',
    'Resistência',
    'Saúde',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      print('[Register] Formulário inválido');
      return;
    }
    
    if (_birthDate == null) {
      print('[Register] Data de nascimento não selecionada');
      _showError('Por favor, selecione sua data de nascimento');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      print('[Register] Senhas não coincidem');
      _showError('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('\n[Register] Iniciando processo de registro...');
      print('[Register] Validando dados:');
      print('  Nome: ${_nameController.text}');
      print('  Email: ${_emailController.text}');
      print('  Data de Nascimento: $_birthDate');
      print('  Gênero: $_gender');
      print('  Altura: ${_heightController.text}');
      print('  Peso: ${_weightController.text}');
      print('  Objetivo: $_goal');

      // Primeiro, verifica se o e-mail já está em uso
      print('[Register] Verificando e-mail...');
      final existingUser = await DatabaseService.getUserByEmail(_emailController.text);
      if (existingUser != null) {
        print('[Register] E-mail já está em uso');
        _showError('Este e-mail já está em uso');
        return;
      }

      print('[Register] Criando objeto User...');
      final user = User(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text, // TODO: Implementar hash
        birthDate: _birthDate!,
        gender: _gender,
        height: double.parse(_heightController.text.replaceAll(',', '.')),
        weight: double.parse(_weightController.text.replaceAll(',', '.')),
        goal: _goal,
      );

      print('[Register] Tentando criar usuário no banco...');
      final success = await DatabaseService.createUser(user);
      
      if (!success) {
        print('[Register] Falha ao criar usuário no banco');
        _showError('Erro ao criar conta. Por favor, tente novamente.');
        return;
      }

      print('[Register] Usuário criado com sucesso. Salvando sessão...');
      // Fazer login após o cadastro
      await DatabaseService.saveUserSession(user);
      
      print('[Register] Redirecionando para home...');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, stackTrace) {
      print('[Register] Erro ao criar conta:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      _showError('Erro ao criar conta: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      locale: const Locale('pt', 'BR'),
    );

    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu e-mail';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                    ),
                  ),
                  obscureText: !_showConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                  value: _gender,
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
                      setState(() => _gender = value);
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
                  value: _goal,
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
                      setState(() => _goal = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Criar Conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 