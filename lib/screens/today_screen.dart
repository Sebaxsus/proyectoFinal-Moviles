// lib/screens/today_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/sensor_chart.dart';
import '../utils/app_theme.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Cargar datos al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<WebSocketService>().loadTodayData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsToday;

    // Calcular estadísticas del día
    double? maxVal, minVal, avgVal, lastVal;
    if (readings.isNotEmpty) {
      maxVal = readings.map((r) => r.valor).reduce((a, b) => a > b ? a : b);
      minVal = readings.map((r) => r.valor).reduce((a, b) => a < b ? a : b);
      avgVal = readings.map((r) => r.valor).reduce((a, b) => a + b) /
          readings.length;
      lastVal = readings.last.valor;
    }

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
            _buildHeader(context, lastVal),
            const SizedBox(height: 20),

            // Estado de carga o error
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_error != null)
              _buildErrorCard(context)
            else ...[
              // Tarjetas de estadísticas en cuadrícula 2x2
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  StatCard(
                    label: 'Último Registro',
                    value: lastVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.getLevelColor(lastVal ?? 0, 100),
                    icon: Icons.sensors,
                  ),
                  StatCard(
                    label: 'Promedio del Día',
                    value: avgVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.analytics_outlined,
                  ),
                  StatCard(
                    label: 'Máximo del Día',
                    value: maxVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.arrow_upward_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo del Día',
                    value: minVal?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gráfico de la línea de tiempo
              SensorChart(
                readings: readings,
                title: 'Lecturas de Hoy',
              ),
              const SizedBox(height: 20),

              // Tabla de últimas lecturas
              _buildRecentReadingsTable(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double? lastVal) {
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen del Día',
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(dateStr,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        // Indicador de nivel de gas
        if (lastVal != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  AppTheme.getLevelColor(lastVal, 100).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getLevelColor(lastVal, 100).withOpacity(0.5),
              ),
            ),
            child: Text(
              _getLevelText(lastVal),
              style: TextStyle(
                color: AppTheme.getLevelColor(lastVal, 100),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  String _getLevelText(double value) {
    if (value < 40) return '✓ Normal';
    if (value < 70) return '⚠ Advertencia';
    return '✗ Peligro';
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            Text('No se pudo obtener datos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error ?? 'Error desconocido',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
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

  Widget _buildRecentReadingsTable(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsToday.reversed.take(10).toList();

    if (readings.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimas Lecturas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Encabezado de la tabla
            Row(
              children: [
                Expanded(
                  child: Text('HORA',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      )),
                ),
                Expanded(
                  child: Text('VALOR (ppm)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      )),
                ),
                Expanded(
                  child: Text('ESTADO',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      )),
                ),
              ],
            ),
            const Divider(color: AppTheme.surface, height: 16),
            // Filas de datos
            ...readings.map((r) {
              final color = AppTheme.getLevelColor(r.valor, 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}:${r.timestamp.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.valor.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getLevelText(r.valor),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: color, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}