import 'package:catspot_mobile/app.dart';
import 'package:catspot_mobile/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CatspotApp renders and theme resolves CatspotColors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CatspotApp());

    expect(find.text('Catspot'), findsOneWidget);

    final BuildContext context = tester.element(find.byType(Scaffold));
    final CatspotColors? colors = Theme.of(context).extension<CatspotColors>();
    expect(colors, isNotNull);
    expect(colors!.brandPrimary, const Color(0xFFE86A33));
    expect(CatspotTheme.of(context).colors.brandPrimary, colors.brandPrimary);
  });
}
