import 'dart:convert';

enum GroundingDisposition {
  grounded('grounded', '来源完整'),
  partial('partial', '部分回答'),
  refused('refused', '证据不足'),
  legacy('legacy', '历史记录');

  final String value;
  final String label;

  const GroundingDisposition(this.value, this.label);

  static GroundingDisposition fromString(String? value) {
    return GroundingDisposition.values.firstWhere(
      (disposition) => disposition.value == value,
      orElse: () => GroundingDisposition.legacy,
    );
  }
}

class GroundedClaimEvidence {
  final String citationId;
  final String quote;

  const GroundedClaimEvidence({
    required this.citationId,
    required this.quote,
  });

  Map<String, dynamic> toJson() {
    return {
      'citation_id': citationId,
      'quote': quote,
    };
  }

  factory GroundedClaimEvidence.fromJson(Map<String, dynamic> json) {
    return GroundedClaimEvidence(
      citationId: json['citation_id'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
    );
  }
}

class GroundedClaim {
  final String section;
  final String text;
  final List<GroundedClaimEvidence> evidence;

  const GroundedClaim({
    required this.section,
    required this.text,
    this.evidence = const [],
  });

  List<String> get citationIds => evidence
      .map((item) => item.citationId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  GroundedClaim copyWith({
    String? section,
    String? text,
    List<GroundedClaimEvidence>? evidence,
  }) {
    return GroundedClaim(
      section: section ?? this.section,
      text: text ?? this.text,
      evidence: evidence ?? this.evidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section': section,
      'text': text,
      'evidence': evidence.map((item) => item.toJson()).toList(),
    };
  }

  factory GroundedClaim.fromJson(Map<String, dynamic> json) {
    return GroundedClaim(
      section: json['section'] as String? ?? '',
      text: json['text'] as String? ?? '',
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => GroundedClaimEvidence.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

String encodeGroundedClaims(List<GroundedClaim> claims) {
  return jsonEncode(claims.map((claim) => claim.toJson()).toList());
}

List<GroundedClaim> decodeGroundedClaims(Object? value) {
  if (value == null) return const [];
  try {
    final decoded = value is String ? jsonDecode(value) : value;
    return (decoded as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => GroundedClaim.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((claim) => claim.text.trim().isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}
