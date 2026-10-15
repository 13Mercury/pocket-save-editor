import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_catalog.dart';
import 'package:pocket_save_editor/games/crystal/crystal_pokemon_moves.dart';
import 'package:pocket_save_editor/games/crystal/crystal_inventory_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_pc_reader.dart';

void main() {
  final original = syntheticCrystalSave();

  test('Gen II catalog preserves historical types and includes every move', () {
    expect(crystalMoves.length, 251);
    expect(crystalSpeciesTypes.length, 251);
    expect(crystalTypesFor(42), ['Veneno', 'Volador']);
    expect(crystalTypesFor(81), ['Eléctrico', 'Acero']);
    expect(crystalTypesFor(35), ['Normal']);
    expect(crystalTypesFor(999), isEmpty);
    expect(crystalMoves[19]!.name, 'Fly');
    expect(crystalMoves[19]!.basePp, 15);
    expect(crystalMoves[174]!.typeId, 19); // Curse is ??? in Gen II.
  });

  test('Reads synthetic party and box moves without modifying the save', () {
    final data = Uint8List.fromList(original);
    final party = readCrystalMoves(data, 0x286d);
    expect(party.map((m) => m.id), [19, 211, 17, 98]);
    expect(party.map((m) => m.currentPp), [14, 15, 18, 30]);
    expect(party[0].maxPp, 15);
    final box = CrystalPcReader(data).readBox(0).first;
    expect(box.moves.map((m) => m.id), [172, 36, 126, 91]);
    expect(box.moves.map((m) => m.currentPp), [25, 20, 5, 10]);
    expect(data, orderedEquals(original));
  });

  test('PP masks, PP Ups, Gen II 40 PP cap and missing slots', () {
    final data = Uint8List(32);
    data[2] = 45; // Growl, 40 base PP; 3 PP Ups add 21, not 24.
    data[23] = (3 << 6) | 60;
    final moves = readCrystalMoves(data, 0);
    expect(moves[0].currentPp, 60);
    expect(moves[0].ppUps, 3);
    expect(moves[0].maxPp, 61);
    expect(moves[1].name, 'Sin movimiento');
    expect(const CrystalMoveSlot(255, 1, 0).name, contains('#255'));
    expect(const CrystalMoveSlot(255, 1, 0).maxPp, isNull);
  });

  test(
    'Reads all five synthetic pockets, including fixed TM/HM quantities',
    () {
      final data = Uint8List.fromList(original);
      final reader = CrystalInventoryReader(data);
      expect(CrystalPocket.values.map((p) => reader.read(p).length), [
        16,
        12,
        3,
        57,
        35,
      ]);
      final items = reader.read(CrystalPocket.items);
      expect(items.first.id, 17);
      expect(items.first.quantity, 39);
      expect(items.first.name, 'Super Potion');
      expect(reader.read(CrystalPocket.keyItems).first.quantity, 1);
      final machines = reader.read(CrystalPocket.machines);
      expect(machines.first.name, 'MT01 · Dynamicpunch');
      expect(machines.first.quantity, 28);
      expect(machines[4].id, 0xc4); // Dummy item 0xc3 is skipped.
      expect(machines[28].id, 0xdd); // Dummy item 0xdc is skipped.
      expect(machines[50].name, 'MO01 · Cut');
      expect(reader.read(CrystalPocket.pc).first.quantity, 3);
      expect(data, orderedEquals(original));
    },
  );

  test('Empty pockets, bad counts, terminators and quantities are handled', () {
    final empty = Uint8List(32768);
    for (final pocket in CrystalPocket.values) {
      if (pocket != CrystalPocket.machines) empty[pocket.offset + 1] = 255;
    }
    for (final pocket in CrystalPocket.values) {
      expect(CrystalInventoryReader(empty).read(pocket), isEmpty);
    }
    expect(
      () => CrystalInventoryReader(Uint8List(2)).read(CrystalPocket.pc),
      throwsFormatException,
    );
    for (final change in [
      {0x2420: 21},
      {0x2441: 0},
      {0x2422: 0},
      {0x23e7: 100},
    ]) {
      final data = Uint8List.fromList(original);
      change.forEach((offset, value) => data[offset] = value);
      final pocket = change.containsKey(0x23e7)
          ? CrystalPocket.machines
          : CrystalPocket.items;
      expect(
        () => CrystalInventoryReader(data).read(pocket),
        throwsFormatException,
      );
    }
    expect(crystalItemName(254), contains('#254'));
  });
}
