import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/prefs.dart';

class NotificationAndFallHistory {
  final Preferences _preferences = Preferences();
  Future<dynamic> getNotifications({int pageSize = 3, int pageNumber = 0}) async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");

    try {
      apiResponse = await Dio().get(
        apiBaseUrl +
            'notificationAndHistory/getNotifications?pageNo=$pageSize&pageSize=$pageNumber',
        options: Options(
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
      );
    } catch (err) {
      Fluttertoast.showToast(
        msg: err.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: const Color(0x4F464646),
        textColor: Colors.black,
        fontSize: 16.0,
      );
      throw "error while making request to server";
    }
    if (apiResponse.statusCode == 200) {
      return apiResponse.data;
    } else {
      throw "server returned with status ${apiResponse.statusCode}";
    }
  }

  Future<dynamic> getFallHistory({int pageSize = 5, int pageNumber = 0}) async {
    Response apiResponse;
    String token = await _preferences.getString("auth_token");
    try {
      apiResponse = await Dio().get(
        apiBaseUrl + 'notificationAndHistory/getFallHistory?pageNo=$pageNumber&pageSize=$pageSize',
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
