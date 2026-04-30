import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

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

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsAll;

    print('Lecturas Obtenidas en General: ${(readings.isEmpty) ? 'No ha completado la promesa' : readings.last.timestamp}\nError?: ${_error}');

    final stats = SensorStats.from(readings);

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
              const LoadingBody(message: 'Cargando Historico...')
            else if (_error != null)
              ErrorCard(message: _error, onRetry: _loadData)
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
                    value: stats.count.toString(),
                    unit: 'registros',
                    color: AppTheme.accent,
                    icon: Icons.dataset_outlined,
                  ),
                  StatCard(
                    label: 'Promedio Global',
                    value: stats.avg?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.show_chart,
                  ),
                  StatCard(
                    label: 'Pico Máximo',
                    value: stats.max?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo Global',
                    value: stats.min?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Distribución de niveles
              if (stats.isNotEmpty) ...[
                _LevelDistributionCard(stats: stats),
                const SizedBox(height: 20),
              ],

              // Gráfico histórico (muestra los últimos 100 registros para no sobrecargar)
              SensorChart(
                readings: readings.take(100).toList().reversed.toList(),
                title: 'Historial de Lecturas (últimas 100)',
              ),
              const SizedBox(height: 20),

              // Información del primer y último registro
              if (stats.isNotEmpty) _RangeCard(stats: stats),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelDistributionCard extends StatelessWidget {
  final SensorStats stats;
 
  const _LevelDistributionCard({required this.stats});
 
  @override
  Widget build(BuildContext context) {
    final dist  = stats.levelDistribution;
    final total = stats.count;
 
    final normalCount  = dist[GasLevel.normal]  ?? 0;
    final warningCount = dist[GasLevel.warning] ?? 0;
    final dangerCount  = dist[GasLevel.danger]  ?? 0;
 
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
 
            // Barra proporcional
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (normalCount > 0)
                    Flexible(
                      flex: normalCount,
                      child: Container(height: 20, color: AppTheme.safe),
                    ),
                  if (warningCount > 0)
                    Flexible(
                      flex: warningCount,
                      child: Container(height: 20, color: AppTheme.warning),
                    ),
                  if (dangerCount > 0)
                    Flexible(
                      flex: dangerCount,
                      child: Container(height: 20, color: AppTheme.danger),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem('Normal',      normalCount,  total, AppTheme.safe),
                _LegendItem('Advertencia', warningCount, total, AppTheme.warning),
                _LegendItem('Peligro',     dangerCount,  total, AppTheme.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 
class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
 
  const _LegendItem(this.label, this.count, this.total, this.color);
 
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text('$pct%',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text('$count lecturas',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
 
class _RangeCard extends StatelessWidget {
  final SensorStats stats;
 
  const _RangeCard({required this.stats});
 
  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/'
      '${dt.month.toString().padLeft(2,'0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2,'0')}:'
      '${dt.minute.toString().padLeft(2,'0')}';
 
  @override
  Widget build(BuildContext context) {
    // readings vienen en DESC → first es el más reciente, last el más antiguo
    final oldest = stats.readings.last;
    final newest = stats.readings.first;
 
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
                Expanded(child: _RangeColumn(
                  label: 'PRIMER REGISTRO',
                  date: _fmt(oldest.timestamp),
                  value: oldest.valor,
                )),
                Container(
                  width: 1, height: 50,
                  color: AppTheme.textSecondary.withOpacity(0.3),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _RangeColumn(
                      label: 'ÚLTIMO REGISTRO',
                      date: _fmt(newest.timestamp),
                      value: newest.valor,
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
}
 
class _RangeColumn extends StatelessWidget {
  final String label;
  final String date;
  final double value;
 
  const _RangeColumn({
    required this.label,
    required this.date,
    required this.value,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(date,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        Text('${value.toStringAsFixed(2)} ppm',
            style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}