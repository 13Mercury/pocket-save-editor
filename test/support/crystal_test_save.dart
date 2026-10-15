import 'dart:typed_data';

import 'package:pocket_save_editor/core/pokemon_text_encoder.dart';
import 'package:pocket_save_editor/games/crystal/crystal_checksum.dart';
import 'package:pocket_save_editor/games/crystal/crystal_stats.dart';

/// Creates a deterministic synthetic Crystal save for automated tests.
/// It contains only fictional sample data; never load a user's save here.
Uint8List syntheticCrystalSave() {
  final data = Uint8List(32768);

  void writeWord(int offset, int value) {
    data[offset] = (value >> 8) & 0xff;
    data[offset + 1] = value & 0xff;
  }

  void writeName(int offset, String name) {
    data.setRange(offset, offset + 11, PokemonTextEncoder.encode(name));
  }

  writeName(0x200b, 'TESTER');
  writeName(0x2021, 'RIVAL');

  // Synthetic party: Magneton is used for the genderless editor coverage;
  // the final Golbat exercises the detail and move-edit screens.
  const partySpecies = [81, 1, 25, 58, 133, 42];
  data[0x2865] = partySpecies.length;
  for (var i = 0; i < partySpecies.length; i++) {
    data[0x2866 + i] = partySpecies[i];
    final offset = 0x286d + i * 48;
    data[offset] = partySpecies[i];
    data[offset + 21] = 0x88;
    data[offset + 22] = 0x88;
    data[offset + 27] = i == 5 ? 70 : 180;
    data[offset + 31] = i == 5 ? 51 : 20;
    if (i == 0) {
      data.setRange(offset + 2, offset + 6, [19, 211, 17, 98]);
      data.setRange(offset + 23, offset + 27, [14, 15, 18, 30]);
    }
    if (i == 5) {
      data[offset + 1] = 146; // Leftovers.
      data.setRange(offset + 2, offset + 6, [57, 0, 0, 0]);
      data[offset + 23] = (3 << 6) | 20;
      data[offset + 28] = 0;
    }
    final stats = CrystalStats.fromBox(data, offset);
    final values = [
      stats.hp,
      stats.attack,
      stats.defense,
      stats.speed,
      stats.specialAttack,
      stats.specialDefense,
    ];
    writeWord(offset + 34, stats.hp);
    for (var s = 0; s < values.length; s++) {
      writeWord(offset + 36 + s * 2, values[s]);
    }
    writeName(0x29cf + i * 11, i == 5 ? 'C' : 'SAMPLE');
  }

  const counts = [20, 19, 20, 19, 7, 13, 8, 0, 0, 0, 0, 1, 8, 10];
  for (var box = 0; box < 14; box++) {
    final start = (box < 7 ? 0x4000 : 0x6000) + (box % 7) * 0x450;
    final count = counts[box];
    data[start] = count;
    for (var slot = 0; slot < count; slot++) {
      final species = box == 0 && slot == 0
          ? 58
          : box == 1 && slot == 0
          ? 62
          : box == 2 && slot == 0
          ? 58
          : box == 11 && slot == 0
          ? 227
          : box == 13 && slot == 0
          ? 160
          : 1 + ((box * 20 + slot) % 251);
      data[start + 1 + slot] = species;
      final record = start + 22 + slot * 32;
      data[record] = species;
      data[record + 31] = box == 0 && slot == 0 ? 34 : 10;
      data[record + 27] = box == 0 && slot == 0 ? 160 : 100;
      data[record + 21] = 0x88;
      data[record + 22] = 0x88;
      if (box == 0 && slot == 0) {
        data.setRange(record + 2, record + 6, [172, 36, 126, 91]);
        data.setRange(record + 23, record + 27, [25, 20, 5, 10]);
      }
      final nickname = box == 0 && slot == 0 || box == 2 && slot == 0
          ? 'GROWLITHE'
          : box == 1 && slot == 0
          ? 'POLIWRATH'
          : 'SAMPLE';
      writeName(start + 882 + slot * 11, nickname);
    }
    data[start + count + 1] = 0xff;
  }

  // Pockets contain fictional test quantities, including representative
  // sample stacks used by the widget tests.
  data[0x2420] = 16;
  for (var i = 0; i < 16; i++) {
    data[0x2421 + i * 2] = i == 0 ? 17 : 1 + i;
    data[0x2422 + i * 2] = i == 0 ? 39 : 1;
  }
  data[0x2441] = 0xff;
  data[0x244a] = 12;
  for (var i = 0; i < 12; i++) {
    data[0x244b + i] = i == 0 ? 58 : 1 + i;
  }
  data[0x2457] = 0xff;
  data[0x2465] = 3;
  for (var i = 0; i < 3; i++) {
    data[0x2466 + i * 2] = 1 + i;
    data[0x2467 + i * 2] = 5;
  }
  data[0x246c] = 0xff;
  for (var i = 0; i < 57; i++) {
    data[0x23e7 + i] = i == 0 ? 28 : 1;
  }
  data[0x247f] = 35;
  for (var i = 0; i < 35; i++) {
    data[0x2480 + i * 2] = 1 + i;
    data[0x2481 + i * 2] = i == 0 ? 3 : 1;
  }
  data[0x24c6] = 0xff;

  CrystalChecksum.synchronizeBackup(data);
  return data;
}
