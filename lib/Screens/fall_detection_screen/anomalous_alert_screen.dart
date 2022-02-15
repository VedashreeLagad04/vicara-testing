import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';
import 'package:vicara/Screens/fall_detection_screen/delivery_partner_safe_screen.dart';

class AnomalousAlertScreen extends StatelessWidget {
  const AnomalousAlertScreen({Key? key}) : super(key: key);

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
                'We’ve informed your contacts that you are safe and it was an anomalous alert.',
                textAlign: TextAlign.center,
                style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
              ),
            ),
            SvgPicture.asset('assets/Images/delivery_partner.svg'),
            Padding(
              padding: const EdgeInsets.only(top: 48.0, bottom: 13.0),
              child: Text(
                'We’re glad that you are safe. Happy Delivering!',
                textAlign: TextAlign.center,
                style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w500-s12'],
              ),
            ),
            RoundButton(
                text: 'Continue',
                onPressed: () async {
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DeliverPartnerSafeScreen(),
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }
}
