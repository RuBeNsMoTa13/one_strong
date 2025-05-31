import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min, max;
import '../../../models/user.dart';
import '../../../models/workout_template.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _selectedPeriod = '1M';
  String _selectedExercise = '';
  final List<String> _periods = ['1S', '1M', '3M', '6M', '1A'];
  User? _user;
  bool _isLoading = true;
  List<FlSpot> _weightData = [];
  List<FlSpot> _exerciseData = [];
  List<WorkoutTemplate>? _workouts;
  double _minWeight = 0;
  double _maxWeight = 0;
  double _minExerciseWeight = 0;
  double _maxExerciseWeight = 0;
  Map<String, List<ExerciseProgress>> _exerciseHistory = {};
  Map<String, double> _personalRecords = {};

  @override
  void initState() {
    super.initState();
    // Configura o locale para português do Brasil
    Intl.defaultLocale = 'pt_BR';
    _loadUserData();
    _loadWorkoutData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        // Ordena o histórico por data
        user.weightHistory.sort((a, b) => a.date.compareTo(b.date));
        
        // Filtra os dados baseado no período selecionado
        final filteredHistory = _filterWeightHistory(user.weightHistory);
        
        // Converte para FlSpot
        final spots = _convertToSpots(filteredHistory);

        setState(() {
          _user = user;
          _weightData = spots;
          if (filteredHistory.isNotEmpty) {
            _minWeight = filteredHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
            _maxWeight = filteredHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[MetricsScreen] Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkoutData() async {
    try {
      final workouts = await DatabaseService.getWorkoutTemplates();
      
      // Processa o histórico de exercícios
      final history = <String, List<ExerciseProgress>>{};
      final records = <String, double>{};

      for (final workout in workouts.where((w) => w.createdBy == _user?.id)) {
        if (workout.lastWorkout != null) {
          for (final exercise in workout.exercises) {
            if (exercise.progressHistory.isNotEmpty) {
              history[exercise.exerciseId.toHexString()] = exercise.progressHistory;
              
              // Atualiza o recorde pessoal
              final maxWeight = exercise.progressHistory
                  .map((p) => p.weight)
                  .reduce((a, b) => max(a, b));
              
              if (!records.containsKey(exercise.exerciseId.toHexString()) ||
                  records[exercise.exerciseId.toHexString()]! < maxWeight) {
                records[exercise.exerciseId.toHexString()] = maxWeight;
              }
            }
          }
        }
      }

      setState(() {
        _workouts = workouts;
        _exerciseHistory = history;
        _personalRecords = records;
      });
    } catch (e) {
      print('[MetricsScreen] Erro ao carregar dados de treino: $e');
    }
  }

  List<WeightHistory> _filterWeightHistory(List<WeightHistory> history) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '1S':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1A':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }

    return history.where((record) => record.date.isAfter(startDate)).toList();
  }

  List<FlSpot> _convertToSpots(List<WeightHistory> history) {
    if (history.isEmpty) return [];

    final firstDate = history.first.date;
    return history.asMap().entries.map((entry) {
      // Usamos o índice como x para garantir pontos únicos
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  String _formatDateTime(DateTime date) {
    // Garante que a data está no fuso horário local
    final localDate = date.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(localDate);
  }

  String _formatDateForTitle(DateTime date) {
    // Formata a data de forma mais amigável
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes < 2) {
          return 'Agora há pouco';
        }
        return 'Há ${difference.inMinutes} minutos';
      }
      if (difference.inHours == 1) {
        return 'Há 1 hora';
      }
      return 'Há ${difference.inHours} horas';
    }

    if (difference.inDays == 1) {
      return 'Ontem ${DateFormat('HH:mm').format(localDate)}';
    }

    if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(localDate)} ${DateFormat('HH:mm').format(localDate)}';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(localDate);
  }

  List<BarChartGroupData> _generateWorkoutBarData() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return [];

    // Agrupa treinos por dia
    final Map<String, int> workoutsByDay = {};
    for (var workout in _user!.workoutHistory) {
      final date = DateFormat('dd/MM').format(workout.date);
      workoutsByDay[date] = (workoutsByDay[date] ?? 0) + 1;
    }

    // Pega os últimos 7 dias
    final List<BarChartGroupData> barData = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('dd/MM').format(date);
      final count = workoutsByDay[dateStr] ?? 0;
      
      barData.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barData;
  }

  List<BarChartGroupData> _generateStreakBarData() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return [];

    // Calcula a sequência para os últimos 30 dias
    final List<int> dailyStreak = [];
    final now = DateTime.now();
    var currentStreak = 0;

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final hasWorkout = _user!.workoutHistory.any((workout) {
        final workoutDate = DateTime(
          workout.date.year,
          workout.date.month,
          workout.date.day,
        );
        final targetDate = DateTime(
          date.year,
          date.month,
          date.day,
        );
        return workoutDate.isAtSameMomentAs(targetDate);
      });

      if (hasWorkout) {
        currentStreak++;
      } else {
        currentStreak = 0;
      }
      dailyStreak.add(currentStreak);
    }

    // Cria os dados do gráfico para os últimos 7 dias
    final List<BarChartGroupData> barData = [];
    for (int i = 0; i < 7; i++) {
      final streakValue = dailyStreak[dailyStreak.length - 7 + i];
      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: streakValue.toDouble(),
              color: Theme.of(context).colorScheme.secondary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barData;
  }

  List<BarChartGroupData> _generateWorkoutTimeBarData() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return [];

    // Pega os últimos 7 treinos
    final recentWorkouts = _user!.workoutHistory
        .map((w) => w.durationSeconds) // Converte para segundos
        .take(7)
        .toList()
        .reversed
        .toList();

    final List<BarChartGroupData> barData = [];
    for (int i = 0; i < recentWorkouts.length; i++) {
      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: recentWorkouts[i].toDouble(),
              color: Theme.of(context).colorScheme.tertiary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barData;
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

    final weightChange = _user!.weightHistory.length > 1
        ? _user!.weight - _user!.weightHistory.first.weight
        : 0.0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Peso'),
              Tab(text: 'Treinos'),
              Tab(text: 'Exercícios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba de Peso
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeightProgressCard(),
                  const SizedBox(height: 16),
                  _buildWeightSummaryCard(weightChange),
                  const SizedBox(height: 16),
                  _buildWeightHistoryCard(),
                ],
              ),
            ),
            
            // Aba de Treinos
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkoutStatsCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutFrequencyCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutTimeCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutStreakCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutHistoryCard(),
                ],
              ),
            ),

            // Aba de Exercícios
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseProgressCard(),
                  const SizedBox(height: 16),
                  _buildPersonalRecordsCard(),
                  const SizedBox(height: 16),
                  _buildExerciseHistoryCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso do Peso',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: _periods.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                        if (_user != null) {
                          final filteredHistory = _filterWeightHistory(_user!.weightHistory);
                          _weightData = _convertToSpots(filteredHistory);
                          if (filteredHistory.isNotEmpty) {
                            _minWeight = filteredHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
                            _maxWeight = filteredHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
                          }
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_weightData.isEmpty)
              const Center(
                child: Text('Nenhum dado disponível para o período selecionado'),
              )
            else
              SizedBox(
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
                            return Text(value.toStringAsFixed(1));
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _weightData.length) {
                              final date = _user!.weightHistory[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    DateFormat('dd/MM HH:mm').format(date.toLocal()),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _weightData,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: _minWeight - 1,
                    maxY: _maxWeight + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummaryCard(double weightChange) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              context,
              'Peso Inicial',
              _user!.weightHistory.isNotEmpty
                  ? '${_user!.weightHistory.first.weight} kg'
                  : '${_user!.weight} kg',
              Icons.monitor_weight_outlined,
            ),
            const Divider(),
            _buildStatItem(
              context,
              'Peso Atual',
              '${_user!.weight} kg',
              Icons.monitor_weight_outlined,
            ),
            const Divider(),
            _buildStatItem(
              context,
              'Variação',
              '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
              weightChange > 0 ? Icons.trending_up : Icons.trending_down,
              color: weightChange > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico Detalhado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_user!.weightHistory.isEmpty)
              const Center(
                child: Text('Nenhum registro de peso disponível'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _user!.weightHistory.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final record = _user!.weightHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Row(
                      children: [
                        Text('${record.weight} kg'),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateForTitle(record.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(_formatDateTime(record.date)),
                    trailing: Text(
                      index > 0
                          ? _calculateDifference(
                              record.weight,
                              _user!.weightHistory[index - 1].weight,
                            )
                          : '',
                      style: TextStyle(
                        color: index > 0
                            ? record.weight >
                                    _user!.weightHistory[index - 1].weight
                                ? Colors.red
                                : Colors.green
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo dos Treinos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              context,
              'Treinos Concluídos',
              '${_user!.workoutsCompleted}',
              Icons.fitness_center,
            ),
            const Divider(),
            _buildStatItem(
              context,
              'Dias Consecutivos',
              '${_user!.daysStreak}',
              Icons.local_fire_department,
              color: _user!.daysStreak > 0 ? Colors.orange : null,
            ),
            const Divider(),
            _buildStatItem(
              context,
              'Tempo Total',
              '${_calculateTotalWorkoutTime()}',
              Icons.timer,
            ),
            const Divider(),
            _buildStatItem(
              context,
              'Média por Treino',
              '${_calculateAverageWorkoutTime()}',
              Icons.av_timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutFrequencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treinos por Dia (Últimos 7 dias)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  barGroups: _generateWorkoutBarData(),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final date = now.subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo de Treino (Últimos 7 treinos)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxWorkoutTime(),
                  barGroups: _generateWorkoutTimeBarData(),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(_formatDuration(value.toInt()));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (_user?.workoutHistory == null || value.toInt() >= _user!.workoutHistory.length) {
                            return const Text('');
                          }
                          final workout = _user!.workoutHistory[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(workout.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStreakCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sequência de Dias (Últimos 7 dias)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barGroups: _generateStreakBarData(),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final date = now.subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHistoryCard() {
    if (_workouts == null || _workouts!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de Treinos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum treino registrado ainda'),
              ),
            ],
          ),
        ),
      );
    }

    // Filtra apenas treinos com sessão completa
    final completedWorkouts = _workouts!
        .where((w) => w.lastWorkout != null && w.lastWorkout!.isCompleted)
        .toList()
      ..sort((a, b) => b.lastWorkout!.startTime.compareTo(a.lastWorkout!.startTime));

    if (completedWorkouts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de Treinos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum treino concluído ainda'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico de Treinos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedWorkouts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final workout = completedWorkouts[index];
                final durationInSeconds = workout.lastWorkout!.getDurationInSeconds();
                
                return ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(workout.name),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      workout.lastWorkout!.startTime.toLocal(),
                    ),
                  ),
                  trailing: Text(
                    _formatDuration(durationInSeconds),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseProgressCard() {
    if (_workouts == null || _workouts!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso dos Exercícios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum treino registrado ainda'),
              ),
            ],
          ),
        ),
      );
    }

    // Coleta todos os exercícios únicos
    final exercises = <String, String>{};
    for (final workout in _workouts!) {
      for (final exercise in workout.exercises) {
        if (exercise.progressHistory.isNotEmpty) {
          exercises[exercise.exerciseId.toHexString()] = exercise.name;
        }
      }
    }

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso dos Exercícios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum exercício com histórico ainda'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso dos Exercícios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButton<String>(
                  value: _selectedExercise.isEmpty ? exercises.keys.first : _selectedExercise,
                  items: exercises.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateExerciseData(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_exerciseData.isEmpty)
              const Center(
                child: Text('Nenhum dado disponível para o exercício selecionado'),
              )
            else
              SizedBox(
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
                            return Text('${value.toStringAsFixed(1)} kg');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _exerciseData.length) {
                              final history = _exerciseHistory[_selectedExercise];
                              if (history != null && index < history.length) {
                                final date = history[index].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      DateFormat('dd/MM').format(date.toLocal()),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                );
                              }
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _exerciseData,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.secondary,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: _minExerciseWeight - 1,
                    maxY: _maxExerciseWeight + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsCard() {
    if (_personalRecords.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recordes Pessoais',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum recorde registrado ainda'),
              ),
            ],
          ),
        ),
      );
    }

    // Encontra o nome dos exercícios
    final exerciseNames = <String, String>{};
    for (final workout in _workouts!) {
      for (final exercise in workout.exercises) {
        exerciseNames[exercise.exerciseId.toHexString()] = exercise.name;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recordes Pessoais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _personalRecords.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final exerciseId = _personalRecords.keys.elementAt(index);
                final record = _personalRecords[exerciseId]!;
                final name = exerciseNames[exerciseId] ?? 'Exercício Desconhecido';
                
                return ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(name),
                  trailing: Text(
                    '${record.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseHistoryCard() {
    if (_exerciseHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de Exercícios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Nenhum histórico de exercício disponível'),
              ),
            ],
          ),
        ),
      );
    }

    // Encontra o nome dos exercícios
    final exerciseNames = <String, String>{};
    for (final workout in _workouts!) {
      for (final exercise in workout.exercises) {
        exerciseNames[exercise.exerciseId.toHexString()] = exercise.name;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico de Exercícios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exerciseHistory.length,
              itemBuilder: (context, index) {
                final exerciseId = _exerciseHistory.keys.elementAt(index);
                final history = _exerciseHistory[exerciseId]!;
                final name = exerciseNames[exerciseId] ?? 'Exercício Desconhecido';

                // Ordena o histórico por data, do mais recente para o mais antigo
                history.sort((a, b) => b.date.compareTo(a.date));

                return ExpansionTile(
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Último peso: ${history.first.weight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final record = history[i];
                        final previousWeight = i < history.length - 1 ? history[i + 1].weight : record.weight;
                        final weightDiff = record.weight - previousWeight;
                        final hasChange = i < history.length - 1;

                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Text(
                                '${record.weight.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasChange) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: weightDiff > 0
                                        ? Colors.green.withOpacity(0.1)
                                        : weightDiff < 0
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        weightDiff > 0
                                            ? Icons.arrow_upward
                                            : weightDiff < 0
                                                ? Icons.arrow_downward
                                                : Icons.remove,
                                        size: 16,
                                        color: weightDiff > 0
                                            ? Colors.green
                                            : weightDiff < 0
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg',
                                        style: TextStyle(
                                          color: weightDiff > 0
                                              ? Colors.green
                                              : weightDiff < 0
                                                  ? Colors.red
                                                  : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            _formatDateForTitle(record.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Text(
                            '${record.completedSets} séries × ${record.completedReps} reps',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _calculateTotalWorkoutTime() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return '0s';

    final totalSeconds = _user!.workoutHistory
        .map((w) => w.durationSeconds) // Já está em segundos
        .fold(0, (sum, duration) => sum + duration);

    return _formatDuration(totalSeconds);
  }

  String _calculateAverageWorkoutTime() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return '0s';

    final totalSeconds = _user!.workoutHistory
        .map((w) => w.durationSeconds) // Já está em segundos
        .fold(0, (sum, duration) => sum + duration);

    return _formatDuration(totalSeconds ~/ _user!.workoutHistory.length);
  }

  double _calculateMaxWorkoutTime() {
    if (_user?.workoutHistory == null || _user!.workoutHistory.isEmpty) return 3600; // 1 hora como padrão
    
    final maxTime = _user!.workoutHistory
        .map((w) => w.durationSeconds) // Já está em segundos
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    
    return maxTime + (maxTime * 0.1); // Adiciona 10% de margem
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _calculateDifference(double current, double previous) {
    final difference = current - previous;
    return '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)} kg';
  }

  void _updateExerciseData(String exerciseId) {
    setState(() {
      _selectedExercise = exerciseId;
      final history = _exerciseHistory[exerciseId] ?? [];
      
      if (history.isEmpty) {
        _exerciseData = [];
        _minExerciseWeight = 0;
        _maxExerciseWeight = 0;
        return;
      }

      history.sort((a, b) => a.date.compareTo(b.date));
      
      _exerciseData = history.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.weight);
      }).toList();

      _minExerciseWeight = history.map((e) => e.weight).reduce(min);
      _maxExerciseWeight = history.map((e) => e.weight).reduce(max);
    });
  }
} 