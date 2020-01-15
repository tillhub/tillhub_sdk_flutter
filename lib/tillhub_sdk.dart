import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillhub_sdk_flutter/api/api.dart';
import 'package:tillhub_sdk_flutter/api/device_api.dart';

const bool _isProduction = bool.fromEnvironment('dart.vm.product');
const String _productionUrl = 'https://api.tillhub.com';
const String _stagingUrl = 'https://staging-api.tillhub.com';

/// Implementation of the Tillhub SDK for Flutter.
///
/// The SDK is split up into [Api] and [DeviceApi].
/// [Api] is used to interact with the backend as a user,
/// while [DeviceApi] is used to interact with the backend as a device.
class TillhubSdk {
  static Future<TillhubSdk> _instance;

  Api api;
  DeviceApi deviceApi;

  // private constructor so no one can create instances besides `getInstance()`
  TillhubSdk._(this.api, this.deviceApi);

  /// Returns an instance of the Tillhub SDK.
  static Future<TillhubSdk> getInstance() {
    _instance ??= _createInstance();
    return _instance;
  }

  static Future<TillhubSdk> _createInstance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String baseUrl = _isProduction ? _productionUrl : _stagingUrl;

    var api = Api(
      baseUrl: baseUrl,
      sharedPreferences: prefs,
    );
    var deviceApi = DeviceApi(
      baseUrl: baseUrl,
      sharedPreferences: prefs,
    );

    return TillhubSdk._(api, deviceApi);
  }

  /// Strips [api] and [deviceApi] from its authentication information.
  void clearAuth() {
    api.setAuth(null);
    deviceApi.setAuth(null);
  }
}
