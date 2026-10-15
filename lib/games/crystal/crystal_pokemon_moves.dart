import 'dart:math' as math;
import 'dart:typed_data';

import 'crystal_catalog.dart';

class CrystalMoveSlot {
  final int id;
  final int currentPp;
  final int ppUps;
  const CrystalMoveSlot(this.id, this.currentPp, this.ppUps);

  String get name => id == 0
      ? 'Sin movimiento'
      : crystalMoves[id]?.name ?? 'Movimiento desconocido (#$id)';
  int? get maxPp {
    final base = crystalMoves[id]?.basePp;
    return base == null ? null : base + ppUps * math.min(7, base ~/ 5);
  }
}

// Same move/PP positions in party (48 bytes) and box (32 bytes) records.
List<CrystalMoveSlot> readCrystalMoves(Uint8List data, int recordOffset) =>
    List.unmodifiable(
      List.generate(4, (slot) {
        final packedPp = data[recordOffset + 23 + slot];
        return CrystalMoveSlot(
          data[recordOffset + 2 + slot],
          packedPp & 0x3f,
          packedPp >> 6,
        );
      }),
    );

/// Writes the four move IDs and packed PP/PP-Up bytes in a Gen II record.
void writeCrystalMoves(
  Uint8List data,
  int recordOffset,
  List<CrystalMoveSlot> moves,
) {
  if (moves.length != 4) throw ArgumentError('Se requieren cuatro espacios.');
  for (var slot = 0; slot < 4; slot++) {
    final move = moves[slot];
    final info = crystalMoves[move.id];
    if (move.id != 0 && info == null) {
      throw RangeError('Movimiento inválido: ${move.id}');
    }
    if (move.ppUps < 0 || move.ppUps > 3) {
      throw RangeError.range(move.ppUps, 0, 3, 'PP Ups');
    }
    final maxPp = info == null
        ? 0
        : info.basePp + move.ppUps * math.min(7, info.basePp ~/ 5).toInt();
    if (move.currentPp < 0 || move.currentPp > maxPp) {
      throw RangeError.range(move.currentPp, 0, maxPp, 'PP');
    }
    data[recordOffset + 2 + slot] = move.id;
    data[recordOffset + 23 + slot] = move.currentPp | (move.ppUps << 6);
  }
}
