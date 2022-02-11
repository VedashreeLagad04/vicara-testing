import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  // Map<String, double> _gravity = {'x': 0, 'y': 0, 'z': 0};
  // Map<String, double> _acc = {'x': 0, 'y': 0, 'z': 0};
  // Map<String, double> _gyro = {'x': 0, 'y': 0, 'z': 0};
  // Map<String, double> _mag = {'x': 0, 'y': 0, 'z': 0};
  Stream<AccelerometerEvent> accelerometerStream = accelerometerEvents;
  Stream<UserAccelerometerEvent> userAccelerometerStream = userAccelerometerEvents;
  Stream<GyroscopeEvent> gyroscopeStream = gyroscopeEvents;
  Stream<MagnetometerEvent> magnetometerStream = magnetometerEvents;
}
