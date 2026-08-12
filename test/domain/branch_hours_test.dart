import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/domain/branch_hours.dart';

void main() {
  group('parses the shapes brands actually type', () {
    test('day range with a 24-hour clock', () {
      final hours = BranchHours.parse('Lunes a viernes · 8:00–17:00')!;
      expect(hours.windows, hasLength(1));
      expect(hours.windows.single.days, {1, 2, 3, 4, 5});
      expect(hours.windows.single.opensAt, 8 * 60);
      expect(hours.windows.single.closesAt, 17 * 60);
    });

    test('day range with spelled meridiems and a trailing period', () {
      final hours = BranchHours.parse('Lunes a viernes de 8:00am a 5:00pm.')!;
      expect(hours.windows.single.opensAt, 8 * 60);
      expect(hours.windows.single.closesAt, 17 * 60);
    });

    test('meridiems written with periods and spaces', () {
      final hours = BranchHours.parse('Lunes a viernes de 8:00 a. m. a 5:00 p. m.')!;
      expect(hours.windows.single.closesAt, 17 * 60);
    });

    test('two clauses without any separator between them', () {
      final hours = BranchHours.parse(
        'Lunes a viernes de 8:00 a.m. a 5:00 p.m. Sábados de 8:00 a.m. a 12:00 p.m.',
      )!;
      expect(hours.windows, hasLength(2));
      expect(hours.windows[0].days, {1, 2, 3, 4, 5});
      expect(hours.windows[1].days, {6});
      expect(hours.windows[1].closesAt, 12 * 60);
    });

    test('comma separated clauses', () {
      final hours = BranchHours.parse(
        'Lunes a viernes 8:00-17:00, Sábados 8:00-12:00',
      )!;
      expect(hours.windows, hasLength(2));
    });

    test('hyphenated day range', () {
      final hours = BranchHours.parse('Lunes-Viernes 8:00-17:00')!;
      expect(hours.windows.single.days, {1, 2, 3, 4, 5});
    });

    test('day list joined with y', () {
      final hours = BranchHours.parse('Sábados y domingos de 9:00 a 13:00')!;
      expect(hours.windows.single.days, {6, 7});
    });

    test('split shift on the same days', () {
      final hours = BranchHours.parse(
        'Lunes a viernes 8:00-12:00, lunes a viernes 14:00-18:00',
      )!;
      expect(hours.windows, hasLength(2));
      expect(hours.windows[1].opensAt, 14 * 60);
    });

    test('every day collapses to the full week', () {
      final hours = BranchHours.parse('Todos los días de 9:00 a 21:00')!;
      expect(hours.windows.single.days, {1, 2, 3, 4, 5, 6, 7});
    });

    test('a range that wraps past Sunday', () {
      final hours = BranchHours.parse('Domingo a martes 9:00-13:00')!;
      expect(hours.windows.single.days, {7, 1, 2});
    });

    test('the shape bmcargo actually stores, letter abbreviations and all', () {
      final hours =
          BranchHours.parse('L-V 9:00am a 7:00pm, S 9:00am a 4:00pm')!;
      expect(hours.windows, hasLength(2));
      expect(hours.windows[0].days, {1, 2, 3, 4, 5});
      expect(hours.windows[0].opensAt, 9 * 60);
      expect(hours.windows[0].closesAt, 19 * 60);
      expect(hours.windows[1].days, {6});
      expect(hours.windows[1].closesAt, 16 * 60);
    });

    test('a colon hanging off the day range', () {
      final hours =
          BranchHours.parse('L a V: 9:00am a 7:00pm S 9:00am a 4:00pm')!;
      expect(hours.windows, hasLength(2));
      expect(hours.windows[0].days, {1, 2, 3, 4, 5});
      expect(hours.windows[0].closesAt, 19 * 60);
      expect(hours.windows[1].days, {6});
      expect(hours.windows[1].closesAt, 16 * 60);
    });

    test('single letters for the unambiguous days', () {
      expect(BranchHours.parse('J 8:00-12:00')!.windows.single.days, {4});
      expect(BranchHours.parse('D 8:00-12:00')!.windows.single.days, {7});
      expect(BranchHours.parse('L a X 8:00-12:00')!.windows.single.days,
          {1, 2, 3});
    });

    test('M alone is refused, since it names two different days', () {
      expect(BranchHours.parse('M 8:00-12:00'), isNull);
      expect(BranchHours.parse('L, M, X, J, V 8:00-12:00'), isNull);
    });

    test('English schedules', () {
      final hours = BranchHours.parse('Monday to Friday 8:00 am to 5:00 pm')!;
      expect(hours.windows.single.days, {1, 2, 3, 4, 5});
      expect(hours.windows.single.closesAt, 17 * 60);
    });
  });

  group('resolves the half of the day without guessing', () {
    test('a bare closing time earlier than opening can only be afternoon', () {
      final hours = BranchHours.parse('Lunes a viernes de 8:00 a 5:00')!;
      expect(hours.windows.single.closesAt, 17 * 60);
    });

    test('a bare closing time that already reads forward stays morning', () {
      final hours = BranchHours.parse('Sábados de 8:00 a 12:00')!;
      expect(hours.windows.single.closesAt, 12 * 60);
    });

    test('midnight and noon meridiems', () {
      final hours = BranchHours.parse('Lunes 12:00am a 11:00am')!;
      expect(hours.windows.single.opensAt, 0);
      expect(hours.windows.single.closesAt, 11 * 60);
    });
  });

  group('refuses anything it would have to guess at', () {
    const unreadable = [
      '',
      '   ',
      'Consultar horario en la sucursal',
      'Lunes a viernes, sábados con cita previa',
      'Abierto 24 horas',
      '24/7',
      'Lunes a viernes de 8:00 a.m. a 12:00 m. y de 2:00 p.m. a 5:00 p.m.',
      'De 8:00 a 17:00',
      'Lunes a viernes',
      'Horario variable',
      'Lun-Vie 8-5 / Sáb cerrado',
      'Lunes a viernes 17:00-8:00',
      'Lunes a viernes 8:00pm a 5:00am',
      'Lunes a viernes 25:00-30:00',
    ];

    for (final value in unreadable) {
      test('"$value"', () => expect(BranchHours.parse(value), isNull));
    }
  });

  group('reports the state against a clock', () {
    final hours = BranchHours.parse(
      'Lunes a viernes 8:00-17:00, Sábados 8:00-12:00',
    )!;

    // 2026-08-12 is a Wednesday, 2026-08-15 a Saturday, 2026-08-16 a Sunday.
    test('open in the middle of the day', () {
      final status = hours.statusAt(DateTime(2026, 8, 12, 10, 30))!;
      expect(status.state, BranchOpenState.open);
      expect(status.closesAt, 17 * 60);
      expect(status.minutesToClose, 390);
    });

    test('closing soon inside the last hour', () {
      final status = hours.statusAt(DateTime(2026, 8, 12, 16, 20))!;
      expect(status.state, BranchOpenState.closingSoon);
      expect(status.minutesToClose, 40);
    });

    test('the closing minute itself is already closed', () {
      final status = hours.statusAt(DateTime(2026, 8, 12, 17, 0))!;
      expect(status.state, BranchOpenState.closed);
      expect(status.opensInDays, 1);
    });

    test('before opening, it opens later today', () {
      final status = hours.statusAt(DateTime(2026, 8, 12, 6, 0))!;
      expect(status.state, BranchOpenState.closed);
      expect(status.opensAt, 8 * 60);
      expect(status.opensInDays, 0);
    });

    test('Saturday afternoon waits for Monday', () {
      final status = hours.statusAt(DateTime(2026, 8, 15, 15, 0))!;
      expect(status.state, BranchOpenState.closed);
      expect(status.opensInDays, 2);
      expect(status.opensOnWeekday, DateTime.monday);
    });

    test('Sunday waits for Monday, one day out', () {
      final status = hours.statusAt(DateTime(2026, 8, 16, 15, 0))!;
      expect(status.opensInDays, 1);
    });

    test('a split shift closes between its halves', () {
      final split = BranchHours.parse(
        'Lunes a viernes 8:00-12:00, lunes a viernes 14:00-18:00',
      )!;
      final status = split.statusAt(DateTime(2026, 8, 12, 13, 0))!;
      expect(status.state, BranchOpenState.closed);
      expect(status.opensAt, 14 * 60);
      expect(status.opensInDays, 0);
    });
  });
}
