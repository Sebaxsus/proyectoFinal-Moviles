// lib/screens/month_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/websocket_service.dart';
import '../models/sensor_reading.dart';
import '../widgets/stat_card.dart';
import '../widgets/sensor_chart.dart';
import '../utils/app_theme.dart';

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

  // Agrupa las lecturas por día y calcula el promedio diario
  Map<int, double> _getDailyAverages(List<SensorReading> readings) {
    final Map<int, List<double>> byDay = {};
    for (final r in readings) {
      byDay.putIfAbsent(r.timestamp.day, () => []).add(r.valor);
    }
    return byDay.map((day, values) =>
        MapEntry(day, values.reduce((a, b) => a + b) / values.length));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsMonth;

    double? maxVal, minVal, avgVal;
    int totalReadings = readings.length;

    if (readings.isNotEmpty) {
      maxVal = readings.map((r) => r.valor).reduce((a, b) => a > b ? a : b);
      minVal = readings.map((r) => r.valor).reduce((a, b) => a < b ? a : b);
      avgVal = readings.map((r) => r.valor).reduce((a, b) => a + b) /
          readings.length;
    }

    final now = DateTime.now();
    final months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

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
            Text('${months[now.month]} ${now.year}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_error != null)
              _buildErrorCard()
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
                    value: totalReadings.toString(),
                    unit: 'lecturas',
                    color: AppTheme.accent,
                    icon: Icons.storage_outlined,
                  ),
                  StatCard(
                    label: 'Promedio Mensual',
                    value: avgVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.analytics_outlined,
                  ),
                  StatCard(
                    label: 'Máximo Registrado',
                    value: maxVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.trending_up_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo Registrado',
                    value: minVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.trending_down_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gráfico de barras: promedio por día
              if (readings.isNotEmpty) _buildDailyBarChart(context, readings),
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

  Widget _buildDailyBarChart(BuildContext context, List<SensorReading> readings) {
    final dailyAverages = _getDailyAverages(readings);
    if (dailyAverages.isEmpty) return const SizedBox();

    final sortedDays = dailyAverages.keys.toList()..sort();
    final maxAvg = dailyAverages.values.reduce((a, b) => a > b ? a : b);

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
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.accent.withOpacity(0.1),
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
                        getTitlesWidget: (value, meta) {
                          final day = sortedDays[value.toInt()];
                          return Text(
                            day.toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: sortedDays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final avg = dailyAverages[day]!;
                    final color = AppTheme.getLevelColor(avg, 100);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: avg,
                          color: color,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = sortedDays[groupIndex];
                        return BarTooltipItem(
                          'Día $day\n${rod.toY.toStringAsFixed(2)} ppm',
                          const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                          ),
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

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            const Text('No se pudo obtener datos',
                style: TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}