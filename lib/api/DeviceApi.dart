import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillhub_sdk_flutter/api/DeviceAuthInfo.dart';
import 'package:tillhub_sdk_flutter/api/routes/BaseRoute.dart';
import 'package:tillhub_sdk_flutter/api/routes/DevicesRoute.dart';
import 'package:tillhub_sdk_flutter/utils/Pather.dart';
import 'package:tillhub_sdk_flutter/utils/Utils.dart';

const _AUTHKEY = 'TillhubSdk/deviceAuthInfo';

/// Abstraction layer for the Tillhub API
///
/// Allows interacting with the API as a device.
///
/// Most features need authentication.
/// Bind this device with the [Api] part of the [TillhubSdk],
/// then use the received device authentication with [setAuth].
class DeviceApi {
  static final Logger logger = new Logger('DeviceApi');

  Dio dio;
  DeviceAuthInfo authInfo;
  final String baseUrl;
  final SharedPreferences sharedPreferences;

  DeviceApi({
    @required this.baseUrl,
    @required this.sharedPreferences,
  }) {
    try {
      String rawAuthInfo = sharedPreferences.getString(_AUTHKEY);
      if (rawAuthInfo != null) {
        setAuth(DeviceAuthInfo.fromJson(jsonDecode(rawAuthInfo)),
            skipSave: true);
      }
    } catch (e, s) {
      logger.info('failed to load auth info from SharedPreferences.', e, s);
    }
  }

  /// Sets the authentication information to be used in future requests.
  ///
  /// Use [skipSave] if saving them in SharedPreferences is undesired.
  setAuth(DeviceAuthInfo authInfo, {bool skipSave = false}) {
    logger.finest('setAuth: $authInfo, skipSave: $skipSave');

    this.authInfo = authInfo;

    if (!skipSave) {
      sharedPreferences.setString(_AUTHKEY, jsonEncode(authInfo.toJson()));
    }

    String authorization;
    if (authInfo?.authed_token != null) {
      authorization = 'Bearer ${authInfo.authed_token}';
    } else {
      authorization =
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3N1ZXIiOiJ0aWxsaHViLXRoaW5ncy1hcGkiLCJhdWRpZW5jZSI6WyJ0aGluZ3Mtc3RhZ2luZy50aWxsaHViLmNvbSIsInRoaW5ncy50aWxsaHViLmNvbSJdLCJqdGkiOiJhMjI2NjRhOS1kYzNhLTRiMDItOGU2NS03YjQ4ZDg2ZTU2ZGMiLCJpYXQiOjE1NTI5MjU0ODJ9.3goE8LKFc0Ui0HUebf7grTNlXjvF1XbeoY1kkEs_bBo';
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: 5000,
      headers: {
        'authorization': authorization,
      },
    ));

    dio.interceptors.add(getInfiniteRetriesInterceptor(dio));
  }

  /// Advertises the device as unbound.
  ///
  /// Returns the remote representation of the device, or a special authentication message if a binding process for this device has been conducted.
  Future<Map<String, dynamic>> advertise([String unboundId]) async {
    Object deviceData = await getDeviceData();
    String path = Pather('v0', 'devices/advertise').path(unboundId);

    logger.finest('advertising $deviceData to: $path');

    Response<Map<String, dynamic>> response;

    if (unboundId != null) {
      response = await dio.patch(path, data: deviceData);
    } else {
      response = await dio.post(path, data: deviceData);
    }
    BaseRoute.logResponse(response);

    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  DevicesRoute get devices {
    if (authInfo == null) throw Exception('Device is not authenticated!');

    return DevicesRoute(dio, authInfo.client_account);
  }

  /// Returns true if authentication information exists that is not expired, false otherwise.
  bool isAuthenticated() {
    if (authInfo == null) return false;

    int expireDate;

    try {
      var jwt = parseJwt(authInfo.authed_token);
      expireDate = jwt['exp'];
    } catch (e) {
      print(e);
    }

    // null implies failed parsing or missing auth token
    if (expireDate == null) return false;

    // expireDate is in the past
    if (expireDate <= DateTime.now().millisecondsSinceEpoch) return false;

    return true;
  }
}
