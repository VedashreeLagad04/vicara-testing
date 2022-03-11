import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class Sync {
  final Preferences _preferences = Preferences();
  Future<dynamic> syncSensorData({required dynamic data}) async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");
    try {
      apiResponse = await Dio().post(
        apiBaseUrl + 'syncSensorData/sync',
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
        data: emergencyInfo,
      );
    } on Exception catch (err, stacktrace) {
      await FirebaseCrashlytics.instance
          .recordError(err, stacktrace, reason: "while calling sync sensor data info API");
      throw "error while making sync request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }
}
