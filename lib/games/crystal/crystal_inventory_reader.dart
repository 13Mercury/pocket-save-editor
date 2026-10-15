import 'dart:typed_data';

import 'crystal_catalog.dart';
import 'crystal_item_icons.dart';

enum CrystalPocket {
  items('Mochila · Objetos', 0x2420, 20),
  keyItems('Mochila · Objetos clave', 0x244a, 25),
  balls('Mochila · Poké Balls', 0x2465, 12),
  machines('Mochila · MT/MO', 0x23e7, 57),
  pc('PC · Objetos', 0x247f, 50);

  final String label;
  final int offset;
  final int capacity;
  const CrystalPocket(this.label, this.offset, this.capacity);
}

class CrystalInventoryItem {
  final int id;
  final int quantity;
  final int? machineIndex;
  const CrystalInventoryItem(this.id, this.quantity, {this.machineIndex});
  bool get hasFixedQuantity =>
      crystalKeyItems.contains(id) || crystalMachineItems.skip(50).contains(id);

  String get name {
    final index = machineIndex;
    if (index == null) return crystalItemName(id);
    final code = index < 50
        ? 'MT${(index + 1).toString().padLeft(2, '0')}'
        : 'MO${(index - 49).toString().padLeft(2, '0')}';
    return '$code · ${crystalMoves[crystalMachineMoves[index]]!.name}';
  }
}

// International Crystal offsets from PKHeX SAV2Offsets.cs; pocket structures
// from pret/pokecrystal ram/wram.asm. Reading never writes into the save.
class CrystalInventoryReader {
  final Uint8List data;
  CrystalInventoryReader(this.data);

  // Only an existing stack's quantity byte changes. No insertion/removal,
  // item-ID edits or checksum changes; the existing export path handles backup/checksums.
  Uint8List withQuantity(CrystalPocket pocket, int slot, int quantity) {
    final items = read(pocket);
    RangeError.checkValidIndex(slot, items);
    final item = items[slot];
    if (pocket == CrystalPocket.keyItems || item.hasFixedQuantity) {
      throw const FormatException(
        'Los objetos clave y las MO conservan su cantidad.',
      );
    }
    RangeError.checkValueInInterval(quantity, 1, 99, 'quantity');
    final offset = pocket == CrystalPocket.machines
        ? pocket.offset + item.machineIndex!
        : pocket.offset + 2 + slot * 2;
    final modified = Uint8List.fromList(data);
    modified[offset] = quantity;
    return modified;
  }

  List<CrystalInventoryItem> read(CrystalPocket pocket) {
    if (data.length != 32768) {
      throw const FormatException('La partida debe tener 32768 bytes.');
    }
    if (pocket == CrystalPocket.machines) {
      final result = <CrystalInventoryItem>[];
      for (var i = 0; i < 57; i++) {
        final quantity = data[pocket.offset + i];
        if (quantity > 99) {
          throw const FormatException('Cantidad de MT/MO inválida.');
        }
        if (quantity != 0) {
          result.add(
            CrystalInventoryItem(
              crystalMachineItems[i],
              quantity,
              machineIndex: i,
            ),
          );
        }
      }
      return List.unmodifiable(result);
    }
    final count = data[pocket.offset];
    final stride = pocket == CrystalPocket.keyItems ? 1 : 2;
    if (count > pocket.capacity ||
        data[pocket.offset + 1 + count * stride] != 0xff) {
      throw FormatException(
        'No se pudo leer ${pocket.label}: datos inválidos.',
      );
    }
    return List.unmodifiable(
      List.generate(count, (i) {
        final offset = pocket.offset + 1 + i * stride;
        final id = data[offset];
        final quantity = stride == 1 ? 1 : data[offset + 1];
        if (id == 0 || id == 255 || quantity < 1 || quantity > 99) {
          throw FormatException(
            'Objeto o cantidad inválidos en ${pocket.label}.',
          );
        }
        return CrystalInventoryItem(id, quantity);
      }),
    );
  }
}
