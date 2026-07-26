import 'package:flutter/services.dart';

import 'project_source_import_service.dart';

class AndroidProjectDirectorySelection {
  final String sourceUri;
  final String displayName;

  const AndroidProjectDirectorySelection({
    required this.sourceUri,
    required this.displayName,
  });
}

class AndroidProjectDirectoryBridge {
  static const channelName = 'com.example.dlg_q/project_directory';
  static const defaultMaxEntries = 2000;

  final MethodChannel _channel;

  const AndroidProjectDirectoryBridge({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  Future<AndroidProjectDirectorySelection?> pickDirectory() async {
    final result = await _channel.invokeMethod<Object?>('pickDirectory');
    if (result == null) return null;
    final map = _stringKeyedMap(result, method: 'pickDirectory');
    final sourceUri = map['sourceUri'];
    final displayName = map['displayName'];
    if (sourceUri is! String || sourceUri.isEmpty || displayName is! String) {
      throw const FormatException('Invalid Android directory selection.');
    }
    return AndroidProjectDirectorySelection(
      sourceUri: sourceUri,
      displayName: displayName,
    );
  }

  Future<List<ProjectSourceInputFile>> listDirectory({
    required String treeUri,
    required int maxFileBytes,
    int maxEntries = defaultMaxEntries,
  }) async {
    final result = await _channel.invokeMethod<Object?>('listDirectory', {
      'treeUri': treeUri,
      'maxEntries': maxEntries,
    });
    if (result is! List<Object?>) {
      throw const FormatException('Invalid Android directory listing.');
    }

    return result.map((value) {
      final map = _stringKeyedMap(value, method: 'listDirectory');
      final relativePath = map['relativePath'];
      final byteLength = map['byteLength'];
      final documentUri = map['documentUri'];
      if (relativePath is! String ||
          byteLength is! num ||
          documentUri is! String ||
          documentUri.isEmpty) {
        throw const FormatException('Invalid Android directory entry.');
      }
      return ProjectSourceInputFile(
        relativePath: relativePath,
        byteLength: byteLength.toInt(),
        readBytes: () => _readFile(
          documentUri: documentUri,
          maxBytes: maxFileBytes,
        ),
      );
    }).toList(growable: false);
  }

  Future<Uint8List> _readFile({
    required String documentUri,
    required int maxBytes,
  }) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('readFile', {
        'documentUri': documentUri,
        'maxBytes': maxBytes,
      });
      if (bytes == null) {
        throw const FormatException('Android returned empty file data.');
      }
      return bytes;
    } on PlatformException catch (error) {
      if (error.code == 'file_too_large') {
        throw ProjectSourceReadLimitException(maxBytes);
      }
      rethrow;
    }
  }

  static Map<Object?, Object?> _stringKeyedMap(
    Object? value, {
    required String method,
  }) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('Invalid Android response for $method.');
    }
    return value;
  }
}
