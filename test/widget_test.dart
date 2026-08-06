import 'package:amutbar_cargo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AmutBar Cargo app root loads correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AmutBarCargoApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.title, 'AmutBar Cargo');
    expect(materialApp.locale, const Locale('fa', 'IR'));
  });
}
