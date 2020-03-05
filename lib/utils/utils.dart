import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:device_id/device_id.dart';
import 'package:dio/dio.dart';
import 'package:dio_retry/dio_retry.dart';
import 'package:logging/logging.dart';

// NOTE: set as private so it's not available to other classes that import this file
final Logger _logger = Logger('Api:Utils');
final Logger _retryLogger = Logger('Api:RetryInterceptor');

/// Returns a map containing data specific to the device it is executed on.
///
/// This is the data you want to send when updating the device state on remote.
Future<Map<String, dynamic>> getDeviceData() async {
  // NOTE: adding an IP fallback here,
  // as iOS Simulator & Android emulator usually don't have wifi connections
  // TODO: add additional safeguards, or SIMULATOR flag, so we don't get undesired entries in db
  var ip = await Connectivity().getWifiIP();
  if (ip == null || ip == 'error') {
    _logger.warning('unable to get ip. got instead: $ip. forcing mock ip');
    ip = '127.0.0.1';
  }

  return {
    'device_id': await DeviceId.getID,
    'type': 'eda',
    'device_configuration': {
      'network': {'ip': ip, 'port': 4040, 'protocol': 'http'}
    },
  };
}

/// Returns a RetryInterceptor for [dio], which makes failed requests retry 3 times,
/// as long as it's not a client error (response code range 400-499).
RetryInterceptor getInfiniteRetriesInterceptor(Dio dio) {
  return RetryInterceptor(
    dio: dio,
    options: RetryOptions(
      retries: 3, // Number of retries before a failure
      retryEvaluator: (e) {
        // REVIEW: remove null check if not necessary
        int code = e?.response?.statusCode ?? -1;
        if (e is DioError && e.response?.data != null) {
          var data = e?.response?.data;
          String errMsg = data is Map ? data['msg'] : data.toString();
          _retryLogger.info(
            '($code) request failed with msg \'$errMsg\'. Maybe retrying...:',
            e,
          );
        } else
          _retryLogger.info('($code) request failed. Maybe retrying...:', e);

        // don't retry client/auth errors
        if (400 <= code && code < 500) return false;

        return true;
      },
    ),
  );
}

/// takes a json object and a 'path' in string format,
/// and tries to resolve the path inside the object.
/// Returns null if unsuccessful
/// based on: https://github.com/onmyway133/json_resolve
T safeGet<T>(Object json, String path) {
  try {
    dynamic current = json;

    for (var segment in path.split('.')) {
      final maybeInt = int.tryParse(segment);

      if (maybeInt != null && current is List<dynamic> && current.isNotEmpty) {
        current = current[maybeInt];
      } else if (current is Map<String, dynamic>) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return (current as T);
  } catch (e) {
    _logger.shout('failed to safeGet $path from object $json:', e);
    return null;
  }
}

/// Parses a given JWT and returns a map with the properties encoded inside.
///
/// [token] must be a base64 encoded String that contains exactly 3 periods. Throws error otherwise.
/// Based on https://stackoverflow.com/a/52021206/584292
Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('invalid token');
  }

  final payload = _getJsonFromJWT(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('invalid payload');
  }

  return payloadMap;
}

/// Decodes JWT payload
/// Taken from https://stackoverflow.com/a/56900065/584292
String _getJsonFromJWT(String splittedToken) {
  String normalizedSource = base64Url.normalize(splittedToken);
  return utf8.decode(base64Url.decode(normalizedSource));
}
