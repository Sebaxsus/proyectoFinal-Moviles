import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

// Modelo simple para una recomendación de seguridad
class SafetyTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;

  const SafetyTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  // Lista completa de recomendaciones de seguridad para gas natural
  static const List<SafetyTip> _tips = [
    // ---- DETECCIÓN ----
    SafetyTip(
      category: 'Detección',
      title: 'Detecta el olor a gas',
      description:
          'El gas natural tiene un olor característico similar al huevo podrido (mercaptano). Si lo percibes, actúa de inmediato: no encendas luces ni aparatos eléctricos.',
      icon: Icons.air,
      color: AppTheme.warning,
    ),
    SafetyTip(
      category: 'Detección',
      title: 'Revisa el sensor regularmente',
      description:
          'El sensor IoT monitorea los niveles de gas. Revisa el dashboard diariamente. Si el valor supera 70 ppm, considera ventilar el área y llamar a un técnico.',
      icon: Icons.sensors,
      color: AppTheme.accent,
    ),

    // ---- EMERGENCIA ----
    SafetyTip(
      category: 'Emergencia',
      title: 'Evacuación inmediata',
      description:
          'Si el sensor indica niveles peligrosos (>70 ppm), evacúa el inmueble. Deja las puertas abiertas para ventilar y llama a los bomberos desde afuera.',
      icon: Icons.exit_to_app,
      color: AppTheme.danger,
    ),
    SafetyTip(
      category: 'Emergencia',
      title: 'Cierra la llave de paso',
      description:
          'Aprende dónde está la llave de paso del gas y cómo cerrarla. En caso de emergencia, ciérrala antes de salir. No la abras sin la autorización de un técnico.',
      icon: Icons.settings_input_component,
      color: AppTheme.danger,
    ),
    SafetyTip(
      category: 'Emergencia',
      title: 'Nunca uses fuego para buscar una fuga',
      description:
          'Nunca uses encendedores, fósforos o llamas para detectar una fuga. Usa agua con jabón: si hay burbujas en la tubería, hay una fuga.',
      icon: Icons.local_fire_department,
      color: AppTheme.danger,
    ),

    // ---- PREVENCIÓN ----
    SafetyTip(
      category: 'Prevención',
      title: 'Ventilación adecuada',
      description:
          'Asegura que los espacios con electrodomésticos de gas tengan ventilación suficiente. Nunca obstruyas rejillas de ventilación.',
      icon: Icons.window_outlined,
      color: AppTheme.safe,
    ),
    SafetyTip(
      category: 'Prevención',
      title: 'Mantenimiento de instalaciones',
      description:
          'Realiza revisiones anuales de toda la instalación de gas por un técnico certificado. Las mangueras y conexiones deben reemplazarse cada 5 años.',
      icon: Icons.engineering,
      color: AppTheme.safe,
    ),
    SafetyTip(
      category: 'Prevención',
      title: 'No modifiques las instalaciones',
      description:
          'Nunca intentes reparar o modificar tuberías de gas por tu cuenta. Siempre contrata personal certificado por la empresa distribuidora de gas.',
      icon: Icons.do_not_disturb_alt,
      color: AppTheme.warning,
    ),

    // ---- COTIDIANO ----
    SafetyTip(
      category: 'Uso Cotidiano',
      title: 'Apaga los quemadores correctamente',
      description:
          'Verifica que todos los quemadores estén apagados al salir de casa. Una llama apagada incidentalmente puede liberar gas sin combustión.',
      icon: Icons.check_circle_outline,
      color: AppTheme.safe,
    ),
    SafetyTip(
      category: 'Uso Cotidiano',
      title: 'No dejes la estufa sin supervisión',
      description:
          'Nunca dejes la cocina sola cuando hay fuego encendido. El viento o líquidos pueden apagar la llama y generar acumulación de gas.',
      icon: Icons.remove_red_eye_outlined,
      color: AppTheme.warning,
    ),
    SafetyTip(
      category: 'Uso Cotidiano',
      title: 'Teléfonos de emergencia visibles',
      description:
          'Ten a la mano el número de la empresa distribuidora de gas y los bomberos. En Colombia: Bomberos 119, Línea de Emergencias 123.',
      icon: Icons.phone_in_talk,
      color: AppTheme.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WebSocketService>();

    // Nivel actual del sensor para mostrar alerta si es necesario
    final latestReadings = service.readingsToday;
    final currentLevel =
        latestReadings.isNotEmpty ? latestReadings.last.valor : null;

    // Agrupar tips por categoría
    final categories = _tips.map((t) => t.category).toSet().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seguridad',
              style: Theme.of(context).textTheme.headlineMedium),
          Text('Recomendaciones para gas natural',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // Alerta dinámica basada en el sensor
          if (currentLevel != null) _buildAlertBanner(context, currentLevel),
          const SizedBox(height: 8),

          // Niveles de referencia
          _buildLevelsCard(context),
          const SizedBox(height: 20),

          // Tips agrupados por categoría
          ...categories.map((category) {
            final categoryTips =
                _tips.where((t) => t.category == category).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                ...categoryTips.map((tip) => _buildTipCard(context, tip)),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, double level) {
    Color color;
    String message;
    IconData icon;

    if (level < 40) {
      color = AppTheme.safe;
      message = 'Nivel de gas normal. Todo en orden.';
      icon = Icons.check_circle;
    } else if (level < 70) {
      color = AppTheme.warning;
      message = 'Nivel de gas elevado. Revisa la ventilación del área.';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppTheme.danger;
      message =
          '¡NIVEL PELIGROSO! Ventila inmediatamente y considera evacuar.';
      icon = Icons.dangerous;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Actual: ${level.toStringAsFixed(2)} ppm',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: color.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveles de Referencia (ppm)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildLevelRow('0 – 40 ppm', 'Normal', AppTheme.safe,
                'Concentración segura para actividades cotidianas'),
            const Divider(color: AppTheme.primary, height: 16),
            _buildLevelRow('40 – 70 ppm', 'Advertencia', AppTheme.warning,
                'Requiere ventilación y revisión de instalaciones'),
            const Divider(color: AppTheme.primary, height: 16),
            _buildLevelRow('> 70 ppm', 'Peligro', AppTheme.danger,
                'Riesgo de explosión o intoxicación. Actuar de inmediato'),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRow(
      String range, String label, Color color, String desc) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(range,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(label,
                        style: TextStyle(color: color, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, SafetyTip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tip.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tip.icon, color: tip.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 4),
                  Text(tip.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}