import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/notification_service.dart';

void main() {
  group('notificationContentFor', () {
    test('reads the visible notification payload', () {
      final content = notificationContentFor(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'Paquete disponible',
            body: 'Ya puedes retirar tu paquete.',
          ),
        ),
      );

      expect(content?.title, 'Paquete disponible');
      expect(content?.body, 'Ya puedes retirar tu paquete.');
    });

    test('reads title and body from a data-only push', () {
      final content = notificationContentFor(
        const RemoteMessage(
          data: {
            'title': 'Cuenta actualizada',
            'body': 'Tu balance fue actualizado.',
          },
        ),
      );

      expect(content?.title, 'Cuenta actualizada');
      expect(content?.body, 'Tu balance fue actualizado.');
    });
  });
}
