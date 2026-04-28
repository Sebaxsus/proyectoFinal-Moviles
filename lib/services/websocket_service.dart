// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/sensor_reading.dart';
import '../models/user_model.dart';
import '../models/auth_state.dart';

class WebSocketService extends ChangeNotifier {
  static const String _serverUrl = 'ws://127.0.0.1:5000';

  static const String _dataUrl = '$_serverUrl';
  static const String _authUrl = '$_serverUrl/auth';

  WebSocketChannel? _channel;
  WebSocketChannel? _authChannel;

  bool _isConnected = false;
  String _statusMessage = 'Desconectado';

  // --- Estado de Auth
  AuthStatus _authStatus = AuthStatus.unauthenticated;
  UserModel? _currentUser;
  String? _authError;

  // Listas de datos para cada sección del dashboard
  List<SensorReading> _readingsToday = [];
  List<SensorReading> _readingsMonth = [];
  List<SensorReading> _readingsAll = [];

  // Completer para esperar la respuesta del servidor
  Completer<List<SensorReading>>? _pendingRequest;
  Completer<Map<String, dynamic>>? _pendingAuthRequest;

  // --- Getters públicos (solo lectura desde afuera) ---
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;

  List<SensorReading> get readingsToday => _readingsToday;
  List<SensorReading> get readingsMonth => _readingsMonth;
  List<SensorReading> get readingsAll => _readingsAll;

  AuthStatus get authStatus => _authStatus;
  UserModel? get currentUser => _currentUser;
  String? get authError => _authError;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  // Conectar al servidor WebSocket
  Future<void> connect() async {
    try {
      _statusMessage = 'Conectando...';
      notifyListeners();

      _channel = WebSocketChannel.connect(
        // Url de conexion
        Uri.parse(_dataUrl),
        // Protocolos de comunicacion WS
        protocols: ["arduino"]
      );

      // Escuchar los men sajes del servidor
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _statusMessage = 'Conectado';
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Error al conectar: $e';
      notifyListeners();
    }
  }

  // Desconectar del servidor
  void disconnect() {
    _channel?.sink.close();
    _authChannel?.sink.close();

    _isConnected = false;
    _statusMessage = 'Desconectado';
    notifyListeners();
  }

  // Inicia sesión enviando credenciales al endpoint ws://.../auth
  /// El servidor debe responder con:
  ///   {"event":"login","status":"ok","username":"...","token":"..."}
  ///   {"event":"login","status":"error","message":"..."}
  Future<void> login(String username, String password) async {
    _authStatus = AuthStatus.loading;
    _authError = null;
    notifyListeners();

    try {
      _authChannel ??= WebSocketChannel.connect(Uri.parse(_authUrl));
      _pendingAuthRequest = Completer<Map<String, dynamic>>();

      // Escuchar la respuesta de Auth
      _authChannel!.stream.listen(
        _onAuthMessage,
        onError: (e) {
          if (_pendingAuthRequest != null && !_pendingAuthRequest!.isCompleted) {
            _pendingAuthRequest!.completeError(e);
          }
        },
      );

      // Enviar Credenciales
      _authChannel!.sink.add(
        jsonEncode(
          {
            'event': 'login',
            'username': username,
            'password': password,
          }
        )
      );

      // Esperar Respuesta con timeout.
      final response = await _pendingAuthRequest!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Sin respuesta del servidor'),
      );

      if (response['status'] == 'ok') {
        _currentUser = UserModel.fromJson(response);
        _authStatus = AuthStatus.authenticated;
        _authError = null;

        // Una vez autenticado, conectar el canal de datos
        await connect();
      } else {
        _authStatus = AuthStatus.error;
        _authError = response['message'] as String? ?? 'Credencianles incorrectas';
      }

    } catch (e) {
      _authStatus = AuthStatus.error;
      _authError = e.toString();
    }

    _pendingAuthRequest = null;
    notifyListeners();

  }

  /// Registra un nuevo usuario enviando credenciales al endpoint /auth
  /// {"event":"register","username":"...","password":"..."}
  Future<void> register(String username, String password) async {
    _authStatus = AuthStatus.loading;
    _authError = null;
    notifyListeners();

    try {
      _authChannel ??= WebSocketChannel.connect(Uri.parse(_authUrl));
      _pendingAuthRequest = Completer<Map<String, dynamic>>();

      _authChannel!.stream.listen(
        _onAuthMessage,
        onError: (e) {
          if (_pendingAuthRequest != null && _pendingAuthRequest!.isCompleted) {
            _pendingAuthRequest!.completeError(e);
          }
        },
      );

      _authChannel!.sink.add(
        jsonEncode(
          {
            'event': 'register',
            'username': username,
            'password': password,
          }
        )
      );

      final response = await _pendingAuthRequest!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Sin respuesta del servidor'),
      );

      if (response['status'] == 'ok') {
        await login(username, password);
        return;
      } else {
        _authStatus = AuthStatus.error;
        _authError = response['message'] as String? ?? 'Error al registrar usuario';
      }
    } catch (e) {
      _authStatus = AuthStatus.error;
      _authError = e.toString();
    }

    _pendingAuthRequest = null;
    notifyListeners();
  }

   /// Cierra la sesión del usuario actual
  void logout() {
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _authError = null;
    _readingsToday = [];
    _readingsMonth = [];
    _readingsAll = [];
    disconnect();
    notifyListeners();
  }

  // Maneja los mensaje recibidos del servidor por auth
  void _onAuthMessage(dynamic message) {
    try {
      final data = jsonDecode(message  as String) as Map<String, dynamic>;
      if (_pendingAuthRequest != null && !_pendingAuthRequest!.isCompleted) {
        _pendingAuthRequest!.complete(data);
      }
    } catch (e) {
      debugPrint('Error en mensaje de auth: $e');
      if (_pendingAuthRequest != null && !_pendingAuthRequest!.isCompleted) {
        _pendingAuthRequest!.completeError(e);
      }
    }
  }

  // Maneja los mensajes recibidos del servidor
  void _onMessage(dynamic message) {
    try {
      final res = jsonDecode(message as String); // Parcialmente res es un tipo _JsonMap
      print('[_onMessage] Res Data: ${res['event']}');
      // El servidor envía una lista de lecturas
      if (res is Map<String, dynamic> && res['data'] is List<dynamic>) {
        final List<dynamic> data = res["data"];
        final readings = data
            .map((item) => SensorReading.fromJson(item))
            .toList();

        // Completar la solicitud pendiente si existe
        if (_pendingRequest != null && !_pendingRequest!.isCompleted) {
          _pendingRequest!.complete(readings);
          // _pendingRequest = null; // Se mueve esta logica al metodo _sendRequest, 
          // Al parecer esto puede generar una codicion de carrera entre la respuesta del servidor
          // Y el mensaje de respuesta puede llegar al método de escucha antes de que el flujo de ejecución haya llegado a la línea del await.
          // Como el Completer ya existe, se completa y se pone en null inmediatamente. 
          // Cuando el código finalmente intenta ejecutar el await, el _pendingRequest ya es null o ya terminó, causando un comportamiento errático.
        }
      } else {
        print('Res no es tipo Map y List: ${res.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error al procesar mensaje: $e');
      if (_pendingRequest != null && !_pendingRequest!.isCompleted) {
        _pendingRequest!.completeError(e);
        // _pendingRequest = null; 
      }
    }
  }

  void _onError(error) {
    _isConnected = false;
    _statusMessage = 'Error de conexión';
    notifyListeners();
    debugPrint('WebSocket error: $error');
  }

  void _onDone() {
    _isConnected = false;
    _statusMessage = 'Conexión cerrada';
    notifyListeners();
  }

  // Envía una solicitud al servidor y espera la respuesta
  Future<List<SensorReading>> _sendRequest(Map<String, dynamic> request) async {
    print('Request Data: ${request}');

    if (!_isConnected || _channel == null) {
      throw Exception('No hay conexión con el servidor');
    }

    // Crear un Completer para esperar la respuesta
    _pendingRequest = Completer<List<SensorReading>>();

    // Enviar la solicitud como JSON
    _channel!.sink.add(jsonEncode(request));

    // Esperar la respuesta con un timeout de 10 segundos
    final res = await _pendingRequest?.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('Entro a timeOut objeto _pendingRequest ${_pendingRequest} ');
        throw TimeoutException('El servidor no respondió');
      },
    );

    print('Respuesta de la peticion ${request}');
    if (res != null) {
      if (res.isNotEmpty) {
        print('Respuesta: ${res.last}');
      } else {
        print('Respuesta Vacia: ${res}');
      }
    } else {
      print('Respuesta Nula: ${res}');
    }
    return res!;
  }

  // ============================================================
  // MÉTODOS PÚBLICOS PARA CARGAR DATOS
  // ============================================================

  // Carga los datos del día actual
  Future<void> loadTodayData() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final request = {
      'event': 'historico',
      'filter': {'date': dateStr},
      'order': {'by': 'timestamp', 'direction': 'ASC'},
    };

    _readingsToday = await _sendRequest(request);
    notifyListeners();
  }

  // Carga los datos del mes actual
  Future<void> loadMonthData() async {
    final now = DateTime.now();
    // Filtramos por mes usando el primer día del mes
    final monthStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final request = {
      'event': 'historico',
      'filter': {'date': monthStr}, // El servidor debe soportar filtro por mes
      'order': {'by': 'timestamp', 'direction': 'ASC'},
    };

    _readingsMonth = await _sendRequest(request);
    notifyListeners();
  }

  // Carga TODOS los datos históricos
  Future<void> loadAllData() async {
    final request = {
      'event': 'historico',
      'order': {'by': 'timestamp', 'direction': 'DESC'},
    };

    _readingsAll = await _sendRequest(request);
    notifyListeners();
  }
}