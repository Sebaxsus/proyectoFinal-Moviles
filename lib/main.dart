// lib/main.dart
// Punto de entrada de la aplicación

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/websocket_service.dart';
import 'services/permisions_service.dart';
import 'screens/today_screen.dart';
import 'screens/month_screen.dart';
import 'screens/general_screen.dart';
import 'screens/safety_screen.dart';
import 'utils/app_theme.dart';

import 'router/router.dart';

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

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // Índice de la pantalla activa en la barra de navegación
//   int _currentIndex = 0;

//   // Lista de todas las pantallas del dashboard
//   final List<Widget> _screens = const [
//     TodayScreen(),
//     MonthScreen(),
//     GeneralScreen(),
//     SafetyScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Conectar al servidor al iniciar la app
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<WebSocketService>().connect();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final service = context.watch<WebSocketService>();

//     return Scaffold(
//       // ---- AppBar superior ----
//       appBar: AppBar(
//         title: Row(
//           children: [
//             // Ícono del sensor
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: AppTheme.accent.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.gas_meter_outlined,
//                   color: AppTheme.accent, size: 18),
//             ),
//             const SizedBox(width: 10),
//             const Text(
//               'Gas Monitor',
//               style: TextStyle(
//                 color: AppTheme.textPrimary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           // Indicador de estado de conexión
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: _buildConnectionStatus(service),
//           ),
//         ],
//       ),

//       // ---- Cuerpo: pantalla activa ----
//       body: IndexedStack(
//         // IndexedStack mantiene el estado de cada pantalla al cambiar de tab
//         index: _currentIndex,
//         children: _screens,
//       ),

//       // ---- Barra de navegación inferior ----
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.today_outlined),
//             activeIcon: Icon(Icons.today),
//             label: 'Hoy',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_month_outlined),
//             activeIcon: Icon(Icons.calendar_month),
//             label: 'Mes',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart_outlined),
//             activeIcon: Icon(Icons.bar_chart),
//             label: 'General',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shield_outlined),
//             activeIcon: Icon(Icons.shield),
//             label: 'Seguridad',
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget que muestra si la app está conectada al servidor
//   Widget _buildConnectionStatus(WebSocketService service) {
//     final isConnected = service.isConnected;

//     return GestureDetector(
//       onTap: () {
//         // Al tocar, intentar reconectar si está desconectado
//         if (!isConnected) service.connect();

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(service.statusMessage),
//             backgroundColor:
//                 isConnected ? AppTheme.safe : AppTheme.danger,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: (isConnected ? AppTheme.safe : AppTheme.danger)
//               .withOpacity(0.15),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: (isConnected ? AppTheme.safe : AppTheme.danger)
//                 .withOpacity(0.5),
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Punto parpadeante de estado
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 500),
//               width: 8,
//               height: 8,
//               decoration: BoxDecoration(
//                 color:
//                     isConnected ? AppTheme.safe : AppTheme.danger,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 6),
//             Text(
//               isConnected ? 'En línea' : 'Sin conexión',
//               style: TextStyle(
//                 color: isConnected ? AppTheme.safe : AppTheme.danger,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }