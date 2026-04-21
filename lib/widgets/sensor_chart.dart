// lib/widgets/sensor_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_reading.dart';
import '../utils/app_theme.dart';

class SensorChart extends StatelessWidget {
  final List<SensorReading> readings;
  final String title;

  const SensorChart({
    super.key,
    required this.readings,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_outlined,
                    color: AppTheme.textSecondary, size: 40),
                const SizedBox(height: 8),
                Text('Sin datos disponibles',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    // Convertir lecturas a puntos del gráfico
    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.valor);
    }).toList();

    // Calcular el máximo para el eje Y
    final maxY = readings.map((r) => r.valor).reduce((a, b) => a > b ? a : b);
    final minY = readings.map((r) => r.valor).reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${readings.length} registros',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  // Fondo del gráfico
                  backgroundColor: Colors.transparent,

                  // Bordes del gráfico
                  borderData: FlBorderData(show: false),

                  // Cuadrícula
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.accent.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),

                  // Títulos de los ejes
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: readings.length > 10
                            ? (readings.length / 5).floorToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < readings.length) {
                            final time = readings[index].timestamp;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),

                  // La línea del gráfico
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppTheme.accent,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: readings.length < 20, // Solo puntos si hay pocos datos
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.accent,
                          strokeWidth: 1,
                          strokeColor: AppTheme.primary,
                        ),
                      ),
                      // Relleno debajo de la línea
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accent.withOpacity(0.3),
                            AppTheme.accent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Tooltip al tocar un punto
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => AppTheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < readings.length) {
                            final reading = readings[index];
                            return LineTooltipItem(
                              '${reading.valor.toStringAsFixed(2)} ppm\n',
                              const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${reading.timestamp.hour}:${reading.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
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