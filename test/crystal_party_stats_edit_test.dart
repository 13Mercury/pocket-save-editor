import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_stats.dart';
import 'package:pocket_save_editor/games/crystal/crystal_dv_properties.dart';
import 'package:pocket_save_editor/games/crystal/crystal_experience.dart';

void main() {
  test(
    'Reads and edits a party held item without changing other save bytes',
    () {
      final original = Uint8List.fromList(syntheticCrystalSave());
      final reader = CrystalReader(original);
      const index = 5;
      final itemOffset = 0x286d + index * 48 + 1;
      final previousItem = reader.partyHeldItemId(index);

      final modified = reader.withPartyHeldItem(index, 146);

      expect(CrystalReader(modified).partyHeldItemId(index), 146);
      expect(original[itemOffset], previousItem);
      for (var offset = 0; offset < original.length; offset++) {
        if (offset != itemOffset) {
          expect(
            modified[offset],
            original[offset],
            reason: 'Unexpected byte $offset',
          );
        }
      }
      expect(() => reader.withPartyHeldItem(index, 256), throwsRangeError);
    },
  );

  test('Uses Gen 2 species growth curves for experience thresholds', () {
    expect(CrystalExperience.forLevel(42, 20), 8000); // Golbat: Medium Fast
    expect(CrystalExperience.forLevel(42, 100), 1000000);
    expect(CrystalExperience.forLevel(39, 100), 800000); // Jigglypuff: Fast
    expect(
      CrystalExperience.forLevel(1, 100),
      1059860,
    ); // Bulbasaur: Medium Slow
    expect(CrystalExperience.forLevel(58, 100), 1250000); // Slow
    expect(CrystalExperience.forLevel(1, 1), 0);
  });

  test(
    'Changing party level updates experience and stats, preserving HP damage',
    () {
      final original = Uint8List.fromList(syntheticCrystalSave());
      const index = 5;
      final reader = CrystalReader(original);
      final recordOffset = 0x286d + index * 48;
      final oldLevel = reader.partyLevel(index);
      final newLevel = oldLevel < 90 ? oldLevel + 10 : oldLevel - 10;
      final oldStats = CrystalStats.fromParty(original, index);
      final oldHp =
          (original[recordOffset + 34] << 8) | original[recordOffset + 35];
      final missingHp = oldStats.hp - oldHp;

      final modified = reader.withPartyLevel(index, newLevel);
      final updated = CrystalReader(modified);
      final newStats = CrystalStats.fromBox(modified, recordOffset);
      final experience = updated.partyExperience(index);
      final minimum = CrystalExperience.forLevel(
        updated.data[recordOffset],
        newLevel,
      );
      final maximum = newLevel == 100
          ? minimum
          : CrystalExperience.forLevel(
              updated.data[recordOffset],
              newLevel + 1,
            );

      expect(updated.partyLevel(index), newLevel);
      expect(experience, greaterThanOrEqualTo(minimum));
      expect(experience, lessThan(maximum));
      expect(CrystalStats.fromParty(modified, index).summary, newStats.summary);
      final newHp =
          (modified[recordOffset + 34] << 8) | modified[recordOffset + 35];
      expect(newStats.hp - newHp, missingHp.clamp(0, newStats.hp));

      final allowedOffsets = <int>{
        recordOffset + 8,
        recordOffset + 9,
        recordOffset + 10,
        recordOffset + 31,
        for (var i = 34; i < 48; i++) recordOffset + i,
      };
      for (var i = 0; i < original.length; i++) {
        if (!allowedOffsets.contains(i)) {
          expect(modified[i], original[i], reason: 'Unexpected change at $i');
        }
      }
    },
  );

  test('Rejects party levels outside 1 to 100', () {
    final reader = CrystalReader(Uint8List.fromList(syntheticCrystalSave()));
    expect(() => reader.withPartyLevel(5, 0), throwsRangeError);
    expect(() => reader.withPartyLevel(5, 101), throwsRangeError);
  });

  test('Edits Gen 2 stat experience and recalculates party stats', () {
    final original = Uint8List.fromList(syntheticCrystalSave());
    final reader = CrystalReader(original);
    const index = 5;
    final recordOffset = 0x286d + index * 48;
    final dvBytes = original.sublist(recordOffset + 21, recordOffset + 23);
    final dvs = reader.partyDvs(index);
    final originalStats = CrystalStats.fromParty(original, index);

    final modified = reader.withPartyTraining(
      index,
      attackDv: dvs['attack']!,
      defenseDv: dvs['defense']!,
      speedDv: dvs['speed']!,
      specialDv: dvs['special']!,
      hp: 65535,
      attack: 65535,
      defense: 65535,
      speed: 65535,
      special: 65535,
    );

    expect(modified, isNot(same(original)));
    expect(
      modified.sublist(recordOffset + 21, recordOffset + 23),
      dvBytes,
      reason: 'Editing stat experience must preserve DVs.',
    );
    expect(CrystalReader(modified).partyStatExperience(index), {
      'hp': 65535,
      'attack': 65535,
      'defense': 65535,
      'speed': 65535,
      'special': 65535,
    });

    final recalculated = CrystalStats.fromBox(modified, recordOffset);
    final stored = CrystalStats.fromParty(modified, index);
    expect(recalculated.summary, isNot(originalStats.summary));
    expect(stored.hp, recalculated.hp);
    expect(stored.attack, recalculated.attack);
    expect(stored.defense, recalculated.defense);
    expect(stored.speed, recalculated.speed);
    expect(stored.specialAttack, recalculated.specialAttack);
    expect(stored.specialDefense, recalculated.specialDefense);

    // A change is expected in effort, current/max HP and the five other stats.
    final allowedOffsets = <int>{};
    for (var i = 11; i < 21; i++) {
      allowedOffsets.add(recordOffset + i);
    }
    for (var i = 34; i < 48; i++) {
      allowedOffsets.add(recordOffset + i);
    }
    for (var i = 0; i < original.length; i++) {
      if (!allowedOffsets.contains(i)) {
        expect(modified[i], original[i], reason: 'Unexpected change at $i');
      }
    }
    expect(originalStats.hp, greaterThan(0));
  });

  test('Rejects values outside Gen 2 stat experience range', () {
    final reader = CrystalReader(Uint8List.fromList(syntheticCrystalSave()));

    expect(
      () => reader.withPartyTraining(
        5,
        attackDv: 15,
        defenseDv: 15,
        speedDv: 15,
        specialDv: 15,
        hp: 65536,
        attack: 0,
        defense: 0,
        speed: 0,
        special: 0,
      ),
      throwsRangeError,
    );
  });

  test('Allows maximum DVs for a genderless Pokémon', () {
    final data = Uint8List.fromList(syntheticCrystalSave());
    const index = 0;
    final recordOffset = 0x286d + index * 48;
    // Mew is genderless in Gen 2; update the fixture's species consistently.
    data[0x2866 + index] = 151;
    data[recordOffset] = 151;
    final reader = CrystalReader(data);
    final effort = reader.partyStatExperience(index);
    final modified = reader.withPartyTraining(
      index,
      attackDv: 15,
      defenseDv: 15,
      speedDv: 15,
      specialDv: 15,
      hp: effort['hp']!,
      attack: effort['attack']!,
      defense: effort['defense']!,
      speed: effort['speed']!,
      special: effort['special']!,
    );

    expect(CrystalReader(modified).partyDvs(index), {
      'attack': 15,
      'defense': 15,
      'speed': 15,
      'special': 15,
    });
  });

  test('Changing DVs updates shiny status and gender from game rules', () {
    final data = Uint8List.fromList(syntheticCrystalSave());
    const index = 0;
    final recordOffset = 0x286d + index * 48;
    data[recordOffset + 21] = 0xaa; // Attack 10, Defense 10.
    data[recordOffset + 22] = 0xaa; // Speed 10, Special 10.
    final reader = CrystalReader(data);
    final effort = reader.partyStatExperience(index);

    final maxed = reader.withPartyTraining(
      index,
      attackDv: 15,
      defenseDv: 15,
      speedDv: 15,
      specialDv: 15,
      hp: effort['hp']!,
      attack: effort['attack']!,
      defense: effort['defense']!,
      speed: effort['speed']!,
      special: effort['special']!,
    );

    final updatedDvs = CrystalReader(maxed).partyDvs(index);
    expect(
      crystalIsShinyFromDvs(
        updatedDvs['attack']!,
        updatedDvs['defense']!,
        updatedDvs['speed']!,
        updatedDvs['special']!,
      ),
      isFalse,
    );
    expect(crystalGenderForDvs(18, 0, 0), 'Hembra');
  });

  test('Finds DVs for a requested gender while retaining shiny status', () {
    final femaleShinyAttack = crystalAttackDvForGender(
      speciesId: 42,
      gender: 'Hembra',
      speedDv: 10,
      currentAttackDv: 10,
      keepShiny: true,
    );
    expect(femaleShinyAttack, 2);
    expect(crystalGenderForDvs(42, femaleShinyAttack!, 10), 'Hembra');
    expect(crystalIsShinyFromDvs(femaleShinyAttack, 10, 10, 10), isTrue);
    expect(
      crystalAttackDvForGender(
        speciesId: 1,
        gender: 'Hembra',
        speedDv: 10,
        currentAttackDv: 2,
        keepShiny: true,
      ),
      isNull,
      reason: 'A female shiny Bulbasaur is impossible with Gen II DVs.',
    );
  });

  test('Sets and cures party Pokérus using its Gen 2 status byte', () {
    final original = Uint8List.fromList(syntheticCrystalSave());
    const index = 5;
    final reader = CrystalReader(original);
    final recordOffset = 0x286d + index * 48;
    final active = reader.withPartyPokerusStatus(index, 0x14);
    expect(CrystalReader(active).partyPokerusStatus(index), 0x14);
    expect(active[recordOffset + 28], 0x14);
    final cured = CrystalReader(active).withPartyPokerusStatus(index, 0x10);
    expect(CrystalReader(cured).partyPokerusStatus(index), 0x10);

    for (var i = 0; i < original.length; i++) {
      if (i != recordOffset + 28) {
        expect(active[i], original[i], reason: 'Unexpected change at $i');
      }
    }
  });
}
