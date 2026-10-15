import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/widgets/crystal_inventory_view.dart';
import 'package:pocket_save_editor/games/crystal/crystal_inventory_reader.dart';

void main() {
  testWidgets('Switches from bag to PC and TM/HM without changing save', (
    tester,
  ) async {
    final original = syntheticCrystalSave();
    final data = Uint8List.fromList(original);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrystalInventoryView(data: data)),
      ),
    );
    expect(find.text('Super Potion'), findsOneWidget);
    expect(find.text('×39'), findsOneWidget);
    expect(find.text('Objetos · Solo lectura'), findsOneWidget);
    for (final label in ['PC · Objetos', 'Mochila · MT/MO']) {
      await tester.tap(find.byType(DropdownButton<CrystalPocket>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('MT01 · Dynamicpunch'), findsOneWidget);
    expect(find.text('×28'), findsOneWidget);
    expect(data, orderedEquals(original));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Displays a friendly error for invalid inventory data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrystalInventoryView(data: Uint8List(1))),
      ),
    );
    expect(find.text('La partida debe tener 32768 bytes.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
