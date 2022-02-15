import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/permission_service.dart';
import 'package:vicara/Services/prefs.dart';
import 'package:vicara/Services/routing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Services/consts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Preferences _preferences = Preferences();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final Auth _auth = Auth();
  String preloadedRoute = auth;
  String? token = await _preferences.getString('auth_token');
  String? phoneNo = await _preferences.getString('phone_no');
  bool? configured = await _preferences.getBool('configured');
  if (token != null && phoneNo != null && _auth.currentUser != null) {
    if (configured != null && configured) {
      preloadedRoute = home;
    } else {
      preloadedRoute = conf;
    }
  }
  runApp(MyApp(initialRoute: preloadedRoute));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final PermissionService _permissionService = PermissionService();
  @override
  void initState() {
    _permissionService.getPermissions;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ThemeDataProvider>(create: (context) => ThemeDataProvider()),
      ],
      child: MaterialApp(
        title: 'Vicara Fall Detector',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        ),
        initialRoute: widget.initialRoute,
        routes: router,
      ),
    );
  }
}
