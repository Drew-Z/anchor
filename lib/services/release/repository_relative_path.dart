import 'package:path/path.dart' as p;

final _posixPathContext = p.Context(style: p.Style.posix);
final _windowsPathContext = p.Context(style: p.Style.windows);

bool isAbsolutePathOnAnyPlatform(String value) {
  final path = value.trim();
  if (path.isEmpty) return false;

  final uri = Uri.tryParse(path);
  return _posixPathContext.isAbsolute(path) ||
      _windowsPathContext.isAbsolute(path) ||
      (uri?.hasScheme ?? false);
}
