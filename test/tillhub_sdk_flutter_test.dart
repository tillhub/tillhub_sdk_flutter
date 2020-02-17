import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tillhub_sdk_flutter/api/auth_info.dart';
import 'package:tillhub_sdk_flutter/tillhub_sdk.dart';

import 'mock_adapter.dart';

const String authTokenDefaultDevice =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3N1ZXIiOiJ0aWxsaHViLXRoaW5ncy1hcGkiLCJhdWRpZW5jZSI6WyJ0aGluZ3Mtc3RhZ2luZy50aWxsaHViLmNvbSIsInRoaW5ncy50aWxsaHViLmNvbSJdLCJqdGkiOiJhMjI2NjRhOS1kYzNhLTRiMDItOGU2NS03YjQ4ZDg2ZTU2ZGMiLCJpYXQiOjE1NTI5MjU0ODJ9.3goE8LKFc0Ui0HUebf7grTNlXjvF1XbeoY1kkEs_bBo';

const String authTokenNoExpiration =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiYXBpLnRpbGxodWIuY29tIiwic3RhZ2luZy1hcGkudGlsbGh1Yi5jb20iLCJkYXNoYm9hcmQudGlsbGh1Yi5jb20iLCJzdGFnaW5nLWRhc2hib2FyZC50aWxsaHViLmNvbSJdLCJzdWIiOiIxMTExMTExMS0xMTExLTExMTEtMTExMS0xMTExMTExMTExMTEiLCJqdGkiOiIyMjIyMjIyMi0yMjIyLTIyMjItMjIyMi0yMjIyMjIyMjIyMjIiLCJzY29wZXMiOlsiYWRtaW4iLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZDpvbmUiLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZCJdLCJyb2xlIjoib3duZXIiLCJpc3MiOiJ0aWxsaHViLWFwaS1uZXh0IiwibnMiOm51bGwsInZzIjoiMC42MS40NCIsImxlZ2FjeV9pZCI6IjQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0IiwiZmVhdHVyZXMiOnsidm91Y2hlcnMiOnRydWUsImludmVudG9yeSI6dHJ1ZX0sImlhdCI6MTU4MDczNjA3MH0.bDCd6wLD-Y8hXcbyMMKjo362oP93Q3gmYZ-mAPpVj5I';

const String authTokenFarFuture =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiYXBpLnRpbGxodWIuY29tIiwic3RhZ2luZy1hcGkudGlsbGh1Yi5jb20iLCJkYXNoYm9hcmQudGlsbGh1Yi5jb20iLCJzdGFnaW5nLWRhc2hib2FyZC50aWxsaHViLmNvbSJdLCJzdWIiOiIxMTExMTExMS0xMTExLTExMTEtMTExMS0xMTExMTExMTExMTEiLCJqdGkiOiIyMjIyMjIyMi0yMjIyLTIyMjItMjIyMi0yMjIyMjIyMjIyMjIiLCJzY29wZXMiOlsiYWRtaW4iLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZDpvbmUiLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZCJdLCJyb2xlIjoib3duZXIiLCJpc3MiOiJ0aWxsaHViLWFwaS1uZXh0IiwibnMiOm51bGwsInZzIjoiMC42MS40NCIsImxlZ2FjeV9pZCI6IjQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0IiwiZmVhdHVyZXMiOnsidm91Y2hlcnMiOnRydWUsImludmVudG9yeSI6dHJ1ZX0sImlhdCI6MTU4MDczNjA3MCwiZXhwIjo5OTk5OTk5OTk5OTk5OTl9.hVJivnYWApMZR3loQ_7KUEW6baRd4XogCtL5n_NP1tM';

const String authTokenExpired =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiYXBpLnRpbGxodWIuY29tIiwic3RhZ2luZy1hcGkudGlsbGh1Yi5jb20iLCJkYXNoYm9hcmQudGlsbGh1Yi5jb20iLCJzdGFnaW5nLWRhc2hib2FyZC50aWxsaHViLmNvbSJdLCJzdWIiOiIxMTExMTExMS0xMTExLTExMTEtMTExMS0xMTExMTExMTExMTEiLCJqdGkiOiIyMjIyMjIyMi0yMjIyLTIyMjItMjIyMi0yMjIyMjIyMjIyMjIiLCJzY29wZXMiOlsiYWRtaW4iLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZDpvbmUiLCIzMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM6cHJvZHVjdHM6cmVhZCJdLCJyb2xlIjoib3duZXIiLCJpc3MiOiJ0aWxsaHViLWFwaS1uZXh0IiwibnMiOm51bGwsInZzIjoiMC42MS40NCIsImxlZ2FjeV9pZCI6IjQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0IiwiZmVhdHVyZXMiOnsidm91Y2hlcnMiOnRydWUsImludmVudG9yeSI6dHJ1ZX0sImlhdCI6MTU4MDczNjA3MCwiZXhwIjo5OTk5OTk5OTk5fQ.lJ9lbvE0vL_aaVToly7OXrSxiBHktnIjZVmODp2iXR8';

// JWT Base data
// {
//   aud: [
//     "api.tillhub.com",
//     "staging-api.tillhub.com",
//     "dashboard.tillhub.com",
//     "staging-dashboard.tillhub.com"
//   ],
//   sub: "11111111-1111-1111-1111-111111111111",
//   jti: "22222222-2222-2222-2222-222222222222",
//   scopes: [
//     "admin",
//     "33333333-3333-3333-3333-333333333333:products:read:one",
//     "33333333-3333-3333-3333-333333333333:products:read"
//   ],
//   role: "owner",
//   iss: "tillhub-api-next",
//   ns: null,
//   vs: "0.61.44",
//   legacy_id: "44444444444444444444444444444444",
//   features: {
//     vouchers: true,
//     inventory: true
//   },
//   iat: 1580736070,
//   exp: 9999999999,
// }

void main() {
  test('can create instance', () {
    var instance = TillhubSdk();

    expect(instance, isNotNull);
    expect(instance.api, isNotNull);
    expect(instance.deviceApi, isNotNull);
  });

  test('Apis have no initial auth data', () {
    var instance = TillhubSdk();

    expect(instance.api.authInfo, isNull);
    expect(instance.deviceApi.authInfo, isNull);
  });

  test('can login', () async {
    var sdk = TillhubSdk();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter()
      ..on(
        'POST',
        'https://staging-api.tillhub.com/api/v0/users/login',
        (options, requestStream, Future cancelFuture) async {
          var payloadChunks = await requestStream.toList();
          // REVIEW: I think .expand() is slow / memory hog
          var payloadBytes = payloadChunks.expand((chunk) => chunk);
          var payloadString = String.fromCharCodes(payloadBytes);
          var payloadJson = jsonDecode(payloadString);

          expect(payloadJson, isNotNull);
          expect(payloadJson['email'], equals('alice@test.com'));
          expect(payloadJson['password'], equals('fooBar1!%'));

          return ResponseBody.fromString(
            jsonEncode({
              'status': 200,
              'msg': 'Authentication was good.',
              'user': {
                'id': 'someUserId',
                'name': 'Alice Test',
                'legacy_id': 'someLegacyId',
                'scopes': ['admin'],
                'role': 'owner'
              },
              'valid_password': true,
              'token': 'someFakeToken',
              'token_type': 'Bearer',
              'expires_at': '2020-02-19T14:01:53.000Z',
              'features': {'vouchers': true, 'inventory': true},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

    var authInfo = await api.login('alice@test.com', 'fooBar1!%');

    expect(authInfo, isNotNull);
    expect(authInfo.user.id, equals('someUserId'));
    expect(authInfo.user.name, equals('Alice Test'));
    expect(authInfo.user.legacy_id, equals('someLegacyId'));
    expect(authInfo.user.scopes, equals(['admin']));
    expect(authInfo.user.role, equals('owner'));

    expect(authInfo.token, equals('someFakeToken'));
    expect(authInfo.token_type, equals('Bearer'));
    expect(authInfo.expires_at, equals('2020-02-19T14:01:53.000Z'));
    expect(authInfo.features, equals({'vouchers': true, 'inventory': true}));
  });

  test('can org login', () async {
    var sdk = TillhubSdk();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter()
      ..on(
        'POST',
        'https://staging-api.tillhub.com/api/v1/users/auth/organisation/login',
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

          return ResponseBody.fromString(
            jsonEncode({
              'status': 200,
              'msg': 'Authentication was good.',
              'user': {
                'id': 'someUserId',
                'name': 'Alice Test',
                'legacy_id': 'someLegacyId',
                'scopes': ['admin'],
                'role': 'owner'
              },
              'sub_user': {
                'id': 'someSubUserId',
                'role': 'staff',
                'scopes': [
                  'staff:read',
                  'staff:create',
                  'staff:update',
                  'staff:delete',
                  'customers'
                ],
                'name': 'someSubUserName',
                'username': 'someSubUserUserName',
                'user_id': 'someSubUserUserId',
                'locations': ['fooLocation', 'barLocation'],
              },
              'valid_password': true,
              'token': 'someFakeToken',
              'token_type': 'Bearer',
              'expires_at': '2020-02-19T14:01:53.000Z',
              'features': {'vouchers': true, 'inventory': true},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

    var authInfo =
        await api.login('alice@test.com', 'fooBar1!%', 'someCompany');

    expect(authInfo, isNotNull);
    expect(authInfo.user.id, equals('someUserId'));
    expect(authInfo.user.name, equals('Alice Test'));
    expect(authInfo.user.legacy_id, equals('someLegacyId'));
    expect(authInfo.user.scopes, equals(['admin']));
    expect(authInfo.user.role, equals('owner'));

    expect(authInfo.token, equals('someFakeToken'));
    expect(authInfo.token_type, equals('Bearer'));
    expect(authInfo.expires_at, equals('2020-02-19T14:01:53.000Z'));
    expect(authInfo.features, equals({'vouchers': true, 'inventory': true}));

    expect(authInfo.sub_user, isNotNull);
    expect(authInfo.sub_user.id, equals('someSubUserId'));
    expect(authInfo.sub_user.role, equals('staff'));
    expect(authInfo.sub_user.name, equals('someSubUserName'));
    expect(authInfo.sub_user.username, equals('someSubUserUserName'));
    expect(authInfo.sub_user.user_id, equals('someSubUserUserId'));
    expect(
      authInfo.sub_user.scopes,
      equals([
        'staff:read',
        'staff:create',
        'staff:update',
        'staff:delete',
        'customers'
      ]),
    );
  });

  test('throws error on wrong password', () async {
    var sdk = TillhubSdk();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    var mockAdapter = MockAdapter();

    mockAdapter.on('POST', 'https://staging-api.tillhub.com/api/v0/users/login',
        (options, requestStream, Future cancelFuture) async {
      return ResponseBody.fromString('', 401);
    });

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = mockAdapter;

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
    var sdk = TillhubSdk();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    // setting mock http adapter, that takes sdk requests and returns custom
    // payload
    api.dio.httpClientAdapter = MockAdapter()
      ..on('POST', 'https://staging-api.tillhub.com/api/v0/users/login',
          (options, requestStream, Future cancelFuture) async {
        return ResponseBody.fromString('', 400);
      });

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
    var sdk = TillhubSdk();
    var api = sdk.api;

    expect(api.authInfo, isNull);
    expect(api.dio, isNotNull);

    api.dio.httpClientAdapter = MockAdapter()
      ..on(
        'POST',
        'https://staging-api.tillhub.com/api/v0/users/login',
        (options, requestStream, Future cancelFuture) async {
          return ResponseBody.fromString('', 422);
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

  test('uses auth info if provided', () async {
    var authInfo = AuthInfo.fromJson({
      'status': 200,
      'msg': 'Authentication was good.',
      'user': {
        'id': 'someUserId',
        'name': 'Alice Test',
        'legacy_id': 'someLegacyId',
        'scopes': ['admin'],
        'role': 'owner'
      },
      'sub_user': {
        'id': 'someSubUserId',
        'role': 'staff',
        'scopes': [
          'staff:read',
          'staff:create',
          'staff:update',
          'staff:delete',
          'customers'
        ],
        'name': 'someSubUserName',
        'username': 'someSubUserUserName',
        'user_id': 'someSubUserUserId',
        'locations': ['fooLocation', 'barLocation'],
      },
      'valid_password': true,
      'token': authTokenFarFuture,
      'token_type': 'Bearer',
      'expires_at': '2020-02-19T14:01:53.000Z',
      'features': {'vouchers': true, 'inventory': true},
    });

    var sdk = TillhubSdk(authInfo: authInfo);
    var api = sdk.api;

    expect(api.authInfo, isNotNull);
    expect(api.dio, isNotNull);
    expect(api.dio.options.headers['authorization'], isNotNull);

    api.dio.httpClientAdapter = MockAdapter()
      ..on(
        'GET',
        'https://staging-api.tillhub.com/api/v1/products/someLegacyId',
        (options, requestStream, Future cancelFuture) async {
          expect(options.headers, contains('authorization'));
          expect(
            options.headers['authorization'],
            equals('Bearer $authTokenFarFuture'),
          );
          return ResponseBody.fromString(
            jsonEncode({
              'status': 200,
              'msg': 'Queried products successfully.',
              'count': 0,
              'results': [],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

    List<Map<String, dynamic>> products = await api.products.getAll();

    expect(products, isNotNull);
    expect(products, isEmpty);

    // TODO: similar check for deviceApi
  });
}
