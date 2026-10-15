import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_pc_reader.dart';
import 'package:pocket_save_editor/widgets/crystal_pc_view.dart';
import 'package:pocket_save_editor/screens/pc_pokemon_detail_screen.dart';

void main() {
  testWidgets(
    'Grid opens detail and preserves the selected box when toggling views',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final original = syntheticCrystalSave();
      final data = Uint8List.fromList(original);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CrystalPcView(data: data)),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
      expect(
        (tester.widget<GridView>(find.byType(GridView)).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        4,
      );
      expect(
        tester
            .widget<GridView>(find.byType(GridView))
            .childrenDelegate
            .estimatedChildCount,
        20,
      );
      expect(find.text('GROWLITHE'), findsOneWidget);
      expect(find.text('Estadísticas'), findsNothing);
      await tester.tap(find.text('GROWLITHE'));
      await tester.pumpAndSettle();
      expect(find.byType(PcPokemonDetailScreen), findsOneWidget);
      expect(find.text('Caja 1 · Posición 1'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Caja siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Caja 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Ver como lista'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(find.text('Poliwrath — POLIWRATH'), findsOneWidget);
      await tester.tap(find.byTooltip('Ver como cuadrícula'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Caja 2'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pc-search')), 'poliwrath');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pc-search-results')), findsOneWidget);
      expect(find.textContaining('Caja 2 · Posición 1 · Nv.'), findsOneWidget);
      await tester.tap(find.text('Poliwrath — POLIWRATH'));
      await tester.pumpAndSettle();
      expect(find.text('Caja 2 · Posición 1'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(data, orderedEquals(original));
    },
  );

  testWidgets('Variocolor filter searches every box', (tester) async {
    final data = Uint8List.fromList(syntheticCrystalSave());
    final pc = CrystalPcReader(data);
    for (var boxIndex = 0; boxIndex < CrystalPcReader.boxCount; boxIndex++) {
      final box = pc.readBox(boxIndex);
      for (var slot = 0; slot < box.length; slot++) {
        final offset = CrystalPcReader.boxRecordOffset(boxIndex, slot);
        data[offset + 21] = 0x11;
        data[offset + 22] = 0x11;
      }
    }
    final first = CrystalPcReader.boxRecordOffset(0, 0);
    data[first + 21] = 0x2A;
    data[first + 22] = 0xAA;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrystalPcView(data: data)),
      ),
    );
    await tester.tap(find.byKey(const Key('pc-shiny-filter')));
    await tester.pumpAndSettle();
    expect(find.text('1 resultados en todas las cajas'), findsOneWidget);
    expect(
      find.text('Caja 1 · Posición 1 · Nv. 34 · Variocolor'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty slots are visible and do not open a detail', (
    tester,
  ) async {
    final data = Uint8List(32768);
    for (var i = 0; i < 14; i++) {
      data[(i < 7 ? 0x4000 : 0x6000) + (i % 7) * 0x450 + 1] = 255;
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrystalPcView(data: data)),
      ),
    );
    expect(find.text('Esta caja está vacía.'), findsOneWidget);
    expect(find.text('1 · Vacío'), findsOneWidget);
    await tester.tap(find.text('1 · Vacío'));
    await tester.pumpAndSettle();
    expect(find.byType(PcPokemonDetailScreen), findsNothing);
    await tester.scrollUntilVisible(
      find.text('20 · Vacío'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('20 · Vacío'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
