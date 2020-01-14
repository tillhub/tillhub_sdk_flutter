import 'dart:convert';

/// Object holding authentication information of the currently bound device.
class DeviceAuthInfo {
  final String authed_token; // ignore: non_constant_identifier_names
  final String client_account; // ignore: non_constant_identifier_names
  final String device;

  DeviceAuthInfo(
    this.authed_token,
    this.client_account,
    this.device,
  ); // device ID

  factory DeviceAuthInfo.fromJson(Map<String, dynamic> json) {
    return DeviceAuthInfo(
      json['authed_token'],
      json['client_account'],
      json['device'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authed_token': authed_token,
      'client_account': client_account,
      'device': device,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
