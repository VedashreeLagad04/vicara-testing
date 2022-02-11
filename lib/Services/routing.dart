import 'package:vicara/Screens/Widgets/loading_screen.dart';
import 'package:vicara/Screens/emergency_info/configuration_screen.dart';
import 'package:vicara/Screens/emergency_info/emergency_info_screen.dart';
import 'package:vicara/Screens/fall_detection_screen/ambulance_screen.dart';
import 'package:vicara/Screens/fall_detection_screen/anomalous_alert_screen.dart';
import 'package:vicara/Screens/fall_detection_screen/delivery_partner_safe_screen.dart';
import 'package:vicara/Screens/feature_screen/fall_history.dart';
import 'package:vicara/Screens/home_screens/home_screen.dart';
import 'package:vicara/Screens/onboarding_screens/signup_screen.dart';
import 'package:vicara/Services/consts.dart';

// MaterialPageRoute router(RouteSettings settings) {
//   switch (settings.name) {
//     case '/':
//       return MaterialPageRoute(builder: (context) => const AuthScreen());
//     case '/home':
//       return MaterialPageRoute(builder: (context) => const HomeScreen());
//     case '/auth':
//       return MaterialPageRoute(builder: (context) => const AuthScreen());
//     default:
//       return MaterialPageRoute(builder: (context) => const AuthScreen());
//   }
// }

dynamic router = {
  auth: (context) => const AuthScreen(),
  home: (context) => const HomeScreen(),
  loading: (context) => const LoadingScreen(),
  emergencyInfo: (context) => EmergencyInfoScreen(),
  fallHistory: (context) => const FallHistoryScreen(),
  ambulance: (context) => const AmbulanceScreen(),
  anomalousAlert: (context) => const AnomalousAlertScreen(),
  safe: (context) => const DeliverPartnerSafeScreen(),
  conf: (context) => const ConfigurationScreen(),
};
