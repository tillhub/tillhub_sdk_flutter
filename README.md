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

## License

Apache-2.0
