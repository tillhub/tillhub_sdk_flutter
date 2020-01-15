import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tillhub_sdk_flutter/utils/Pather.dart';

import 'BaseRoute.dart';

/// Extension of [BaseRoute] offering features specific for the 'devices' route
class DevicesRoute extends BaseRoute {
  static final Logger logger = Logger('Api:DevicesRoute');

  DevicesRoute(Dio dio, userId) : super(dio, Pather('v0', 'devices', userId));

  /// Binds an unbound device matching [unboundId] to the currently logged in account, using the [token] that the device received from the backend.
  /// [registerId] is required if the unbound device is a Hubfront device (as it must belong to a register).
  Future<Map<String, dynamic>> bind({
    @required String unboundId,
    @required String token,
    String registerId,
  }) async {
    String path = pather.path('$unboundId/bind');
    logger.finest('POST $path');

    Response<Map<String, dynamic>> response = await dio.post(path, data: {
      'client_account': pather.userId,
      if (registerId != null) 'register': registerId,
      'token': token
    });
    BaseRoute.logResponse(response);

    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  /// Returns the authentication token for a bound device matching [id].
  Future<Map<String, dynamic>> token(String id) async {
    String path = pather.path('$id/token');
    logger.finest('GET $path');
    Response<Map<String, dynamic>> response = await dio.get(path);
    BaseRoute.logResponse(response);

    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }
}
