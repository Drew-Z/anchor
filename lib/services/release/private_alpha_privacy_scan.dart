import 'dart:io';

import 'package:path/path.dart' as p;

import 'repository_relative_path.dart';

enum PrivateAlphaPrivacyFindingCategory {
  apiKey,
  authorization,
  credentialQuery,
  privateAbsolutePath,
  jwt,
  sensitiveFile,
  unreadable,
  pathOutsideRepository,
}

class PrivateAlphaPrivacyFinding {
  final PrivateAlphaPrivacyFindingCategory category;
  final String relativePath;

  const PrivateAlphaPrivacyFinding({
    required this.category,
    required this.relativePath,
  });

  String get blocker => 'privacy_scan_${category.name}:$relativePath';
}

class PrivateAlphaPrivacyScanEvidence {
  final List<String> paths;

  const PrivateAlphaPrivacyScanEvidence({required this.paths});

  factory PrivateAlphaPrivacyScanEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final value = json['privacy_scan'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException('privacy_scan must be a JSON object.');
    }
    final rawPaths = value['paths'];
    if (rawPaths is! List || rawPaths.isEmpty) {
      throw const FormatException(
        'privacy_scan.paths must be a non-empty array.',
      );
    }
    final paths = <String>[];
    for (final rawPath in rawPaths) {
      if (rawPath is! String || rawPath.trim().isEmpty) {
        throw const FormatException(
          'privacy_scan.paths must contain non-empty strings.',
        );
      }
      if (isAbsolutePathOnAnyPlatform(rawPath)) {
        throw const FormatException(
          'privacy_scan.paths must be repository-relative.',
        );
      }
      paths.add(p.normalize(rawPath));
    }
    return PrivateAlphaPrivacyScanEvidence(
      paths: List.unmodifiable(paths.toSet()),
    );
  }
}

class PrivateAlphaPrivacyScanResult {
  final List<PrivateAlphaPrivacyFinding> findings;

  const PrivateAlphaPrivacyScanResult(this.findings);

  bool get passed => findings.isEmpty;
  List<String> get blockers =>
      findings.map((finding) => finding.blocker).toList(growable: false);
}

class PrivateAlphaPrivacyScanner {
  static final _apiKeyPatterns = [
    RegExp(r'\bsk-[A-Za-z0-9_-]{20,}\b'),
    RegExp(r'\bAIza[A-Za-z0-9_-]{20,}\b'),
  ];
  static final _authorizationPattern = RegExp(
    r'(?:authorization|x-api-key|api[_ -]?key|access[_ -]?token|refresh[_ -]?token|client[_ -]?secret)\s*[:=]\s*(?:bearer\s+)?\S{12,}',
    caseSensitive: false,
  );
  static final _credentialQueryPattern = RegExp(
    r'https?://\S+[?&](?:api[_-]?key|token|access_token|refresh_token|key|secret|credential|signature)=\S+',
    caseSensitive: false,
  );
  static final _privatePathPatterns = [
    RegExp(r'[A-Za-z]:\\(?:Users|Documents and Settings)\\\S+'),
    RegExp(
      r'/(?:Users|home|data|storage|sdcard|var|tmp)/\S+',
    ),
    RegExp(r'file://(?:/[A-Za-z]:|/Users/|/home/)\S+'),
  ];
  static final _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b',
  );
  static const _sensitiveFileNames = {
    '.env',
    '.netrc',
    '.npmrc',
    '.pypirc',
    'credentials.json',
    'id_ed25519',
    'id_rsa',
    'key.properties',
    'local.properties',
    'service-account.json',
  };
  static const _sensitiveExtensions = {
    '.jks',
    '.key',
    '.keystore',
    '.p12',
    '.pem',
    '.pfx',
  };

  final int maximumBytes;

  const PrivateAlphaPrivacyScanner({this.maximumBytes = 5 * 1024 * 1024});

  Future<PrivateAlphaPrivacyScanResult> scan({
    required String repositoryRoot,
    required PrivateAlphaPrivacyScanEvidence evidence,
  }) async {
    final root = p.normalize(p.absolute(repositoryRoot));
    final findings = <PrivateAlphaPrivacyFinding>[];
    for (final relativePath in evidence.paths) {
      final absolutePath = p.normalize(p.absolute(root, relativePath));
      if (!p.isWithin(root, absolutePath)) {
        findings.add(PrivateAlphaPrivacyFinding(
          category: PrivateAlphaPrivacyFindingCategory.pathOutsideRepository,
          relativePath: relativePath,
        ));
        continue;
      }
      if (_isSensitiveFile(relativePath)) {
        findings.add(PrivateAlphaPrivacyFinding(
          category: PrivateAlphaPrivacyFindingCategory.sensitiveFile,
          relativePath: relativePath,
        ));
        continue;
      }
      final file = File(absolutePath);
      try {
        if (!await file.exists() || await file.length() > maximumBytes) {
          findings.add(PrivateAlphaPrivacyFinding(
            category: PrivateAlphaPrivacyFindingCategory.unreadable,
            relativePath: relativePath,
          ));
          continue;
        }
        final content = await file.readAsString();
        final categories = _categoriesFor(content);
        for (final category in categories) {
          findings.add(PrivateAlphaPrivacyFinding(
            category: category,
            relativePath: relativePath,
          ));
        }
      } on FileSystemException {
        findings.add(PrivateAlphaPrivacyFinding(
          category: PrivateAlphaPrivacyFindingCategory.unreadable,
          relativePath: relativePath,
        ));
      }
    }
    findings.sort((left, right) {
      final pathOrder = left.relativePath.compareTo(right.relativePath);
      if (pathOrder != 0) return pathOrder;
      return left.category.name.compareTo(right.category.name);
    });
    return PrivateAlphaPrivacyScanResult(List.unmodifiable(findings));
  }

  Set<PrivateAlphaPrivacyFindingCategory> _categoriesFor(String content) {
    final categories = <PrivateAlphaPrivacyFindingCategory>{};
    if (_apiKeyPatterns.any((pattern) => pattern.hasMatch(content))) {
      categories.add(PrivateAlphaPrivacyFindingCategory.apiKey);
    }
    if (_authorizationPattern.hasMatch(content)) {
      categories.add(PrivateAlphaPrivacyFindingCategory.authorization);
    }
    if (_credentialQueryPattern.hasMatch(content)) {
      categories.add(PrivateAlphaPrivacyFindingCategory.credentialQuery);
    }
    if (_privatePathPatterns.any((pattern) => pattern.hasMatch(content))) {
      categories.add(PrivateAlphaPrivacyFindingCategory.privateAbsolutePath);
    }
    if (_jwtPattern.hasMatch(content)) {
      categories.add(PrivateAlphaPrivacyFindingCategory.jwt);
    }
    return categories;
  }

  bool _isSensitiveFile(String relativePath) {
    final name = p.basename(relativePath).toLowerCase();
    if (_sensitiveFileNames.contains(name) ||
        name.startsWith('.env.') ||
        name.startsWith('secrets.') ||
        name.endsWith('.secrets.json')) {
      return true;
    }
    return _sensitiveExtensions.contains(p.extension(name));
  }
}
