import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedart/main.dart';

void main() {
  testWidgets('Pokédex app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PokedexApp());

    // Verifica que o título aparece
    expect(find.text('POKÉDEX'), findsOneWidget);

    // Verifica que o campo de busca existe
    expect(find.byType(TextField), findsOneWidget);
  });
}
