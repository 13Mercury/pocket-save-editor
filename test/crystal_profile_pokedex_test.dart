import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/core/pokemon_text_encoder.dart';

void main() {
  test(
    'reads trainer profile, money, coins, gender, and badges from Crystal',
    () {
      final data = Uint8List(32768);
      data.setRange(0x200B, 0x200B + 11, PokemonTextEncoder.encode('RED'));
      data.setRange(0x2021, 0x2021 + 11, PokemonTextEncoder.encode('BLUE'));
      data.setRange(0x23DC, 0x23DF, [0x01, 0x23, 0x45]);
      data.setRange(0x23E3, 0x23E5, [0x34, 0x12]);
      data[0x23E5] = 0x85;
      data[0x23E6] = 0x02;
      data[0x3E3D] = 1;

      final reader = CrystalReader(data);

      expect(reader.trainerName, 'RED');
      expect(reader.rivalName, 'BLUE');
      expect(reader.money, 12345);
      expect(reader.coins, 0x1234);
      expect(reader.isFemale, isTrue);
      expect(reader.johtoBadges.take(8).toList(), [
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        true,
      ]);
      expect(reader.kantoBadges[1], isTrue);
      expect(reader.badgeCount, 4);
    },
  );

  test('reads seen and caught Pokédex flags by national number', () {
    final data = Uint8List(32768);
    // Pokédex number 1 is the low bit of the first byte.
    data[CrystalReader.pokedexSeenOffset] = 0x01;
    data[CrystalReader.pokedexCaughtOffset] = 0x01;
    // Pokédex number 251 is bit 2 of byte 31.
    data[CrystalReader.pokedexSeenOffset + 31] = 0x04;

    final reader = CrystalReader(data);

    expect(reader.hasSeenSpecies(1), isTrue);
    expect(reader.hasCaughtSpecies(1), isTrue);
    expect(reader.hasSeenSpecies(251), isTrue);
    expect(reader.hasCaughtSpecies(251), isFalse);
    expect(reader.hasSeenSpecies(0), isFalse);
    expect(reader.hasCaughtSpecies(252), isFalse);
    expect(reader.seenSpeciesCount, 2);
    expect(reader.caughtSpeciesCount, 1);
  });

  test(
    'edits only trainer profile fields and leaves checksum bytes untouched',
    () {
      final data = Uint8List(32768);
      data[0x2D0D] = 0xA5;
      data[0x1F0D] = 0x5A;
      data[0x2345] = 0x7C;
      final reader = CrystalReader(data);

      final edited = reader.withTrainerProfile(
        trainerName: 'ASH',
        rivalName: 'GARY',
        money: 12345,
        coins: 9876,
        johtoBadges: [true, false, true, false, true, false, true, false],
        kantoBadges: [false, true, false, true, false, true, false, true],
      );
      final updated = CrystalReader(edited);

      expect(updated.trainerName, 'ASH');
      expect(updated.rivalName, 'GARY');
      expect(updated.money, 12345);
      expect(updated.coins, 9876);
      expect(updated.badgeCount, 8);
      expect(edited[0x2D0D], 0xA5);
      expect(edited[0x1F0D], 0x5A);
      expect(edited[0x2345], 0x7C);
      expect(reader.money, 0);
    },
  );

  test('rejects profile values outside Crystal limits', () {
    final reader = CrystalReader(Uint8List(32768));
    final badges = List<bool>.filled(8, false);

    expect(
      () => reader.withTrainerProfile(
        trainerName: 'ASH',
        rivalName: 'GARY',
        money: 1000000,
        coins: 0,
        johtoBadges: badges,
        kantoBadges: badges,
      ),
      throwsRangeError,
    );
    expect(
      () => reader.withTrainerProfile(
        trainerName: 'ASH',
        rivalName: 'GARY',
        money: 0,
        coins: 10000,
        johtoBadges: badges,
        kantoBadges: badges,
      ),
      throwsRangeError,
    );
    expect(
      () => reader.withTrainerProfile(
        trainerName: 'VERY LONG NAME',
        rivalName: 'GARY',
        money: 0,
        coins: 0,
        johtoBadges: badges,
        kantoBadges: badges,
      ),
      throwsArgumentError,
    );
  });
}
