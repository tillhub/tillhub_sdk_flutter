import 'package:flutter_test/flutter_test.dart';

import 'package:tillhub_sdk_flutter/tillhub_sdk_flutter.dart';

void main() {
  test('Can init', () {
    final impl = Tillhub();
    final inst = impl.init();
  });
}
