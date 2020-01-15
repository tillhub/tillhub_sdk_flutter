import 'package:dio/dio.dart';
import 'package:tillhub_sdk_flutter/utils/pather.dart';

import 'base_route.dart';

/// Extension of [BaseRoute] offering features specific for the 'stock' route
class StocksRoute extends BaseRoute {
  StocksRoute(Dio dio, String userId)
      : super(dio, Pather('v0', 'stock', userId));

  /// Returns all available location created be the current user, optionally filtered by [query] parameters.
  Future<List<Map<String, dynamic>>> locations(
      [Map<String, dynamic> query]) async {
    var path = pather.path('locations');

    Response<Map<String, dynamic>> response =
        await dio.get(path, queryParameters: query);
    BaseRoute.logResponse(response);

    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results;
  }
}
