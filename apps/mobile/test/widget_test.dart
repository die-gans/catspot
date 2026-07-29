import 'package:catspot_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders Catspot title', (WidgetTester tester) async {
    await tester.pumpWidget(const CatspotApp());

    expect(find.text('Catspot'), findsOneWidget);
  });
}
