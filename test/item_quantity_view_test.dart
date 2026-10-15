
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/widgets/crystal_inventory_view.dart';
import 'package:pocket_save_editor/widgets/item_sprite.dart';
import 'package:pocket_save_editor/games/crystal/crystal_inventory_reader.dart';

void main() {
  testWidgets('Plus and minus buttons adjust the stack quantity', (
    tester,
  ) async {
    var data = syntheticCrystalSave();
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: CrystalInventoryView(
              data: data,
              onChanged: (updated) => setState(() => data = updated),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Super Potion'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quantity-plus')));
    await tester.tap(find.byKey(const Key('quantity-plus')));
    await tester.tap(find.byKey(const Key('quantity-plus')));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    await tester.tap(find.text('Guardar cantidad'));
    await tester.pumpAndSettle();
    expect(find.text('×42'), findsOneWidget);
  });

  testWidgets(
    'Applies quantity through parent callback and keeps current pocket',
    (tester) async {
      var data = syntheticCrystalSave();
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: CrystalInventoryView(
                data: data,
                onChanged: (updated) => setState(() => data = updated),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Super Potion'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '42');
      await tester.tap(find.text('Guardar cantidad'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('×42'), findsOneWidget);
      expect(
        CrystalInventoryReader(data).read(CrystalPocket.items).first.quantity,
        42,
      );
      expect(find.text('Mochila · Objetos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Invalid quantities stay in dialog and cancelling leaves bytes intact',
    (tester) async {
      final data = syntheticCrystalSave();
      var callbacks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrystalInventoryView(
              data: data,
              onChanged: (_) => callbacks++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Super Potion'));
      await tester.pumpAndSettle();
      for (final value in ['', '0', '100']) {
        await tester.enterText(find.byType(TextFormField), value);
        await tester.tap(find.text('Guardar cantidad'));
        await tester.pumpAndSettle();
        expect(find.text('Introduce una cantidad de 1 a 99.'), findsOneWidget);
      }
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(callbacks, 0);
      expect(data[0x2422], 39);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Key items and HMs do not open quantity editor', (tester) async {
    final data = syntheticCrystalSave();
    // Keep only MO01 in the fixed-order machine pocket.
    data.fillRange(0x23e7, 0x23e7 + 57, 0);
    data[0x23e7 + 50] = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrystalInventoryView(
            data: data,
            onChanged: (_) => fail('Fixed quantities must not change'),
          ),
        ),
      ),
    );
    for (final label in ['Mochila · Objetos clave', 'Mochila · MT/MO']) {
      await tester.tap(find.byType(DropdownButton<CrystalPocket>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(label.contains('MT/MO') ? 'MO01 · Cut' : 'Old Rod'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unknown and failed item images use fallback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItemSprite(itemId: 254)));
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: ItemSprite(itemId: 17)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
