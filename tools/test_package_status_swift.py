#!/usr/bin/env python3
"""Run the shared status cases against the actual WidgetKit mapper and decoder."""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'ios/ICourierWidget/ICourierWidget.swift'

with tempfile.TemporaryDirectory(prefix='icourier-stage-test-') as folder:
    temp = pathlib.Path(folder)
    widget = SOURCE.read_text()
    # The persisted counts type is Foundation-only; exercise the actual decoder.
    counts = widget[widget.index('private struct WidgetCounts:'):widget.index('private struct WidgetFeatured:')]
    counts = counts.replace('private struct', 'struct')
    (temp / 'Counts.swift').write_text('import Foundation\n' + counts)
    def method(name):
        start = widget.index('  private static func ' + name)
        opening = widget.index('{', start)
        depth = 1
        end = opening + 1
        while depth:
            depth += (widget[end] == '{') - (widget[end] == '}')
            end += 1
        return widget[start:end].replace('private static func', 'static func')

    remote = widget[widget.index('private struct RemotePackage:'):widget.index('private enum WidgetRemoteRefresh')]
    (temp / 'Summary.swift').write_text('import Foundation\n' + remote.replace('private struct', 'struct') +
        'enum NativeSummary {\n' + method('summarize') + '\n' + method('stage') + '\n}\n')
    (temp / 'main.swift').write_text('''import Foundation
let rows = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))) as! [[String: Any]]
for row in rows {
  let actual = PackageStatusMapper.map(status: row["status"] as! String, isAvailable: row["isAvailable"] as! Bool, progress: row["progress"] as! Int)
  precondition(actual.rawValue == row["expected"] as! String, "Mismatch: \\(row["name"]!)")
}
let old = try JSONDecoder().decode(WidgetCounts.self, from: Data(#"{"disponible":1,"retenido":0,"enRuta":3,"enProceso":1,"total":5}"#.utf8))
precondition(!old.hasJourneyCounts && old.enTransito == nil && old.enDistribucion == nil)
let fresh = try JSONDecoder().decode(WidgetCounts.self, from: Data(#"{"disponible":1,"retenido":1,"enRuta":3,"enTransito":1,"enDistribucion":2,"enProceso":1,"total":5}"#.utf8))
precondition(fresh.hasJourneyCounts && fresh.enTransito == 1 && fresh.enDistribucion == 2)
let packages = try JSONDecoder().decode([RemotePackage].self, from: Data(#"[{"estatus":"Disponible","disponible":true,"retenido":true,"progreso":4},{"estatus":"Aduana","disponible":false,"retenido":true,"progreso":3},{"estatus":"Embarcado","disponible":false,"retenido":false,"progreso":2},{"estatus":"Recibido en sucursal","disponible":false,"retenido":false,"progreso":1},{"estatus":"Recibido para procesar","disponible":false,"retenido":false,"progreso":1}]"#.utf8))
let counts = NativeSummary.summarize(packages)
precondition(counts.total == 5 && counts.disponible == 1 && counts.retenido == 1 && counts.enRuta == 3 && counts.enTransito == 2 && counts.enDistribucion == 1 && counts.enProceso == 1)
print("Swift: \\(rows.count) shared status cases, 2 snapshot compatibility cases and native stage counts passed")
''')
    executable = temp / 'status-tests'
    subprocess.run(['swiftc', str(ROOT / 'ios/ICourierWidget/PackageStage.swift'),
                    str(temp / 'Counts.swift'), str(temp / 'Summary.swift'), str(temp / 'main.swift'), '-o', str(executable)], check=True)
    subprocess.run([str(executable), str(ROOT / 'test/fixtures/package_stages.json')], check=True)
