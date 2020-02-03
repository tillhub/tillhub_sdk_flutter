import 'package:dio/dio.dart';

typedef Future<ResponseBody> OnFetch(RequestOptions options,
    Stream<List<int>> requestStream, Future cancelFuture);

class MockAdapter extends HttpClientAdapter {
  final Map<String, Map<String, OnFetch>> routes = {
    'GET': <String, OnFetch>{},
    'POST': <String, OnFetch>{},
    'PATCH': <String, OnFetch>{},
    'PUT': <String, OnFetch>{},
    'DELETE': <String, OnFetch>{},
  };

  void on(String method, String url, OnFetch handler) {
    routes[method][url] = handler;
  }

  void clear() {
    routes.values.forEach((map) => map.clear());
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    // for some reason, target uri contains '?' even when no query is present
    // removing it if it's the last character, to make creating tests easier
    Uri uri = options.uri;
    String formattedUrl = uri.toString();
    if (formattedUrl.endsWith('?')) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }

    try {
      var onFetch = routes[options.method][formattedUrl];
      if (onFetch == null) {
        throw new Exception(
            'no handler defined for route (${options.method}) $formattedUrl');
      }

      return await onFetch(options, requestStream, cancelFuture);
    } catch (e) {
      print(e);
      return ResponseBody.fromString('$e', 666);
    }
  }

  @override
  void close({bool force = false}) {
    // nothing to do here
  }
}
