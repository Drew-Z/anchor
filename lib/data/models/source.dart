enum SourceType {
  text('text', '文本'),
  markdown('markdown', 'Markdown'),
  url('url', '网页'),
  project('project', '项目'),
  codeFile('code_file', '代码文件'),
  officialDoc('official_doc', '官方文档'),
  userNote('user_note', '个人笔记');

  final String value;
  final String label;
  const SourceType(this.value, this.label);

  static SourceType fromString(String value) {
    return SourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SourceType.text,
    );
  }
}

enum SourceTrustLevel {
  officialDoc('official_doc', '官方文档'),
  sourceCode('source_code', '源码'),
  bookCourse('book_course', '书籍/课程'),
  article('article', '文章'),
  userNote('user_note', '个人笔记'),
  unknown('unknown', '未知');

  final String value;
  final String label;
  const SourceTrustLevel(this.value, this.label);

  static SourceTrustLevel fromString(String value) {
    return SourceTrustLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SourceTrustLevel.unknown,
    );
  }
}

class Source {
  final String id;
  final String title;
  final SourceType type;
  final String? uri;
  final String? revision;
  final String? publisher;
  final String? licenseExpression;
  final DateTime? retrievedAt;
  final String contentHash;
  final SourceTrustLevel trustLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Source({
    required this.id,
    required this.title,
    required this.type,
    this.uri,
    this.revision,
    this.publisher,
    this.licenseExpression,
    this.retrievedAt,
    this.contentHash = '',
    this.trustLevel = SourceTrustLevel.unknown,
    required this.createdAt,
    required this.updatedAt,
  });

  Source copyWith({
    String? id,
    String? title,
    SourceType? type,
    String? uri,
    String? revision,
    String? publisher,
    String? licenseExpression,
    DateTime? retrievedAt,
    String? contentHash,
    SourceTrustLevel? trustLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Source(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      uri: uri ?? this.uri,
      revision: revision ?? this.revision,
      publisher: publisher ?? this.publisher,
      licenseExpression: licenseExpression ?? this.licenseExpression,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      contentHash: contentHash ?? this.contentHash,
      trustLevel: trustLevel ?? this.trustLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.value,
      'uri': uri,
      'revision': revision,
      'publisher': publisher,
      'license_expression': licenseExpression,
      'retrieved_at': retrievedAt?.millisecondsSinceEpoch,
      'content_hash': contentHash,
      'trust_level': trustLevel.value,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Source.fromMap(Map<String, dynamic> map) {
    return Source(
      id: map['id'] as String,
      title: map['title'] as String,
      type: SourceType.fromString(
        (map['type'] as String?) ?? SourceType.text.value,
      ),
      uri: map['uri'] as String?,
      revision: map['revision'] as String?,
      publisher: map['publisher'] as String?,
      licenseExpression: map['license_expression'] as String?,
      retrievedAt: map['retrieved_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['retrieved_at'] as int),
      contentHash: (map['content_hash'] as String?) ?? '',
      trustLevel: SourceTrustLevel.fromString(
        (map['trust_level'] as String?) ?? SourceTrustLevel.unknown.value,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
