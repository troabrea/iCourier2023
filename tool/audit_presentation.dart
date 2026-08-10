import 'dart:io';

const _presentationRoots = [
  'lib/adicional',
  'lib/calculadora',
  'lib/courier',
  'lib/design_system',
  'lib/navigation',
  'lib/noticas',
  'lib/preguntas',
  'lib/servicios',
  'lib/sucursales',
  'lib/tracking',
];

final _visualLiterals = <MapEntry<String, RegExp>>[
  MapEntry('color literal', RegExp(r'\bColor\s*\(')),
  MapEntry('Material color literal', RegExp(r'\bColors\.')),
  MapEntry('fontFamily literal', RegExp(r'''fontFamily\s*:\s*['"]''')),
  MapEntry(
    'radius literal',
    RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
  ),
];

final _brandCondition = RegExp(
  r'''(?:brandSlug|metricsPrefixKey|pushChannelTopic|\.dominio)\s*(?:==|!=)''',
);

void main() {
  final failures = <String>[];
  for (final root in _presentationRoots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    for (final file in directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        for (final pattern in _visualLiterals) {
          if (pattern.value.hasMatch(line)) {
            failures.add(
              '${file.path}:${index + 1}: ${pattern.key}: ${line.trim()}',
            );
          }
        }
        if (_brandCondition.hasMatch(line)) {
          failures.add(
            '${file.path}:${index + 1}: condición de marca: ${line.trim()}',
          );
        }
      }
    }
  }

  final serviceFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
  for (final file in serviceFiles) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (_brandCondition.hasMatch(lines[index])) {
        failures.add(
          '${file.path}:${index + 1}: condición de marca: ${lines[index].trim()}',
        );
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Falló la auditoría de presentación:');
    for (final failure in failures.toSet()) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
      'Presentación validada: sin condiciones de marca ni literales visuales.');
}
