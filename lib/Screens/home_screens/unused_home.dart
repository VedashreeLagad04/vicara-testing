import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/notification_card.dart';
import 'package:badges/badges.dart';
import 'package:vicara/Screens/fall_detection_screen/ambulance_screen.dart';
import 'package:vicara/Services/APIs/auth_api.dart';
import 'package:vicara/Services/APIs/emergency_sms_service.dart';
import 'package:vicara/Services/APIs/notification_and_fall_history_apis.dart';
import 'package:vicara/Services/APIs/sensor_sync.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/db/sensordb.dart';
import 'package:vicara/Services/location_service.dart';
import 'package:vicara/Services/logout_popup.dart';
import 'package:vicara/Services/low_pass_filter.dart';
import 'package:vicara/Services/notifier.dart';
import 'package:vicara/Services/prefs.dart';
import 'package:vicara/Services/sensor_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

bool shouldExit = false;

class ForegroundTaskHandler extends TaskHandler {
  @override
  void onButtonPressed(String id) {
    print('onButtonPressed >> $id');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onEvent
    throw UnimplementedError();
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onStart
    throw UnimplementedError();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final Notifier _notifier = Notifier();
  final Preferences _preferences = Preferences();
  final SensorService _sensorService = SensorService();
  final StreamController<bool> _locationConnectionStream = StreamController<bool>();
  final Auth _auth = Auth();
  final Sync _sync = Sync();
  dynamic sensorEvent;
  late StreamSubscription _miniStream;
  late StreamSubscription _majorStream;
  final NotificationAndFallHistory _notificationAndFallHistory = NotificationAndFallHistory();
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

  bool internetAvailable = false;
  var acclData;
  var gyroData;
  var location;
  var gravityData;
  var _freshNotification = [];
  final LocalDB _localDB = LocalDB();
  final StreamController<bool> _wsConnectionStream = StreamController();
  final StreamController<Map> _notifications = StreamController();
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
  };

  Future<void> wsTalker(String? phone) async {
    if (phone == null) return;
    if (channel == null) {
      channel = WebSocketChannel.connect(Uri.parse(wsURL + phone));
      channel!.stream.listen(
        (event) async {
          var result = json.decode(event);
          var date = DateTime.fromMillisecondsSinceEpoch(result['timestamp'] * 1000);
          _notifications.sink.add({
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

  StreamSubscription<UserAccelerometerEvent>? _userAcclSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _acclSub;
  StreamSubscription<LocationData>? _locationSub;
  StreamSubscription<ConnectivityResult>? _connSub;
  @override
  void initState() {
    _locationService.init();
    var _sensorFilteredData = _sensorDataEmpty;

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
    _preferences.getString('phone_no').then((phone) {
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
        _sensorFilteredData['userId'] = phone;
        if (channel != null) {
          channel?.sink.add(json.encode(_sensorFilteredData));
        } else {
          if (internetAvailable) {
            if (await _apIs.getWSAuth()) {
              channel = WebSocketChannel.connect(Uri.parse(wsURL + phone));
              _wsConnectionStream.sink.add(true);
            }
          } else {}
          await _localDB.insertIntoDatabase(
              json.encode(_sensorFilteredData), _sensorFilteredData['timestamp']);
        }
        _sensorFilteredData = _sensorDataEmpty;
      });
    });
    _auth.authState.listen((user) {
      if (user == null) Navigator.pushReplacementNamed(context, auth);
    });
    _locationService.serviceEnabled.then((value) {
      _locationConnectionStream.add(value);
    });

    Stream.periodic(const Duration(seconds: 5)).listen((ticker) async {
      _locationConnectionStream.add(await _locationService.serviceEnabled);
    });
    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        internetAvailable = true;
      } else {
        internetAvailable = false;
      }
    });
    // _initForegroundTask();
    Stream.periodic(const Duration(seconds: 20)).listen((event) async {
      List data = await _localDB.getAllEntries('limit 25');
      if (data.isNotEmpty) {
        // TODO: UPLOAD SQLITE DATA
        try {
          await _sync.syncSensorData(data: data);
          await _localDB.deleteEntries('');
          print(data.length);
        } catch (e) {
          print(e);
        }
        print(data);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _acclSub?.cancel();
    _gyroSub?.cancel();
    _userAcclSub?.cancel();
    _locationSub?.cancel();
    channel?.sink.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          popLogout(
              context: context,
              callback: _auth.signOut,
              title: "Logout?",
              subTitle: "Do you want logout?");
          return true;
        } catch (e) {
          return false;
        }
      },
      child: WillStartForegroundTask(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'Vicara Foreground Service',
          channelName: 'Foreground Notification',
          channelDescription: 'This notification appears when the foreground service is running.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            const NotificationButton(id: 'exit', text: 'exit'),
          ],
        ),
        callback: () => FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler()),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          autoRunOnBoot: false,
          allowWifiLock: false,
        ),
        printDevLog: true,
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        onWillStart: () async => _auth.currentUser != null || shouldExit,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Welcome to ',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['dark-w400-s24']),
                            TextSpan(
                                text: 'Drive Safe',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['dark-w600-s24'])
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 2.0, color: Provider.of<ThemeDataProvider>(context).orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              StreamBuilder<bool>(
                                stream: _locationConnectionStream.stream,
                                builder: (context, snapshot) {
                                  return snapshot.data == true
                                      ? Badge(
                                          badgeColor:
                                              Provider.of<ThemeDataProvider>(context).alertGreen,
                                          child: Text(
                                            'GPS Connected',
                                            style: Provider.of<ThemeDataProvider>(context)
                                                .textTheme['dark-w600-s10'],
                                          ),
                                        )
                                      : Badge(
                                          badgeColor:
                                              Provider.of<ThemeDataProvider>(context).alertRed,
                                          child: Text(
                                            'GPS disconnected',
                                            style: Provider.of<ThemeDataProvider>(context)
                                                .textTheme['dark-w600-s10'],
                                          ),
                                        );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
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
                                  await FirebaseCrashlytics.instance.recordError(err, stacktrace,
                                      reason: "requesting websocket connection");
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
                                        snapshot.data == true
                                            ? 'Server Connected'
                                            : 'Server Disconnected',
                                        style: Provider.of<ThemeDataProvider>(context)
                                            .textTheme['dark-w600-s10'],
                                      ),
                                    );
                                  }),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Provider.of<ThemeDataProvider>(context).black,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Stars Collected',
                                  style: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w600-s16'],
                                ),
                                Text(
                                  'You got 4 stars on your latest ride. Keep it up champ!',
                                  style: Provider.of<ThemeDataProvider>(context)
                                      .textTheme['white-w400-s10'],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '450',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w400-s48'],
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: 48,
                                color: Provider.of<ThemeDataProvider>(context).orange,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Provider.of<ThemeDataProvider>(context).orange,
                      ),
                      width: double.maxFinite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Text(
                              'Notifications',
                              style: Provider.of<ThemeDataProvider>(context)
                                  .textTheme['white-w600-s16'],
                            ),
                          ),
                          StreamBuilder<dynamic>(
                            stream: _notifications.stream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState != ConnectionState.active) {
                                return const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                );
                              } else {
                                if (snapshot.hasError) {
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          "Something went wrong while loading notifications",
                                          textAlign: TextAlign.center,
                                          style: Provider.of<ThemeDataProvider>(context)
                                              .textTheme['white-w600-s16']
                                              ?.copyWith(
                                                color: Provider.of<ThemeDataProvider>(context)
                                                    .alertRed,
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  if (snapshot.data == null || snapshot.data.length == 0) {
                                    return Center(
                                      child: Text("Nothing to show here!:(",
                                          style: Provider.of<ThemeDataProvider>(context)
                                              .textTheme['white-w600-s16']),
                                    );
                                  } else {
                                    _freshNotification.insert(0, snapshot.data);
                                    if (_freshNotification.length > 3) {
                                      _freshNotification = _freshNotification.sublist(0, 3);
                                    }

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _freshNotification
                                          .map<NotificationCard>(
                                            (element) => NotificationCard(
                                              event: element['type'] ?? 'UNKNOWN',
                                              time: element['time'].length < 5
                                                  ? element['time']
                                                  : element['time'].substring(0, 5) ?? 'UNKNOWN',
                                              date: element['date'] ?? 'UNKNOWN',
                                              place: element['place'] != null
                                                  ? element['place'].split('/')[0]
                                                  : 'Nearby',
                                            ),
                                          )
                                          .toList(),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Provider.of<ThemeDataProvider>(context).orange,
                      ),
                      width: double.maxFinite,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Text(
                              'Additional Information',
                              style: Provider.of<ThemeDataProvider>(context)
                                  .textTheme['white-w600-s16'],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(emergencyInfo);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                      color: Provider.of<ThemeDataProvider>(context).white,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.medical_services),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          'Emergency Information',
                                          style: Provider.of<ThemeDataProvider>(context)
                                              .textTheme['dark-w600-s14'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  // Notification.();
                                  Navigator.of(context).pushNamed(fallHistory);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                      color: Provider.of<ThemeDataProvider>(context).white,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(FontAwesomeIcons.carCrash),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          'Fall History',
                                          style: Provider.of<ThemeDataProvider>(context)
                                              .textTheme['dark-w600-s14'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center(
                    //   child: RoundButton(
                    //     text: 'Log Out',
                    //     onPressed: () async {
                    //       await _auth.signOut();
                    //       Navigator.pushReplacementNamed(context, auth);
                    //     },
                    //   ),
                    // ),
                    // Center(
                    //   child: RoundButton(
                    //     text: 'Kill me',
                    //     onPressed: () async {

                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
