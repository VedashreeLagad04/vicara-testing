import 'package:dio/dio.dart';

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
    } catch (e) {
      throw "error while making request to server";
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
