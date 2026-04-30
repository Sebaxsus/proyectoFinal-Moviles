// lib/main.dart
// Punto de entrada de la aplicación

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gas_monitor/gas_monitor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(providers:
      [
        // ChangeNotifierProvider hace que WebSocketService esté disponible
        // en TODA la app sin pasar datos manualmente entre pantallas
        ChangeNotifierProvider(
          create: (_) => WebSocketService(),
        ),
        ChangeNotifierProvider(
          create: (_) => PermissionService(),
        )
      ],
      child: const GasDashboardApp(),
    )
  );
}

class GasDashboardApp extends StatefulWidget {
  const GasDashboardApp({super.key});

  @override
    State<GasDashboardApp> createState() => _GasDashboardAppState();
  }

  class _GasDashboardAppState extends State<GasDashboardApp> {
  // El router se crea UNA sola vez. Si se creara dentro de build()
  // se recrearía en cada notifyListeners() y perdería el estado.
  late final _router = createRouter(context.read<WebSocketService>());
 
  @override
  void initState() {
    super.initState();
    // Verificar permisos del dispositivo al arrancar (sin pedirlos)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionService>().checkAllPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gas Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}