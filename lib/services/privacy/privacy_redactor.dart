class PrivacyRedactor {
  static const int currentVersion = 1;

  const PrivacyRedactor();

  String redact(String input) {
    var value = input;
    value = value.replaceAllMapped(
      RegExp(r'''https?://[^\s\]\[<>"']+'''),
      (match) => _sanitizeUrl(match.group(0)!),
    );
    value = value.replaceAll(
      RegExp(r'\bsk-[A-Za-z0-9_-]{6,}\b'),
      '[redacted_api_key]',
    );
    value = value.replaceAll(
      RegExp(r'\bAIza[A-Za-z0-9_-]{12,}\b'),
      '[redacted_api_key]',
    );
    value = value.replaceAllMapped(
      RegExp(
        r'\b(authorization|api[_ -]?key|access[_ -]?token|bearer)\b\s*[:=]?\s*[^\s,;]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}: [redacted_secret]',
    );
    value = value.replaceAllMapped(
      RegExp(r'''(^|[\s=(])[A-Za-z]:[\\/][^\s\]\[<>"']+''', multiLine: true),
      (match) => '${match.group(1)}[private_path]',
    );
    value = value.replaceAllMapped(
      RegExp(
        r'(^|[\s=(])/(?:Users|home|data|storage|sdcard|var|tmp)/[^\s,;)]*',
        multiLine: true,
      ),
      (match) => '${match.group(1)}[private_path]',
    );
    return value;
  }

  List<String> redactLines(Iterable<Object?> lines) {
    return lines.map((line) => redact(line?.toString() ?? '')).toList();
  }

  String redactDiagnostic(String input) {
    final sanitized = redact(input);
    final output = <String>[];
    var omittingPrivateList = false;
    for (final line in sanitized.split('\n')) {
      final trimmed = line.trimLeft();
      if (_privateListHeading.hasMatch(trimmed)) {
        output.add(line);
        output.add('- [omitted_private_content]');
        omittingPrivateList = true;
        continue;
      }
      if (omittingPrivateList && trimmed.startsWith('- ')) continue;
      if (omittingPrivateList && trimmed.isNotEmpty) {
        omittingPrivateList = false;
      }
      final match = _privateLine.matchAsPrefix(trimmed);
      if (match != null) {
        final indentation = line.substring(0, line.length - trimmed.length);
        output.add('$indentation${match.group(1)}: [omitted_private_content]');
        continue;
      }
      output.add(line);
    }
    return output.join('\n');
  }

  String _sanitizeUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return '[redacted_url]';
    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }
}

final RegExp _privateLine = RegExp(
  r'^(问题|查询|用户回答|原始回答|模型输出|原始模型输出|源码|文件内容|片段内容|片段位置|绝对路径)\s*:',
);

final RegExp _privateListHeading = RegExp(
  r'^(来源片段摘要|引用片段摘要|源码摘要|文件内容摘要)\s*:',
);
