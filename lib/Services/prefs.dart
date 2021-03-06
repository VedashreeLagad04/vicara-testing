import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(){
    // SharedPreferences.
  }
  Future<void> setString(String value, String identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(identifier, value);
  }

  Future getString(String identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(identifier);
  }

  Future<void> setBool(bool value, String identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(identifier, value);
  }

  Future getBool(String identifier) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool(identifier);
  }

  Future clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
