import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vicara/Services/APIs/auth_api.dart';
import 'package:vicara/Services/APIs/emergency_sms_service.dart';
import 'package:vicara/Services/consts.dart';
// import 'package:vicara/Services/db/sensordb.dart';
import 'package:vicara/Services/low_pass_filter.dart';
import 'package:vicara/Services/sensor_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:background_location/background_location.dart';

void startCallback() => FlutterForegroundTask.setTaskHandler(FirstTaskHandler());

class FirstTaskHandler extends TaskHandler {
  WebSocketChannel? channel;
  final AuthAPIs _apIs = AuthAPIs();
  final LowPassFilter _lpf = LowPassFilter(1, 50);
  StreamSubscription<Position>? streamSubscription;
  final EmergencySMSServiceApi _emergencySMSServiceApi = EmergencySMSServiceApi();
  // final Auth _auth = Auth();
  StreamSubscription<UserAccelerometerEvent>? _userAcclSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _acclSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _connSub;
  final SensorService _sensorService = SensorService();
  dynamic applyLowPassFilter(unfiltered) {
    try {
      var filtered = _lpf.filter(unfiltered);
      return filtered.any((element) => element.isNaN) ? unfiltered.toList() : filtered.toList();
    } catch (e) {
      return unfiltered.toList();
    }
  }

  StreamSubscription? _majorStream;
  StreamSubscription? _miniStream;
  var acclData;
  var gyroData;
  var location;
  var gravityData;
  // final LocalDB _localDB = LocalDB();
  int _connectionAttempt = 0;
  Future<void> wsTalker(String? phone, SendPort? sendPort) async {
    if (phone == null) return;
    final Map<String, dynamic> _sensorDataEmpty = {
      'accuracy': 0,
      'gravityX': [],
      'gravityY': [],
      'gravityZ': [],
      'gyroX': [],
      'gyroY': [],
      'gyroZ': [],
      'linearAccelX': [],
      'linearAccelY': [],
      'linearAccelZ': [],
      'lat': 0,
      'long': 0,
      'speed': 0,
      'acceleration': 0,
      'cornering': 0,
      'timestamp': 0,
      'userId': phone
    };
    var _sensorFilteredData = _sensorDataEmpty;
    if (channel == null) {
      channel = WebSocketChannel.connect(Uri.parse(wsURL + phone));
      _connectionAttempt = 0;
      _miniStream = Stream.periodic(const Duration(milliseconds: 20)).listen(
        (event) {
          _sensorFilteredData['gravityX'].add(gravityData.x ?? 0);
          _sensorFilteredData['gravityY'].add(gravityData.y ?? 0);
          _sensorFilteredData['gravityZ'].add(gravityData.z ?? 0);
          _sensorFilteredData['gyroX'].add(gyroData.x ?? 0);
          _sensorFilteredData['gyroY'].add(gyroData.y ?? 0);
          _sensorFilteredData['gyroZ'].add(gyroData.z ?? 0);
          _sensorFilteredData['linearAccelX'].add(acclData.x ?? 0);
          _sensorFilteredData['linearAccelY'].add(acclData.y ?? 0);
          _sensorFilteredData['linearAccelZ'].add(acclData.z ?? 0);
        },
      );
      _majorStream = Stream.periodic(const Duration(seconds: 1)).listen((event) async {
        _sensorFilteredData['accuracy'] = location?.accuracy ?? 0;
        _sensorFilteredData['speed'] = location?.speed ?? 0;
        _sensorFilteredData['lat'] = location?.latitude ?? 0;
        _sensorFilteredData['long'] = location?.longitude ?? 0;
        _sensorFilteredData['timestamp'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        _sensorFilteredData['acceleration'] =
            sqrt((acclData.x * acclData.x) + (acclData.y * acclData.y) + (acclData.z * acclData.z));
        _sensorFilteredData['cornering'] =
            sqrt((gyroData.x * gyroData.x) + (gyroData.y * gyroData.y) + (gyroData.z * gyroData.z));
        _sensorFilteredData['gravityX'] = applyLowPassFilter(_sensorFilteredData['gravityX']);
        _sensorFilteredData['gravityY'] = applyLowPassFilter(_sensorFilteredData['gravityY']);
        _sensorFilteredData['gravityZ'] = applyLowPassFilter(_sensorFilteredData['gravityZ']);
        _sensorFilteredData['gyroX'] = applyLowPassFilter(_sensorFilteredData['gyroX']);
        _sensorFilteredData['gyroY'] = applyLowPassFilter(_sensorFilteredData['gyroY']);
        _sensorFilteredData['gyroZ'] = applyLowPassFilter(_sensorFilteredData['gyroZ']);
        _sensorFilteredData['linearAccelX'] =
            applyLowPassFilter(_sensorFilteredData['linearAccelX']);
        _sensorFilteredData['linearAccelY'] =
            applyLowPassFilter(_sensorFilteredData['linearAccelY']);
        _sensorFilteredData['linearAccelZ'] =
            applyLowPassFilter(_sensorFilteredData['linearAccelZ']);
        if (channel != null) {
          channel?.sink.add(json.encode(_sensorFilteredData));
        } else {
          // await _localDB.insertIntoDatabase(
          //     json.encode(_sensorFilteredData), _sensorFilteredData['timestamp']);
        }
        _sensorFilteredData = _sensorDataEmpty;
      });
      channel?.stream.listen((event) {
        var result = json.decode(event);
        if (result['type'] == "Fall") {
          var date = DateTime.fromMillisecondsSinceEpoch(result["timestamp"] * 1000);
          // _notifier.show("Seems like you have taken a fall", "Fall detected", "fall");
          _emergencySMSServiceApi
              .sendEmergencyMessage(lat: location.latitude ?? 0, long: location.longitude ?? 0)
              .then((value) {
            Fluttertoast.showToast(
              msg: "Emergency message sent!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              fontSize: 16.0,
            );
          }).onError((error, stackTrace) {});
          FlutterForegroundTask.updateService(
              notificationTitle: 'Vicara fall detection service',
              notificationText:
                  "Fall detected on ${(date.hour < 10 ? '0${date.hour}' : date.hour)}:${(date.minute < 10 ? '0${date.minute}' : date.minute)}");
        }
        sendPort?.send({'type': 'event', 'data': result});
      }, onDone: () {
        print("done-------------------------");
        channel = null;
        sendPort?.send({'type': 'ws-connection-status', 'data': false});
      }, onError: (err) {
        print("Error-------------------------");
        channel = null;
        sendPort?.send({'type': 'ws-connection-status', 'data': false});
      });
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    BackgroundLocation.setAndroidNotification(
      title: 'Background service is running',
      message: 'Background location in progress',
      icon: '@mipmap/ic_launcher',
    ).then((data) {
      Stream.periodic(const Duration(seconds: 1)).listen((event) {
        BackgroundLocation.startLocationService(distanceFilter: 20).then((data) {
          BackgroundLocation.getLocationUpdates((Location? locationData) {
            if (locationData != null) location = locationData;
          });
        });
      });
    });
    _userAcclSub = _sensorService.userAccelerometerStream.listen((event) {
      acclData = event;
    });
    _gyroSub = _sensorService.gyroscopeStream.listen((event) {
      gyroData = event;
    });
    _acclSub = _sensorService.accelerometerStream.listen((event) {
      gravityData = event;
    });
    // _locationSub = _locationService.locationStream.listen((event) {
    //   location = event;
    // });

    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none && channel == null) {
        FlutterForegroundTask.getData<String>(key: 'phone').then((phone) {
          _apIs.getWSAuth().then((poolGranted) {
            sendPort?.send({'type': 'pool-access', 'data': true});
            wsTalker(phone, sendPort)
                .then((value) => sendPort?.send({'type': 'ws-connection-status', 'data': true}));
          }).onError((error, stackTrace) {
            sendPort?.send({'type': 'pool-access', 'data': false});
          });
        });
      }
    });
    _connSub = Stream.periodic(const Duration(seconds: 10)).listen((event) {
      if (channel == null && _connectionAttempt < 5) {
        Connectivity().checkConnectivity().then((connStatus) async {
          if (connStatus != ConnectivityResult.none && channel == null) {
            FlutterForegroundTask.getData<String>(key: 'phone').then((phone) {
              _apIs.getWSAuth().then((poolGranted) {
                wsTalker(phone, sendPort).then(
                    (value) => sendPort?.send({'type': 'ws-connection-status', 'data': true}));
              });
            });
          }
          _connectionAttempt++;
        });
      }
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _acclSub?.cancel();
    _gyroSub?.cancel();
    _userAcclSub?.cancel();
    _locationSub?.cancel();
    channel?.sink.close();
    _majorStream?.cancel();
    _miniStream?.cancel();
    // _localUploader?.cancel();
    FlutterForegroundTask.clearAllData();
    _connSub?.cancel();
  }

  @override
  void onButtonPressed(String id) {
    if (id == "false_alert") {
      // TODO: Send emergency false message
      _emergencySMSServiceApi.sendFalseEmergencyMessage().then((value) {
        FlutterForegroundTask.updateService(
            notificationTitle: 'Vicara fall detection service',
            notificationText: "Tap to return to the app.");
      });
    } else if (id == "exit") {
      channel?.sink.close();
      channel = null;
      FlutterForegroundTask.stopService();
    }
  }
}
