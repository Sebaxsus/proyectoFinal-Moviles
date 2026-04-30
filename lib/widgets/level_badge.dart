import 'package:flutter/material.dart';

import 'package:gas_monitor/gas_monitor.dart';

// Píldora de color que indica el nivel de riesgo del gas.
class LevelBadge extends StatelessWidget {
  final GasLevel level;

  const LevelBadge({super.key, required this.level});

  /// Constructor de conveniencia que acepta un valor directo.
  factory LevelBadge.fromValue(double value) {
    return LevelBadge(level: SensorStats.levelOf(value));
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  static Color _colorOf(GasLevel level) => switch (level) {
        GasLevel.normal  => AppTheme.safe,
        GasLevel.warning => AppTheme.warning,
        GasLevel.danger  => AppTheme.danger,
      };
}