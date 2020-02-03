import 'package:tillhub_sdk_flutter/api/api.dart';
import 'package:tillhub_sdk_flutter/api/auth_info.dart';
import 'package:tillhub_sdk_flutter/api/device_api.dart';
import 'package:tillhub_sdk_flutter/api/device_auth_info.dart';

const bool _isProduction = bool.fromEnvironment('dart.vm.product');
const String _productionUrl = 'https://api.tillhub.com';
const String _stagingUrl = 'https://staging-api.tillhub.com';

/// Implementation of the Tillhub SDK for Flutter.
///
/// The SDK is split up into [Api] and [DeviceApi].
/// [Api] is used to interact with the backend as a user,
/// while [DeviceApi] is used to interact with the backend as a device.
class TillhubSdk {
  final AuthInfo authInfo;
  final DeviceAuthInfo deviceAuthInfo;

  Api api;
  DeviceApi deviceApi;

  TillhubSdk({
    this.authInfo,
    this.deviceAuthInfo,
  }) {
    String baseUrl = _isProduction ? _productionUrl : _stagingUrl;

    api = Api(
      baseUrl: baseUrl,
      authInfo: authInfo,
    );
    deviceApi = DeviceApi(
      baseUrl: baseUrl,
      authInfo: deviceAuthInfo,
    );
  }
}
