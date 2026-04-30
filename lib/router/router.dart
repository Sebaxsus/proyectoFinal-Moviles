// El redirect() actúa como AuthGate: si el usuario no está
// autenticado lo manda a /login; si lo está y va a /login, lo
// manda a /today. Así el código de auth está en UN solo lugar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

// ----------------------------------------------------------------
// NOMBRES DE RUTA — constantes para evitar typos al navegar
// ----------------------------------------------------------------
// Uso: context.goNamed(AppRoutes.today)
// En vez de: context.go('/today')
// ----------------------------------------------------------------
abstract final class AppRoutes {
  static const login   = 'login';
  static const today   = 'today';
  static const month   = 'month';
  static const general = 'general';
  static const safety  = 'safety';
  static const profile = 'profile';
}
 
// ----------------------------------------------------------------
// PATHS — las URLs reales (usados internamente por go_router)
// ----------------------------------------------------------------
abstract final class AppPaths {
  static const login   = '/login';
  static const today   = '/today';
  static const month   = '/month';
  static const general = '/general';
  static const safety  = '/safety';
  static const profile = '/profile';
}
 
// ----------------------------------------------------------------
// FACTORY — crea el GoRouter con acceso al WebSocketService
// ----------------------------------------------------------------
// Se llama desde main.dart y se inyecta en MaterialApp.router.
// Recibe el WebSocketService para poder leer authStatus en el
// redirect sin usar BuildContext (go_router lo requiere así).
// ----------------------------------------------------------------
GoRouter createRouter(WebSocketService wsService) {
  return GoRouter(
    // Ruta de inicio: go_router evaluará el redirect antes de mostrarla
    initialLocation: AppPaths.today,
 
    // refreshListenable: cada vez que WebSocketService llame
    // notifyListeners() (cambio de auth, desconexión, etc.)
    // go_router re-evalúa el redirect automáticamente.
    refreshListenable: wsService,
 
    // ---- GUARD DE AUTENTICACIÓN ----
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated =
          wsService.authStatus == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == AppPaths.login;
 
      // No autenticado + no está en /login → mandar a /login
      if (!isAuthenticated && !isOnLogin) return AppPaths.login;
 
      // Autenticado + está en /login → mandar al dashboard
      if (isAuthenticated && isOnLogin) return AppPaths.today;
 
      // En cualquier otro caso no redirigir
      return null;
    },
 
    routes: [
      // ---- RUTA PÚBLICA: login/registro ----
      GoRoute(
        path: AppPaths.login,
        name: AppRoutes.login,
        builder: (context, state) => const AuthScreen(),
      ),
 
      // ---- SHELL ROUTE: scaffold compartido con BottomNavigationBar ----
      // El ShellRoute envuelve las rutas hijas con MainShell.
      // Cuando navegas entre /today, /month, /general, /safety,
      // el AppBar y el BottomNav NO se reconstruyen — solo cambia
      // el body. Esto es el equivalente al IndexedStack pero con rutas reales.
      ShellRoute(
        builder: (context, state, child) {
          // child = la pantalla activa (Today, Month, General o Safety)
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppPaths.today,
            name: AppRoutes.today,
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: AppPaths.month,
            name: AppRoutes.month,
            builder: (context, state) => const MonthScreen(),
          ),
          GoRoute(
            path: AppPaths.general,
            name: AppRoutes.general,
            builder: (context, state) => const GeneralScreen(),
          ),
          GoRoute(
            path: AppPaths.safety,
            name: AppRoutes.safety,
            builder: (context, state) => const SafetyScreen(),
          ),
        ],
      ),
 
      // ---- RUTA DE PERFIL: push sobre el shell (tiene back button) ----
      GoRoute(
        path: AppPaths.profile,
        name: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
 
    // Página de error personalizada si se navega a una ruta inexistente
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFFF4757), size: 48),
            const SizedBox(height: 16),
            Text(
              'Ruta no encontrada: ${state.uri}',
              style: const TextStyle(color: Color(0xFFE8F4FD)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.today),
              child: const Text('Ir al inicio',
                  style: TextStyle(color: Color(0xFF00D4AA))),
            ),
          ],
        ),
      ),
    ),
  );
}