import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/model/servicio.dart';

void main() {
  test('prefers details_url and exposes only a safe web destination', () {
    final service = Servicio.fromJson({
      'registroID': ' service-1 ',
      'empresa': 'demo',
      'titulo': ' Casillero internacional ',
      'resumen': ' Recibe tus compras. ',
      'details_url': ' https://example.com/servicios/casillero ',
      'url': 'https://legacy.example.com',
      'orden': 1,
      'deleted': false,
    });

    expect(service.registroId, 'service-1');
    expect(service.titulo, 'Casillero internacional');
    expect(
      service.externalDetailsUri,
      Uri.https('example.com', '/servicios/casillero'),
    );
  });

  test('supports the legacy url field while services migrate', () {
    final service = Servicio.fromJson({
      'url': 'https://example.com/legacy',
      'orden': 2,
      'deleted': 'true',
    });

    expect(service.detailsUrl, 'https://example.com/legacy');
    expect(service.externalDetailsUri, Uri.https('example.com', '/legacy'));
    expect(service.deleted, isTrue);
  });

  test('malformed optional CMS values do not create a broken action', () {
    final service = Servicio.fromJson({
      'details_url': 'javascript:alert(1)',
      'orden': null,
    });

    expect(service.titulo, isEmpty);
    expect(service.orden, 0);
    expect(service.externalDetailsUri, isNull);
  });

  test('round-trips the details_url field', () {
    final service = Servicio(
      registroId: 'service-2',
      empresa: 'demo',
      titulo: 'Carga comercial',
      resumen: 'Opciones para empresas.',
      detailsUrl: 'https://example.com/carga',
      orden: 2,
      deleted: false,
    );

    final decoded = Servicio.fromJson(service.toJson());
    expect(decoded.detailsUrl, service.detailsUrl);
    expect(decoded.titulo, service.titulo);
  });
}
