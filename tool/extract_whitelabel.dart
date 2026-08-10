import 'dart:convert';
import 'dart:io';

/// Audits fields migrated from the legacy AppInfo classes.
///
/// This intentionally does not rewrite configuration. It emits a deterministic
/// JSON snapshot with the legacy values and fails when a checked-in WhiteLabel
/// file drifts from that source.
const _legacyRevision = '4bb071ea672bc63b76a8ccf9851e9414564fda2e';

Future<void> main(List<String> arguments) async {
  final appInfoFiles = Directory('lib/apps')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => RegExp(r'appinfo_[^/]+\.dart$').hasMatch(file.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final extracted = <Map<String, String>>[];
  final failures = <String>[];
  for (final file in appInfoFiles) {
    final source = _legacySource(file.path);
    final legacy = <String, String>{
      'slug':
          _required(source, r'metricsPrefixKey\s*=>\s*"([^"]+)"').toLowerCase(),
      'currency': _required(source, r'''currencyCode\s*=\s*['"]([^'"]+)''')
          .replaceAll(r'\$', r'$'),
      'logoWide': _required(source, r'brandLogoImage\s*=>\s*"([^"]+)"'),
      'logoMark': _required(source, r'centerIconImage\s*=>\s*"([^"]+)"'),
      'primary': _lightColor(source, 'primaryColor'),
    };
    extracted.add(legacy);

    final configFile = File('whitelabel/${legacy['slug']}.json');
    if (!configFile.existsSync()) {
      failures.add('${legacy['slug']}: falta ${configFile.path}');
      continue;
    }
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final assets = config['assets'] as Map<String, dynamic>? ?? const {};
    final light = ((config['palettes'] as Map<String, dynamic>?)?['light']
            as Map<String, dynamic>?) ??
        const {};
    _compare(failures, legacy['slug']!, 'currency', legacy['currency'],
        config['currency']);
    _compare(failures, legacy['slug']!, 'logoWide', legacy['logoWide'],
        assets['logoWide']);
    _compare(failures, legacy['slug']!, 'logoMark', legacy['logoMark'],
        assets['logoMark']);
    _compare(failures, legacy['slug']!, 'primary', legacy['primary'],
        (light['primary'] as String?)?.toUpperCase());
  }

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(extracted));
  if (appInfoFiles.length != 35) {
    failures
        .add('Se esperaban 35 AppInfo; se encontraron ${appInfoFiles.length}.');
  }
  if (failures.isNotEmpty) {
    stderr.writeln('\nFalló la auditoría de migración:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
  }
}

String _legacySource(String path) {
  final result = Process.runSync(
    'git',
    ['show', '$_legacyRevision:$path'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError('No se pudo leer $path en $_legacyRevision.');
  }
  return result.stdout as String;
}

String _required(String source, String pattern) {
  final value = RegExp(pattern).firstMatch(source)?.group(1);
  if (value == null) {
    throw FormatException('No se encontró $pattern');
  }
  return value;
}

String _lightColor(String source, String variable) {
  final lightStart = source.indexOf('ThemeData getLightTheme()');
  if (lightStart < 0) {
    throw const FormatException('No se encontró getLightTheme');
  }
  final lightSource = source.substring(lightStart);
  final raw = _required(
    lightSource,
    'const $variable = Color\\(0x([0-9a-fA-F]{8})\\)',
  );
  return '#${raw.substring(2).toUpperCase()}';
}

void _compare(
  List<String> failures,
  String slug,
  String field,
  Object? legacy,
  Object? config,
) {
  if (legacy != config) {
    failures.add('$slug.$field: AppInfo=$legacy, config=$config');
  }
}
