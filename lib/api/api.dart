import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillhub_sdk_flutter/api/auth_info.dart';
import 'package:tillhub_sdk_flutter/api/routes/base_route.dart';
import 'package:tillhub_sdk_flutter/api/routes/devices_route.dart';
import 'package:tillhub_sdk_flutter/api/routes/stocks_route.dart';
import 'package:tillhub_sdk_flutter/utils/pather.dart';
import 'package:tillhub_sdk_flutter/utils/utils.dart';

const _authKey = 'TillhubSdk/authInfo';

/// Abstraction layer for the Tillhub API
///
/// Allows interacting with the API as a regular or sub user.
/// Don't forget to login first!
class Api {
  static final Logger logger = Logger('Api');
  Dio dio;
  AuthInfo authInfo;
  final String baseUrl;
  final SharedPreferences sharedPreferences;

  Api({
    @required this.baseUrl,
    @required this.sharedPreferences,
  }) {
    try {
      String rawAuthInfo = sharedPreferences.getString(_authKey);
      if (rawAuthInfo != null) {
        setAuth(AuthInfo.fromJson(jsonDecode(rawAuthInfo)), skipSave: true);
      }
    } catch (e, s) {
      logger.info('failed to load auth info from SharedPreferences.', e, s);
    }
  }

  BaseRoute get branches => _genRoute('v0', 'branches');
  BaseRoute get processes => _genRoute('v0', 'processes');
  BaseRoute get staff => _genRoute('v0', 'staff');

  BaseRoute get products => _genRoute('v1', 'products');
  BaseRoute get registers => _genRoute('v1', 'registers');
  StocksRoute get stocks => StocksRoute(dio, _getUserId());
  DevicesRoute get devices => DevicesRoute(dio, _getUserId());

  /// Sets the authentication information to be used in future requests.
  ///
  /// Use [skipSave] if saving them in SharedPreferences is undesired.
  setAuth(AuthInfo authInfo, {bool skipSave = false}) {
    logger.finest('setAuth: $authInfo, skipSave: $skipSave');

    this.authInfo = authInfo;

    if (!skipSave) {
      sharedPreferences.setString(_authKey, jsonEncode(authInfo.toJson()));
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: 5000,
//      receiveTimeout: 5000,
      headers: {
        if (authInfo != null)
          'authorization': '${authInfo.token_type} ${authInfo.token}'
      },
    ));

    dio.interceptors.add(getInfiniteRetriesInterceptor(dio));
  }

  /// Logs the user into a new session.
  ///
  /// Automatically calls [setAuth], so you don't have to.
  Future<void> login(String name, String password,
      [String organisation]) async {
    logger.finest('login');

    Response<Map<String, dynamic>> response;
    if (organisation == null || organisation.isEmpty) {
      response = await dio.post<Map<String, dynamic>>(
        '/api/v0/users/login',
        data: {
          "email": name,
          "password": password,
        },
      );
    } else {
      response = await dio.post<Map<String, dynamic>>(
        '/api/v1/users/auth/organisation/login',
        data: {
          "username": name,
          "password": password,
          "organisation": organisation,
        },
      );
    }

    BaseRoute.logResponse(response);

    AuthInfo aInfo = AuthInfo.fromJson(response.data);
    setAuth(aInfo);
  }

  /// Logs the user out of the current session.
  void logout() {
    setAuth(null);
  } // not sure if needed

  /// Returns true if authentication information exists that is not expired, false otherwise.
  bool isAuthenticated() {
    if (authInfo == null) return false;

    int expireDate;

    try {
      var jwt = parseJwt(authInfo.token);
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

  /// Calls the /me route and returns the result.
  Future<Map<String, dynamic>> me() async {
    String path = '/api/v0/me';

    Response<Map<String, dynamic>> response = await dio.get(path);
    BaseRoute.logResponse(response);

    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  _genRoute(String version, String type) {
    if (authInfo == null) throw Exception('Client is not authenticated!');

    return BaseRoute(dio, Pather(version, type, _getUserId()));
  }

  String _getUserId() {
    String id = authInfo?.user?.legacy_id ?? authInfo?.user?.id;
    if (id == null) throw new Exception('missing authInfo or legacy_id/id');
    return id;
  }
}
