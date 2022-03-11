import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:badges/badges.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/fall_detection_screen/ambulance_screen.dart';
import 'package:vicara/Services/APIs/auth_api.dart';
import 'package:vicara/Services/auth/auth.dart';
// import 'package:vicara/Services/APIs/sensor_sync.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/db/sensordb.dart';
import 'package:vicara/Services/location_service.dart';
import 'package:vicara/Services/low_pass_filter.dart';
import 'package:vicara/Services/notifier.dart';
import 'package:vicara/Services/prefs.dart';
import 'package:vicara/Services/sensor_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';

class ServerStatus extends StatefulWidget {
  final StreamSink<Map<dynamic, dynamic>> notificationSink;
  const ServerStatus({required this.notificationSink, Key? key}) : super(key: key);

  @override
  _ServerStatusState createState() => _ServerStatusState();
}

class _ServerStatusState extends State<ServerStatus> {
  final LocationService _locationService = LocationService();
  final Notifier _notifier = Notifier();
  final Preferences _preferences = Preferences();
  final SensorService _sensorService = SensorService();
  final StreamController<bool> _locationConnectionStream = StreamController<bool>();
  // final Sync _sync = Sync();
  dynamic sensorEvent;
  final AuthAPIs _apIs = AuthAPIs();
  WebSocketChannel? channel;
  final LowPassFilter _lpf = LowPassFilter(1, 50);
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
  final LocalDB _localDB = LocalDB();
  final StreamController<bool> _wsConnectionStream = StreamController.broadcast();
  double _connectionAttempt = 0;
  Future<void> wsTalker(String? phone) async {
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
        (event) async {
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
        _sensorFilteredData['accuracy'] = location.accuracy;
        _sensorFilteredData['speed'] = location.speed;
        _sensorFilteredData['lat'] = location.latitude;
        _sensorFilteredData['long'] = location.longitude;
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

      channel!.stream.listen(
        (event) async {
          var result = json.decode(event);
          var date = DateTime.fromMillisecondsSinceEpoch(result['timestamp'] * 1000);

          widget.notificationSink.add({
            'type': result['type'],
            'place': result['place'],
            'time':
                "${(date.hour < 10 ? '0${date.hour}' : date.hour)}:${(date.minute < 10 ? '0${date.minute}' : date.minute)}",
            'date': "${date.year}-${date.month}-${date.day}"
          });
          if (result['type'] == 'Fall') {
            try {
              await _notifier.show(
                'event detected ' + result['name'],
                'Notified',
                result['type'],
              );
              Fluttertoast.showToast(
                msg: "Notified!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: const Color(0xFF1A1C1F),
                textColor: Colors.white,
                fontSize: 16.0,
              );
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AmbulanceScreen(lat: result['lat'], long: result['long'])));
            } on Exception catch (err, stacktrace) {
              await FirebaseCrashlytics.instance
                  .recordError(err, stacktrace, reason: "showing event notification");
              Fluttertoast.showToast(
                msg: err.toString(),
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: const Color(0xFF1A1C1F),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          }
        },
        onError: (error) {
          print("Error-------------------------");
          channel = null;
          _wsConnectionStream.sink.add(false);
        },
        onDone: () {
          print("Done-------------------------");
          channel = null;
          _wsConnectionStream.sink.add(false);
        },
      );
    }
  }

  final Auth _auth = Auth();
  StreamSubscription? _localUploader;
  StreamSubscription<UserAccelerometerEvent>? _userAcclSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _acclSub;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription? _connSub;
  @override
  void initState() {
    ForegroundService().start();
    _userAcclSub = _sensorService.userAccelerometerStream.listen((event) {
      acclData = event;
    });
    _gyroSub = _sensorService.gyroscopeStream.listen((event) {
      gyroData = event;
    });
    _acclSub = _sensorService.accelerometerStream.listen((event) {
      gravityData = event;
    });
    _locationSub = _locationService.locationStream.listen((event) {
      location = event;
    });
    _locationService.serviceEnabled.then((value) {
      _locationConnectionStream.add(value);
    });

    Connectivity().checkConnectivity().then((connStatus) async {
      if (connStatus != ConnectivityResult.none && channel == null) {
        try {
          bool pool = await _apIs.getWSAuth();
          if (pool == true) {
            wsTalker(await _preferences.getString('phone_no'))
                .then((val) => _wsConnectionStream.sink.add(true));
          }
        } catch (err) {
          Fluttertoast.showToast(
            msg: err.toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color(0xFF1A1C1F),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    });

    _connSub = Stream.periodic(const Duration(seconds: 10)).listen((event) {
      if (channel == null && _connectionAttempt < 5) {
        Connectivity().checkConnectivity().then((connStatus) async {
          if (connStatus != ConnectivityResult.none && channel == null) {
            try {
              bool pool = await _apIs.getWSAuth();
              if (pool == true) {
                wsTalker(await _preferences.getString('phone_no'))
                    .then((val) => _wsConnectionStream.sink.add(true));
              }
            } catch (err) {
              Fluttertoast.showToast(
                msg: err.toString(),
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: const Color(0xFF1A1C1F),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          }
          _connectionAttempt++;
        });
      }
    });

    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none && channel == null) {
        _apIs.getWSAuth().then((value) {
          if (value = true) {
            _preferences.getString('phone_no').then((val) {
              wsTalker(val).then((value) {
                _wsConnectionStream.sink.add(true);
              }).catchError((err) {
                Fluttertoast.showToast(
                  msg: err.toString(),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: const Color(0xFF1A1C1F),
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              });
            });
          } else {
            Fluttertoast.showToast(
              msg: "Server pool full, try again later.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: const Color(0xFF1A1C1F),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }).catchError((err) {
          Fluttertoast.showToast(
            msg: err.toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color(0xFF1A1C1F),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        });
      }
    });
    _notifier.load((payload) async {
      if (payload != null && payload == "Fall") {
        debugPrint('notification payload: $payload');
      }
    });
    _localUploader = Stream.periodic(const Duration(seconds: 20)).listen((event) async {
      // List data = await _localDB.getAllEntries('limit 25');
      // if (data.isNotEmpty) {
      //   // TODO: UPLOAD SQLITE DATA
      //   try {
      //     await _sync.syncSensorData(data: data);
      //     await _localDB.deleteEntries('');
      //     print(data.length);
      //   } catch (e) {
      //     print(e);
      //   }
      //   print(data);
      // }
    });
    _locationService.init();
    super.initState();
  }

  @override
  void dispose() {
    if (_auth.currentUser == null) {
      _acclSub?.cancel();
      _gyroSub?.cancel();
      _userAcclSub?.cancel();
      _locationSub?.cancel();
      channel?.sink.close();
      _majorStream?.cancel();
      _miniStream?.cancel();
      _localUploader?.cancel();
      _connSub?.cancel();
      ForegroundService().stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.dns_outlined),
        GestureDetector(
          onTap: () async {
            try {
              if (await _apIs.getWSAuth() == true) {
                var phone = await _preferences.getString('phone_no');
                await wsTalker(phone);
                _wsConnectionStream.sink.add(true);
              } else {
                Fluttertoast.showToast(
                  msg: "Try connecting after some time.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: const Color(0xFF1A1C1F),
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
            } on Exception catch (err, stacktrace) {
              await FirebaseCrashlytics.instance
                  .recordError(err, stacktrace, reason: "requesting websocket connection");
              Fluttertoast.showToast(
                msg: err.toString(),
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: const Color(0xFF1A1C1F),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          },
          child: StreamBuilder<bool>(
              stream: _wsConnectionStream.stream,
              initialData: false,
              builder: (context, snapshot) {
                return Badge(
                  badgeColor: snapshot.data == true
                      ? Provider.of<ThemeDataProvider>(context).alertGreen
                      : Provider.of<ThemeDataProvider>(context).alertRed,
                  child: Text(
                    snapshot.data == true ? 'Server Connected' : 'Server Disconnected',
                    style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s10'],
                  ),
                );
              }),
        ),
      ],
    );
  }
}
