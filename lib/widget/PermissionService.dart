import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final List<Permission> _requiredPermissions = [
    Permission.location,
    Permission.locationAlways,
    Permission.locationWhenInUse,
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.audio,
    Permission.accessMediaLocation,
    Permission.phone,
    Permission.microphone,
    Permission.notification,
    Permission.sensors,
    Permission.manageExternalStorage,

    Permission.accessMediaLocation
  ];

  /// Request permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};

    for (var permission in _requiredPermissions) {
      // Request permissions that are denied or permanently denied
      if (await permission.isDenied || await permission.isPermanentlyDenied) {
        statuses[permission] = await permission.request();
      } else {
        statuses[permission] = await permission.status;
      }
    }

    // Check if all permissions are granted
    return statuses.values.every((status) => status.isGranted);
  }

  /// Check permissions again after returning from settings
  Future<bool> checkPermissionsAgain() async {
    return (await Future.wait(
      _requiredPermissions.map((permission) => permission.status),
    )).every((status) => status.isGranted);
  }

  /// Get list of denied permissions
  Future<List<Permission>> getDeniedPermissions() async {
    List<Permission> deniedPermissions = [];

    for (var permission in _requiredPermissions) {
      if (await permission.isDenied) {
        deniedPermissions.add(permission);
      }
    }
    return deniedPermissions;
  }
}
