import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart'; // BARREL FILE

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
    print('Llamo loadData');
    try {
      await context.read<WebSocketService>().loadTodayData();
    } catch (e) {
      print('LoadData Fallo ${e}');
      setState(() => _error = e.toString());
    } finally {
      print('LoadData termino!');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();
    final readings = service.readingsToday;
    print('Lecturas Obtenidas en Today: ${readings}\nError?: ${_error}');

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
            // ---- Encabezado ----
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen del Día',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        '${now.day.toString().padLeft(2,'0')}/'
                        '${now.month.toString().padLeft(2,'0')}/'
                        '${now.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (stats.last != null) LevelBadge.fromValue(stats.last!),
              ],
            ),
            const SizedBox(height: 20),
 
            // ---- Estado ----
            if (_isLoading)
              const LoadingBody(message: 'Cargando lecturas de hoy...')
            else if (_error != null)
              ErrorCard(message: _error, onRetry: _loadData)
            else ...[
              // ---- Grid de estadísticas ----
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
                    value: stats.last?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.getLevelColor(stats.last ?? 0, 100),
                    icon: Icons.sensors,
                  ),
                  StatCard(
                    label: 'Promedio del Día',
                    value: stats.avg?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.accent,
                    icon: Icons.analytics_outlined,
                  ),
                  StatCard(
                    label: 'Máximo del Día',
                    value: stats.max?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.danger,
                    icon: Icons.arrow_upward_rounded,
                  ),
                  StatCard(
                    label: 'Mínimo del Día',
                    value: stats.min?.toStringAsFixed(2) ?? '--',
                    unit: 'ppm',
                    color: AppTheme.safe,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
 
              // ---- Gráfico ----
              SensorChart(readings: readings, title: 'Lecturas de Hoy'),
              const SizedBox(height: 20),
 
              // ---- Tabla de últimas lecturas ----
              if (readings.isNotEmpty)
                _RecentReadingsTable(readings: readings),
            ],
          ],
        ),
      ),
    );
  }

}

class _RecentReadingsTable extends StatelessWidget {
  final List<SensorReading> readings;
 
  const _RecentReadingsTable({required this.readings});
 
  String _levelText(double v) {
    if (v < 40) return '✓ Normal';
    if (v < 70) return '⚠ Advertencia';
    return '✗ Peligro';
  }
 
  @override
  Widget build(BuildContext context) {
    final recent = readings.reversed.take(10).toList();
 
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimas Lecturas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: _TableHeader('HORA')),
                Expanded(
                    child: _TableHeader('VALOR (ppm)', align: TextAlign.right)),
                Expanded(
                    child: _TableHeader('ESTADO', align: TextAlign.right)),
              ],
            ),
            const Divider(color: AppTheme.surface, height: 16),
            ...recent.map((r) {
              final color = AppTheme.getLevelColor(r.valor, 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.timestamp.hour.toString().padLeft(2,'0')}:'
                        '${r.timestamp.minute.toString().padLeft(2,'0')}:'
                        '${r.timestamp.second.toString().padLeft(2,'0')}',
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
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _levelText(r.valor),
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
 
class _TableHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
 
  const _TableHeader(this.text, {this.align = TextAlign.left});
 
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}