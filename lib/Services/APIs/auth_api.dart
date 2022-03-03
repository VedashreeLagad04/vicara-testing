import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
    } on Exception catch (err, stacktrace) {
      await FirebaseCrashlytics.instance
          .recordError(err, stacktrace, reason: "while calling loguser API");
      throw "error while making authorization request to server" + err.toString();
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
    } on Exception catch (err, stacktrace) {
      await FirebaseCrashlytics.instance
          .recordError(err, stacktrace, reason: "while calling wsauth API");
      return false;
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode} +${apiResponse.data}";
    }
  }
}
