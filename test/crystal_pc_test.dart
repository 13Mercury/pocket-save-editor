import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_pc_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_stats.dart';

void main() {
  final fixture = syntheticCrystalSave();

  test('Reads all stored boxes in synthetic Crystal fixture without changing bytes', () {
    final bytes = Uint8List.fromList(fixture);
    final reader = CrystalPcReader(bytes);
    expect(List.generate(14, (i) => reader.readBox(i).length), [
      20,
      19,
      20,
      19,
      7,
      13,
      8,
      0,
      0,
      0,
      0,
      1,
      8,
      10,
    ]);
    final first = reader.readBox(0).first;
    expect(first.speciesId, 58);
    expect(first.nickname, 'GROWLITHE');
    expect(first.level, 34);
    expect(first.friendship, 160);
    expect(reader.readBox(11).single.speciesId, 227);
    expect(reader.readBox(13).first.speciesId, 160);
    expect(bytes, orderedEquals(fixture));
  });

  test(
    'Calculated Gen II stats agree with saved stats for all six party members',
    () {
      for (var i = 0; i < 6; i++) {
        final stored = CrystalStats.fromParty(fixture, i);
        final calculated = CrystalStats.fromBox(fixture, 0x286d + i * 48);
        expect(calculated.summary, stored.summary, reason: 'Party slot $i');
      }
      final golbat = CrystalStats.fromParty(fixture, 5);
      expect(golbat.hp, greaterThan(0));
      expect(golbat.speed, greaterThan(0));
    },
  );

  test('Rejects malformed sizes, box counts, terminators and species', () {
    expect(
      () => CrystalPcReader(Uint8List(1)).readBox(0),
      throwsFormatException,
    );
    expect(() => CrystalPcReader(fixture).readBox(14), throwsRangeError);
    for (final change in [
      {0x4000: 21},
      {0x4015: 0},
      {0x4016: 0},
    ]) {
      final bytes = Uint8List.fromList(fixture);
      change.forEach((offset, value) => bytes[offset] = value);
      expect(() => CrystalPcReader(bytes).readBox(0), throwsFormatException);
    }
  });

  test('Handles eggs without displaying hidden species stats', () {
    final bytes = Uint8List.fromList(fixture);
    bytes[0x4001] = 0xfd;
    final egg = CrystalPcReader(bytes).readBox(0).first;
    expect(egg.isEgg, isTrue);
    expect(egg.stats, isNull);
  });

  test('Stat experience rounding and maximum match Generation II', () {
    final mon = Uint8List(32);
    mon[0] = 1; // Bulbasaur: Attack 49.
    mon[31] = 100;
    mon[14] = 10; // ceil(sqrt(10)) / 4 = 1.
    expect(CrystalStats.fromBox(mon, 0).attack, 104);
    mon[13] = 255;
    mon[14] = 255;
    expect(CrystalStats.fromBox(mon, 0).attack, 166);
  });
}
