import 'sensor_reading.dart';

/// Nivel de riesgo basado en el valor del sensor.
enum GasLevel { normal, warning, danger }

extension GasLevelX on GasLevel {
  String get label => switch (this) {
        GasLevel.normal  => '✓ Normal',
        GasLevel.warning => '⚠ Advertencia',
        GasLevel.danger  => '✗ Peligro',
      };

  bool get isNormal  => this == GasLevel.normal;
  bool get isDanger  => this == GasLevel.danger;
}

class SensorStats {
  /// Todas las lecturas de las que se calcularon las stats.
  final List<SensorReading> readings;

  // Null safety: son null cuando readings está vacío.
  final double? max;
  final double? min;
  final double? avg;
  final double? last;
  final double? first;

  /// Cuántas lecturas hay en total.
  final int count;

  const SensorStats._({
    required this.readings,
    required this.max,
    required this.min,
    required this.avg,
    required this.last,
    required this.first,
    required this.count,
  });

  /// Factory que calcula todas las estadísticas en una sola pasada.
  factory SensorStats.from(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return SensorStats._(
        readings: readings,
        max: null, min: null, avg: null,
        last: null, first: null, count: 0,
      );
    }

    double maxV = readings.first.valor;
    double minV = readings.first.valor;
    double sum  = 0;

    for (final r in readings) {
      if (r.valor > maxV) maxV = r.valor;
      if (r.valor < minV) minV = r.valor;
      sum += r.valor;
    }

    return SensorStats._(
      readings: readings,
      max:   maxV,
      min:   minV,
      avg:   sum / readings.length,
      last:  readings.last.valor,
      first: readings.first.valor,
      count: readings.length,
    );
  }

  /// Stats vacías, útil como valor inicial antes de cargar datos.
  factory SensorStats.empty() => SensorStats.from([]);

  bool get isEmpty => readings.isEmpty;
  bool get isNotEmpty => readings.isNotEmpty;

  /// Nivel de riesgo de un valor dado.
  static GasLevel levelOf(double value) {
    if (value < 40) return GasLevel.normal;
    if (value < 70) return GasLevel.warning;
    return GasLevel.danger;
  }

  /// Nivel del último valor registrado.
  GasLevel get lastLevel => last != null ? levelOf(last!) : GasLevel.normal;

  /// Agrupa las lecturas por día → promedio por día.
  /// Útil para el gráfico de barras de MonthScreen.
  Map<int, double> get dailyAverages {
    final Map<int, List<double>> byDay = {};
    for (final r in readings) {
      byDay.putIfAbsent(r.timestamp.day, () => []).add(r.valor);
    }
    return byDay.map(
      (day, values) =>
          MapEntry(day, values.reduce((a, b) => a + b) / values.length),
    );
  }

  /// Cuántas lecturas caen en cada nivel de riesgo.
  Map<GasLevel, int> get levelDistribution {
    final dist = {
      GasLevel.normal:  0,
      GasLevel.warning: 0,
      GasLevel.danger:  0,
    };
    for (final r in readings) {
      dist[levelOf(r.valor)] = (dist[levelOf(r.valor)] ?? 0) + 1;
    }
    return dist;
  }

  @override
  String toString() =>
      'SensorStats(count: $count, max: $max, min: $min, avg: $avg)';
}