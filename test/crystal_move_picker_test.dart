import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/widgets/crystal_move_picker.dart';

void main() {
  testWidgets('Shows level and pre-evolution source for natural moves', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet<int>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CrystalMovePickerSheet(
                    speciesId: 12,
                    selectedMoveId: 0,
                  ),
                ),
                child: const Text('Abrir selector'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();

    expect(find.text('Caterpie · Nivel 1 · al nacer'), findsWidgets);
    expect(find.text('Metapod · Nivel 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filters the move list by name, type and damage category', (
    tester,
  ) async {
    int? selectedMove;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selectedMove = await showModalBottomSheet<int>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CrystalMovePickerSheet(
                      speciesId: 42,
                      selectedMoveId: 0,
                    ),
                  );
                },
                child: const Text('Abrir selector'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('move-picker-search')), 'surf');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('move-picker-item-57')), findsOneWidget);
    expect(find.text('Tackle'), findsNothing);

    await tester.tap(find.byKey(const Key('move-category-especial')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('move-picker-item-57')), findsOneWidget);

    await tester.tap(find.byKey(const Key('move-picker-type-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agua').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('move-picker-item-57')), findsOneWidget);

    await tester.tap(find.byKey(const Key('move-picker-item-57')));
    await tester.pumpAndSettle();
    expect(selectedMove, 57);
    expect(tester.takeException(), isNull);
  });
}
