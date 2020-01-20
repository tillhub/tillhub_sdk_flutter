import 'package:dio/dio.dart';

typedef Future<ResponseBody> OnFetch(RequestOptions options,
    Stream<List<int>> requestStream, Future cancelFuture);

class MockAdapter extends HttpClientAdapter {
  final OnFetch onFetch;

  MockAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    try {
      return await onFetch(options, requestStream, cancelFuture);
    } catch (e) {
      print(e);
      // return unexpected error code
      return ResponseBody.fromString("", 666);
    }
  }

  @override
  void close({bool force = false}) {
    // nothing to do here
  }
}
