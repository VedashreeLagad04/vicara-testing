import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationPermission? permission;
  Future<bool> get serviceEnabled async => await Geolocator.isLocationServiceEnabled();
  init() async {
    var _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print(_serviceEnabled);
    if (!_serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }
  Future<Position?> getLocation() async {
    return await Geolocator.getCurrentPosition();
  }
}
