import 'dart:io';

Future<String> findDartCliExecutable() async {
  final executable = Platform.isWindows ? 'dart.exe' : 'dart';
  for (final sdkRoot in [
    Platform.environment['DART_SDK'],
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
          '${Platform.pathSeparator}dart-sdk',
  ]) {
    if (sdkRoot == null) continue;
    final candidate = File('$sdkRoot${Platform.pathSeparator}bin'
        '${Platform.pathSeparator}$executable');
    if (await candidate.exists()) return candidate.path;
  }

  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    for (final relative in [
      'dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}$executable',
      'bin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk'
          '${Platform.pathSeparator}bin${Platform.pathSeparator}$executable',
    ]) {
      final candidate = File(
        '${directory.path}${Platform.pathSeparator}$relative',
      );
      if (await candidate.exists()) return candidate.path;
    }
    directory = directory.parent;
  }
  throw StateError('Unable to locate the Dart CLI executable.');
}
