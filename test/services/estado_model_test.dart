import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/model/estado_model.dart';

EstadoResponse _doc(int dias) => EstadoResponse(
      documento: 'F-1',
      fecha: '01/01/2026',
      balance: 10,
      diasVencidos: dias,
    );

void main() {
  test('un documento vence solo después de 30 días, como en Legacy', () {
    expect(_doc(0).vencido, isFalse);
    expect(_doc(30).vencido, isFalse);
    expect(_doc(31).vencido, isTrue);
  });
}
