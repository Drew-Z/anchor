class SourceChunk {
  final String id;
  final String sourceId;
  final int chunkIndex;
  final String content;
  final String? locator;
  final String? relativePath;
  final int? startLine;
  final int? endLine;
  final String contentHash;
  final DateTime createdAt;

  SourceChunk({
    required this.id,
    required this.sourceId,
    required this.chunkIndex,
    required this.content,
    this.locator,
    this.relativePath,
    this.startLine,
    this.endLine,
    this.contentHash = '',
    required this.createdAt,
  });

  SourceChunk copyWith({
    String? id,
    String? sourceId,
    int? chunkIndex,
    String? content,
    String? locator,
    String? relativePath,
    int? startLine,
    int? endLine,
    String? contentHash,
    DateTime? createdAt,
  }) {
    return SourceChunk(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      content: content ?? this.content,
      locator: locator ?? this.locator,
      relativePath: relativePath ?? this.relativePath,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'chunk_index': chunkIndex,
      'content': content,
      'locator': locator,
      'relative_path': relativePath,
      'start_line': startLine,
      'end_line': endLine,
      'content_hash': contentHash,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SourceChunk.fromMap(Map<String, dynamic> map) {
    return SourceChunk(
      id: map['id'] as String,
      sourceId: map['source_id'] as String,
      chunkIndex: map['chunk_index'] as int,
      content: map['content'] as String,
      locator: map['locator'] as String?,
      relativePath: map['relative_path'] as String?,
      startLine: map['start_line'] as int?,
      endLine: map['end_line'] as int?,
      contentHash: (map['content_hash'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
