import 'dart:convert';

import 'package:crypto/crypto.dart';

enum PrivateAlphaCredentialScope {
  controlled,
  participantOwned,
  sharedPublic,
}

class PrivateAlphaModelProfileEvidence {
  static const requiredCases = {
    'structuredJson',
    'chinesePoem',
    'dartCoding',
    'claimGrounding',
    'evidenceRefusal',
  };

  final String role;
  final String providerId;
  final String endpoint;
  final String model;
  final String protocol;
  final String fingerprint;
  final DateTime completedAt;
  final String apkSha256;
  final PrivateAlphaCredentialScope credentialScope;
  final Map<String, String> cases;

  const PrivateAlphaModelProfileEvidence({
    required this.role,
    required this.providerId,
    required this.endpoint,
    required this.model,
    required this.protocol,
    required this.fingerprint,
    required this.completedAt,
    required this.apkSha256,
    required this.credentialScope,
    required this.cases,
  });

  factory PrivateAlphaModelProfileEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final role = _requiredString(json, 'role');
    if (role != 'primary' && role != 'fallback') {
      throw const FormatException(
        'release_day_acceptance profile role must be primary or fallback.',
      );
    }
    final completedAt =
        DateTime.tryParse(_requiredString(json, 'completed_at'));
    if (completedAt == null) {
      throw const FormatException(
        'release_day_acceptance completed_at must be ISO-8601.',
      );
    }
    final scopeName = _requiredString(json, 'credential_scope');
    final scope = PrivateAlphaCredentialScope.values
        .where((value) => value.name == scopeName)
        .firstOrNull;
    if (scope == null) {
      throw const FormatException(
        'credential_scope must be controlled, participantOwned, or sharedPublic.',
      );
    }
    final rawCases = json['cases'];
    if (rawCases is! Map<String, dynamic>) {
      throw const FormatException(
        'release_day_acceptance cases must be a JSON object.',
      );
    }
    return PrivateAlphaModelProfileEvidence(
      role: role,
      providerId: _requiredString(json, 'provider_id').toLowerCase(),
      endpoint: _requiredString(json, 'endpoint'),
      model: _requiredString(json, 'model'),
      protocol: _requiredString(json, 'protocol'),
      fingerprint: _requiredString(json, 'fingerprint').toLowerCase(),
      completedAt: completedAt.toUtc(),
      apkSha256: _requiredHash(json, 'apk_sha256'),
      credentialScope: scope,
      cases: Map.unmodifiable(
        rawCases.map((key, value) => MapEntry(key, value.toString())),
      ),
    );
  }

  String get canonicalSignature =>
      '$providerId|${_canonicalEndpoint(endpoint)}|$model|$protocol';

  String get calculatedFingerprint =>
      sha256.convert(utf8.encode(canonicalSignature)).toString();
}

class PrivateAlphaReleaseDayAcceptanceEvidence {
  final bool fallbackOffered;
  final List<PrivateAlphaModelProfileEvidence> profiles;

  const PrivateAlphaReleaseDayAcceptanceEvidence({
    required this.fallbackOffered,
    required this.profiles,
  });

  factory PrivateAlphaReleaseDayAcceptanceEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final value = json['release_day_acceptance'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'release_day_acceptance must be a JSON object.',
      );
    }
    final fallbackOffered = value['fallback_offered'];
    final rawProfiles = value['profiles'];
    if (fallbackOffered is! bool || rawProfiles is! List) {
      throw const FormatException(
        'release_day_acceptance requires fallback_offered and profiles.',
      );
    }
    return PrivateAlphaReleaseDayAcceptanceEvidence(
      fallbackOffered: fallbackOffered,
      profiles: List.unmodifiable(
        rawProfiles.map((item) {
          if (item is! Map) {
            throw const FormatException(
              'release_day_acceptance profiles must be JSON objects.',
            );
          }
          return PrivateAlphaModelProfileEvidence.fromJson(
            Map<String, dynamic>.from(item),
          );
        }),
      ),
    );
  }
}

class PrivateAlphaModelAcceptanceVerification {
  final List<String> blockers;

  const PrivateAlphaModelAcceptanceVerification(this.blockers);
}

class PrivateAlphaModelAcceptanceEvidenceVerifier {
  final Duration maximumAge;

  const PrivateAlphaModelAcceptanceEvidenceVerifier({
    this.maximumAge = const Duration(hours: 24),
  });

  PrivateAlphaModelAcceptanceVerification verify({
    required PrivateAlphaReleaseDayAcceptanceEvidence evidence,
    required String expectedApkSha256,
    required DateTime evaluatedAt,
  }) {
    final blockers = <String>[];
    final roles = evidence.profiles.map((profile) => profile.role).toList();
    if (roles.where((role) => role == 'primary').length != 1) {
      blockers.add('release_day_acceptance_primary_required');
    }
    final fallbackCount = roles.where((role) => role == 'fallback').length;
    if (evidence.fallbackOffered && fallbackCount != 1) {
      blockers.add('release_day_acceptance_fallback_required');
    }
    if (!evidence.fallbackOffered && fallbackCount > 0) {
      blockers.add('release_day_acceptance_unoffered_fallback');
    }
    final fingerprints = <String>{};
    for (final profile in evidence.profiles) {
      final prefix = 'release_day_acceptance_${profile.role}';
      if (!_isSafeEndpoint(profile.endpoint)) {
        blockers.add('${prefix}_endpoint_invalid');
      }
      if (profile.fingerprint != profile.calculatedFingerprint ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(profile.fingerprint)) {
        blockers.add('${prefix}_fingerprint_mismatch');
      }
      if (!fingerprints.add(profile.fingerprint)) {
        blockers.add('release_day_acceptance_profiles_not_independent');
      }
      final age = evaluatedAt.toUtc().difference(profile.completedAt);
      if (age.isNegative || age > maximumAge) {
        blockers.add('${prefix}_stale');
      }
      if (profile.apkSha256 != expectedApkSha256.toLowerCase()) {
        blockers.add('${prefix}_apk_mismatch');
      }
      if (profile.credentialScope == PrivateAlphaCredentialScope.sharedPublic) {
        blockers.add('${prefix}_credential_uncontrolled');
      }
      if (profile.cases.keys
              .toSet()
              .difference(
                PrivateAlphaModelProfileEvidence.requiredCases,
              )
              .isNotEmpty ||
          PrivateAlphaModelProfileEvidence.requiredCases
              .difference(profile.cases.keys.toSet())
              .isNotEmpty ||
          profile.cases.values.any((status) => status != 'passed')) {
        blockers.add('${prefix}_five_of_five_required');
      }
    }
    return PrivateAlphaModelAcceptanceVerification(
      List.unmodifiable(blockers.toSet()),
    );
  }

  bool _isSafeEndpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        _canonicalEndpoint(value) == value;
  }
}

String _canonicalEndpoint(String value) {
  final uri = Uri.tryParse(value.trim().replaceFirst(RegExp(r'/+$'), ''));
  if (uri == null || uri.host.isEmpty) return value.trim();
  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: uri.path.replaceFirst(RegExp(r'/+$'), ''),
  ).toString();
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

String _requiredHash(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key).toLowerCase();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('$key must contain 64 hexadecimal characters.');
  }
  return value;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
