import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/widgets/crystal_pc_view.dart';
import 'package:pocket_save_editor/screens/pc_pokemon_detail_screen.dart';
import 'package:pocket_save_editor/games/crystal/crystal_pc_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/screens/pokemon_edit_screen.dart';

void main() {
  testWidgets(
    'Opens PC detail, shows all stats and returns without changing save',
    (tester) async {
      final original = syntheticCrystalSave();
      final data = Uint8List.fromList(original);
      final mon = CrystalPcReader(data).readBox(0).first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CrystalPcView(data: data)),
        ),
      );
      await tester.tap(find.byTooltip('Ver como lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Growlithe — GROWLITHE'));
      await tester.pumpAndSettle();
      expect(find.byType(PcPokemonDetailScreen), findsOneWidget);
      expect(find.text('Caja 1 · Posición 1'), findsOneWidget);
      expect(find.text('Pokédex #058'), findsOneWidget);
      expect(find.text('Apodo: GROWLITHE'), findsOneWidget);
      expect(find.text('Fuego'), findsOneWidget);
      expect(find.text('${mon.level}'), findsOneWidget);
      expect(find.text('${mon.friendship}/255'), findsOneWidget);
      for (final label in [
        'PS máximos',
        'Ataque',
        'Defensa',
        'Ataque Especial',
        'Defensa Especial',
        'Velocidad',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(label), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('Movimientos'), 150);
      await tester.scrollUntilVisible(find.text('Flame Wheel'), 100);
      expect(find.text('Flame Wheel'), findsOneWidget);
      expect(find.text('PP 25/25'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PcPokemonDetailScreen), findsNothing);
      expect(find.text('Caja 1'), findsOneWidget);
      expect(data, orderedEquals(original));
    },
  );

  testWidgets('PC Pokémon can be edited and saved from its detail page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = syntheticCrystalSave();
    final initialReader = CrystalReader(Uint8List.fromList(original));
    CrystalReader? savedReader;

    Future<CrystalReader?> save(
      int boxIndex,
      int slotIndex,
      PokemonEditResult result,
    ) async {
      final nickname = initialReader.withBoxNickname(
        boxIndex,
        slotIndex,
        result.nickname,
      );
      savedReader = CrystalReader(nickname);
      return savedReader;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrystalPcView(data: initialReader.data, onSave: save),
        ),
      ),
    );
    await tester.tap(find.text('GROWLITHE'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar Pokémon'));
    await tester.tap(find.text('Editar Pokémon'));
    await tester.pumpAndSettle();
    expect(find.byType(PokemonEditScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pokemon-nickname')), 'FUEGO');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(savedReader, isNotNull);
    expect(savedReader!.boxNickname(0, 0), 'FUEGO');
    expect(find.text('Apodo: FUEGO'), findsOneWidget);
    expect(initialReader.boxNickname(0, 0), 'GROWLITHE');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Egg detail hides species, nickname and stats on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const egg = CrystalBoxPokemon(
        speciesId: 172,
        nickname: 'SECRET',
        level: 5,
        friendship: 10,
        isEgg: true,
        stats: null,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: PcPokemonDetailScreen(
            pokemon: egg,
            boxNumber: 14,
            slotNumber: 20,
          ),
        ),
      );
      expect(find.text('Huevo'), findsOneWidget);
      expect(find.text('Pendiente de eclosionar'), findsOneWidget);
      expect(find.text('Caja 14 · Posición 20'), findsOneWidget);
      expect(find.textContaining('SECRET'), findsNothing);
      expect(find.textContaining('Pichu'), findsNothing);
      expect(find.text('Estadísticas'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
