import 'package:dio/dio.dart';

import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class EmergencySMSServiceApi {
  final Preferences _preferences = Preferences();
  Future<dynamic> sendEmergencyMessage({required double lat, required double long}) async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");

    try {
      apiResponse = await Dio().post(
        apiBaseUrl + 'emergencySMS/sendEmergencySMS',
        data: {
          "location": {
            "location": {"lat": lat, "long": long}
          }
        },
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw "error while making request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }

  Future<dynamic> sendFalseEmergencyMessage() async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");
    try {
      apiResponse = await Dio().post(
        apiBaseUrl + 'emergencySMS/sendFalseEmergencySMS',
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw "error while making request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }
}
