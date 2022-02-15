import 'package:dio/dio.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class AuthAPIs {
  final Preferences _preferences = Preferences();

  Future<dynamic> logUser(
      {required String name, required String phoneNumber, required String userUID}) async {
    Response apiResponse;
    try {
      apiResponse = await Dio().post(
        apiBaseUrl + 'auth/logUser',
        data: {
          "user": {"name": name, "phone": phoneNumber, "userUID": userUID}
        },
      );
    } catch (e) {
      throw "error while making request to server" + e.toString();
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode} +${apiResponse.data}";
    }
  }

  Future<dynamic> getWSAuth() async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");

    try {
      apiResponse = await Dio().get(
        apiBaseUrl + 'auth/authorize',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw "error while making request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode} +${apiResponse.data}";
    }
  }
}
