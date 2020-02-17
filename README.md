# tillhub_sdk_flutter

Flutter SDK for the Tillhub API and common local functionality.

## Getting Started
```dart
// 1. get an instance of the SDK
var sdk = await TillhubSdk.getInstance();

// 2. login as a user
await sdk.api.login('name', 'password', 'organization');

// 3. request some resources, .e.g:
var results = await sdk.api.products.getAll(query: { 'deleted': false });
```

Authentication information from a successful login is automatically saved to SharedPreferences, and loaded when the instance is created.

## Testing

Flutter tests are started via the `flutter test` command.

### Coverage Reports

You can also generate coverage reports and view them in the browser by running a command similar to this (from the root directory):

(You will need to manually install `lcov`, which provides the `genhtml` command. You can install it e.g. via `brew install lcov`)

```bash
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

## License

Apache-2.0
