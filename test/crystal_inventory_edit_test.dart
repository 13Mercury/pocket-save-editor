import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'support/crystal_test_save.dart';

import 'package:pocket_save_editor/games/crystal/crystal_inventory_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_checksum.dart';
import 'package:pocket_save_editor/games/crystal/crystal_item_icons.dart';

void main() {
  final original = syntheticCrystalSave();

  test('Changes only one quantity byte in Items, Balls, PC and TM pockets', () {
    for (final entry in {
      CrystalPocket.items: 0x2422,
      CrystalPocket.balls: 0x2467,
      CrystalPocket.pc: 0x2481,
      CrystalPocket.machines: 0x23e7,
    }.entries) {
      final data = Uint8List.fromList(original);
      final modified = CrystalInventoryReader(data)
          .withQuantity(entry.key, 0, 99);
      final differences = [
        for (var i = 0; i < data.length; i++)
          if (data[i] != modified[i]) i,
      ];
      expect(differences, [entry.value]);
      expect(data, orderedEquals(original));
      expect(
        CrystalInventoryReader(modified).read(entry.key).first.quantity,
        99,
      );
    }
  });

  test('Quantity edit survives backup/checksum export and reimport', () {
    final modified = CrystalInventoryReader(original)
        .withQuantity(CrystalPocket.pc, 0, 42);
    CrystalChecksum.synchronizeBackup(modified);
    expect(CrystalChecksum.isPrimaryValid(modified), isTrue);
    expect(CrystalChecksum.isBackupValid(modified), isTrue);
    expect(
      CrystalInventoryReader(modified).read(CrystalPocket.pc).first.quantity,
      42,
    );
    expect(modified[0x2481 - 0xe00], 42);
    final allowed = {0x2481, 0x2481 - 0xe00, 0x2d0d, 0x2d0e, 0x1f0d, 0x1f0e};
    for (var i = 0; i < original.length; i++) {
      if (!allowed.contains(i)) expect(modified[i], original[i]);
    }
  });

  test('Rejects deletion, overflow, missing slots, key items and HMs', () {
    final reader = CrystalInventoryReader(original);
    for (final quantity in [-1, 0, 100, 255]) {
      expect(
        () => reader.withQuantity(CrystalPocket.items, 0, quantity),
        throwsRangeError,
      );
    }
    expect(
      () => reader.withQuantity(CrystalPocket.items, 16, 4),
      throwsRangeError,
    );
    expect(
      () => reader.withQuantity(CrystalPocket.keyItems, 0, 4),
      throwsFormatException,
    );
    expect(
      () => reader.withQuantity(CrystalPocket.machines, 50, 4),
      throwsFormatException,
    );
    expect(reader.withQuantity(CrystalPocket.items, 0, 1)[0x2422], 1);
  });

  test(
    'Edits the selected duplicate stack rather than matching by item ID',
    () {
      final data = Uint8List.fromList(original);
      data.setRange(0x247f, 0x2485, [2, 18, 5, 18, 7, 255]);
      final modified = CrystalInventoryReader(data)
          .withQuantity(CrystalPocket.pc, 1, 9);
      expect(
        CrystalInventoryReader(modified)
            .read(CrystalPocket.pc)
            .map((i) => i.quantity),
        [5, 9],
      );
    },
  );

  test(
    'Icon mappings resolve old IDs and TM/HM discs without ID collisions',
    () {
      expect(crystalItemIconUrl(17), endsWith('/super-potion.png'));
      expect(crystalItemIconUrl(0x74), endsWith('/blue-card.png'));
      expect(crystalItemIconUrl(0xdd), endsWith('/tm-psychic.png'));
      expect(crystalItemIconUrl(0xf3), endsWith('/hm-normal.png'));
      expect(crystalItemIconUrl(254), isNull);
      expect(crystalItemIconUrl(0), isNull);
    },
  );
}
