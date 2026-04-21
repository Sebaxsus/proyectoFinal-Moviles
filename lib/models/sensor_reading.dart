// lib/models/sensor_reading.dart

class SensorReading {
  final int id;
  final double valor;
  final DateTime timestamp;

  SensorReading({
    required this.id,
    required this.valor,
    required this.timestamp,
  });

  // Convierte el JSON del servidor a un objeto SensorReading
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] ?? 0,
      valor: (json['valor'] ?? json['value'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Convierte el objeto a JSON (útil para debug)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}