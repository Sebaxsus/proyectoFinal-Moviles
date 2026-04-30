// PRUEBA UNITARIA 3 — PermissionService (lógica pura)
// Prueba la lógica estática y los valores del servicio sin
// necesitar el hardware real del dispositivo.
//
// NOTA: permission_handler interactúa con APIs nativas, por lo que
// en pruebas unitarias probamos la lógica pura que SÍ podemos aislar.

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gas_monitor/gas_monitor.dart';

void main() {
  group('PermissionService — lógica pura', () {
    // ----------------------------------------------------------------
    // 3a. statusLabel devuelve texto correcto para cada estado
    // ----------------------------------------------------------------
    test('statusLabel devuelve etiqueta para granted', () {
      final label = PermissionService.statusLabel(PermissionStatus.granted);
      expect(label, equals('Concedido'));
    });

    test('statusLabel devuelve etiqueta para denied', () {
      final label = PermissionService.statusLabel(PermissionStatus.denied);
      expect(label, equals('Denegado'));
    });

    test('statusLabel devuelve etiqueta para permanentlyDenied', () {
      final label =
          PermissionService.statusLabel(PermissionStatus.permanentlyDenied);
      expect(label, equals('Bloqueado permanentemente'));
    });

    test('statusLabel devuelve etiqueta para limited', () {
      final label = PermissionService.statusLabel(PermissionStatus.limited);
      expect(label, equals('Acceso limitado'));
    });

    test('statusLabel devuelve etiqueta para restricted', () {
      final label =
          PermissionService.statusLabel(PermissionStatus.restricted);
      expect(label, equals('Restringido por el sistema'));
    });

    // ----------------------------------------------------------------
    // 3b. PermissionResult respeta null safety
    // ----------------------------------------------------------------
    test('PermissionResult.granted=true tiene mensaje no vacío', () {
      const result = PermissionResult(
        granted: true,
        message: 'Permiso de cámara concedido.',
      );
      // Null safety: granted y message son non-nullable
      expect(result.granted, isTrue);
      expect(result.message, isNotEmpty);
    });

    test('PermissionResult.granted=false con mensaje de ajustes', () {
      const result = PermissionResult(
        granted: false,
        message:
            'Cámara bloqueada. Ve a Ajustes > Aplicaciones > Gas Monitor para habilitarla.',
      );
      expect(result.granted, isFalse);
      expect(result.message, contains('Ajustes'));
    });

    // ----------------------------------------------------------------
    // 3c. Estado inicial del servicio
    // ----------------------------------------------------------------
    test('estado inicial de permisos es denied (sin pedir)', () {
      final service = PermissionService();
      // Antes de checkAllPermissions(), los estados son denied por defecto
      expect(service.isCameraGranted, isFalse);
      expect(service.isGalleryGranted, isFalse);
    });
  });
}