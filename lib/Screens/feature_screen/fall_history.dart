import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/fall_history_card.dart';
import 'package:vicara/Services/APIs/notification_and_fall_history_apis.dart';

class FallHistoryScreen extends StatelessWidget {
  const FallHistoryScreen({Key? key}) : super(key: key);
  static final NotificationAndFallHistory _notificationAndFallHistory =
      NotificationAndFallHistory();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fall History',
                          style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
                        )
                      ],
                    ),
                    SvgPicture.asset('assets/Images/falling_delivery_partner_mini.svg')
                  ],
                ),
                FutureBuilder<dynamic>(
                  future: _notificationAndFallHistory.getFallHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                      );
                    } else {
                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                "Something went wrong while loading fall history.",
                                textAlign: TextAlign.center,
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w600-s16']
                                    ?.copyWith(
                                      color: Provider.of<ThemeDataProvider>(context).alertRed,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 50.0),
                              child: Text(
                                "Nothing to show here!:(",
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w600-s16']
                                    ?.copyWith(color: Colors.orange),
                              ),
                            ),
                          );
                        } else {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: snapshot.data['data'].map(
                              (element) => const FallHistoryCard(),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
