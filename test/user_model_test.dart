// PRUEBA UNITARIA 2 — UserModel y AuthState
// Verifica el parsing del modelo de usuario y los valores del enum.

import 'package:flutter_test/flutter_test.dart';

import 'package:gas_monitor/gas_monitor.dart';
void main() {
  // ================================================================
  // UserModel
  // ================================================================
  group('UserModel', () {
    // ----------------------------------------------------------------
    // 2a. Respuesta de login exitoso con token
    // ----------------------------------------------------------------
    test('parsea respuesta de login con token', () {
      // ARRANGE: respuesta típica del servidor Python
      final json = {
        'event': 'login',
        'status': 'ok',
        'username': 'juan123',
        'token': 'eyJhbGciOiJIUzI1NiJ9.abc',
      };

      // ACT
      final user = UserModel.fromJson(json);

      // ASSERT
      expect(user.username, equals('juan123'));
      expect(user.token, equals('eyJhbGciOiJIUzI1NiJ9.abc'));
      // username es non-nullable — nunca puede ser null
      expect(user.username, isNotNull);
    });

    // ----------------------------------------------------------------
    // 2b. Respuesta de login sin token (campo opcional)
    // Null safety: token es String? → puede ser null sin problema
    // ----------------------------------------------------------------
    test('parsea respuesta sin token — campo nullable correcto', () {
      final json = {
        'event': 'login',
        'status': 'ok',
        'username': 'admin',
        // 'token' no viene en la respuesta
      };

      final user = UserModel.fromJson(json);

      expect(user.username, equals('admin'));
      // Null safety: token es String?, su valor null es válido
      expect(user.token, isNull);
    });

    // ----------------------------------------------------------------
    // 2c. toJson omite el token si es null
    // ----------------------------------------------------------------
    test('toJson no incluye token cuando es null', () {
      const user = UserModel(username: 'tester');
      final json = user.toJson();

      expect(json.containsKey('username'), isTrue);
      // Si token es null, no debe aparecer en el JSON
      expect(json.containsKey('token'), isFalse);
    });

    // ----------------------------------------------------------------
    // 2d. toJson incluye token cuando tiene valor
    // ----------------------------------------------------------------
    test('toJson incluye token cuando tiene valor', () {
      const user = UserModel(username: 'tester', token: 'mi-token');
      final json = user.toJson();

      expect(json['token'], equals('mi-token'));
    });
  });

  // ================================================================
  // AuthStatus enum
  // ================================================================
  group('AuthStatus enum', () {
    test('tiene exactamente los estados esperados', () {
      // Verificar que el enum tiene todos los casos definidos
      expect(AuthStatus.values.length, equals(4));
      expect(AuthStatus.values, containsAll([
        AuthStatus.unauthenticated,
        AuthStatus.loading,
        AuthStatus.authenticated,
        AuthStatus.error,
      ]));
    });

    test('estado inicial debe ser unauthenticated', () {
      // Simular el estado inicial de la app
      const initialStatus = AuthStatus.unauthenticated;
      expect(initialStatus, isNot(AuthStatus.authenticated));
    });
  });
}