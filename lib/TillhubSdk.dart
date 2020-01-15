import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillhub_sdk_flutter/api/Api.dart';
import 'package:tillhub_sdk_flutter/api/DeviceApi.dart';

const bool _isProduction = bool.fromEnvironment('dart.vm.product');
const String _productionUrl = 'https://api.tillhub.com';
const String _stagingUrl = 'https://staging-api.tillhub.com';

/// Implementation of the Tillhub SDK for Flutter.
///
/// The SDK is split up into [Api] and [DeviceApi].
/// [Api] is used to interact with the backend as a user,
/// while [DeviceApi] is used to interact with the backend as a device.
class TillhubSdk {
  static TillhubSdk _instance;

  Api api;
  DeviceApi deviceApi;

  // private constructor so no one can create instances besides `getInstance()`
  TillhubSdk._(this.api, this.deviceApi);

  /// Returns an instance of the Tillhub SDK.
  static Future<TillhubSdk> getInstance() async {
    if (_instance == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String baseUrl = _isProduction ? _productionUrl : _stagingUrl;

      Api api = Api(
        baseUrl: baseUrl,
        sharedPreferences: prefs,
      );
      DeviceApi deviceApi = DeviceApi(
        baseUrl: baseUrl,
        sharedPreferences: prefs,
      );

      _instance = TillhubSdk._(api, deviceApi);
    }

    return _instance;
  }

  /// Strips [api] and [deviceApi] from its authentication information.
  void clearAuth() {
    api.setAuth(null);
    deviceApi.setAuth(null);
  }
}
