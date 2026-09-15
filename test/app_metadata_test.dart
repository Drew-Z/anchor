import 'dart:io';

import 'package:anchor_learning/core/constants/app_metadata.dart';
import 'package:anchor_learning/services/privacy/product_event_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display and event versions stay aligned with pubspec', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    final match =
        RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(match!.group(1), AppMetadata.version);
    expect(ProductEventRecorder.appVersion, AppMetadata.version);
  });
}
