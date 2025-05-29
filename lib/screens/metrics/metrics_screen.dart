import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _selectedPeriod = '1M';
  final List<String> _periods = ['1S', '1M', '3M', '6M', '1A'];

  // TODO: Substituir por dados reais do banco
  final List<FlSpot> _weightData = [
    const FlSpot(0, 80),
    const FlSpot(1, 79.5),
    const FlSpot(2, 79.8),
    const FlSpot(3, 79.2),
    const FlSpot(4, 78.9),
    const FlSpot(5, 78.5),
    const FlSpot(6, 78.2),
  ];

  final List<FlSpot> _workoutData = [
    const FlSpot(0, 3),
    const FlSpot(1, 4),
    const FlSpot(2, 3),
    const FlSpot(3, 5),
    const FlSpot(4, 4),
    const FlSpot(5, 3),
    const FlSpot(6, 4),
  ];

  @override
  Widget build(BuildContext context) {
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
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                reservedSize: 30,
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
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
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
                      'Treinos por Semana',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
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
                                reservedSize: 30,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _workoutData.map((spot) {
                            return BarChartGroupData(
                              x: spot.x.toInt(),
                              barRods: [
                                BarChartRodData(
                                  toY: spot.y,
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
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
                      'Treinos Realizados',
                      '32',
                      Icons.fitness_center,
                    ),
                    const Divider(),
                    _buildStatItem(
                      context,
                      'Peso Atual',
                      '78.2 kg',
                      Icons.monitor_weight_outlined,
                    ),
                    const Divider(),
                    _buildStatItem(
                      context,
                      'Perda de Peso',
                      '-1.8 kg',
                      Icons.trending_down,
                      color: Colors.green,
                    ),
                    const Divider(),
                    _buildStatItem(
                      context,
                      'Meta de Peso',
                      '75.0 kg',
                      Icons.flag_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar adição de medidas
        },
        child: const Icon(Icons.add),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
} 