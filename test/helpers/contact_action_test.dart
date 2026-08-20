import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/helpers/contact_action.dart';

void main() {
  test('normalizes legacy customer service and support destinations', () {
    expect(
      resolveExternalContactUri('servicio@example.com'),
      Uri.parse('mailto:servicio@example.com'),
    );
    expect(
      resolveExternalContactUri('support.example.com'),
      Uri.parse('https://support.example.com'),
    );
    expect(
      resolveExternalContactUri('https://support.example.com/help'),
      Uri.parse('https://support.example.com/help'),
    );
  });
}
