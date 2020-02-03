import 'package:dio/dio.dart';

typedef Future<ResponseBody> OnFetch(RequestOptions options,
    Stream<List<int>> requestStream, Future cancelFuture);

class MockAdapter extends HttpClientAdapter {
  final Map<String, Map<Uri, OnFetch>> routes = {
    'GET': <Uri, OnFetch>{},
    'POST': <Uri, OnFetch>{},
    'PATCH': <Uri, OnFetch>{},
    'PUT': <Uri, OnFetch>{},
    'DELETE': <Uri, OnFetch>{},
  };

  void on(String method, Uri path, OnFetch handler) {
    routes[method][path] = handler;
  }

  void clear() {
    routes.values.forEach((map) => map.clear());
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    try {
      var onFetch = routes[options.method][options.uri];
      if (onFetch == null) {
        throw new Exception(
            'no handler defined for route (${options.method}) ${options.path}');
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
