import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();
  Stream<LocationData> locationStream = Location().onLocationChanged;
  Future<bool> get serviceEnabled async => _location.serviceEnabled();

  init() async {
    if (!await serviceEnabled) {
      await _location.requestService();
      if (!await serviceEnabled) {
        return;
      }
    }
    PermissionStatus _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    locationStream = _location.onLocationChanged;
  }
  
}
