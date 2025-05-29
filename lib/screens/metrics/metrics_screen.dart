import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _selectedPeriod = '1M';
  final List<String> _periods = ['1S', '1M', '3M', '6M', '1A'];
  User? _user;
  bool _isLoading = true;
  List<FlSpot> _weightData = [];
  double _minWeight = 0;
  double _maxWeight = 0;

  @override
  void initState() {
    super.initState();
    // Configura o locale para português do Brasil
    Intl.defaultLocale = 'pt_BR';
    _loadUserData();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
            ),
            const SizedBox(height: 16),
            Card(
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
            ),
            Card(
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
            ),
          ],
        ),
      ),
    );
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
} 