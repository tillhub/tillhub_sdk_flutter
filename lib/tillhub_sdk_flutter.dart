library tillhub_sdk_flutter;

import 'package:dio/dio.dart';

/// Tillhub SDK.
class Tillhub {
  Dio _client;
  TillhubSDKOptions options;

  Tillhub([TillhubSDKOptions options]) {
    if (options == null) {
      options = new TillhubSDKOptions();
    }
    this.options = options;
  }

  /// Initialises an API instance
  Tillhub init() {
    return new Tillhub();
  }
}

class TillhubSDKOptions {}
