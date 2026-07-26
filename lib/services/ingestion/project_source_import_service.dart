import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../data/models/source_chunk.dart';
import 'semantic_chunker.dart';

enum ProjectSourceImportKind { directory, zip }

enum ProjectSourceExclusionReason {
  generated,
  sensitive,
  unsupported,
  binary,
  tooLarge,
  fileLimit,
  totalSizeLimit,
  unsafePath,
  invalidEncoding,
  empty,
  readFailed,
}

class ProjectSourceFile {
  final String relativePath;
  final String content;
  final String contentHash;
  final int byteLength;
  final int lineCount;
  final bool selectedByDefault;

  const ProjectSourceFile({
    required this.relativePath,
    required this.content,
    required this.contentHash,
    required this.byteLength,
    required this.lineCount,
    this.selectedByDefault = true,
  });

  String get locator =>
      lineCount > 0 ? '$relativePath:1-$lineCount' : relativePath;
}

class ProjectSourceExclusion {
  final String relativePath;
  final ProjectSourceExclusionReason reason;
  final String detail;

  const ProjectSourceExclusion({
    required this.relativePath,
    required this.reason,
    required this.detail,
  });
}

class ProjectSourceSnapshot {
  final ProjectSourceImportKind kind;
  final String displayName;
  final String sourceUri;
  final String revision;
  final List<ProjectSourceFile> files;
  final List<ProjectSourceExclusion> exclusions;

  const ProjectSourceSnapshot({
    required this.kind,
    required this.displayName,
    required this.sourceUri,
    required this.revision,
    required this.files,
    required this.exclusions,
  });

  int get includedBytes =>
      files.fold(0, (total, file) => total + file.byteLength);
}

class ProjectSourceImportPolicy {
  final int maxFileBytes;
  final int maxTotalBytes;
  final int maxFiles;
  final int maxDefaultSelectedBytes;
  final int maxDefaultSelectedFiles;

  const ProjectSourceImportPolicy({
    this.maxFileBytes = 512 * 1024,
    this.maxTotalBytes = 8 * 1024 * 1024,
    this.maxFiles = 500,
    this.maxDefaultSelectedBytes = 192 * 1024,
    this.maxDefaultSelectedFiles = 30,
  });

  static const _generatedDirectories = <String>{
    '.dart_tool',
    '.git',
    '.gradle',
    '.idea',
    '.next',
    '.nuxt',
    '.pub-cache',
    '.vscode',
    'build',
    'coverage',
    'deriveddata',
    'dist',
    'node_modules',
    'pods',
    'target',
    'vendor',
  };

  static const _sensitiveFileNames = <String>{
    '.env',
    '.netrc',
    '.npmrc',
    '.pypirc',
    'credentials.json',
    'google-services.json',
    'googleservice-info.plist',
    'id_ed25519',
    'id_rsa',
    'key.properties',
    'local.properties',
    'service-account.json',
  };

  static const _sensitiveExtensions = <String>{
    '.jks',
    '.key',
    '.keystore',
    '.mobileprovision',
    '.p12',
    '.pem',
    '.pfx',
  };

  static const _generatedFileNames = <String>{
    'package-lock.json',
    'pnpm-lock.yaml',
    'pubspec.lock',
    'yarn.lock',
  };

  static const _supportedExtensions = <String>{
    '.bat',
    '.c',
    '.cc',
    '.cfg',
    '.cmd',
    '.cpp',
    '.cs',
    '.css',
    '.csv',
    '.dart',
    '.fish',
    '.go',
    '.gradle',
    '.graphql',
    '.groovy',
    '.h',
    '.hpp',
    '.html',
    '.ini',
    '.java',
    '.js',
    '.json',
    '.jsx',
    '.kt',
    '.kts',
    '.less',
    '.lua',
    '.md',
    '.mjs',
    '.mm',
    '.m',
    '.php',
    '.plist',
    '.properties',
    '.proto',
    '.ps1',
    '.py',
    '.rb',
    '.rs',
    '.sass',
    '.scala',
    '.scss',
    '.sh',
    '.sql',
    '.svelte',
    '.swift',
    '.toml',
    '.ts',
    '.tsx',
    '.txt',
    '.vue',
    '.xml',
    '.yaml',
    '.yml',
    '.zsh',
  };

  static const _supportedExtensionlessNames = <String>{
    '.gitignore',
    'dockerfile',
    'gemfile',
    'makefile',
    'podfile',
    'procfile',
  };

  ProjectSourceExclusionReason? classifyPath(
    String relativePath,
    int byteLength,
  ) {
    final normalized = relativePath.replaceAll('\\', '/');
    final lowerPath = normalized.toLowerCase();
    final segments = lowerPath.split('/');
    final fileName = segments.last;
    final extension = p.extension(fileName).toLowerCase();

    if (segments.any(_generatedDirectories.contains)) {
      return ProjectSourceExclusionReason.generated;
    }
    if (_isSensitive(fileName, extension)) {
      return ProjectSourceExclusionReason.sensitive;
    }
    if (_isGeneratedFile(fileName)) {
      return ProjectSourceExclusionReason.generated;
    }
    if (byteLength > maxFileBytes) {
      return ProjectSourceExclusionReason.tooLarge;
    }
    if (!_supportedExtensions.contains(extension) &&
        !_supportedExtensionlessNames.contains(fileName)) {
      return ProjectSourceExclusionReason.unsupported;
    }
    return null;
  }

  bool _isSensitive(String fileName, String extension) {
    if (_sensitiveFileNames.contains(fileName) ||
        _sensitiveExtensions.contains(extension)) {
      return true;
    }
    return fileName.startsWith('.env.') ||
        fileName.startsWith('secrets.') ||
        fileName.endsWith('.secrets.json');
  }

  bool _isGeneratedFile(String fileName) {
    return _generatedFileNames.contains(fileName) ||
        fileName.endsWith('.freezed.dart') ||
        fileName.endsWith('.g.dart') ||
        fileName.endsWith('.gen.dart') ||
        fileName.endsWith('.min.css') ||
        fileName.endsWith('.min.js');
  }
}

class ProjectSourceInputFile {
  final String relativePath;
  final int byteLength;
  final Future<Uint8List> Function() readBytes;

  const ProjectSourceInputFile({
    required this.relativePath,
    required this.byteLength,
    required this.readBytes,
  });
}

class ProjectSourceReadLimitException implements Exception {
  final int maxBytes;

  const ProjectSourceReadLimitException(this.maxBytes);

  @override
  String toString() => 'File exceeds the $maxBytes-byte read limit.';
}

class ProjectSourceImportService {
  final ProjectSourceImportPolicy policy;
  final SemanticChunker _semanticChunker;

  const ProjectSourceImportService({
    this.policy = const ProjectSourceImportPolicy(),
    SemanticChunker? semanticChunker,
  }) : _semanticChunker = semanticChunker ?? const SemanticChunker();

  Future<ProjectSourceSnapshot> scanDirectory(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw StateError('Project directory does not exist: $rootPath');
    }

    final entries = <ProjectSourceInputFile>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relativePath = _normalizeRelativePath(
        p.relative(entity.path, from: root.absolute.path),
      );
      entries.add(
        ProjectSourceInputFile(
          relativePath: relativePath,
          byteLength: await entity.length(),
          readBytes: entity.readAsBytes,
        ),
      );
    }
    entries.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    final collected = await _collect(entries);
    final manifestHash = _manifestHash(collected.files);
    final gitRevision = await _readGitRevision(root);
    final revision = gitRevision == null
        ? 'snapshot:$manifestHash'
        : 'git:$gitRevision;snapshot:$manifestHash';

    return ProjectSourceSnapshot(
      kind: ProjectSourceImportKind.directory,
      displayName: p.basename(root.absolute.path),
      sourceUri: root.absolute.path,
      revision: revision,
      files: collected.files,
      exclusions: collected.exclusions,
    );
  }

  Future<ProjectSourceSnapshot> scanDirectoryEntries({
    required String displayName,
    required String sourceUri,
    required List<ProjectSourceInputFile> entries,
  }) async {
    final safeEntries = <ProjectSourceInputFile>[];
    final exclusions = <ProjectSourceExclusion>[];
    final seenPaths = <String>{};

    for (final entry in entries) {
      final safePath = _safeRelativePath(entry.relativePath);
      if (safePath == null || !seenPaths.add(safePath)) {
        exclusions.add(
          ProjectSourceExclusion(
            relativePath: entry.relativePath,
            reason: ProjectSourceExclusionReason.unsafePath,
            detail: safePath == null
                ? 'Directory entry is outside the project root.'
                : 'Directory contains a duplicate relative path.',
          ),
        );
        continue;
      }
      safeEntries.add(
        ProjectSourceInputFile(
          relativePath: safePath,
          byteLength: math.max(0, entry.byteLength),
          readBytes: entry.readBytes,
        ),
      );
    }
    safeEntries.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    final collected = await _collect(
      safeEntries,
      initialExclusions: exclusions,
    );
    final manifestHash = _manifestHash(collected.files);

    return ProjectSourceSnapshot(
      kind: ProjectSourceImportKind.directory,
      displayName: displayName.trim().isEmpty ? 'Project' : displayName.trim(),
      sourceUri: sourceUri,
      revision: 'snapshot:$manifestHash',
      files: collected.files,
      exclusions: collected.exclusions,
    );
  }

  Future<ProjectSourceSnapshot> scanZipFile(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw StateError('Project ZIP does not exist: $zipPath');
    }
    return scanZipBytes(
      archiveName: p.basename(zipPath),
      bytes: await file.readAsBytes(),
      sourceUri: file.absolute.path,
    );
  }

  Future<ProjectSourceSnapshot> scanZipBytes({
    required String archiveName,
    required List<int> bytes,
    String? sourceUri,
  }) async {
    final archiveBytes = Uint8List.fromList(bytes);
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(archiveBytes, verify: true);
    } catch (error) {
      throw StateError('Invalid project ZIP: $error');
    }

    final safeFiles = archive.files.where((entry) => entry.isFile).toList();
    final safePaths = safeFiles
        .map((entry) => _safeArchivePath(entry.name))
        .whereType<String>()
        .toList();
    final commonRoot = _commonArchiveRoot(safePaths);
    final entries = <ProjectSourceInputFile>[];
    final exclusions = <ProjectSourceExclusion>[];

    for (final entry in safeFiles) {
      final safePath = _safeArchivePath(entry.name);
      if (safePath == null) {
        exclusions.add(
          ProjectSourceExclusion(
            relativePath: entry.name,
            reason: ProjectSourceExclusionReason.unsafePath,
            detail: 'Archive path escapes the project root.',
          ),
        );
        continue;
      }
      final relativePath = commonRoot == null
          ? safePath
          : safePath.substring(commonRoot.length + 1);
      if (relativePath.isEmpty) continue;
      entries.add(
        ProjectSourceInputFile(
          relativePath: relativePath,
          byteLength: entry.size,
          readBytes: () async => entry.readBytes() ?? Uint8List(0),
        ),
      );
    }
    entries.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    final collected = await _collect(entries, initialExclusions: exclusions);
    final manifestHash = _manifestHash(collected.files);
    final archiveHash = sha256.convert(archiveBytes).toString();
    final displayName = p.basenameWithoutExtension(archiveName);

    return ProjectSourceSnapshot(
      kind: ProjectSourceImportKind.zip,
      displayName: displayName.isEmpty ? archiveName : displayName,
      sourceUri: sourceUri ?? archiveName,
      revision: 'zip:$archiveHash;snapshot:$manifestHash',
      files: collected.files,
      exclusions: collected.exclusions,
    );
  }

  List<SourceChunk> buildSourceChunks({
    required ProjectSourceSnapshot snapshot,
    required Set<String> selectedPaths,
    required String sourceId,
    required DateTime createdAt,
    int maxLinesPerChunk = 160,
  }) {
    if (maxLinesPerChunk <= 0) {
      throw ArgumentError.value(
        maxLinesPerChunk,
        'maxLinesPerChunk',
        'Must be greater than zero.',
      );
    }

    final selectedFiles = snapshot.files
        .where((file) => selectedPaths.contains(file.relativePath))
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    final chunks = <SourceChunk>[];

    void appendSemanticChunks(
      Iterable<SourceChunk> fileChunks,
      String relativePath,
    ) {
      for (final chunk in fileChunks) {
        final chunkIndex = chunks.length;
        chunks.add(
          chunk.copyWith(
            id: '${sourceId}_chunk_$chunkIndex',
            chunkIndex: chunkIndex,
            relativePath: relativePath,
          ),
        );
      }
    }

    for (final file in selectedFiles) {
      // 检测文件类型
      final ext = p.extension(file.relativePath).toLowerCase();
      final isMarkdown = ext == '.md' || ext == '.markdown';
      final isCode = _isCodeFile(ext);

      if (isMarkdown) {
        // Markdown 文件使用语义切分
        final mdChunks = _semanticChunker.chunkMarkdown(
          sourceId: sourceId,
          markdown: file.content,
          createdAt: createdAt,
          baseLocator: file.relativePath,
        );
        appendSemanticChunks(mdChunks, file.relativePath);
      } else if (isCode) {
        // 代码文件使用固定行数切分(保持简单可溯源)
        final codeChunks = _semanticChunker.chunkCode(
          sourceId: sourceId,
          code: file.content,
          filePath: file.relativePath,
          createdAt: createdAt,
          maxLinesPerChunk: maxLinesPerChunk,
        );
        appendSemanticChunks(codeChunks, file.relativePath);
      } else {
        // 其他文本文件回退到行切分
        final lines = const LineSplitter().convert(file.content);
        for (var start = 0; start < lines.length; start += maxLinesPerChunk) {
          final end = math.min(start + maxLinesPerChunk, lines.length);
          final chunkContent = lines.sublist(start, end).join('\n');
          final chunkIndex = chunks.length;
          final startLine = start + 1;
          final endLine = end;
          chunks.add(
            SourceChunk(
              id: '${sourceId}_chunk_$chunkIndex',
              sourceId: sourceId,
              chunkIndex: chunkIndex,
              content: chunkContent,
              locator: '${file.relativePath}:$startLine-$endLine',
              relativePath: file.relativePath,
              startLine: startLine,
              endLine: endLine,
              contentHash: sha256.convert(utf8.encode(chunkContent)).toString(),
              createdAt: createdAt,
            ),
          );
        }
      }
    }
    return chunks;
  }

  bool _isCodeFile(String ext) {
    const codeExtensions = {
      '.dart',
      '.java',
      '.kt',
      '.swift',
      '.js',
      '.ts',
      '.tsx',
      '.jsx',
      '.py',
      '.rb',
      '.go',
      '.rs',
      '.c',
      '.cpp',
      '.h',
      '.hpp',
      '.cs',
      '.php',
      '.sh',
      '.bash',
      '.sql',
      '.yaml',
      '.yml',
      '.json',
      '.xml',
    };
    return codeExtensions.contains(ext);
  }

  Future<_CollectedProjectSources> _collect(
    List<ProjectSourceInputFile> entries, {
    List<ProjectSourceExclusion> initialExclusions = const [],
  }) async {
    final files = <ProjectSourceFile>[];
    final exclusions = <ProjectSourceExclusion>[...initialExclusions];
    var totalBytes = 0;
    var defaultSelectedBytes = 0;
    var defaultSelectedFiles = 0;

    for (final entry in entries) {
      final pathReason = policy.classifyPath(
        entry.relativePath,
        entry.byteLength,
      );
      if (pathReason != null) {
        exclusions.add(
          _exclusion(entry.relativePath, pathReason),
        );
        continue;
      }
      if (files.length >= policy.maxFiles) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.fileLimit,
          ),
        );
        continue;
      }
      if (totalBytes + entry.byteLength > policy.maxTotalBytes) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.totalSizeLimit,
          ),
        );
        continue;
      }

      late final Uint8List bytes;
      try {
        bytes = await entry.readBytes();
      } on ProjectSourceReadLimitException {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.tooLarge,
          ),
        );
        continue;
      } catch (error) {
        exclusions.add(
          ProjectSourceExclusion(
            relativePath: entry.relativePath,
            reason: ProjectSourceExclusionReason.readFailed,
            detail: 'Could not read file: $error',
          ),
        );
        continue;
      }

      if (bytes.length > policy.maxFileBytes) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.tooLarge,
          ),
        );
        continue;
      }
      if (totalBytes + bytes.length > policy.maxTotalBytes) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.totalSizeLimit,
          ),
        );
        continue;
      }

      if (bytes.contains(0)) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.binary,
          ),
        );
        continue;
      }

      late final String decoded;
      try {
        decoded = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.invalidEncoding,
          ),
        );
        continue;
      }

      final content = _normalizeContent(decoded);
      if (content.trim().isEmpty) {
        exclusions.add(
          _exclusion(
            entry.relativePath,
            ProjectSourceExclusionReason.empty,
          ),
        );
        continue;
      }

      final canonicalBytes = Uint8List.fromList(utf8.encode(content));
      final selectedByDefault =
          defaultSelectedFiles < policy.maxDefaultSelectedFiles &&
              defaultSelectedBytes + canonicalBytes.length <=
                  policy.maxDefaultSelectedBytes;
      files.add(
        ProjectSourceFile(
          relativePath: entry.relativePath,
          content: content,
          contentHash: sha256.convert(canonicalBytes).toString(),
          byteLength: canonicalBytes.length,
          lineCount: const LineSplitter().convert(content).length,
          selectedByDefault: selectedByDefault,
        ),
      );
      totalBytes += canonicalBytes.length;
      if (selectedByDefault) {
        defaultSelectedBytes += canonicalBytes.length;
        defaultSelectedFiles += 1;
      }
    }

    return _CollectedProjectSources(files: files, exclusions: exclusions);
  }

  ProjectSourceExclusion _exclusion(
    String relativePath,
    ProjectSourceExclusionReason reason,
  ) {
    final detail = switch (reason) {
      ProjectSourceExclusionReason.generated =>
        'Generated, dependency, cache, or build output.',
      ProjectSourceExclusionReason.sensitive =>
        'Potential secret, credential, key, or local configuration.',
      ProjectSourceExclusionReason.unsupported =>
        'Unsupported file type for source-grounded learning.',
      ProjectSourceExclusionReason.binary => 'Binary content detected.',
      ProjectSourceExclusionReason.tooLarge =>
        'File exceeds the ${policy.maxFileBytes}-byte limit.',
      ProjectSourceExclusionReason.fileLimit =>
        'Project exceeds the ${policy.maxFiles}-file limit.',
      ProjectSourceExclusionReason.totalSizeLimit =>
        'Selected source exceeds the ${policy.maxTotalBytes}-byte limit.',
      ProjectSourceExclusionReason.unsafePath =>
        'Path escapes or is ambiguous within the project root.',
      ProjectSourceExclusionReason.invalidEncoding =>
        'File is not valid UTF-8 text.',
      ProjectSourceExclusionReason.empty => 'File has no learning content.',
      ProjectSourceExclusionReason.readFailed => 'File could not be read.',
    };
    return ProjectSourceExclusion(
      relativePath: relativePath,
      reason: reason,
      detail: detail,
    );
  }

  String _manifestHash(List<ProjectSourceFile> files) {
    final manifest = files
        .map(
          (file) =>
              '${file.relativePath}\u0000${file.contentHash}\u0000${file.byteLength}',
        )
        .join('\n');
    return sha256.convert(utf8.encode(manifest)).toString();
  }

  Future<String?> _readGitRevision(Directory root) async {
    var gitDirectory = Directory(p.join(root.path, '.git'));
    if (!await gitDirectory.exists()) {
      final gitMarker = File(p.join(root.path, '.git'));
      if (!await gitMarker.exists()) return null;
      final marker = (await gitMarker.readAsString()).trim();
      if (!marker.startsWith('gitdir:')) return null;
      final gitPath = marker.substring('gitdir:'.length).trim();
      gitDirectory = Directory(
        p.isAbsolute(gitPath)
            ? gitPath
            : p.normalize(p.join(root.path, gitPath)),
      );
      if (!await gitDirectory.exists()) return null;
    }

    final headFile = File(p.join(gitDirectory.path, 'HEAD'));
    if (!await headFile.exists()) return null;
    final head = (await headFile.readAsString()).trim();
    if (!head.startsWith('ref:')) {
      return _isGitHash(head) ? head : null;
    }

    final ref = head.substring('ref:'.length).trim();
    final refFile = File(p.join(gitDirectory.path, p.joinAll(ref.split('/'))));
    if (await refFile.exists()) {
      final value = (await refFile.readAsString()).trim();
      if (_isGitHash(value)) return value;
    }

    final packedRefs = File(p.join(gitDirectory.path, 'packed-refs'));
    if (!await packedRefs.exists()) return null;
    for (final line in await packedRefs.readAsLines()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('^')) {
        continue;
      }
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length == 2 && parts[1] == ref && _isGitHash(parts[0])) {
        return parts[0];
      }
    }
    return null;
  }

  bool _isGitHash(String value) =>
      RegExp(r'^[0-9a-fA-F]{7,64}$').hasMatch(value);

  String _normalizeRelativePath(String value) {
    return value.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');
  }

  String _normalizeContent(String value) {
    final withoutBom = value.startsWith('\uFEFF') ? value.substring(1) : value;
    return withoutBom.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  String? _safeRelativePath(String value) {
    final normalized = _normalizeRelativePath(value);
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:/').hasMatch(normalized)) {
      return null;
    }
    final segments = normalized.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    )) {
      return null;
    }
    return normalized;
  }

  String? _safeArchivePath(String value) => _safeRelativePath(value);

  String? _commonArchiveRoot(List<String> paths) {
    if (paths.isEmpty) return null;
    final firstSegments = paths.first.split('/');
    if (firstSegments.length < 2) return null;
    final root = firstSegments.first;
    final hasCommonRoot = paths.every((path) {
      final segments = path.split('/');
      return segments.length >= 2 && segments.first == root;
    });
    return hasCommonRoot ? root : null;
  }
}

class _CollectedProjectSources {
  final List<ProjectSourceFile> files;
  final List<ProjectSourceExclusion> exclusions;

  const _CollectedProjectSources({
    required this.files,
    required this.exclusions,
  });
}
