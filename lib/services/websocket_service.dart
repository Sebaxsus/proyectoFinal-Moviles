// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/sensor_reading.dart';

class WebSocketService extends ChangeNotifier {
  static const String _serverUrl = 'ws://127.0.0.1:5000';

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _statusMessage = 'Desconectado';

  // Listas de datos para cada sección del dashboard
  List<SensorReading> _readingsToday = [];
  List<SensorReading> _readingsMonth = [];
  List<SensorReading> _readingsAll = [];

  // Completer para esperar la respuesta del servidor
  Completer<List<SensorReading>>? _pendingRequest;

  // --- Getters públicos (solo lectura desde afuera) ---
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  List<SensorReading> get readingsToday => _readingsToday;
  List<SensorReading> get readingsMonth => _readingsMonth;
  List<SensorReading> get readingsAll => _readingsAll;

  // Conectar al servidor WebSocket
  Future<void> connect() async {
    try {
      _statusMessage = 'Conectando...';
      notifyListeners();

      _channel = WebSocketChannel.connect(
        // Url de conexion
        Uri.parse(_serverUrl),
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
    _isConnected = false;
    _statusMessage = 'Desconectado';
    notifyListeners();
  }

  // Maneja los mensajes recibidos del servidor
  void _onMessage(dynamic message) {
    try {
      final res = jsonDecode(message); // Parcialmente res es un tipo _JsonMap
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