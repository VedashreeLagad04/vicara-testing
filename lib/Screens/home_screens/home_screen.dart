import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/notification_card.dart';
import 'package:badges/badges.dart';
import 'package:vicara/Screens/fall_detection_screen/ambulance_screen.dart';
import 'package:vicara/Services/APIs/auth_api.dart';
import 'package:vicara/Services/APIs/emergency_sms_service.dart';
import 'package:vicara/Services/APIs/notification_and_fall_history_apis.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/location_service.dart';
import 'package:vicara/Services/logout_popup.dart';
import 'package:vicara/Services/notifier.dart';
import 'package:vicara/Services/prefs.dart';
import 'package:vicara/Services/sensor_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final EmergencySMSServiceApi _emergencySMSServiceApi = EmergencySMSServiceApi();
  dynamic sensorEvent;
  final NotificationAndFallHistory _notificationAndFallHistory = NotificationAndFallHistory();
  final AuthAPIs _apIs = AuthAPIs();
  bool _serverConnected = false;
  WebSocketChannel? channel;
  var acclData;
  var gyroData;
  var location;
  var gravityData;

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
      channel = WebSocketChannel.connect(
        Uri.parse(wsURL + phone),
      );

      StreamSubscription _miniStream =
          Stream.periodic(const Duration(milliseconds: 200)).listen((event) async {
        _sensorFilteredData['gravityX'].add(gravityData.x ?? 0);
        _sensorFilteredData['gravityY'].add(gravityData.y ?? 0);
        _sensorFilteredData['gravityZ'].add(gravityData.z ?? 0);
        _sensorFilteredData['gyroX'].add(gyroData.x ?? 0);
        _sensorFilteredData['gyroY'].add(gyroData.y ?? 0);
        _sensorFilteredData['gyroZ'].add(gyroData.z ?? 0);
        _sensorFilteredData['linearAccelX'].add(acclData.x ?? 0);
        _sensorFilteredData['linearAccelY'].add(acclData.y ?? 0);
        _sensorFilteredData['linearAccelZ'].add(acclData.z ?? 0);
      });
      StreamSubscription _majorStream =
          Stream.periodic(const Duration(seconds: 10)).listen((event) async {
        _sensorFilteredData['accuracy'] = location.accuracy;
        _sensorFilteredData['speed'] = location.speed;
        _sensorFilteredData['lat'] = location.latitude;
        _sensorFilteredData['long'] = location.longitude;
        _sensorFilteredData['timestamp'] = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        _sensorFilteredData['acceleration'] =
            sqrt((acclData.x * acclData.x) + (acclData.y * acclData.y) + (acclData.z * acclData.z));
        _sensorFilteredData['acceleration'] =
            sqrt((gyroData.x * gyroData.x) + (gyroData.y * gyroData.y) + (gyroData.z * gyroData.z));
        channel!.sink.add(json.encode(_sensorFilteredData));
        _sensorFilteredData = _sensorDataEmpty;
      });
      channel!.stream.listen((event) async {
        var result = json.decode(event);
        if (result['type'] == 'Fall') {
          // fall event id
          await _emergencySMSServiceApi.sendEmergencyMessage(
              lat: location.latitude ?? 0, long: location.longitude ?? 0);
          await _notifier.show(
            'You have Taken a fall',
            'notification sent to your emergency contacts',
            'Loerm',
          );
          Fluttertoast.showToast(
            msg: "Notified!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color(0x4F464646),
            textColor: Colors.black,
            fontSize: 16.0,
          );
        }
      }, onError: (error) {
        _miniStream.cancel();
        _majorStream.cancel();
        setState(() {
          _serverConnected = false;
        });
      });
    }
  }

  @override
  void initState() {
    _sensorService.userAccelerometerStream.listen((event) {
      acclData = event;
    });
    _sensorService.gyroscopeStream.listen((event) {
      gyroData = event;
    });
    _sensorService.userAccelerometerStream.listen((event) {
      gravityData = event;
    });
    _locationService.locationStream.listen((event) {
      location = event;
    });
    super.initState();
    _auth.authState.listen((user) {
      if (user == null) Navigator.pushReplacementNamed(context, auth);
    });
    Stream.periodic(const Duration(seconds: 5)).listen((ticker) async {
      _locationConnectionStream.add(await _locationService.serviceEnabled);
    });
    _locationService.init();
    // _apIs.getWSAuth().then((value) {
    //   if (value = true) {
    //     _preferences.getString('phone_no').then((val) {
    //       wsTalker(val).then((value) {
    //         setState(() {
    //           _serverConnected = true;
    //         });
    //       }).catchError((err) {
    //         Fluttertoast.showToast(
    //           msg: err.toString(),
    //           toastLength: Toast.LENGTH_SHORT,
    //           gravity: ToastGravity.CENTER,
    //           timeInSecForIosWeb: 1,
    //           backgroundColor: const Color(0x4F464646),
    //           textColor: Colors.black,
    //           fontSize: 16.0,
    //         );
    //       });
    //     });
    //   } else {
    //     Fluttertoast.showToast(
    //       msg: "Server pool full, try again later.",
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.CENTER,
    //       timeInSecForIosWeb: 1,
    //       backgroundColor: const Color(0x4F464646),
    //       textColor: Colors.black,
    //       fontSize: 16.0,
    //     );
    //   }
    // }).catchError((err) {
    //   Fluttertoast.showToast(
    //     msg: err.toString(),
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: const Color(0x4F464646),
    //     textColor: Colors.black,
    //     fontSize: 16.0,
    //   );
    // });
    _notifier.load((payload) async {
      if (payload != null) {
        debugPrint('notification payload: $payload');
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AmbulanceScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
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
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
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
                                  setState(() {
                                    _serverConnected = true;
                                  });
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Try connecting after some time.",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: const Color(0x4F464646),
                                    textColor: Colors.black,
                                    fontSize: 16.0,
                                  );
                                }
                              } catch (err) {
                                Fluttertoast.showToast(
                                  msg: err.toString(),
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: const Color(0x4F464646),
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                              }
                            },
                            child: Badge(
                              badgeColor: _serverConnected
                                  ? Provider.of<ThemeDataProvider>(context).alertGreen
                                  : Provider.of<ThemeDataProvider>(context).alertRed,
                              child: Text(
                                _serverConnected ? 'Server Connected' : 'Server Disconnected',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['dark-w600-s10'],
                              ),
                            ),
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
                            style:
                                Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s16'],
                          ),
                        ),
                        FutureBuilder<dynamic>(
                          future: _notificationAndFallHistory.getNotifications(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
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
                                              color:
                                                  Provider.of<ThemeDataProvider>(context).alertRed,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                if (!snapshot.hasData ||
                                    snapshot.data['data'] == null ||
                                    snapshot.data['data'].length == 0) {
                                  return Center(
                                    child: Text("Nothing to show here!:(",
                                        style: Provider.of<ThemeDataProvider>(context)
                                            .textTheme['white-w600-s16']),
                                  );
                                } else {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: snapshot.data['data']
                                        .map((element) => const NotificationCard()),
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
                            style:
                                Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s16'],
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
                                    const Icon(Icons.dns_outlined),
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
                                    const Icon(Icons.dns_outlined),
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
    );
  }
}
