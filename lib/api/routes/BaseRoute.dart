import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:tillhub_sdk_flutter/utils/Pather.dart';
import 'package:tillhub_sdk_flutter/utils/Utils.dart';

/// A basic route implementation offering CRUD functions.
class BaseRoute {
  static final Logger logger = Logger('Api:BaseRoute');

  final Dio dio;
  final Pather pather;

  /// small utility function to log responses in a standardised manner.
  static logResponse(Response r) =>
      logger.finest('got response: ${r?.data?.toString()?.substring(0, 100)}');

  /// Creates a new Instance of [BaseRoute].
  ///
  /// [dio] needs to contain any required authorization headers.
  /// [pather] needs to be prepared with the correct API level & resource type for this route.
  BaseRoute(this.dio, this.pather);

  /// Returns all resources on this route, optionally filtered by [query] parameters.
  ///
  /// If backend results are paged, each page is queried until all resources have been gathered.
  /// Please use this only if you know that the amount of results is
  Future<List<Map<String, dynamic>>> getAll(
      [Map<String, dynamic> query]) async {
    var path = pather.path();
    logger.finest('GET $path, query: ${jsonEncode(query)}');

    var pageIterator = getAllPaged(startUrl: path, query: query);

    List<Map<String, dynamic>> results = [];
    // gather all pages
    while (pageIterator.moveNext()) {
      results.addAll(await pageIterator.current);
    }

    return results;
  }

  /// Returns all resources on this route, optionally filtered by [query] parameters.
  ///
  /// Contrary to [BaseRoute.getAll], this function returns a [PagedGetIterator], allowing the user to manually iterate through the pages.
  PagedGetIterator getAllPaged({String startUrl, Map<String, dynamic> query}) {
    logger.finest('getAllPaged startUrl: $startUrl, query: $query');
    String path = startUrl ?? pather.path();

    return PagedGetIterator(dio, path, query);
  }

  /// Returns a resource on this route matching the [id], optionally filtered by [query] parameters.
  Future<Map<String, dynamic>> getOne(String id,
      [Map<String, dynamic> query]) async {
    var path = pather.path(id);
    logger.finest('GET $path, query: ${jsonEncode(query)}');
    Response<Map<String, dynamic>> response =
        await dio.get(path, queryParameters: query);
    logResponse(response);
    List<Map<String, dynamic>> results =
        response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  /// Creates a resource on this route based on the given [data].
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    var path = pather.path();
    logger.finest('CREATE $path, ${jsonEncode(data)}');
    Response<Map<String, dynamic>> response = await dio.post(path, data: data);
    logResponse(response);
    List results = response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  /// Updates a resource matching the [id] with the given [data].
  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    var path = pather.path(id);
    logger.finest('UPDATE $path, ${jsonEncode(data)}');
    Response<Map<String, dynamic>> response = await dio.patch(path, data: data);
    logResponse(response);
    List results = response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  /// Replaces a resource matching the [id] with the given [data].
  Future<Map<String, dynamic>> replace(
      String id, Map<String, dynamic> data) async {
    var path = pather.path(id);
    logger.finest('REPLACE $path, ${jsonEncode(data)}');
    Response<Map<String, dynamic>> response = await dio.put(path, data: data);
    logResponse(response);
    List results = response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }

  /// Deletes a resource matching the [id].
  Future<Map<String, dynamic>> delete(String id) async {
    var path = pather.path(id);
    logger.finest('DELETE $path');
    Response<Map<String, dynamic>> response = await dio.delete(path);
    logResponse(response);
    List results = response.data['results'].cast<Map<String, dynamic>>();

    return results[0];
  }
}

/// A custom iterator wrapping paged queries.
/// Allows iterating over subsequent pages as long as each result contains the url of the next page.
class PagedGetIterator extends Iterator<Future<List<Map<String, dynamic>>>> {
  static final Logger logger = Logger('Api:PagedGetIterator');
  final Dio _dio;

  /// URL pointing to the next page
  String nextPath;

  /// URL pointing to the current page
  String currentPath;

  /// cached response for the current pages, in case [current] is called multiple times
  Response<Map<String, dynamic>> _response;

  /// Creates a new [PagedGetIterator] instance.
  ///
  /// [_dio] needs to be a [Dio] instance with the required authorization header(s).
  /// [path] is the initial url to resolve, i.e. the first page.
  /// [query] is optional and can contain filters such as limit, page_size, etc.
  /// (depending on what is supported by the backend).
  PagedGetIterator(this._dio, String path, [Map<String, dynamic> query]) {
    logger.finest('PagedGetIterator path: $path, query: $query');
    // NOTE: Uri can only handle query values that are String or String[]
    // therefore, we stringify the query values
    var parsedQuery = query?.map((k, v) {
      if (v is String) return MapEntry(k, v);

      // REVIEW: can this break?
      // spec says it supports "number, boolean, string, null, list or a map with string keys",
      // which should cover all use cases
      return MapEntry(k, jsonEncode(v));
    });

    // path might be a full URL, so we use tryParse to make this work for both
    var parsedUri = Uri.parse(path);

    // now we inject the parsed queries,
    // by merging the ones from path with the parsed ones
    parsedUri = parsedUri?.replace(queryParameters: {
      ...parsedUri.queryParameters,
      if (parsedQuery != null) ...parsedQuery,
    });

    // intentionally not allowing null here to see if this can ever break
    nextPath = parsedUri.toString();
  }

  @override
  get current async {
    if (_response == null) _response = await _dio.get(nextPath);

    nextPath = safeGet<String>(_response.data, 'cursor.next');

    return _response.data['results'].cast<Map<String, dynamic>>();
  }

  @override
  bool moveNext() {
    // make sure response gets cleared so that we can cache it in [current]
    _response = null;

    currentPath = nextPath;
    return nextPath != null;
  }
}
