// BARREL FILE — punto de entrada único para imports.
//
// En lugar de escribir en cada pantalla:
//   import '../models/sensor_reading.dart';
//   import '../models/sensor_stats.dart';
//   import '../services/websocket_service.dart';
//   import '../utils/app_theme.dart';
//
// Se escribe solo:
//   import 'package:gas_dashboard/gas_dashboard.dart';

// Models
export 'models/sensor_reading.dart';
export 'models/sensor_stats.dart';
export 'models/user_model.dart';
export 'models/auth_state.dart';

// Services
export 'services/websocket_service.dart';
export 'services/permisions_service.dart';

// Router
export 'router/router.dart';

// Widgets
export 'widgets/stat_card.dart';
export 'widgets/sensor_chart.dart';
export 'widgets/main_shell.dart';
export 'widgets/error_card.dart';
export 'widgets/loading_body.dart';
export 'widgets/level_badge.dart';

// Utils
export 'utils/app_theme.dart';

// Screens

export 'screens/auth_screen.dart';
export 'screens/profile_screen.dart';
export 'screens/today_screen.dart';
export 'screens/month_screen.dart';
export 'screens/general_screen.dart';
export 'screens/safety_screen.dart';