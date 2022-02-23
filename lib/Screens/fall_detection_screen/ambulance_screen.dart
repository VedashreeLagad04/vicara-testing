import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Screens/fall_detection_screen/anomalous_alert_screen.dart';
import 'package:vicara/Services/APIs/emergency_sms_service.dart';

class AmbulanceScreen extends StatefulWidget {
  final double? lat;
  final double? long;
  const AmbulanceScreen({required this.lat, required this.long, Key? key}) : super(key: key);

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  final EmergencySMSServiceApi _emergencySMSServiceApi = EmergencySMSServiceApi();

  @override
  void initState() {
    _emergencySMSServiceApi
        .sendEmergencyMessage(lat: widget.lat ?? 0, long: widget.long ?? 0)
        .then((value) {
      Fluttertoast.showToast(
        msg: "Emergency message sent!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color(0xFF1A1C1F),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }).onError((error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 37.0),
              child: Text(
                'An Emergency Notification has been sent to your contacts',
                textAlign: TextAlign.center,
                style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
              ),
            ),
            Image.asset('assets/Images/ambulance.png'),
            Padding(
              padding: const EdgeInsets.only(top: 48.0, bottom: 13.0),
              child: Text(
                'If you are a bystander, please wait till the ambulance reaches. This act of kindness can save someone’s life.',
                textAlign: TextAlign.center,
                style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w500-s12'],
              ),
            ),
            RoundButton(
              text: 'Are you okay?',
              onPressed: () async {
                try {
                  await _emergencySMSServiceApi.sendFalseEmergencyMessage();
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AnomalousAlertScreen(),
                    ),
                  );
                } catch (err) {
                  Fluttertoast.showToast(
                    msg: err.toString(),
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 5,
                    backgroundColor: const Color(0xFF1A1C1F),
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
