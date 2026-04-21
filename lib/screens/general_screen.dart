// lib/screens/general_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../models/sensor_reading.dart';
import '../widgets/stat_card.dart';
import '../widgets/sensor_chart.dart';
import '../utils/app_theme.dart';

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
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
      await context.read<WebSocketService>().loadAllData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Calcula cuántas lecturas están en cada nivel de peligro
  Map<String, int> _getLevelDistribution(List<SensorReading> readings) {
    int safe = 0, warning = 0, danger = 0;
    for (final r in readings) {
      if (r.valor < 40) {
        safe++;
      } else if (r.valor < 70) {
        warning++;
      } else {
        danger++;
      }
    }
    return {'Normal': safe, 'Advertencia': warning, 'Peligro': danger};
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsAll;

    double? maxVal, minVal, avgVal;
    int totalReadings = readings.length;

    if (readings.isNotEmpty) {
      maxVal = readings.map((r) => r.valor).reduce((a, b) => a > b ? a : b);
      minVal = readings.map((r) => r.valor).reduce((a, b) => a < b ? a : b);
      avgVal = readings.map((r) => r.valor).reduce((a, b) => a + b) / readings.length;
    }

    final distribution = _getLevelDistribution(readings);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen General',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('Todos los datos históricos',
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
              // Estadísticas generales
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    label: 'Total Histórico',
                    value: totalReadings.toString(),
                    unit: 'registros',
                    color: AppTheme.accent,
                    icon: Icons.dataset_outlined,
                  ),
                  StatCard(
                    label: 'Promedio Global',
                    value: avgVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.show_chart,
                  ),
                  StatCard(
                    label: 'Pico Máximo',
                    value: maxVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo Global',
                    value: minVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Distribución de niveles
              if (readings.isNotEmpty)
                _buildDistributionCard(context, distribution, totalReadings),
              const SizedBox(height: 20),

              // Gráfico histórico (muestra los últimos 100 registros para no sobrecargar)
              SensorChart(
                readings: readings.take(100).toList().reversed.toList(),
                title: 'Historial de Lecturas (últimas 100)',
              ),
              const SizedBox(height: 20),

              // Información del primer y último registro
              if (readings.isNotEmpty) _buildFirstLastCard(context, readings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard(
      BuildContext context, Map<String, int> dist, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distribución de Niveles',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Porcentaje de tiempo en cada nivel',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),

            // Barra de distribución visual
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (dist['Normal']! > 0)
                    Flexible(
                      flex: dist['Normal']!,
                      child: Container(
                        height: 20,
                        color: AppTheme.safe,
                      ),
                    ),
                  if (dist['Advertencia']! > 0)
                    Flexible(
                      flex: dist['Advertencia']!,
                      child: Container(
                        height: 20,
                        color: AppTheme.warning,
                      ),
                    ),
                  if (dist['Peligro']! > 0)
                    Flexible(
                      flex: dist['Peligro']!,
                      child: Container(
                        height: 20,
                        color: AppTheme.danger,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  context,
                  'Normal',
                  dist['Normal']!,
                  total,
                  AppTheme.safe,
                ),
                _buildLegendItem(
                  context,
                  'Advertencia',
                  dist['Advertencia']!,
                  total,
                  AppTheme.warning,
                ),
                _buildLegendItem(
                  context,
                  'Peligro',
                  dist['Peligro']!,
                  total,
                  AppTheme.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$pct%',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '$count lecturas',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildFirstLastCard(
      BuildContext context, List<SensorReading> readings) {
    // Los datos vienen en DESC (más reciente primero)
    final first = readings.last;   // el más antiguo
    final last = readings.first;   // el más reciente

    String formatDate(DateTime dt) =>
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rango del Historial',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PRIMER REGISTRO',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(formatDate(first.timestamp),
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13)),
                      Text('${first.valor.toStringAsFixed(2)} ppm',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.textSecondary.withOpacity(0.3),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ÚLTIMO REGISTRO',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(formatDate(last.timestamp),
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13)),
                        Text('${last.valor.toStringAsFixed(2)} ppm',
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
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