import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_move_compatibility.dart';
import 'package:pocket_save_editor/games/crystal/crystal_catalog.dart';
import 'package:pocket_save_editor/games/crystal/crystal_move_battle_info.dart';
import 'package:pocket_save_editor/games/crystal/crystal_pokemon_moves.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';

void main() {
  test(
    'Writes move IDs, current PP and PP Ups only in the party move fields',
    () {
      final original = Uint8List.fromList(syntheticCrystalSave());
      final reader = CrystalReader(original);
      const index = 5;
      final offset = 0x286d + index * 48;
      final moves = readCrystalMoves(original, offset);
      final edited = reader.withPartyMoves(index, [
        const CrystalMoveSlot(57, 20, 3),
        ...moves.skip(1),
      ]);

      final written = readCrystalMoves(edited, offset);
      expect(written.first.id, 57);
      expect(written.first.currentPp, 20);
      expect(written.first.ppUps, 3);
      for (var i = 0; i < original.length; i++) {
        final isMoveId = i >= offset + 2 && i < offset + 6;
        final isPp = i >= offset + 23 && i < offset + 27;
        if (!isMoveId && !isPp) expect(edited[i], original[i]);
      }
    },
  );

  test('Move compatibility data flags Golbat Surf without blocking it', () {
    expect(crystalCanLearnMove(42, 57), isFalse);
    expect(crystalCanLearnMove(131, 57), isTrue);
    expect(crystalCanLearnMove(42, 0), isTrue);
  });

  test('Evolved Pokémon inherit level moves from pre-evolutions only', () {
    expect(crystalCanLearnMove(12, 33), isTrue); // Butterfree inherits Tackle.
    expect(crystalCanLearnMove(12, 106), isTrue); // From Metapod: Harden.
    expect(
      crystalCanLearnMove(10, 106),
      isFalse,
    ); // Caterpie cannot inherit forward.
    expect(
      crystalMovePickerGroups(172).first.learnedBySpecies.values,
      isNot(contains(25)),
      reason: 'Pichu cannot inherit Pikachu level-up moves.',
    );

    final group = crystalMovePickerGroups(12).first;
    expect(group.levels[33], 1);
    expect(group.learnedBySpecies[33], 10);
    expect(group.levels[106], 1);
    expect(group.learnedBySpecies[106], 11);
    expect(
      crystalMoveLevelDescription(
        speciesId: 12,
        level: group.levels[33]!,
        learnedBySpeciesId: group.learnedBySpecies[33]!,
      ),
      'Caterpie · Nivel 1 · al nacer',
    );
    expect(
      crystalMoveLevelDescription(
        speciesId: 151,
        level: 1,
        learnedBySpeciesId: 151,
      ),
      'Nivel 1',
    );
  });

  test(
    'Move picker orders Golbat level moves then other and incompatible moves',
    () {
      final groups = crystalMovePickerGroups(42);
      expect(groups.first.label, 'Por nivel');
      final levels = groups.first.moveIds.map((id) => groups.first.levels[id]!);
      expect(levels, orderedEquals(levels.toList()..sort()));
      expect(groups[1].label, 'Otros métodos');
      expect(groups.last.label, 'No compatible en Cristal');
      expect(
        groups.last.moveIds,
        contains(57),
        reason: 'Surf is shown but marked incompatible for Golbat.',
      );
      final unavailableNames = groups.last.moveIds
          .map((id) => crystalMoves[id]!.name.toLowerCase())
          .toList();
      expect(
        unavailableNames,
        orderedEquals(unavailableNames.toList()..sort()),
      );
    },
  );

  test('Crystal move details report power, accuracy and Gen II category', () {
    expect(crystalMoveBattleInfo[57]!.power, 95);
    expect(crystalMoveBattleInfo[57]!.accuracy, 100);
    expect(crystalMoveDamageCategory(57, 21), 'Especial');
    expect(crystalMoveDamageCategory(10, 0), 'Físico');
    expect(crystalMoveDamageCategory(14, 0), 'Estado');
  });

  test('Rejects invalid move IDs and PP ranges', () {
    final reader = CrystalReader(Uint8List.fromList(syntheticCrystalSave()));
    final offset = 0x286d + 5 * 48;
    final moves = readCrystalMoves(reader.data, offset);
    expect(
      () => reader.withPartyMoves(5, [
        const CrystalMoveSlot(252, 0, 0),
        ...moves.skip(1),
      ]),
      throwsRangeError,
    );
    expect(
      () => reader.withPartyMoves(5, [
        const CrystalMoveSlot(57, 25, 3),
        ...moves.skip(1),
      ]),
      throwsRangeError,
    );
  });
}
