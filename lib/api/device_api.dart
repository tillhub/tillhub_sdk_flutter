import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tillhub_sdk_flutter/api/device_auth_info.dart';
import 'package:tillhub_sdk_flutter/api/routes/base_route.dart';
import 'package:tillhub_sdk_flutter/api/routes/devices_route.dart';
import 'package:tillhub_sdk_flutter/utils/pather.dart';
import 'package:tillhub_sdk_flutter/utils/utils.dart';

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

  DeviceApi({
    @required this.baseUrl,
    this.authInfo,
  }) {
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
    try {
      checkAuth(authInfo);
    } catch (e) {
      return false;
    }

    return true;
  }

  static void checkAuth(DeviceAuthInfo authInfo) {
    if (authInfo == null) throw new Exception('DeviceAuthInfo is null');

    int expireDate;

    try {
      var jwt = parseJwt(authInfo.authed_token);
      expireDate = jwt['exp'];
    } catch (e) {
      throw new Exception('Failed to parse DeviceAuthInfo token: $e');
    }

    // expiration date, so token is still valid
    if (expireDate == null) return;

    // expireDate is in the past
    if (expireDate <= DateTime.now().millisecondsSinceEpoch)
      throw new Exception('DeviceAuthInfo expired (date: $expireDate)');
  }
}
