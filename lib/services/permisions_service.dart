import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado de una solicitud de permiso.
/// Encapsula el estado y un mensaje legible para el usuario.
class PermissionResult {
  final bool granted;
  final String message;
 
  const PermissionResult({required this.granted, required this.message});
}

class PermissionService extends ChangeNotifier {
  // Estado observable de cada permiso
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _galleryStatus = PermissionStatus.denied;
 
  // --- Getters ---
  PermissionStatus get cameraStatus => _cameraStatus;
  PermissionStatus get galleryStatus => _galleryStatus;
 
  bool get isCameraGranted => _cameraStatus == PermissionStatus.granted;
  bool get isGalleryGranted => _galleryStatus == PermissionStatus.granted;
 
  /// Verifica el estado actual de todos los permisos relevantes sin pedirlos.
  /// Llamar en initState o al arrancar la app para reflejar el estado real.
  Future<void> checkAllPermissions() async {
    _cameraStatus = await Permission.camera.status;
    _galleryStatus = await _getGalleryPermission().status;
    notifyListeners();
  }
 
  // ----------------------------------------------------------------
  // CÁMARA
  // ----------------------------------------------------------------
 
  /// Solicita el permiso de cámara al usuario.
  /// Retorna [PermissionResult] con el resultado y un mensaje descriptivo.
  Future<PermissionResult> requestCamera() async {
    // Verificar estado actual antes de pedir
    _cameraStatus = await Permission.camera.status;
 
    if (_cameraStatus == PermissionStatus.granted) {
      return const PermissionResult(
        granted: true,
        message: 'Permiso de cámara concedido.',
      );
    }
 
    // Si fue denegado permanentemente, redirigir a ajustes del sistema
    if (_cameraStatus == PermissionStatus.permanentlyDenied) {
      notifyListeners();
      return const PermissionResult(
        granted: false,
        message:
            'Cámara bloqueada. Ve a Ajustes > Aplicaciones > Gas Monitor para habilitarla.',
      );
    }
 
    // Solicitar el permiso
    _cameraStatus = await Permission.camera.request();
    notifyListeners();
 
    if (_cameraStatus == PermissionStatus.granted) {
      return const PermissionResult(
        granted: true,
        message: 'Permiso de cámara concedido.',
      );
    }
 
    return const PermissionResult(
      granted: false,
      message: 'Permiso de cámara denegado.',
    );
  }
 
  // ----------------------------------------------------------------
  // GALERÍA / MEDIA LIBRARY
  // ----------------------------------------------------------------
 
  /// Solicita el permiso de galería/fotos.
  /// En Android 13+ usa READ_MEDIA_IMAGES; en versiones anteriores READ_EXTERNAL_STORAGE.
  Future<PermissionResult> requestGallery() async {
    final permission = _getGalleryPermission();
    _galleryStatus = await permission.status;
 
    if (_galleryStatus == PermissionStatus.granted ||
        _galleryStatus == PermissionStatus.limited) {
      notifyListeners();
      return const PermissionResult(
        granted: true,
        message: 'Acceso a galería concedido.',
      );
    }
 
    if (_galleryStatus == PermissionStatus.permanentlyDenied) {
      notifyListeners();
      return const PermissionResult(
        granted: false,
        message:
            'Galería bloqueada. Ve a Ajustes > Aplicaciones > Gas Monitor para habilitarla.',
      );
    }
 
    _galleryStatus = await permission.request();
    notifyListeners();
 
    final ok = _galleryStatus == PermissionStatus.granted ||
        _galleryStatus == PermissionStatus.limited;
 
    return PermissionResult(
      granted: ok,
      message: ok ? 'Acceso a galería concedido.' : 'Acceso a galería denegado.',
    );
  }
 
  // ----------------------------------------------------------------
  // CÁMARA + GALERÍA juntos
  // ----------------------------------------------------------------
 
  /// Solicita cámara y galería en paralelo.
  /// Útil para pantallas que necesitan ambos (ej: perfil de usuario).
  Future<Map<String, PermissionResult>> requestCameraAndGallery() async {
    final results = await Future.wait([
      requestCamera(),
      requestGallery(),
    ]);
    return {
      'camera': results[0],
      'gallery': results[1],
    };
  }
 
  // ----------------------------------------------------------------
  // ABRIR AJUSTES DEL SISTEMA
  // ----------------------------------------------------------------
 
  /// Abre la pantalla de ajustes de la aplicación en el sistema operativo.
  /// Útil cuando el permiso fue denegado permanentemente.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
 
  // ----------------------------------------------------------------
  // HELPER PRIVADO
  // ----------------------------------------------------------------
 
  /// Retorna el permiso correcto según la versión de Android.
  /// En iOS siempre usa photos.
  Permission _getGalleryPermission() {
    // permission_handler 12.x expone photos para iOS y
    // photos / storage para Android según el API level.
    // Usamos photos como abstracción unificada.
    return Permission.photos;
  }
 
  /// Texto legible del estado de un permiso (útil para debug y UI).
  static String statusLabel(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Concedido';
      case PermissionStatus.denied:
        return 'Denegado';
      case PermissionStatus.permanentlyDenied:
        return 'Bloqueado permanentemente';
      case PermissionStatus.limited:
        return 'Acceso limitado';
      case PermissionStatus.restricted:
        return 'Restringido por el sistema';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }
}

/// Servicio centralizado para gestionar permisos del dispositivo.
///
/// Patrón de uso:
///   1. Se registra en main.dart con MultiProvider.
///   2. Las pantallas llaman a requestCamera() / requestGallery() antes de
///      interactuar con recursos del dispositivo.
///   3. Si el permiso fue denegado permanentemente, se ofrece ir a Ajustes.
///
var notification = Permission.notification;
var mediaLib = Permission.accessMediaLocation;
var camera = Permission.camera;

Future<bool> notificationService () async {
  
  try {
    bool notiStatus = await notification.request().isGranted;
    bool cameraStatus = await camera.request().isGranted;
    
    if (notiStatus && cameraStatus) {
      // Either the permission was already granted before or the user just granted it.
    }

    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      notification,
      mediaLib,
      camera,
    ].request();
    print(statuses[notification]);
    
    return true;
  } catch (e) {
    print('Fallo el modulo notificationService:\n\tError: $e');
    return false;
  }


}
