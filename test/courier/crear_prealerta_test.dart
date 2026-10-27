import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/courier/crear_prealerta.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:intl/intl.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<CourierService>(CourierService());
  });

  tearDown(() => GetIt.I.reset());

  for (final offset in [1, 365, -1]) {
    testWidgets('selects and retains a prealert date $offset days from today',
        (tester) async {
      final today = DateUtils.dateOnly(DateTime.now());
      final selected = today.add(Duration(days: offset));
      await tester.pumpWidget(
        brandTestApp(
          config: GetIt.I<BrandConfig>(),
          child: const CrearPreAlertaPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      final pickerContext = tester.element(find.byType(DatePickerDialog));
      final localizations = MaterialLocalizations.of(pickerContext);
      await tester.tap(find.byTooltip(localizations.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextFormField),
        ),
        localizations.formatCompactDate(selected),
      );
      await tester.tap(find.text(localizations.okButtonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text(DateFormat('dd-MMM-yyyy').format(selected)),
          findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DatePickerDialog>(find.byType(DatePickerDialog))
              .initialDate,
          selected);
      await tester.tap(find.text(localizations.cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat('dd-MMM-yyyy').format(selected)),
          findsOneWidget);
    });
  }
}
