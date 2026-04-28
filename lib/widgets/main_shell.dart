// lib/widgets/main_shell.dart
//
// MAIN SHELL — scaffold compartido del dashboard
//
// Este widget envuelve todas las pantallas internas (Today, Month,
// General, Safety). go_router lo mantiene vivo mientras navegas
// entre esas rutas, así que el AppBar y el BottomNav nunca parpadean.
//
// Antes (IndexedStack):
//   _currentIndex  → controla qué widget mostrar
//   setState()     → reconstruye HomeScreen completo
//
// Ahora (go_router ShellRoute):
//   context.goNamed('today')  → go_router swapea solo el body
//   Shell nunca se reconstruye al cambiar de tab

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/router.dart';
import '../services/websocket_service.dart';
import '../utils/app_theme.dart';

class MainShell extends StatelessWidget {
  /// [child] es la pantalla activa inyectada por go_router (ShellRoute).
  final Widget child;

  const MainShell({super.key, required this.child});

  // Mapeo ruta → índice del BottomNavigationBar
  // Necesario para saber cuál tab resaltar según la ruta actual.
  static const List<String> _tabPaths = [
    AppPaths.today,
    AppPaths.month,
    AppPaths.general,
    AppPaths.safety,
  ];

  static const List<String> _tabRouteNames = [
    AppRoutes.today,
    AppRoutes.month,
    AppRoutes.general,
    AppRoutes.safety,
  ];

  /// Devuelve el índice del tab activo según la ubicación actual.
  /// Retorna 0 (today) si la ruta no coincide con ningún tab.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabPaths.indexOf(location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final wsService = context.watch<WebSocketService>();
    final tabIndex = _currentIndex(context);

    return Scaffold(
      // ---- AppBar compartido ----
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.gas_meter_outlined,
                color: AppTheme.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gas Monitor',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ConnectionStatusPill(service: wsService),
          ),
          // Botón de perfil → go_router push (tiene back button)
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Mi perfil',
            // context.pushNamed en vez de Navigator.push
            // El router maneja el stack de navegación correctamente
            onPressed: () => context.pushNamed(AppRoutes.profile),
          ),
        ],
      ),

      // ---- Cuerpo: la pantalla activa inyectada por ShellRoute ----
      // go_router se encarga de hacer el swap; aquí solo lo mostramos
      body: child,

      // ---- BottomNavigationBar compartido ----
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: (index) {
          // go_router navega a la ruta nombrada del tab seleccionado.
          // Si ya está en ese tab, go() no hace nada (no duplica rutas).
          context.goNamed(_tabRouteNames[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Mes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'General',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Seguridad',
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Widget auxiliar: píldora de estado de conexión
// Extraído del Shell para mantener build() limpio.
// ----------------------------------------------------------------
class _ConnectionStatusPill extends StatelessWidget {
  final WebSocketService service;

  const _ConnectionStatusPill({required this.service});

  @override
  Widget build(BuildContext context) {
    final isConnected = service.isConnected;
    final color = isConnected ? AppTheme.safe : AppTheme.danger;

    return GestureDetector(
      onTap: () {
        if (!isConnected) service.connect();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(service.statusMessage),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'En línea' : 'Sin conexión',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}