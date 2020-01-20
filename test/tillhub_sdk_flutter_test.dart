import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tillhub_sdk_flutter/tillhub_sdk.dart';

import 'mock_adapter.dart';
import 'vars.dart';

void main() {
  setUpAll(() {
    // required for SharedPreferences
    TestWidgetsFlutterBinding.ensureInitialized();

    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    // clear SharedPreferences, so that auth data is not carried over between tests
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCleared = await prefs.clear();
    assert(isCleared == true);

    // also reset TillhubSdk
    TillhubSdk.clearInstance();
  });

  test('can create instance', () async {
    var instance = await TillhubSdk.getInstance();

    expect(instance, isNotNull);
    expect(instance.api, isNotNull);
    expect(instance.deviceApi, isNotNull);
  });

  test('Apis have no initial auth data', () async {
    var instance = await TillhubSdk.getInstance();

    expect(instance.api.authInfo, isNull);
    expect(instance.deviceApi.authInfo, isNull);
  });

  test('can create instance & same instance is being reused', () async {
    var firstInstance = await TillhubSdk.getInstance();
    var secondInstance = await TillhubSdk.getInstance();

    expect(firstInstance, equals(secondInstance));
  });

  test('instances differ after clearing', () async {
    var firstInstance = await TillhubSdk.getInstance();
    TillhubSdk.clearInstance();
    var secondInstance = await TillhubSdk.getInstance();

    expect(firstInstance, isNot(secondInstance));
  });

  test('can login', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        var payloadChunks = await requestStream.toList();
        // REVIEW: I think .expand() is slow / memory hog
        var payloadBytes = payloadChunks.expand((chunk) => chunk);
        var payloadString = String.fromCharCodes(payloadBytes);
        var payloadJson = jsonDecode(payloadString);

        expect(payloadJson, isNotNull);
        expect(payloadJson['email'], equals('alice@test.com'));
        expect(payloadJson['password'], equals('fooBar1!%'));

        Uri uri = options.uri;

        expect(uri.host, equals(allowedHost));
        expect(uri.path, equals('/api/v0/users/login'));

        return ResponseBody.fromString(
          jsonEncode({
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
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );

    await api.login('alice@test.com', 'fooBar1!%');

    var authInfo = api.authInfo;

    expect(authInfo, isNotNull);
    expect(authInfo.user.id, equals('someUserId'));
    expect(authInfo.user.name, equals('Alice Test'));
    expect(authInfo.user.legacy_id, equals('someLegacyId'));
    expect(authInfo.user.scopes, equals(["admin"]));
    expect(authInfo.user.role, equals('owner'));

    expect(authInfo.token, equals('someFakeToken'));
    expect(authInfo.token_type, equals('Bearer'));
    expect(authInfo.expires_at, equals('2020-02-19T14:01:53.000Z'));
    expect(authInfo.features, equals({"vouchers": true, "inventory": true}));
  });

  test('can org login', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        var payloadChunks = await requestStream.toList();
        // REVIEW: I think .expand() is slow / memory hog
        var payloadBytes = payloadChunks.expand((chunk) => chunk);
        var payloadString = String.fromCharCodes(payloadBytes);
        var payloadJson = jsonDecode(payloadString);

        expect(payloadJson, isNotNull);
        expect(payloadJson['username'], equals('alice@test.com'));
        expect(payloadJson['password'], equals('fooBar1!%'));
        expect(payloadJson['organisation'], equals('someCompany'));

        Uri uri = options.uri;

        expect(uri.host, equals(allowedHost));
        expect(uri.path, equals('/api/v1/users/auth/organisation/login'));

        return ResponseBody.fromString(
          jsonEncode({
            "status": 200,
            "msg": "Authentication was good.",
            "user": {
              "id": "someUserId",
              "name": "Alice Test",
              "legacy_id": "someLegacyId",
              "scopes": ["admin"],
              "role": "owner"
            },
            "sub_user": {
              "id": "someSubUserId",
              "role": "staff",
              "scopes": [
                "staff:read",
                "staff:create",
                "staff:update",
                "staff:delete",
                "customers"
              ],
              "name": "someSubUserName",
              "username": "someSubUserUserName",
              "user_id": "someSubUserUserId",
              "locations": ['fooLocation', 'barLocation'],
            },
            "valid_password": true,
            "token": "someFakeToken",
            "token_type": "Bearer",
            "expires_at": "2020-02-19T14:01:53.000Z",
            "features": {"vouchers": true, "inventory": true},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );

    await api.login('alice@test.com', 'fooBar1!%', 'someCompany');

    var authInfo = api.authInfo;

    expect(authInfo, isNotNull);
    expect(authInfo.user.id, equals('someUserId'));
    expect(authInfo.user.name, equals('Alice Test'));
    expect(authInfo.user.legacy_id, equals('someLegacyId'));
    expect(authInfo.user.scopes, equals(["admin"]));
    expect(authInfo.user.role, equals('owner'));

    expect(authInfo.token, equals('someFakeToken'));
    expect(authInfo.token_type, equals('Bearer'));
    expect(authInfo.expires_at, equals('2020-02-19T14:01:53.000Z'));
    expect(authInfo.features, equals({"vouchers": true, "inventory": true}));

    expect(authInfo.sub_user, isNotNull);
    expect(authInfo.sub_user.id, equals('someSubUserId'));
    expect(authInfo.sub_user.role, equals('staff'));
    expect(authInfo.sub_user.name, equals('someSubUserName'));
    expect(authInfo.sub_user.username, equals('someSubUserUserName'));
    expect(authInfo.sub_user.user_id, equals('someSubUserUserId'));
    expect(
      authInfo.sub_user.scopes,
      equals([
        "staff:read",
        "staff:create",
        "staff:update",
        "staff:delete",
        "customers"
      ]),
    );
  });

  test('throws error on wrong password', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString("", 401);
      },
    );

    try {
      await api.login('alice@test.com', 'fooBar1!%');
    } catch (e) {
      if (e is DioError) {
        expect(e.response.statusCode, 401);
      } else {
        fail('error should be DioError');
      }
    }
  });

  test('throws error on non existent user', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString("", 400);
      },
    );

    try {
      await api.login('alice@test.com', 'fooBar1!%');
    } catch (e) {
      if (e is DioError) {
        expect(e.response.statusCode, 400);
      } else {
        fail('error should be DioError');
      }
    }
  });

  test('throws error on invalid request', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString("", 422);
      },
    );

    try {
      await api.login('alice@test.com', 'fooBar1!%');
    } catch (e) {
      if (e is DioError) {
        expect(e.response.statusCode, 422);
      } else {
        fail('error should be DioError');
      }
    }
  });

  test('can clear auth', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString(
          jsonEncode({
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
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );

    await api.login('alice@test.com', 'fooBar1!%');

    // TODO: also check deviceApi
    expect(api.authInfo, isNotNull);
    sdk.clearAuth();
    expect(api.authInfo, isNull);
  });

  test('can restore auth from sharedPreferences', () async {
    var sdk = await TillhubSdk.getInstance();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter(
      (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString(
          jsonEncode({
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
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );

    await api.login('alice@test.com', 'fooBar1!%');

    expect(api.authInfo, isNotNull);

    TillhubSdk.clearInstance();

    var sdk2 = await TillhubSdk.getInstance();

    expect(sdk2, isNot(sdk));
    expect(sdk2.api.authInfo, isNotNull);
    expect(sdk2.api.authInfo.toJson(), equals(sdk.api.authInfo.toJson()));

    // TODO: similar check for deviceApi
  });
}
