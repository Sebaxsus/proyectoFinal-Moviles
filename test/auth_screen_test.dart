// PRUEBA DE WIDGET 4 — AuthScreen
// Verifica que la pantalla de login/registro se renderiza bien
// y que los validadores de formulario funcionan.
// Usa go_router en modo test (ProviderScope + GoRouter directo).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

/// Helper que envuelve AuthScreen con go_router + Provider.
/// En tests se crea un GoRouter mínimo que solo apunta a /login.
Widget buildTestableAuth() {
  final wsService = WebSocketService();
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const AuthScreen(),
      ),
    ],
  );

  return ChangeNotifierProvider<WebSocketService>.value(
    value: wsService,
    child: MaterialApp.router(
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

void main() {
  group('AuthScreen — prueba de widget', () {
    // ----------------------------------------------------------------
    // 4a. Elementos principales visibles al cargar
    // ----------------------------------------------------------------
    testWidgets('muestra logo, tabs y campo de usuario', (tester) async {
      await tester.pumpWidget(buildTestableAuth());
      await tester.pumpAndSettle();

      expect(find.text('Gas Monitor'), findsOneWidget);
      expect(find.text('Sistema de monitoreo IoT'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Registrarse'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Usuario'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 4b. Validación: submit sin datos muestra errores
    // ----------------------------------------------------------------
    testWidgets('mostrar errores de validación al enviar vacío',
        (tester) async {
      await tester.pumpWidget(buildTestableAuth());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      expect(find.text('El usuario no puede estar vacío'), findsOneWidget);
      expect(find.text('La contraseña no puede estar vacía'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 4c. Validación: usuario muy corto
    // ----------------------------------------------------------------
    testWidgets('muestra error si el usuario tiene menos de 3 caracteres',
        (tester) async {
      await tester.pumpWidget(buildTestableAuth());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Usuario'), 'ab');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      expect(find.text('Mínimo 3 caracteres'), findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 4d. Cambiar a la pestaña de Registro muestra sus campos
    // ----------------------------------------------------------------
    testWidgets('navegar a pestaña Registro muestra campo de confirmación',
        (tester) async {
      await tester.pumpWidget(buildTestableAuth());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre de usuario'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Crear Cuenta'),
          findsOneWidget);
    });

    // ----------------------------------------------------------------
    // 4e. Contraseñas distintas muestran error en registro
    // ----------------------------------------------------------------
    testWidgets('registro con contraseñas distintas muestra error',
        (tester) async {
      await tester.pumpWidget(buildTestableAuth());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de usuario'), 'usuario1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'), 'pass123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar contraseña'),
          'diferente');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });
  });
}