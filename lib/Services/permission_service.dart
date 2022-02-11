import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  _getContactPermission() async {
    const Permission permission = Permission.contacts;
    if (await permission.status != PermissionStatus.granted &&
        await permission.status == PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts] ?? PermissionStatus.limited;
    } else {
      return permission;
    }
  }

  _getStoragePermission() async {
    const Permission permission = Permission.storage;
    if (await permission.status != PermissionStatus.granted &&
        await permission.status == PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.storage].request();
      return permissionStatus[Permission.storage] ?? PermissionStatus.limited;
    } else {
      return permission;
    }
  }

  _getLocationPermission() async {
    const Permission permission = Permission.locationWhenInUse;
    if (await permission.status != PermissionStatus.granted &&
        await permission.status == PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.locationWhenInUse].request();
      return permissionStatus[Permission.locationWhenInUse] ?? PermissionStatus.limited;
    } else {
      return permission;
    }
  }

  _getSensorPermission() async {
    const Permission permission = Permission.sensors;
    if (await permission.status != PermissionStatus.granted &&
        await permission.status == PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.sensors].request();
      return permissionStatus[Permission.sensors] ?? PermissionStatus.limited;
    } else {
      return permission;
    }
  }

  get getPermissions async {
    await _getContactPermission();
    await _getLocationPermission();
    await _getSensorPermission();
    await _getStoragePermission();
  }
}
