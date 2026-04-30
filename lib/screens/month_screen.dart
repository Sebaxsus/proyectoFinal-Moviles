import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gas_monitor/gas_monitor.dart'; // BARREL FILE

class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  static const _months = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<WebSocketService>().loadMonthData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsMonth;

    final stats = SensorStats.from(readings);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Text('Resumen del Mes',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('${_months[now.month]} ${now.year}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            if (_isLoading)
              const LoadingBody(message: 'Cargando lecturas del mes...')
            else if (_error != null)
              ErrorCard(message: _error, onRetry: _loadData)
            else ...[
              // Estadísticas del mes en grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    label: 'Total de Registros',
                    value: stats.count.toString(),
                    unit: 'lecturas',
                    color: AppTheme.accent,
                    icon: Icons.storage_outlined,
                  ),
                  StatCard(
                    label: 'Promedio Mensual',
                    value: stats.avg?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.analytics_outlined,
                  ),
                  StatCard(
                    label: 'Máximo Registrado',
                    value: stats.max?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.trending_up_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo Registrado',
                    value: stats.min?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.trending_down_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gráfico de barras: promedio por día
              if (stats.isNotEmpty) _DailyBarChart(dailyAverages: stats.dailyAverages),
              const SizedBox(height: 20),

              // Gráfico de línea completo del mes
              SensorChart(
                readings: readings,
                title: 'Todas las Lecturas del Mes',
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _DailyBarChart extends StatelessWidget {
  final Map<int, double> dailyAverages;
 
  const _DailyBarChart({required this.dailyAverages});
 
  @override
  Widget build(BuildContext context) {
    if (dailyAverages.isEmpty) return const SizedBox();
 
    final sortedDays = dailyAverages.keys.toList()..sort();
 
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promedio Diario del Mes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Valor promedio por día',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  backgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0x1A00D4AA),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedDays.length) {
                            return const SizedBox();
                          }
                          return Text(
                            sortedDays[idx].toString(),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: sortedDays.asMap().entries.map((e) {
                    final avg   = dailyAverages[e.value]!;
                    final color = AppTheme.getLevelColor(avg, 100);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: avg,
                          color: color,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.surface,
                      getTooltipItem: (group, groupIndex, rod, _) {
                        final day = sortedDays[groupIndex];
                        return BarTooltipItem(
                          'Día $day\n${rod.toY.toStringAsFixed(2)} ppm',
                          const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}