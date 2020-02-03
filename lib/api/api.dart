import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:tillhub_sdk_flutter/api/auth_info.dart';
import 'package:tillhub_sdk_flutter/api/routes/base_route.dart';
import 'package:tillhub_sdk_flutter/api/routes/devices_route.dart';
import 'package:tillhub_sdk_flutter/api/routes/stocks_route.dart';
import 'package:tillhub_sdk_flutter/utils/pather.dart';
import 'package:tillhub_sdk_flutter/utils/utils.dart';

/// Abstraction layer for the Tillhub API
///
/// Allows interacting with the API as a regular or sub user.
/// Don't forget to login first!
class Api {
  static final Logger logger = Logger('Api');
  Dio dio;
  final AuthInfo authInfo;
  final String baseUrl;

  Api({
    @required this.baseUrl,
    this.authInfo,
  }) {
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

  BaseRoute get branches => _genRoute('v0', 'branches');
  BaseRoute get processes => _genRoute('v0', 'processes');
  BaseRoute get staff => _genRoute('v0', 'staff');

  BaseRoute get products => _genRoute('v1', 'products');
  BaseRoute get registers => _genRoute('v1', 'registers');
  StocksRoute get stocks => StocksRoute(dio, _getUserId());
  DevicesRoute get devices => DevicesRoute(dio, _getUserId());

  /// Logs the user into a new session.
  ///
  /// Automatically calls [setAuth], so you don't have to.
  Future<AuthInfo> login(String name, String password,
      [String organisation]) async {
    logger.finest('login');

    Response<Map<String, dynamic>> response;
    if (organisation == null) {
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

    return AuthInfo.fromJson(response.data);
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

  static void checkAuth(AuthInfo authInfo) {
    if (authInfo == null) throw new Exception('AuthInfo is null');

    int expireDate;

    try {
      var jwt = parseJwt(authInfo.token);
      expireDate = jwt['exp'];
    } catch (e) {
      throw new Exception('Failed to parse AuthInfo token: $e');
    }

    // expiration date, so token is still valid
    if (expireDate == null) return;

    // expireDate is in the past
    if (expireDate <= DateTime.now().millisecondsSinceEpoch)
      throw new Exception('AuthInfo expired (date: $expireDate)');
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

  BaseRoute _genRoute(String version, String type) {
    return BaseRoute(dio, Pather(version, type, _getUserId()));
  }

  String _getUserId() {
    return authInfo?.user?.legacy_id ?? authInfo?.user?.id;
  }
}
