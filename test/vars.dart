import 'dart:convert';

import 'package:dio/dio.dart';

const String stagingHost = 'staging-api.tillhub.com';
const String productionHost = 'api.tillhub.com';

const bool isProduction = bool.fromEnvironment('dart.vm.product');

const String allowedHost = isProduction ? productionHost : stagingHost;

final mockLoginResponse = {
  "status": 200,
  "msg": "Authentication was good.",
  "user": {
    "id": "someUserId",
    "name": "Alice Test",
    "legacy_id": "someLegacyId",
    "scopes": ["admin"],
    "role": "owner"
  },
  "valid_password": true,
  "token": "someFakeToken",
  "token_type": "Bearer",
  "expires_at": "2020-02-19T14:01:53.000Z",
  "features": {"vouchers": true, "inventory": true},
};

// ResponseBody stream can only be listened to once,
// so we use a getter to always return a new ResponseBody instance
ResponseBody get mockLoginResponseBody {
  return ResponseBody.fromString(
    jsonEncode(mockLoginResponse),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
