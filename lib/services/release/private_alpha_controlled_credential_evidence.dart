import 'private_alpha_model_acceptance_evidence.dart';

class PrivateAlphaCredentialBindingEvidence {
  final String role;
  final PrivateAlphaCredentialScope scope;
  final String credentialReference;
  final String profileFingerprint;
  final bool quotaOwnerDeclared;
  final bool quotaLimitKnown;
  final bool revocationSupported;
  final bool revocationOwnerDeclared;
  final bool retentionPolicyDeclared;
  final bool dataHandlingPolicyDeclared;

  const PrivateAlphaCredentialBindingEvidence({
    required this.role,
    required this.scope,
    required this.credentialReference,
    required this.profileFingerprint,
    required this.quotaOwnerDeclared,
    required this.quotaLimitKnown,
    required this.revocationSupported,
    required this.revocationOwnerDeclared,
    required this.retentionPolicyDeclared,
    required this.dataHandlingPolicyDeclared,
  });

  factory PrivateAlphaCredentialBindingEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final role = _requiredString(json, 'role');
    if (role != 'primary' && role != 'fallback') {
      throw const FormatException(
        'controlled_credential binding role must be primary or fallback.',
      );
    }
    final scopeName = _requiredString(json, 'scope');
    final scope = PrivateAlphaCredentialScope.values
        .where((value) => value.name == scopeName)
        .firstOrNull;
    if (scope == null) {
      throw const FormatException(
        'controlled_credential scope must be controlled, participantOwned, or sharedPublic.',
      );
    }
    return PrivateAlphaCredentialBindingEvidence(
      role: role,
      scope: scope,
      credentialReference: _requiredString(json, 'credential_reference'),
      profileFingerprint: _requiredHash(json, 'profile_fingerprint'),
      quotaOwnerDeclared: _requiredBool(json, 'quota_owner_declared'),
      quotaLimitKnown: _requiredBool(json, 'quota_limit_known'),
      revocationSupported: _requiredBool(json, 'revocation_supported'),
      revocationOwnerDeclared: _requiredBool(json, 'revocation_owner_declared'),
      retentionPolicyDeclared: _requiredBool(json, 'retention_policy_declared'),
      dataHandlingPolicyDeclared:
          _requiredBool(json, 'data_handling_policy_declared'),
    );
  }
}

class PrivateAlphaControlledCredentialEvidence {
  final List<PrivateAlphaCredentialBindingEvidence> bindings;

  const PrivateAlphaControlledCredentialEvidence({required this.bindings});

  factory PrivateAlphaControlledCredentialEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final value = json['controlled_credential'];
    if (value is! Map<String, dynamic> || value['bindings'] is! List) {
      throw const FormatException(
        'controlled_credential must contain a bindings array.',
      );
    }
    return PrivateAlphaControlledCredentialEvidence(
      bindings: List.unmodifiable(
        (value['bindings'] as List).map((item) {
          if (item is! Map) {
            throw const FormatException(
              'controlled_credential bindings must be JSON objects.',
            );
          }
          return PrivateAlphaCredentialBindingEvidence.fromJson(
            Map<String, dynamic>.from(item),
          );
        }),
      ),
    );
  }
}

class PrivateAlphaControlledCredentialVerification {
  final List<String> blockers;

  const PrivateAlphaControlledCredentialVerification(this.blockers);
}

class PrivateAlphaControlledCredentialEvidenceVerifier {
  const PrivateAlphaControlledCredentialEvidenceVerifier();

  PrivateAlphaControlledCredentialVerification verify({
    required PrivateAlphaControlledCredentialEvidence evidence,
    PrivateAlphaReleaseDayAcceptanceEvidence? acceptanceEvidence,
  }) {
    final blockers = <String>[];
    final references = <String>{};
    final bindingsByRole =
        <String, List<PrivateAlphaCredentialBindingEvidence>>{};
    for (final binding in evidence.bindings) {
      bindingsByRole.putIfAbsent(binding.role, () => []).add(binding);
      final prefix = 'controlled_credential_${binding.role}';
      if (binding.scope == PrivateAlphaCredentialScope.sharedPublic) {
        blockers.add('${prefix}_scope_uncontrolled');
      }
      if (!RegExp(r'^CRED-[A-Z0-9-]{3,64}$')
          .hasMatch(binding.credentialReference)) {
        blockers.add('${prefix}_reference_invalid');
      } else if (!references.add(binding.credentialReference)) {
        blockers.add('controlled_credential_references_not_independent');
      }
      if (!binding.quotaOwnerDeclared || !binding.quotaLimitKnown) {
        blockers.add('${prefix}_quota_control_required');
      }
      if (!binding.revocationSupported || !binding.revocationOwnerDeclared) {
        blockers.add('${prefix}_revocation_control_required');
      }
      if (!binding.retentionPolicyDeclared ||
          !binding.dataHandlingPolicyDeclared) {
        blockers.add('${prefix}_data_policy_required');
      }
    }

    if (acceptanceEvidence == null) {
      blockers.add('controlled_credential_release_day_binding_required');
    } else {
      for (final profile in acceptanceEvidence.profiles) {
        final matches = bindingsByRole[profile.role] ?? const [];
        if (matches.length != 1) {
          blockers.add(
            'controlled_credential_${profile.role}_binding_required',
          );
          continue;
        }
        final binding = matches.single;
        if (binding.profileFingerprint != profile.fingerprint ||
            binding.scope != profile.credentialScope) {
          blockers.add(
            'controlled_credential_${profile.role}_profile_mismatch',
          );
        }
      }
      final acceptedRoles =
          acceptanceEvidence.profiles.map((profile) => profile.role).toSet();
      for (final role
          in bindingsByRole.keys.toSet().difference(acceptedRoles)) {
        blockers.add('controlled_credential_${role}_unoffered_binding');
      }
    }
    return PrivateAlphaControlledCredentialVerification(
      List.unmodifiable(blockers.toSet()),
    );
  }
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

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
