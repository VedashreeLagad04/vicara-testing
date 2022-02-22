import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class EmergencyInfo {
  final Preferences _preferences = Preferences();
  Future<dynamic> setEmergencyInfo({required Map<String, dynamic> emergencyInfo}) async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");
    try {
      apiResponse = await Dio().post(
        apiBaseUrl + 'emergency_details/emergencyDetails',
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
        data: emergencyInfo,
      );
    } on Exception catch (err, stacktrace) {
      await FirebaseCrashlytics.instance
          .recordError(err, stacktrace, reason: "while calling set emergency info API");
      throw "error while making set emergency info request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }

  Future<dynamic> getEmergencyInfo() async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");
    try {
      apiResponse = await Dio().get(
        apiBaseUrl + 'emergency_details/emergencyDetails',
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
      );
    } on Exception catch (err, stacktrace) {
      await FirebaseCrashlytics.instance
          .recordError(err, stacktrace, reason: "while calling get emergency info API");
      throw "error while making get emergency info request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }
}
