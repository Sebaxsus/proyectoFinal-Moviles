// PRUEBA UNITARIA 1 — Modelo SensorReading
// Verifica que el modelo parsea JSON correctamente y que los
// campos non-nullable nunca sean null (null safety en acción).

import 'package:flutter_test/flutter_test.dart';

import 'package:gas_monitor/gas_monitor.dart';

void main() {
  group('SensorReading.fromJson', () {
    // ----------------------------------------------------------------
    // 1a. JSON completo → todos los campos correctos
    // ----------------------------------------------------------------
    test('parsea un JSON válido correctamente', () {
      // ARRANGE: JSON que envía el servidor Python
      final json = {
        'id': 42,
        'valor': 25.7,
        'timestamp': '2026-04-14T10:30:00',
      };

      // ACT
      final reading = SensorReading.fromJson(json);

      // ASSERT
      expect(reading.id, equals(42));
      expect(reading.valor, equals(25.7));
      expect(reading.timestamp, equals(DateTime.parse('2026-04-14T10:30:00')));
    });

    // ----------------------------------------------------------------
    // 1b. El campo 'valor' puede venir como int → debe convertirse a double
    // ----------------------------------------------------------------
    test('convierte valor entero a double sin lanzar error', () {
      final json = {
        'id': 1,
        'valor': 30, // entero, no double
        'timestamp': '2026-04-14T08:00:00',
      };

      final reading = SensorReading.fromJson(json);

      // Null safety: valor es double, nunca puede ser null
      expect(reading.valor, isA<double>());
      expect(reading.valor, equals(30.0));
    });

    // ----------------------------------------------------------------
    // 1c. Lista de JSONs → lista de SensorReading
    // ----------------------------------------------------------------
    test('parsea una lista de JSONs en una lista de SensorReading', () {
      final jsonList = [
        {'id': 1, 'valor': 10.0, 'timestamp': '2026-04-14T06:00:00'},
        {'id': 2, 'valor': 20.0, 'timestamp': '2026-04-14T07:00:00'},
        {'id': 3, 'valor': 30.0, 'timestamp': '2026-04-14T08:00:00'},
      ];

      final readings = jsonList
          .map((j) => SensorReading.fromJson(j))
          .toList();

      expect(readings.length, equals(3));
      expect(readings[2].valor, equals(30.0));
      // Null safety: ninguno puede ser null
      for (final r in readings) {
        expect(r.id, isNotNull);
        expect(r.valor, isNotNull);
        expect(r.timestamp, isNotNull);
      }
    });

    // ----------------------------------------------------------------
    // 1d. toJson → fromJson es idempotente
    // ----------------------------------------------------------------
    test('toJson y fromJson son operaciones inversas', () {
      final original = SensorReading(
        id: 99,
        valor: 55.5,
        timestamp: DateTime(2026, 4, 14, 12, 0, 0),
      );

      final json = original.toJson();
      final restored = SensorReading.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.valor, equals(original.valor));
      expect(restored.timestamp, equals(original.timestamp));
    });
  });
}