import 'package:permission_handler/permission_handler.dart';

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
