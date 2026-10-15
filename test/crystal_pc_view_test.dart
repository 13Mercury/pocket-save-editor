import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/widgets/crystal_pc_view.dart';

void main() {
  testWidgets('Switches boxes and displays empty and malformed states', (
    tester,
  ) async {
    final data = Uint8List(32768);
    for (var i = 0; i < 14; i++) {
      data[(i < 7 ? 0x4000 : 0x6000) + (i % 7) * 0x450 + 1] = 255;
    }
    data[0x4450] = 21;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrystalPcView(data: data)),
      ),
    );
    expect(find.text('Esta caja está vacía.'), findsOneWidget);
    expect(find.text('Caja 1 · 0/20 Pokémon'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Caja anterior',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Caja siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Caja 2'), findsAtLeastNWidgets(1));
    expect(find.textContaining('No se pudo leer la caja 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Caja anterior'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Caja 1'), findsAtLeastNWidgets(1));
    expect(find.text('Esta caja está vacía.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pc-box-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Caja 2').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo leer la caja 2'), findsOneWidget);
    for (var i = 2; i < 14; i++) {
      await tester.tap(find.byTooltip('Caja siguiente'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Caja 14'), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Caja siguiente',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Caja anterior'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Caja 13'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
