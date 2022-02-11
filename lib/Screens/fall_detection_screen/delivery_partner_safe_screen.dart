import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';

class DeliverPartnerSafeScreen extends StatelessWidget {
  const DeliverPartnerSafeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'We’re glad that you are okay.',
              textAlign: TextAlign.center,
              style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Text(
                'Stay Safe. Happy Delivering!',
                textAlign: TextAlign.center,
                style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s16'],
              ),
            ),
            SvgPicture.asset('assets/Images/delivery_partner.svg'),
            Padding(
              padding: const EdgeInsets.only(top: 51.0),
              child: RoundButton(
                  text: 'Continue',
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            )
          ],
        ),
      ),
    );
  }
}
