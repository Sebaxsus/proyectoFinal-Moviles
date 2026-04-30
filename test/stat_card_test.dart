// PRUEBA DE WIDGET 5 — StatCard
// Verifica que el widget reutilizable muestra los datos correctamente
// y que cumple null safety (no acepta valores nulos en sus campos).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gas_monitor/gas_monitor.dart';

/// Helper mínimo para renderizar StatCard en tests.
/// StatCard es un widget "puro" (no necesita Provider).
Widget buildCard({
  required String label,
  required String value,
  required String unit,
  required Color color,
  required IconData icon,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: StatCard(
        label: label,
        value: value,
        unit: unit,
        color: color,
        icon: icon,
      ),
    ),
  );
}

void main() {
  group('StatCard — prueba de widget', () {
    // ----------------------------------------------------------------
    // 5a. Muestra el valor y la unidad correctamente
    // ----------------------------------------------------------------
    testWidgets('muestra el valor numérico y la unidad', (tester) async {
      await tester.pumpWidget(buildCard(
        label: 'Promedio del Día',
        value: '21.80',
        unit: 'ppm',
        color: AppTheme.accent,
        icon: Icons.analytics_outlined,
      ));

      // Null safety: value y unit son String no-nullable, siempre presentes
      expect(find.text('21.80'), findsOneWidget);
      expect(find.text('ppm'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 5b. Muestra la etiqueta correctamente
    // ----------------------------------------------------------------
    testWidgets('muestra la etiqueta del indicador', (tester) async {
      await tester.pumpWidget(buildCard(
        label: 'Máximo del Día',
        value: '75.00',
        unit: 'ppm',
        color: AppTheme.danger,
        icon: Icons.arrow_upward_rounded,
      ));

      expect(find.text('Máximo del Día'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 5c. El ícono está presente en el widget tree
    // ----------------------------------------------------------------
    testWidgets('contiene el ícono especificado', (tester) async {
      await tester.pumpWidget(buildCard(
        label: 'Total',
        value: '42',
        unit: 'lecturas',
        color: AppTheme.safe,
        icon: Icons.storage_outlined,
      ));

      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 5d. Muestra '--' como valor cuando no hay datos
    // (patrón usado en today/month/general screen)
    // ----------------------------------------------------------------
    testWidgets('muestra placeholder cuando no hay datos', (tester) async {
      await tester.pumpWidget(buildCard(
        label: 'Último Registro',
        value: '--',    // valor centinela cuando el dato es null
        unit: 'ppm',
        color: AppTheme.accent,
        icon: Icons.sensors,
      ));

      expect(find.text('--'), findsOneWidget);
      // La unidad igual debe aparecer
      expect(find.text('ppm'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 5e. El widget se renderiza sin overflow en tamaño reducido
    // ----------------------------------------------------------------
    testWidgets('no lanza errores de layout en tamaño pequeño',
        (tester) async {
      // Simular un tamaño de pantalla pequeña (ej: Galaxy S5)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCard(
        label: 'Mínimo del Día',
        value: '5.32',
        unit: 'ppm',
        color: AppTheme.safe,
        icon: Icons.arrow_downward_rounded,
      ));

      // Si no hay excepción de overflow, el test pasa
      expect(tester.takeException(), isNull);
    });
  });
}